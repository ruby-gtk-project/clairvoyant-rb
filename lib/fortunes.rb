# frozen_string_literal: true

require_relative 'intl'

# Fortunes is the static Content[] table from upstream's src/FortuneLabel.vala:
# twenty-eight replies, each paired with the Adwaita CSS class that colours it
# — "success" for a yes, "error" for a no, "warning" for a maybe.
#
# The titles are marked with N_() and translated at display time, which is what
# a table of strings needs: marking extracts them for the catalogue, and the
# lookup happens once the locale is known rather than at load time.
module Fortunes
  extend Intl

  # Upstream's three css_class values, in the order its table uses them.
  SUCCESS = 'success'
  ERROR = 'error'
  WARNING = 'warning'

  # One row of upstream's `private struct Content`.
  Fortune = Struct.new(:title, :css_class)

  TABLE = [
    # TRANSLATORS: Positive response, the thing is certain to happen
    [N_('It is certain.'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('It is decidedly so.'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('Without a doubt.'), SUCCESS],
    # TRANSLATORS: Positive response, the thing is certain to happen
    [N_('Yes—definitely.'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('You may rely on it.'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('As I see it, yes.'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('Most likely.'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('Outlook good.'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('Yes.'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('Signs point to yes.'), SUCCESS],
    # TRANSLATORS: Positive response, casual
    [N_('Yep!'), SUCCESS],
    # TRANSLATORS: Positive response
    [N_('Absolutely!'), SUCCESS],
    # TRANSLATORS: Positive response, casual
    [N_('You bet!'), SUCCESS],
    [N_('Confirmed.'), SUCCESS],
    # TRANSLATORS: Negative response
    [N_('Don’t count on it.'), ERROR],
    # TRANSLATORS: Negative response
    [N_('My reply is no.'), ERROR],
    # TRANSLATORS: Negative response, referring to the 8-ball's "sources"
    [N_('My sources say no.'), ERROR],
    # TRANSLATORS: Negative response
    [N_('Outlook not so good.'), ERROR],
    # TRANSLATORS: Negative response
    [N_('Very doubtful.'), ERROR],
    # TRANSLATORS: Negative response, casual
    [N_('Naw.'), ERROR],
    # TRANSLATORS: Negative response; reference to the recurring Star Wars line
    [N_('I’ve got a bad feeling about this…'), ERROR],
    # TRANSLATORS: Neutral response
    [N_('Reply hazy, try again.'), WARNING],
    # TRANSLATORS: Neutral response
    [N_('Ask again later.'), WARNING],
    # TRANSLATORS: Neutral response
    [N_('Better not tell you now.'), WARNING],
    # TRANSLATORS: Neutral response
    [N_('Cannot predict now.'), WARNING],
    # TRANSLATORS: Neutral response
    [N_('Concentrate and ask again.'), WARNING],
    # TRANSLATORS: Neutral response; reference to a line from Yoda from Star Wars
    [N_('Impossible to see, the future is.'), WARNING],
    # TRANSLATORS: Neutral response; a play on the "404 Page Not Found" web browser error code
    [N_('404 Answer Not Found'), WARNING],
  ].freeze

  ENTRIES = TABLE.map { |title, css_class| Fortune.new(title, css_class) }.freeze

  # The stack page names are the one-based index of the fortune, as strings,
  # because that is what upstream's `i.to_string ()` produces and what its
  # randomizer parses back out of visible_child_name.
  def self.page_names = @page_names ||= (1..ENTRIES.length).map(&:to_s).freeze

  def self.entry(page_name) = ENTRIES[page_name.to_i - 1]

  # Upstream's `Random.int_range (1, 29)`: a page name from 1 to 28 inclusive.
  def self.random_page_name = rand(1..ENTRIES.length).to_s
end
