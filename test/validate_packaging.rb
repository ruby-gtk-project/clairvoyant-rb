# frozen_string_literal: true

# Validates the two installed-data components upstream's meson build checks
# with its own tests — validate-desktop and validate-appdata — which this
# port had neither a build step for nor a test of until now.
#
#   ruby test/validate_packaging.rb
#
# Needs `msgfmt` (the `gettext` package), which the dev shell already carries
# as a nativeBuildInput for exactly this merge. No GTK and no display are
# needed, so this does not go through xvfb-run.
#
# It runs the same two merges flake.nix's installPhase does —
# `msgfmt --desktop` on data/launcher.desktop.in and `msgfmt --xml` on
# data/metainfo.appdata.xml — against a temporary output, then checks the
# merged result the way upstream's validate-desktop (desktop-file-validate)
# and validate-appdata (appstreamcli validate) checks would: that the keys a
# desktop entry and an AppStream component must carry are present and hold
# the values the source templates set.

require 'open3'
require 'tmpdir'

DATA_DIR = File.expand_path('../data', __dir__)
PO_DIR = File.expand_path('../po', __dir__)

$checks = 0
$failed = []

def check(description)
  $checks += 1
  ok = yield
  puts(ok ? "ok   #{description}" : "FAIL #{description}")
  unless ok
    $failed << description
  end
  ok
rescue StandardError => e
  puts "FAIL #{description} (#{e.class}: #{e.message})"
  $failed << description
  false
end

def run!(*cmd)
  stdout, stderr, status = Open3.capture3(*cmd)
  unless status.success?
    raise "#{cmd.join(' ')} failed: #{stderr}"
  end

  stdout
end

# Upstream's data/metainfo.appdata.xml.in's own <id>, read the same way
# flake.nix's installPhase finds the AppStream id to name the merged files
# after.
def component_id
  File.read(File.join(DATA_DIR, 'metainfo.appdata.xml'))[%r{<id>(.*?)</id>}, 1]
end

# --- validate-desktop ------------------------------------------------------

def parse_desktop_entry(text)
  text.lines
      .map(&:strip)
      .reject { |line| line.empty? || line.start_with?('#') || line.start_with?('[') }
      .map { |line| line.split('=', 2) }
      .to_h
end

Dir.mktmpdir do |tmp|
  desktop_path = File.join(tmp, "#{component_id}.desktop")

  run!(
    'msgfmt',
    '--desktop',
    "--template=#{File.join(DATA_DIR, 'launcher.desktop.in')}",
    '-d',
    PO_DIR,
    '-o',
    desktop_path,
  )

  entry = parse_desktop_entry(File.read(desktop_path))

  check('desktop entry has a Name') { !entry['Name'].to_s.empty? }
  check('desktop entry has a GenericName') { entry['GenericName'] == 'Fortune Teller' }
  check('desktop entry Comment matches the source template') do
    entry['Comment'] == 'Ask questions, get psychic answers'
  end
  check('desktop entry Keywords list the magic-8-ball terms') do
    entry['Keywords'].to_s.split(';').include?('magic')
  end
  check('desktop entry Exec names the launcher') { entry['Exec'] == 'clairvoyant' }
  check('desktop entry Icon names the component id') { entry['Icon'] == component_id }
  check('desktop entry Type is Application') { entry['Type'] == 'Application' }
  check('desktop entry carries at least one localized Comment') do
    entry.keys.any? { |key| key.start_with?('Comment[') }
  end
end

# --- validate-appdata -------------------------------------------------------

Dir.mktmpdir do |tmp|
  appdata_path = File.join(tmp, "#{component_id}.metainfo.xml")

  run!(
    'msgfmt',
    '--xml',
    "--template=#{File.join(DATA_DIR, 'metainfo.appdata.xml')}",
    '-d',
    PO_DIR,
    '-o',
    appdata_path,
  )

  merged = File.read(appdata_path)

  check('appdata id matches the desktop component id') do
    merged[%r{<id>(.*?)</id>}, 1] == component_id
  end
  check('appdata declares a project_license') do
    !merged[%r{<project_license>(.*?)</project_license>}, 1].to_s.empty?
  end
  check('appdata declares a metadata_license') do
    !merged[%r{<metadata_license>(.*?)</metadata_license>}, 1].to_s.empty?
  end
  check('appdata has an unqualified <name>') { merged =~ %r{<name>[^<]+</name>} }
  check('appdata has an unqualified <summary>') { merged =~ %r{<summary>[^<]+</summary>} }
  check('appdata picked up at least one localized <summary>') do
    merged =~ /<summary xml:lang="[^"]+">/
  end
  check('appdata names a release matching this build\'s version') do
    require_relative '../lib/config'
    merged.include?(%(<release version="#{Config::VERSION}"))
  end
  check('appdata tag nesting balances (open == close for name/summary/description/release)') do
    %w[name summary description release].all? do |tag|
      merged.scan(/<#{tag}[\s>]/).length == merged.scan("</#{tag}>").length
    end
  end
end

puts
puts "#{$checks - $failed.length} of #{$checks} checks passed"

if $failed.empty?
  puts 'VALIDATE OK'
else
  puts "VALIDATE FAILED: #{$failed.join(', ')}"
  exit(1)
end
