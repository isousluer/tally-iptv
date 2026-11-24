import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database.dart';
import 'l10n/strings.dart';
import 'platform/device.dart';
import 'state/providers.dart';
import 'ui/add_playlist_screen.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await initializeDateFormatting();
  await Device.init();
  final db = await AppDatabase.open();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db), prefsProvider.overrideWithValue(prefs)],
      child: const TallyApp(),
    ),
  );
}

class TallyApp extends ConsumerWidget {
  const TallyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(settingsProvider.select((s) => s.language));
    final locale = language == null ? systemLocale() : Locale(language);
    useLocale(locale);
    return MaterialApp(
      title: 'Tally',
      locale: locale,
      supportedLocales: appLocales,
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(),
      themeMode: ThemeMode.dark,
      // TV remotes send "select" for the OK button.
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return playlists.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(context.l10n.libraryOpenFailed('$e')))),
      data: (list) => list.isEmpty ? const AddPlaylistScreen(firstRun: true) : const HomeShell(),
    );
  }
}
