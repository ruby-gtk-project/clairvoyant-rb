# frozen_string_literal: true

require 'adwaita'

require_relative 'about_dialog'
require_relative 'config'
require_relative 'fortune_label'
require_relative 'fortunes'
require_relative 'intl'
require_relative 'resources'

# MainWindow is the whole of the app on screen: a flat header bar with an About
# button, the fortune, and the button that asks again.
#
# Ported from src/MainWindow.vala. The window is not resizable, has no visible
# title, and its content is a Gtk.WindowHandle wrapping a vertical box, so the
# entire surface — fortune and all — drags the window.
class MainWindow
  include Intl

  def initialize(app)
    @app = app
  end

  def build
    window.tap do |win|
      win.content = window_handle

      window_handle.tap do |handle|
        handle.child = main_layout

        main_layout.tap do |layout|
          layout.append(header)
          layout.append(fortune_label.build)
          layout.append(ask_button)

          header.pack_start(about_button)

          about_button.signal_connect('clicked') { about_dialog.present }
          ask_button.signal_connect('clicked') { randomize_fortune }

          # A fresh fortune every time the window comes up, and the one already
          # showing is allowed — upstream's `allow_current` on realize.
          fortune_label.signal_connect('realize') { randomize_fortune(allow_current: true) }
        end
      end

      # Upstream takes the window title from the AppData the About window has
      # already parsed, rather than repeating the app's name in the source.
      win.title = about_dialog.application_name
    end
  end

  def present = window.present

  def close = window.destroy

  # Adwaita::ApplicationWindow, not Gtk::ApplicationWindow: upstream's window is
  # an Adw.ApplicationWindow with `set_content`, and the Gtk one would draw its
  # own titlebar above the header bar in the box.
  #
  # (Adwaita::Application is broken in the bindings, so the application object
  # handed in stays a Gtk::Application.)
  def window
    @window ||= Adwaita::ApplicationWindow.new(@app).tap do |win|
      win.icon_name = Config::APP_ID
      win.resizable = false
    end
  end

  def window_handle = @window_handle ||= Gtk::WindowHandle.new
  def main_layout = @main_layout ||= Gtk::Box.new(:vertical, 0)

  def header
    @header ||= Gtk::HeaderBar.new.tap do |header|
      header.title_widget = Gtk::Label.new(nil)
      header.add_css_class('flat')
    end
  end

  def about_button
    @about_button ||= Gtk::Button.new.tap do |button|
      button.icon_name = Resources::ABOUT_ICON
      button.tooltip_text = _('About')
      button.add_css_class('dim-label')
    end
  end

  def fortune_label
    @fortune_label ||= FortuneLabel.new.tap do |label|
      label.margin_top = 24
      label.margin_bottom = 24
    end
  end

  def ask_button
    @ask_button ||= Gtk::Button.new(label: _('Ask Again')).tap do |button|
      button.halign = :center
      button.margin_bottom = 48
      button.add_css_class('suggested-action')
      button.add_css_class('pill')
    end
  end

  def about_dialog
    @about_dialog ||= AboutDialog.new.build.tap do |about|
      about.transient_for = window
    end
  end

  private

  # Upstream's randomize_fortune: draw a page, and unless the caller allows the
  # one already showing, draw again until it changes.
    def randomize_fortune(allow_current: false)
      Fortunes.random_page_name.then do |name|
        if allow_current || name != fortune_label.stack.visible_child_name
          fortune_label.stack.visible_child_name = name
        else
          randomize_fortune
        end
      end
    end
end
