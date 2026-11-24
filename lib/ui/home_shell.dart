import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'account_sheet.dart';
import 'library_screen.dart';
import 'live_screen.dart';
import 'settings_screen.dart';
import 'updates.dart';
import 'vod_screen.dart';
import 'widgets.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Refresh stale online playlists in the background after the first frame,
    // and look for a new version of the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(settingsProvider).checkUpdates) notifyAboutUpdate(context, ref);
    });
    // Later than the update notice, so the two don't replace each other at once.
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted) warnAboutAccount(context, ref);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!ref.read(settingsProvider).autoRefresh) return;
      final updated = await ref.read(playlistsProvider.notifier).refreshStale();
      if (!mounted || updated.isEmpty) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.playlistsAutoUpdated(updated.join(', ')))));
    });
  }

  static List<(IconData, IconData, String)> _destinations(AppLocalizations l) => [
    (Icons.live_tv_outlined, Icons.live_tv, l.liveTv),
    (Icons.movie_outlined, Icons.movie, l.movies),
    (Icons.video_library_outlined, Icons.video_library, l.series),
    (Icons.bookmarks_outlined, Icons.bookmarks, l.library),
    (Icons.tune_outlined, Icons.tune, l.settings),
  ];

  // Tabs are built lazily and then kept alive so scroll positions survive.
  final _built = <int>{0};

  Widget _page(int i) => switch (i) {
    0 => const LiveScreen(),
    1 => const VodScreen(kind: ContentKind.movie),
    2 => const VodScreen(kind: ContentKind.series),
    3 => const LibraryScreen(),
    _ => const SettingsScreen(),
  };

  void _select(int i) => setState(() {
    _index = i;
    _built.add(i);
  });

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context.l10n);
    final body = IndexedStack(
      index: _index,
      children: [for (var i = 0; i < destinations.length; i++) _built.contains(i) ? _page(i) : const SizedBox.shrink()],
    );

    if (isWide(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.85,
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
              ],
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
