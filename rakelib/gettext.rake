# frozen_string_literal: true

# Translation tasks, the port's stand-in for upstream's po/meson.build
# (`i18n.gettext (meson.project_name(), …)`).
#
#   rake gettext:pot:update   re-extract the message set from lib/
#   rake gettext:mo:update    compile locale/<lang>/LC_MESSAGES/<domain>.mo,
#                             which is what the running app reads
#
# There is deliberately no po:update. The po/*.po are donated work, they carry
# the AppStream messages from data/metainfo.appdata.xml as well as the ones in
# lib/, and the pot below covers only the Ruby sources — the gem's extractor
# does not read AppStream XML. Merging that pot into the catalogues would
# delete every donated AppStream translation. When the message set genuinely
# changes, merge by hand with GNU msgmerge against a pot that covers both.
#
# The domain is upstream's meson project name, unchanged, so upstream's own
# catalogues apply; renaming it would orphan all 196 of them.
#
# GetText::Tools::Task is not used, even though it defines tasks by these
# names: it insists on a po/<locale>/<domain>.po layout, and upstream's
# catalogues are the flat po/<locale>.po that GNU gettext and meson expect.
# Moving them to suit the task generator would be the one thing a port of a
# translated app must not do.

require "gettext/tools"

namespace :gettext do
  domain = "com.cassidyjames.clairvoyant"
  pot_file = "po/#{domain}.pot"
  locales = File.read("po/LINGUAS").split
  sources = File.readlines("po/POTFILES.in", chomp: true).grep(/\.rb\z/)

  namespace :pot do
    desc "Extract the translatable strings from lib/ into #{pot_file}"
    task :update do
      GetText::Tools::XGetText.run(
        *sources,
        "--output",
        pot_file,
        "--package-name",
        "clairvoyant",
        "--package-version",
        "3.1.12",
        # The gem's Ruby parser drops translator comments unless asked for
        # them, and every one of upstream's says which sense of a reply is
        # meant.
        "--add-comments=TRANSLATORS",
      )
    end
  end

  namespace :mo do
    desc "Compile po/*.po into locale/<lang>/LC_MESSAGES/#{domain}.mo"
    task :update do
      locales.each do |locale|
        "locale/#{locale}/LC_MESSAGES".then do |mo_dir|
          mkdir_p(mo_dir)
          GetText::Tools::MsgFmt.run(
            "po/#{locale}.po",
            "--output",
            File.join(mo_dir, "#{domain}.mo"),
          )
        end
      end
    end
  end
end
