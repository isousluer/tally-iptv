# Changelog

All notable changes to Tally are listed here. Downloads are on the
[Releases page](https://github.com/isousluer/tally-iptv/releases).

## Unreleased

### Fixed
- The universal APK of 0.1.2 wouldn't install over an earlier per-device APK ("package appears to be invalid").
  Every APK now carries the same, higher version number, so updates install whichever file you pick.
- The Download button on the new version notice, and other buttons on pop-up messages, were dark on a dark
  background. They are yellow now.

## 0.1.2 (2026-11-24)

### Added
- Turkish. The app follows your device's language, and you can pick English or Turkish yourself under
  Settings → Language.
- Catch-up for Xtream Codes channels that keep recordings: a clock icon marks them, and the clock button under the
  player lists past programs to watch, with a Back to live button. Channels show the icon after the playlist's
  next update.
- Last channel: a button in the player (and `B` or a remote's Last key) jumps back to the channel you watched
  before, and pressing it again comes back.
- Stream info in the player options (or `I` / a remote's Info key): resolution, frame rate, codecs, bitrate,
  buffer and whether the hardware decoder is in use.
- Subtitle style: size, background (outline, see-through box or dark box) and position, with a live sample. In
  Settings → Playback and in the player options.
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
