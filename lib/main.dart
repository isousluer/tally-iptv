import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/database.dart';
import 'state/providers.dart';
import 'ui/add_playlist_screen.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final db = await AppDatabase.open();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const SlayerApp(),
    ),
  );
}

class SlayerApp extends StatelessWidget {
  const SlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slayer IPTV',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(),
      themeMode: ThemeMode.dark,
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
      error: (e, _) => Scaffold(body: Center(child: Text('Could not open the library: $e'))),
      data: (list) => list.isEmpty ? const AddPlaylistScreen(firstRun: true) : const HomeShell(),
    );
  }
}
