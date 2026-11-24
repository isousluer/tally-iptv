import 'dart:math';
import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

/// An icon button with a menu that opens the way Android's own menus do:
/// it grows out of the button's corner while fading in, below the button
/// (or above it when there's no room). Flutter's [PopupMenuButton] unrolls
/// its menu from the top instead.
///
/// Takes the same [PopupMenuItem]s; tapping one closes the menu with its
/// value.
class MenuButton<T> extends StatelessWidget {
  const MenuButton({super.key, required this.itemBuilder, this.onSelected, this.tooltip, this.icon});

  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T>? onSelected;
  final String? tooltip;

  /// Defaults to the three-dot "more" icon.
  final Widget? icon;

  Future<void> _open(BuildContext context) async {
    final button = context.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final anchor = Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    );
    final value = await navigator.push(
      _MenuRoute<T>(
        anchor: anchor,
        items: itemBuilder(context),
        barrierLabel: MaterialLocalizations.of(context).menuDismissLabel,
        capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
      ),
    );
    if (value != null) onSelected?.call(value);
  }

  @override
  Widget build(BuildContext context) =>
      IconButton(tooltip: tooltip, icon: icon ?? Icon(Icons.adaptive.more), onPressed: () => _open(context));
}

class _MenuRoute<T> extends PopupRoute<T> {
  _MenuRoute({required this.anchor, required this.items, required this.barrierLabel, required this.capturedThemes});

  final Rect anchor;
  final List<PopupMenuEntry<T>> items;
  final CapturedThemes capturedThemes;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 100);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final theme = PopupMenuTheme.of(context);
    final padding = MediaQuery.paddingOf(context);
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: capturedThemes.wrap(
        CustomSingleChildLayout(
          delegate: _MenuLayout(anchor: anchor, padding: padding),
          child: _MenuBody(
            animation: animation,
            anchor: anchor,
            screenWidth: MediaQuery.sizeOf(context).width,
            child: Material(
              color: theme.color,
              elevation: theme.elevation ?? 8,
              shape: theme.shape,
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 112, maxWidth: 280),
                child: IntrinsicWidth(
                  stepWidth: 56,
                  child: SingleChildScrollView(
                    padding: theme.menuPadding ?? const EdgeInsets.symmetric(vertical: 8),
                    child: Semantics(
                      role: SemanticsRole.menu,
                      scopesRoute: true,
                      namesRoute: true,
                      explicitChildNodes: true,
                      label: barrierLabel,
                      child: ListBody(children: items),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades the menu in while it grows from the corner nearest the button.
class _MenuBody extends StatelessWidget {
  const _MenuBody({required this.animation, required this.anchor, required this.screenWidth, required this.child});
  final Animation<double> animation;
  final Rect anchor;
  final double screenWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fromRight = anchor.center.dx > screenWidth / 2;
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
        alignment: fromRight ? Alignment.topRight : Alignment.topLeft,
        child: child,
      ),
    );
  }
}

/// Puts the menu under the button, lined up with the button's outer edge,
/// and keeps it on screen.
class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout({required this.anchor, required this.padding});
  final Rect anchor;
  final EdgeInsets padding;

  static const _margin = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(constraints.biggest)
          .deflate(EdgeInsets.fromLTRB(_margin, padding.top + _margin, _margin, padding.bottom + _margin));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final fromRight = anchor.center.dx > size.width / 2;
    var x = fromRight ? anchor.right - child.width : anchor.left;
    x = x.clamp(_margin, max(_margin, size.width - child.width - _margin));
    final below = anchor.bottom;
    final roomBelow = size.height - padding.bottom - _margin - below;
    final y = child.height <= roomBelow
        ? below
        : max(
            padding.top + _margin,
            min(anchor.top - child.height, size.height - padding.bottom - _margin - child.height),
          );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) => anchor != old.anchor || padding != old.padding;
}
