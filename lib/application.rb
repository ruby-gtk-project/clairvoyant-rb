# frozen_string_literal: true

require 'adwaita'

require_relative 'config'
require_relative 'intl'
require_relative 'main_window'
require_relative 'resources'
require_relative 'style'

# Application is the app itself: one window, and the accelerators that close it.
#
# Ported from src/Application.vala. Activating with a window already up presents
# that one instead of building a second, and the app.quit action — on Escape,
# Ctrl+Q and Ctrl+W, exactly upstream's list — destroys the window.
#
# Adwaita::Application is broken in the Ruby bindings, so the application object
# is a Gtk::Application with Adwaita initialised by hand; the window is still an
# Adwaita one.
class Application
  include Intl

  # Upstream's set_accels_for_action ("app.quit", {…}).
  QUIT_ACCELS = ['Escape', '<Ctrl>Q', '<Ctrl>W'].freeze

  def build
    app.tap do
      app.signal_connect('activate') do
        if app.windows.empty?
          start
        else
          app.windows.first.present
        end
      end
    end
  end

  def run = app.run([])

  def app
    @app ||= begin
      Adwaita.init
      Gtk::Application.new(Config::APP_ID, :default_flags)
    end
  end

  def main_window = @main_window ||= MainWindow.new(app)

  def quit_action = @quit_action ||= Gio::SimpleAction.new('quit', nil)

  private

  # The icons and the stylesheet are per-display, so they are registered once a
  # display exists — which is to say on activate, not at construction.
    def start
      Resources.register
      Style.apply

      main_window.build
      main_window.present

      quit_action.tap do |action|
        app.add_action(action)
        app.set_accels_for_action('app.quit', QUIT_ACCELS)

        action.signal_connect('activate') { main_window.close }
      end
    end
end
