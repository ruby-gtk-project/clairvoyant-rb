# frozen_string_literal: true

# Config holds the values meson substitutes into upstream's src/Config.vala.in
# at build time: the app ID (upstream's meson project name) and the version.
#
# Ported from src/Config.vala.in and the `conf` block of upstream's root
# meson.build. There is no configure step in the port, so the values are
# literals; APP_ID doubles as the gettext domain exactly as upstream's
# GETTEXT_PACKAGE does.
module Config
  # Upstream's meson.project_name(), which is also the app ID and the icon name.
  APP_ID = 'com.cassidyjames.clairvoyant'

  # Upstream's meson project version, and the release the About window shows
  # notes for.
  VERSION = '3.1.12'

  # GETTEXT_PACKAGE in upstream's meson.build is meson.project_name().
  GETTEXT_PACKAGE = APP_ID

  # Where the port keeps what upstream installs into its pkgdatadir.
  DATA_DIR = File.expand_path('../data', __dir__)

  # Compiled catalogues, the port's equivalent of meson's LOCALEDIR. Built by
  # `rake gettext:mo:update`, so it is absent until that has run.
  LOCALE_DIR = File.expand_path('../locale', __dir__)
end
