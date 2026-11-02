# frozen_string_literal: true

require 'gettext'

require_relative 'config'

# Intl is the gettext binding upstream does in src/Application.vala's main():
#
#   Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
#   Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
#   Intl.textdomain (Config.GETTEXT_PACKAGE);
#
# The domain name is upstream's, unchanged, so the port reads upstream's own
# po/ catalogues: a .mo is looked up at
# <LOCALE_DIR>/<lang>/LC_MESSAGES/com.cassidyjames.clairvoyant.mo.
#
# glib2 only exposes bindtextdomain for GTK's own strings, so the app's strings
# go through the pure-Ruby `gettext` gem. Its bindtextdomain binds to a class
# rather than to the process, which is why every class with strings includes
# this module: the lookup walks the ancestors and finds the domain bound here.
# GLib gets the same binding for the AppStream and desktop-file messages it
# translates itself.
module Intl
  include GetText

  bindtextdomain(Config::GETTEXT_PACKAGE, path: Config::LOCALE_DIR)
  GLib::GetText.bindtextdomain(Config::GETTEXT_PACKAGE, Config::LOCALE_DIR)
end
