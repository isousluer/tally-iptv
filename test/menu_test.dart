import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tally/ui/menu.dart';

void main() {
  testWidgets('opens below the button and returns the picked value', (t) async {
    String? picked;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              MenuButton<String>(
                onSelected: (v) => picked = v,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'a', child: Text('First')),
                  PopupMenuItem(value: 'b', child: Text('Second')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final button = t.getRect(find.byType(IconButton));
    await t.tap(find.byType(IconButton));
    await t.pumpAndSettle();
    final menu = t.getRect(find.text('First'));
    expect(menu.top, greaterThanOrEqualTo(button.bottom));
    // Lined up with the button's right edge, kept 8 px inside the screen.
    expect(t.getRect(find.byType(Material).last).right, closeTo(button.right - 8, 1));
    await t.tap(find.text('Second'));
    await t.pumpAndSettle();
    expect(picked, 'b');
    expect(find.text('First'), findsNothing);
  });
}
