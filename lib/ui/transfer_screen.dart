import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/backup.dart';
import '../data/transfer.dart';
import '../l10n/strings.dart';
import '../platform/device.dart';
import '../state/providers.dart';
import 'settings_screen.dart' show runRestore;
import 'theme.dart';

/// Shows a QR code another device scans to copy this one's lists,
/// favorites and settings over the local network.
Future<void> sendToDevice(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const _SendScreen()));

/// Scans the other device's QR code (or takes its address and code typed
/// in), then merges its backup into this one.
Future<void> receiveFromDevice(BuildContext context, WidgetRef ref) async {
  final ticket = await Navigator.of(context)
      .push(MaterialPageRoute<TransferTicket>(builder: (_) => const _ReceiveScreen()));
  if (ticket == null || !context.mounted) return;
  final l = context.l10n;
  await runRestore(context, ref, l.transferReceiving, () async {
    try {
      return await fetchTransfer(ticket);
    } on TransferException catch (e) {
      throw _Message(e.reason == 'code' ? l.transferBadCode : l.transferUnreachable);
    }
  });
}

class _Message implements Exception {
  _Message(this.text);
  final String text;
  @override
  String toString() => text;
}

class _SendScreen extends ConsumerStatefulWidget {
  const _SendScreen();

  @override
  ConsumerState<_SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<_SendScreen> {
  TransferServer? _server;
  bool _starting = true;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final db = ref.read(databaseProvider);
    final prefs = ref.read(prefsProvider);
    TransferServer? server;
    try {
      server = await TransferServer.start(() => exportBackup(db, prefs));
    } catch (_) {
      server = null;
    }
    if (!mounted) {
      await server?.close();
      return;
    }
    setState(() {
      _server = server;
      _starting = false;
    });
    await server?.sent;
    if (mounted && server != null) setState(() => _sent = true);
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final server = _server;
    Widget body;
    if (_starting) {
      body = const Center(child: CircularProgressIndicator());
    } else if (server == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 40, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(l.transferNoWifi, textAlign: TextAlign.center, style: t.bodyLarge),
            ],
          ),
        ),
      );
    } else {
      final ticket = server.ticket;
      body = ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(l.transferSendHint, style: t.bodyLarge),
          const SizedBox(height: 20),
          Center(
            child: AnimatedOpacity(
              opacity: _sent ? 0.25 : 1,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: ticket.encode(), size: 240, padding: EdgeInsets.zero),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _sent
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.tally),
                      const SizedBox(width: 8),
                      Flexible(child: Text(l.transferSent, style: t.titleMedium)),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text(l.transferWaiting, style: t.bodyMedium),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          SelectableText(
            l.transferManual('${ticket.host}:${ticket.port}', ticket.displayCode),
            textAlign: TextAlign.center,
            style: t.bodyMedium!.copyWith(fontFeatures: tabular),
          ),
          const SizedBox(height: 16),
          Text(
            l.transferPrivacy,
            textAlign: TextAlign.center,
            style: t.bodySmall!.copyWith(color: AppColors.muted),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.transferSend)),
      body: SafeArea(top: false, child: body),
    );
  }
}

/// Why the camera didn't open, with a way forward: the app's settings when
/// the permission was refused, another try otherwise.
class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.scanner});
  final MobileScannerException error;
  final MobileScannerController scanner;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final reason = error.errorDetails?.message ?? error.errorCode.name;
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(denied ? Icons.no_photography_outlined : Icons.videocam_off_outlined, color: AppColors.muted),
              const SizedBox(height: 10),
              Text(
                error.errorCode == MobileScannerErrorCode.unsupported
                    ? l.transferNoCamera
                    : denied
                    ? l.transferCameraDenied
                    : l.transferCameraFailed(reason),
                textAlign: TextAlign.center,
                style: t.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (denied)
                FilledButton.tonal(onPressed: Device.openAppSettings, child: Text(l.transferOpenSettings))
              else if (error.errorCode != MobileScannerErrorCode.unsupported)
                FilledButton.tonal(
                  onPressed: () async {
                    try {
                      await scanner.stop();
                      await scanner.start();
                    } catch (_) {}
                  },
                  child: Text(l.tryAgain),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiveScreen extends StatefulWidget {
  const _ReceiveScreen();

  @override
  State<_ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<_ReceiveScreen> with WidgetsBindingObserver {
  final _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the app's settings with the camera allowed: try again.
    if (state == AppLifecycleState.resumed && _scanner.value.error != null && !_done) {
      _scanner.stop().then((_) => _scanner.start()).catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanner.dispose();
    super.dispose();
  }

  void _detect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final ticket = TransferTicket.parse(b.rawValue ?? '');
      if (ticket != null) {
        _done = true;
        Navigator.of(context).pop(ticket);
        return;
      }
    }
  }

  Future<void> _typeIn() async {
    final l = context.l10n;
    final address = TextEditingController();
    final code = TextEditingController();
    final ticket = await showDialog<TransferTicket>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final parsed = TransferTicket.parse(address.text, code: code.text);
          final ok = parsed != null && parsed.code.length == 8;
          return AlertDialog(
            title: Text(l.transferEnterManually),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: address,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(labelText: l.transferAddress, hintText: '192.168.1.20:41234'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l.transferCode, hintText: 'ABCD-2345'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
              FilledButton(onPressed: ok ? () => Navigator.pop(ctx, parsed) : null, child: Text(l.transferConnect)),
            ],
          );
        },
      ),
    );
    if (ticket != null && mounted && !_done) {
      _done = true;
      Navigator.of(context).pop(ticket);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.transferReceive)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(l.transferScanHint, style: t.bodyLarge),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox.square(
                  dimension: 280,
                  child: MobileScanner(
                    controller: _scanner,
                    onDetect: _detect,
                    errorBuilder: (context, error) => _CameraError(error: error, scanner: _scanner),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _typeIn,
                icon: const Icon(Icons.keyboard_outlined),
                label: Text(l.transferEnterManually),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
