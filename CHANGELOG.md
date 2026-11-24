# Changelog

All notable changes to Tally are listed here. Downloads are on the
[Releases page](https://github.com/isousluer/tally-iptv/releases).

## Unreleased

### Fixed
- Tablets held sideways show the player with the channel list or details next to the video, instead of always
  going full screen like a phone turned sideways. The full screen button still fills the screen.
- On tablets, the player's side panel no longer sits under the status bar, and the ends of lists stay clear of
  the navigation buttons.
- Series pages keep a readable width on tablets, with a larger poster.
- Back in full screen leaves full screen instead of closing the player.
- When a stream can't play, the play buttons no longer cover the message and its Try again button.
- The guide says "1 min left" in a program's last minute instead of "0 min left".

## 0.1.5 (2026-11-24)

### Changed
- Menus, such as sorting and the playlist and list options, open the way Android's own menus do: below their
  button, growing out of it as they fade in, instead of unrolling from the top over the button.

## 0.1.4 (2026-11-24)

### Added
- Xtream account info: open a playlist's menu in Settings and choose Account info to see whether the subscription
  is active, when it ends, how many of its connections are in use, and how many channels, movies and series it has.
  Tally also warns you, once a day, when it ends within a week.
- Sound and subtitle sync in the player options: move the sound or the subtitles earlier or later in steps of a
  tenth of a second when they don't match the picture. Each stream starts in sync again.
- Channel lists of your own, such as Sports, News or Kids. Touch and hold a channel to add it to a list; your lists
  show up next to All and Favorites in Live TV, and changing channels in the player stays within the list. Make,
  rename, reorder and delete lists, and put their channels in your order, under Settings → My channel lists. Lists
  are included in backups.
- Open in another app: for the rare stream Tally can't play, hand it to VLC, MX Player or another video player from
  the player options or the error message (Android).

## 0.1.3 (2026-11-24)

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
