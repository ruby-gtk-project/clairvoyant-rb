# frozen_string_literal: true

require 'adwaita'

require_relative 'fortunes'
require_relative 'intl'

# FortuneLabel is the answer on screen.
#
# Ported from upstream's src/FortuneLabel.vala: a Gtk.Box wrapping a crossfading
# Gtk.Stack with one page per fortune, each page named with the fortune's
# one-based index so the window can switch to a page by number. The stack is
# public because the window drives it — same as upstream's `public Gtk.Stack
# stack`.
class FortuneLabel < Gtk::Box
  include Intl

  def initialize
    super(:horizontal, 0)
  end

  def build
    tap do |label|
      label.append(stack)

      stack.tap do |s|
        Fortunes.page_names.each { |name| s.add_named(page(Fortunes.entry(name)), name) }

        s.visible_child_name = Fortunes.random_page_name
      end
    end
  end

  def stack
    @stack ||= Gtk::Stack.new.tap do |stack|
      stack.transition_type = :crossfade
    end
  end

  private

  # One page of the stack: the fortune's text, as a title, in the colour its
  # css_class picks. Built per fortune rather than memoized one method apiece,
  # since the pages come from a table.
    def page(fortune)
      Gtk::Box.new(:vertical, 0).tap do |box|
        box.margin_start = 24
        box.margin_end = 24
        box.halign = :center

        box.append(title_label(fortune))
      end
    end

    def title_label(fortune)
      Gtk::Label.new(_(fortune.title)).tap do |label|
        label.selectable = true
        label.add_css_class('title-1')
        label.add_css_class(fortune.css_class)
      end
    end
end
