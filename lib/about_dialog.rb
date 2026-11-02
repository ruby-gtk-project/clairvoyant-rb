# frozen_string_literal: true

require 'adwaita'

require_relative 'config'
require_relative 'intl'
require_relative 'resources'

# AboutDialog is the window behind the header bar's About button.
#
# Ported from the Adw.AboutWindow.from_appdata call in src/MainWindow.vala
# together with data/metainfo.appdata.xml.in, the file it reads. The
# from_appdata constructor is not bound in the Ruby bindings — only the plain
# one is — so the AppData is read here and the same properties are set by hand:
# the component id becomes the application icon, its name the application name,
# the SPDX project_license the license type, the developer's name the developer
# name, the <url> entries the website, issue and support links, and the release
# matching the version becomes the release notes. The summary fills `comments`,
# which libadwaita leaves empty.
#
# The window is transient for the main window and hides rather than closes, so
# the About button can bring the same instance back — upstream's hide_on_close.
class AboutDialog < Adwaita::AboutWindow
  include Intl

  # SPDX ids to the Gtk::License values libadwaita renders a link for. Only the
  # licenses this app's metadata can name are listed; anything else is shown as
  # the SPDX string itself.
  LICENSES = {
    'GPL-3.0-or-later'  => 'GPL_3_0',
    'GPL-3.0-only'      => 'GPL_3_0_ONLY',
    'GPL-2.0-or-later'  => 'GPL_2_0',
    'GPL-2.0-only'      => 'GPL_2_0_ONLY',
    'LGPL-3.0-or-later' => 'LGPL_3_0',
    'LGPL-2.1-or-later' => 'LGPL_2_1',
    'AGPL-3.0-or-later' => 'AGPL_3_0',
    'MIT'               => 'MIT_X11',
    'Apache-2.0'        => 'APACHE_2_0',
    'MPL-2.0'           => 'MPL_2_0',
  }.freeze

  def initialize(appdata_path = Resources::METAINFO, version = Config::VERSION)
    super()
    @appdata = AppData.new(File.read(appdata_path, encoding: Encoding::UTF_8))
    @version = version
  end

  # The window title the main window takes from the AppData, as upstream does
  # with `this.title = about_window.application_name`.
  def application_name = @appdata.name

  def build
    tap do |about|
      about.application_name = @appdata.name
      about.application_icon = @appdata.id
      about.developer_name = @appdata.developer_name
      about.comments = @appdata.summary
      about.version = @version
      about.website = @appdata.url('homepage')
      about.issue_url = @appdata.url('bugtracker')
      about.support_url = @appdata.url('help')
      about.hide_on_close = true

      license.then do |spdx|
        if LICENSES.key?(spdx)
          about.license_type = Gtk::License.const_get(LICENSES.fetch(spdx))
        else
          about.license_type = Gtk::License::CUSTOM
          about.license = spdx
        end
      end

      @appdata.release_notes(@version).then do |notes|
        if notes
          about.release_notes = notes
          about.release_notes_version = @version
        end
      end

      # Upstream builds the copyright line from the current year and the
      # developer name rather than storing it in the AppData.
      about.copyright = format('© 2018–%d %s', Time.now.year, @appdata.developer_name)

      # TRANSLATORS: The translator credits. Please translate this with your name(s).
      about.translator_credits = _('translator-credits')
    end
  end

  private

    def license = @appdata.project_license

  # AppData reads the handful of AppStream tags libadwaita's from_appdata reads.
  #
  # rexml is not in the port's gem closure, and the file is a fixed, known
  # document that ships with the app rather than arbitrary input, so the tags
  # are matched directly. Each lookup takes the first matching element, which is
  # the component's own: <name> before the developer's <name>, <summary> before
  # any release description.
    class AppData
      def initialize(xml)
        @xml = xml
      end

      def id = text('id')
      def name = text('name')
      def summary = text('summary')
      def project_license = text('project_license')

      # AppStream allows either the deprecated <developer_name> or the
      # <developer><name> element; this file carries both.
      def developer_name = text('developer_name') || text('name', skip: 1)

      def url(type) = @xml[%r{<url\s+type="#{type}"\s*>(.*?)</url>}m, 1]&.strip

      # The <description> of the <release> whose version matches, as the
      # AppStream markup subset libadwaita renders.
      def release_notes(version)
        @xml[%r{<release\s+version="#{Regexp.escape(version)}".*?>(.*?)</release>}m, 1]
          &.then { |release| release[%r{<description>(.*?)</description>}m, 1] }
          &.then { |notes| dedent(notes) }
      end

      private

        def text(tag, skip: 0)
          @xml.scan(%r{<#{tag}(?:\s[^>]*)?>(.*?)</#{tag}>}m)
            .dig(skip, 0)
            &.strip
        end

        def dedent(markup)
          markup.lines.map(&:strip).reject(&:empty?).join("\n")
        end
    end
end
