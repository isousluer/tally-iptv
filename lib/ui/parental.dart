import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'theme.dart';

/// Asks for the parental PIN. Returns true and unlocks locked categories for
/// this session when it matches.
Future<bool> unlockWithPin(BuildContext context, WidgetRef ref) async {
  if (ref.read(lockedContentOpenProvider)) return true;
  final pin = ref.read(parentalPinProvider);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _PinDialog(title: ctx.l10n.enterPin, check: (v) => v == pin),
  );
  if (ok == true) ref.read(parentalUnlockedProvider.notifier).set(true);
  return ok == true;
}

/// Lets [item] open only when its category isn't locked, or the PIN is given.
Future<bool> ensureUnlockedFor(BuildContext context, WidgetRef ref, MediaItem item) async {
  if (ref.read(lockedContentOpenProvider)) return true;
  final locked = await ref.read(databaseProvider).isGroupLocked(item.playlistId, item.kind, item.group);
  if (!locked || !context.mounted) return !locked;
  return unlockWithPin(context, ref);
}

/// Creates or changes the PIN. Returns the new PIN, or null when cancelled.
Future<String?> choosePin(BuildContext context) async {
  final first = await showDialog<String>(
    context: context,
    builder: (ctx) => _PinDialog(title: ctx.l10n.chooseFourDigitPin, returnValue: true),
  );
  if (first == null || !context.mounted) return null;
  final again = await showDialog<String>(
    context: context,
    builder: (ctx) => _PinDialog(title: ctx.l10n.enterPinAgain, returnValue: true, check: (v) => v == first),
  );
  return again;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.title, this.check, this.returnValue = false});
  final String title;
  final bool Function(String)? check;

  /// Pops the entered value instead of `true`.
  final bool returnValue;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _c = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.length != 4) {
      setState(() => _error = context.l10n.pinUseFourDigits);
      return;
    }
    if (widget.check != null && !widget.check!(v)) {
      setState(() {
        _error = widget.returnValue ? context.l10n.pinsDontMatch : context.l10n.wrongPin;
        _c.clear();
      });
      // Keep the keyboard up so the viewer can try again right away.
      _focus.requestFocus();
      return;
    }
    Navigator.pop(context, widget.returnValue ? v : true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        focusNode: _focus,
        autofocus: true,
        // Submitting shouldn't close the keyboard; a wrong PIN needs a retry.
        onEditingComplete: () {},
        obscureText: true,
        maxLength: 4,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(letterSpacing: 12),
        decoration: InputDecoration(counterText: '', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
        TextButton(
          onPressed: _submit,
          style: TextButton.styleFrom(foregroundColor: AppColors.tally),
          child: Text(context.l10n.ok),
        ),
      ],
    );
  }
}
