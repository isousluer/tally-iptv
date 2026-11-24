# Changelog

All notable changes to Tally are listed here. Downloads are on the
[Releases page](https://github.com/isousluer/tally-iptv/releases).

## Unreleased

### Added
- Turkish. The app follows your device's language, and you can pick English or Turkish yourself under
  Settings → Language.
- Tally tells you when a new version is out on GitHub, once per version. You can turn this off or check by hand
  under Settings → About.

### Changed
- The Library has two tabs. History opens first, with continue watching and recently watched channels; Favorites
  holds your starred channels, movies and series.
- Clearing the watch history asks first.

### Fixed
- Pulling down the notification shade or swiping up to go home in the player no longer changes brightness or
  volume.
- A movie now shows up in watch history as soon as you leave it, instead of after the next refresh.

## 0.1.1 (2026-11-24)

### Changed
- The series page has a cleaner header: the poster sits on the left with the title, year, seasons, rating and plot
  beside it, over a soft blurred copy of the poster. The large cover image is gone, because providers often only
  have a portrait poster and it showed up as an odd, stretched crop.
- The play button, seasons and first episodes now fit on the first screen.
- The top bar fills in and shows the series name when you scroll down.
- Episodes without a picture show their number instead of repeating their title, on the series page and under the
  player.

## 0.1.0 (2026-11-23)

First release for Android: M3U and Xtream Codes playlists, live TV with a TV guide, movies and series with
continue watching, a libmpv-based player, parental lock and backups.
