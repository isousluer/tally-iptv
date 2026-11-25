# Changelog

All notable changes to Tally are listed here. Downloads are on the
[Releases page](https://github.com/isousluer/tally-iptv/releases).

## 1.1.1 (2026-11-25)

### Changed
- In the channel list under the player, merged channel rows show their quality (4K, Full HD, HD, SD). The
  playing row shows the copy on screen.

## 1.1.0 (2026-11-25)

### New
- Pause and rewind live TV. The last minutes of the channel you watch are kept on the phone (off, 5, 10 or 30
  minutes in Settings, 10 by default; less when space runs low). Jump 10 seconds back or forward, drag the bar,
  see how far behind live you are, and go back to live with one tap.
- Swipe left or right on the picture to change channel.
- Today's matches above the channel list, for people in Turkey: time, competition and the channel from your own
  list. Tap one to watch it; matches on channels you don't have are dimmed. Turn it off or pick
  the sports you want (only football, say) in Settings.
- Send your lists, favorites and settings to another device over your home Wi-Fi with a QR code, no cloud in
  between. A code can be typed in when there's no camera.
- Copies of a channel (HD, SD, Full HD) show as one row that plays the best copy and moves on to the next one
  when it doesn't play. Channels that keep failing are marked. Turn it off in Settings.
- A short wizard right after adding a list lets you keep only the countries you want and hide adult categories.
- Sound only, in the player options: the picture turns off and the sound keeps going with the screen off.
- A short notice when a video starts on mobile data.

### Changed
- Merged channel rows show the name without quality tags ("TR: beIN SPORTS 1").

### Fixed
- Live channels no longer stop when the provider closes the connection every half minute or so; they reconnect
  on their own.
- When the account is already open on another device (and allows one at a time), Tally says so before playing,
  and explains it when a channel keeps dropping, instead of freezing.

## 1.0.1 (2026-11-25)

### Fixed
- When a channel can't play, previous and next channel buttons sit beside Try again, so you can move on without
  going back to the list.
- On a channel that can't play, the full screen, options and other player buttons work again. The message no
  longer spills over them in the small player.
- The player options sheet closes when you pull it down, however long it is. Pull it up to see all options.

## 1.0.0 (2026-11-25)

The first stable release of Tally, an IPTV player for Android phones and tablets. It installs over the earlier test
versions and keeps your playlists, favorites and history.

### Playlists
- Add an M3U / M3U8 link, a local M3U file or an Xtream Codes login, and switch between several playlists.
- Large lists are read once and stored on your device, so they open instantly. Every channel, movie and series of a
  category shows, even in libraries with tens of thousands of titles.
- Playlists update by hand or on their own once a day. When an Xtream server sends a broken list during an update,
  Tally keeps what it had, so your history and favorites don't disappear.
- Hide, reorder and lock categories, sort channels and titles, and make channel lists of your own, such as Sports
  or Kids.
- Xtream account info shows when the subscription ends and how many devices can watch at once, with a warning a
  week before it runs out.

### Live TV
- TV guide with what's on now and next, from the playlist's XMLTV guide or your Xtream server.
- Change channels without leaving the player: previous and next buttons, a channel list next to the video, channel
  numbers and a Last channel button.
- Catch-up for Xtream channels that keep recordings.

### Movies and series
- Posters, ratings, plot, director and cast.
- Episode lengths read as "45m" instead of "00:45:00".
- Continue watching, and the next episode starts on its own with a countdown you can cancel.

### Player
- Plays almost any stream with libmpv, or hands it to another video app.
- Audio and subtitle tracks, subtitle style, and sound and subtitle sync.
- Picture size (fit, fill, stretch) and, new in this version, a picture shape of 16:9 or 4:3 for channels that look
  squashed, remembered per channel.
- Swipe for brightness and volume, double tap for full screen, picture-in-picture, sleep timer, playback speed and
  stream info.
- On tablets held sideways, the channel list or details stay next to the video.

### Everything else
- English and Turkish.
- Parental lock, backup and restore, and a notice when a new version is out.
- No accounts, no analytics, no tracking.

Earlier test versions (0.1.0 to 0.1.6) were published between 2026-11-23 and 2026-11-24.
