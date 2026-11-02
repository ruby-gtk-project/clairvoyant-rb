# frozen_string_literal: true

require 'adwaita'

require_relative 'config'

# Resources is where the port keeps what upstream compiles into a GResource and
# installs into the icon theme.
#
# Ported from data/gresource.xml plus the install_data calls in
# data/meson.build. Upstream's about-symbolic.svg is looked up from the
# GResource icon path, and its app.svg and symbolic.svg are renamed to the app
# ID at install time. glib-compile-resources has no counterpart here, so the
# three icons sit under data/icons in the layout the icon theme expects —
# hicolor/scalable/apps/<app-id>.svg and so on — and that directory is added to
# the display's icon theme search path, which makes them resolve by name just
# as the installed ones do.
module Resources
  ICON_DIR = File.join(Config::DATA_DIR, 'icons')

  # Upstream's data/metainfo.appdata.xml.in, aliased as metainfo.xml in the
  # GResource and read by the About window.
  METAINFO = File.join(Config::DATA_DIR, 'metainfo.appdata.xml')

  # The action icon the header bar's About button wears.
  ABOUT_ICON = 'about-symbolic'

  def self.register(display = Gdk::Display.default)
    Gtk::IconTheme.get_for_display(display).add_search_path(ICON_DIR)
  end
end
