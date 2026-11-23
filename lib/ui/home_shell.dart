import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import 'library_screen.dart';
import 'live_screen.dart';
import 'settings_screen.dart';
import 'vod_screen.dart';
import 'widgets.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    (Icons.live_tv_outlined, Icons.live_tv, 'Live TV'),
    (Icons.movie_outlined, Icons.movie, 'Movies'),
    (Icons.video_library_outlined, Icons.video_library, 'Series'),
    (Icons.bookmarks_outlined, Icons.bookmarks, 'Library'),
    (Icons.tune_outlined, Icons.tune, 'Settings'),
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
    final body = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < _destinations.length; i++)
          _built.contains(i) ? _page(i) : const SizedBox.shrink(),
      ],
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
                for (final (icon, selected, label) in _destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
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
          for (final (icon, selected, label) in _destinations)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
