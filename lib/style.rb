# frozen_string_literal: true

require 'adwaita'

require_relative 'config'

# Style loads upstream's only stylesheet, data/styles/style.css, which tints the
# window background and foreground with the user's accent colour.
#
# Ported from data/styles/style.css and the gresource entry that ships it:
# upstream puts the file in its GResource at the application's base path, where
# GtkApplication picks it up automatically. The port has no GResource, so the
# same file is loaded through a Gtk::CssProvider at the application priority,
# which is where an app's own stylesheet belongs — above the theme, below the
# user's own overrides.
module Style
  PATH = File.join(Config::DATA_DIR, 'styles', 'style.css')

  def self.apply(display = Gdk::Display.default)
    Gtk::StyleContext.add_provider_for_display(
      display,
      provider,
      Gtk::StyleProvider::PRIORITY_APPLICATION,
    )
  end

  def self.provider
    @provider ||= Gtk::CssProvider.new.tap do |provider|
      provider.load_from_path(PATH)
    end
  end
end
