# frozen_string_literal: true

# Translation tasks, the port's stand-in for upstream's po/meson.build
# (`i18n.gettext (meson.project_name(), …)`).
#
#   rake gettext:po:update   re-extract the message set and merge it into the
#                            catalogues — only when the strings themselves
#                            changed; po/*.po is donated work and is never
#                            edited by hand
#   rake gettext:mo:update   compile locale/<lang>/LC_MESSAGES/<domain>.mo,
#                            which is what the running app reads
#
# The domain is upstream's meson project name, unchanged, so upstream's own
# catalogues apply; renaming it would orphan all 196 of them.

require "gettext/tools/task"

GetText::Tools::Task.define do |task|
  task.domain = "com.cassidyjames.clairvoyant"
  task.package_name = "clairvoyant"
  task.package_version = "3.1.12"
  task.files = File.readlines("po/POTFILES.in", chomp: true).grep(/\.rb\z/)
  task.po_base_directory = "po"
  task.mo_base_directory = "locale"
  task.locales = File.read("po/LINGUAS").split
  # The gem's Ruby parser drops translator comments unless asked for them, and
  # every one of upstream's says which sense of a reply is meant.
  task.xgettext_options = ["--add-comments=TRANSLATORS"]
end
