# frozen_string_literal: true

# Drives the real application through everything the port puts on screen, one
# step per turn of the GTK main loop, and writes a screenshot of each state.
#
#   xvfb-run -a ruby test/drive_main_window.rb
#
# The PNGs under tmp/shots are what a real session looks like. Run it under a
# language to check the translations on screen as well:
#
#   LANGUAGE=de xvfb-run -a ruby test/drive_main_window.rb
#
# which needs the catalogues compiled first, with `rake gettext:mo:update`.

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'application'
require 'fortunes'
require 'intl'
require_relative 'gtk_driver'

# The labels on screen are translated, so the expectations have to be too: a
# run under LANGUAGE=de must compare against the German, not the msgid. The
# gettext gem binds a domain to a class, so the lookup needs a class that
# includes the app's binding rather than a bare call at the top level.
class Expected
  include Intl

  def t(msgid) = _(msgid)
end

EXPECTED = Expected.new

APP = Application.new

GtkDriver.drive(APP, shots: 'tmp/shots') do |d, app|
  d.window { app.main_window.window }

  d.step('the window') do
    app.main_window.then do |win|
      d.check('titled from the AppData') { win.window.title == 'Clairvoyant' }
      d.check('the ask button is translated') { win.ask_button.label == EXPECTED.t('Ask Again') }
      d.check('not resizable') { !win.window.resizable? }
      d.check('header bar is flat') { win.header.css_classes.include?('flat') }
      d.check('header title is blank') { win.header.title_widget.text.to_s.empty? }
      d.check('about button is dimmed') { win.about_button.css_classes.include?('dim-label') }
      d.check('about icon resolves') do
        Gtk::IconTheme.get_for_display(Gdk::Display.default).has_icon?('about-symbolic')
      end
      d.check('ask button is a suggested pill') do
        %w[suggested-action pill].all? { |css| win.ask_button.css_classes.include?(css) }
      end
      d.shot('01-window')
    end
  end

  d.step('the fortune') do
    app.main_window.fortune_label.stack.then do |stack|
      d.check('one page per fortune') { stack.pages.n_items == Fortunes::ENTRIES.length }
      d.check('crossfades') { stack.transition_type == Gtk::StackTransitionType::CROSSFADE }
      d.check('a page is showing') { Fortunes.page_names.include?(stack.visible_child_name) }

      # The page the label belongs to, asked of the child itself: during a
      # crossfade the stack's visible_child_name is already the incoming page
      # while visible_child still answers with the outgoing one.
      stack.visible_child.then do |page|
        Fortunes.entry(stack.get_page(page).name).then do |fortune|
          page.first_child.then do |label|
            d.check('the answer is the showing page’s fortune') do
              label.text == EXPECTED.t(fortune.title)
            end
            d.check('the answer is a selectable title') do
              label.selectable? && label.css_classes.include?('title-1')
            end
            d.check('the answer is coloured by its kind') do
              label.css_classes.include?(fortune.css_class)
            end
          end
        end
      end
    end
  end

  d.step('ask again') do
    app.main_window.fortune_label.stack.visible_child_name.then do |before|
      app.main_window.ask_button.signal_emit('clicked')

      d.check('a different fortune comes up') do
        app.main_window.fortune_label.stack.visible_child_name != before
      end
    end
  end

  # A tick later, so the crossfade has finished and the picture is of the new
  # answer rather than of the transition.
  d.step('the new fortune') do
    d.shot('02-asked-again')
  end

  d.step('about') do
    app.main_window.about_button.signal_emit('clicked')

    app.main_window.about_dialog.then do |about|
      d.check('the about window opens') { about.visible? }
      d.check('named from the AppData') { about.application_name == 'Clairvoyant' }
      d.check('the app icon is the component id') { about.application_icon == 'com.cassidyjames.clairvoyant' }
      d.check('the developer is credited') { about.developer_name == 'Cassidy James Blaede' }
      d.check('the summary is the comment') { about.comments == 'Ask questions, get psychic answers' }
      d.check('licensed GPL-3.0-or-later') { about.license_type == Gtk::License::GPL_3_0 }
      d.check('the version is upstream\'s') { about.version == '3.1.12' }
      d.check('it links the issue tracker') { about.issue_url.include?('clairvoyant/issues') }
      d.check('it carries the release notes') { about.release_notes.to_s.include?('Ubuntu Summit') }
      d.check('the copyright names the developer') { about.copyright.include?('Cassidy James Blaede') }
    end
  end

  # A tick after the About window opened, so it has been realised and can be
  # painted.
  d.step('the about window') do
    d.shot('03-about', app.main_window.about_dialog)
  end

  d.step('quit') do
    d.check('Escape, Ctrl+Q and Ctrl+W quit') do
      app.app.get_accels_for_action('app.quit') == ['Escape', '<Control>q', '<Control>w']
    end

    app.main_window.about_dialog.close
    app.app.lookup_action('quit').activate(nil)

    d.check('the window is gone') { app.app.windows.empty? }
  end
end
