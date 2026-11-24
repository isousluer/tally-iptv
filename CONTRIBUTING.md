# Contributing to Tally

Thanks for helping make Tally better! This guide explains how to get your change merged.

## Ground rules

- Tally is a **player**. Pull requests that add playlists, channel lists, links to content, or anything that helps bypass paid services will be closed.
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
  Messages people see come from `strings` in `lib/l10n/strings.dart`.
- `lib/state` — Riverpod providers that connect data to the UI.
- `lib/ui` — screens and widgets. Use the colors in `ui/theme.dart` (`AppColors`) instead of hard-coded values.

## Translations

All text people see lives in `lib/l10n/app_en.arb` (English, the template) and one file per language, such as
`app_tr.arb`. To change or add text:

1. Add the key to `app_en.arb` and to every other `.arb` file.
2. Run `flutter gen-l10n` (or just `flutter run`) to regenerate `app_localizations*.dart`.
3. In widgets use `context.l10n.yourKey`; in code without a `BuildContext` use `strings.yourKey`.

To add a language, copy `app_en.arb` to `app_<code>.arb`, translate the values, add the locale to `appLocales`
in `lib/l10n/strings.dart` and its name to `languageLabel` in `lib/ui/settings_screen.dart`.

## UI writing style

- Sentence case everywhere ("Add playlist", not "Add Playlist" or "ADD PLAYLIST").
- Buttons say what happens: "Update channels", not "Submit".
- Error messages say what went wrong and how to fix it.

## Releases

Maintainers: see [RELEASING.md](RELEASING.md).

## Commit messages

Use short, imperative subjects: `Add channel number search`, `Fix EPG time zone parsing`.

## License

By contributing, you agree that your contributions are licensed under the GPL-3.0.
