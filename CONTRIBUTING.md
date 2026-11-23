# Contributing to Slayer IPTV

Thanks for helping make Slayer IPTV better! This guide explains how to get your change merged.

## Ground rules

- Slayer IPTV is a **player**. Pull requests that add playlists, channel lists, links to content, or anything that helps bypass paid services will be closed.
- Be kind. Assume good intent.

## Reporting bugs

Open an issue and include:

- Your platform and app version (Settings → About)
- Your source type (M3U link, M3U file or Xtream Codes) — **never post your playlist URL or credentials**
- What you did, what you expected, and what happened instead

## Development setup

1. Install Flutter 3.50+ (stable).
2. `flutter pub get`
3. `flutter run`

Before you open a pull request:

```bash
dart format --line-length 120 lib test
flutter analyze
flutter test
```

## Code layout

- `lib/data` — parsing, network and storage. Keep it free of Flutter UI imports so it can run in isolates and be unit tested.
- `lib/state` — Riverpod providers that connect data to the UI.
- `lib/ui` — screens and widgets. Use the colors in `ui/theme.dart` (`SlayerColors`) instead of hard-coded values.

## UI writing style

- Sentence case everywhere ("Add playlist", not "Add Playlist" or "ADD PLAYLIST").
- Buttons say what happens: "Update channels", not "Submit".
- Error messages say what went wrong and how to fix it.

## Commit messages

Use short, imperative subjects: `Add channel number search`, `Fix EPG time zone parsing`.

## License

By contributing, you agree that your contributions are licensed under the GPL-3.0.
