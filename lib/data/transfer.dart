/// Moves a backup from one device to another over the home Wi-Fi, with no
/// cloud in between: the sending device serves it once, the receiving one
/// fetches it with the address and code from a QR code.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Where to fetch a backup and the code that unlocks it.
class TransferTicket {
  const TransferTicket({required this.host, required this.port, required this.code});

  final String host;
  final int port;

  /// Eight letters and digits, easy to type when the camera can't be used.
  final String code;

  static const _scheme = 'tally-transfer';

  /// What the QR code holds.
  String encode() => '$_scheme:1:$host:$port:$code';

  /// Reads a QR code, or "192.168.1.20:41234" and a code typed by hand.
  static TransferTicket? parse(String text, {String? code}) {
    final t = text.trim();
    if (t.startsWith('$_scheme:')) {
      final parts = t.split(':');
      if (parts.length != 5 || parts[1] != '1') return null;
      final port = int.tryParse(parts[3]);
      if (port == null || InternetAddress.tryParse(parts[2]) == null) return null;
      return TransferTicket(host: parts[2], port: port, code: normalizeCode(parts[4]));
    }
    if (code == null) return null;
    final i = t.lastIndexOf(':');
    if (i <= 0) return null;
    final host = t.substring(0, i), port = int.tryParse(t.substring(i + 1));
    if (port == null || InternetAddress.tryParse(host) == null) return null;
    return TransferTicket(host: host, port: port, code: normalizeCode(code));
  }

  /// Upper case without spaces or dashes, so "abcd-1234" works too.
  static String normalizeCode(String code) => code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// "ABCD-2345", for showing.
  String get displayCode => code.length == 8 ? '${code.substring(0, 4)}-${code.substring(4)}' : code;
}

/// Letters and digits that can't be mistaken for one another.
const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String _newCode() {
  final r = Random.secure();
  return List.generate(8, (_) => _alphabet[r.nextInt(_alphabet.length)]).join();
}

/// This device's address on the local network, preferring Wi-Fi and
/// Ethernet. Null when it isn't on one.
Future<String?> localAddress() async {
  final List<NetworkInterface> all;
  try {
    all = await NetworkInterface.list(type: InternetAddressType.IPv4);
  } catch (_) {
    return null;
  }
  bool private(InternetAddress a) {
    final b = a.rawAddress;
    return b[0] == 10 || (b[0] == 172 && b[1] >= 16 && b[1] < 32) || (b[0] == 192 && b[1] == 168);
  }

  int rank(NetworkInterface i) {
    final n = i.name.toLowerCase();
    if (n.startsWith('wlan') || n.startsWith('eth') || n.startsWith('ap')) return 0;
    if (n.startsWith('rmnet') || n.startsWith('ccmni') || n.startsWith('tun')) return 2;
    return 1;
  }

  final candidates = [
    for (final i in all)
      for (final a in i.addresses)
        if (!a.isLoopback && private(a) && rank(i) < 2) (i, a),
  ]..sort((x, y) => rank(x.$1) - rank(y.$1));
  return candidates.isEmpty ? null : candidates.first.$2.address;
}

/// Serves one backup to whoever brings the right code, then stops.
class TransferServer {
  TransferServer._(this._server, this.ticket, this._backup);

  final HttpServer _server;
  final TransferTicket ticket;
  final Future<String> Function() _backup;
  final _done = Completer<void>();
  int _wrong = 0;

  /// Completes once the other device has the backup.
  Future<void> get sent => _done.future;

  /// Null when the device isn't on a local network. Tests pass [host].
  static Future<TransferServer?> start(Future<String> Function() backup, {String? host}) async {
    host ??= await localAddress();
    if (host == null) return null;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final t = TransferServer._(server, TransferTicket(host: host, port: server.port, code: _newCode()), backup);
    server.listen(t._handle, onError: (_) {});
    return t;
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final code = TransferTicket.normalizeCode(req.uri.queryParameters['code'] ?? '');
      if (req.method != 'GET' || req.uri.path != '/backup') {
        res.statusCode = HttpStatus.notFound;
      } else if (code != ticket.code) {
        res.statusCode = HttpStatus.forbidden;
        // A few wrong guesses close the door for good.
        if (++_wrong >= 5) unawaited(close());
      } else {
        final body = utf8.encode(await _backup());
        res.headers.contentType = ContentType.json;
        res.contentLength = body.length;
        res.add(body);
        await res.close();
        if (!_done.isCompleted) _done.complete();
        unawaited(close());
        return;
      }
    } catch (_) {
      res.statusCode = HttpStatus.internalServerError;
    }
    await res.close();
  }

  Future<void> close() => _server.close(force: true);
}

class TransferException implements Exception {
  TransferException(this.reason);

  /// "code" when the code was wrong, "network" when the device couldn't be
  /// reached.
  final String reason;
}

/// Fetches the backup a [TransferServer] offers.
Future<String> fetchTransfer(TransferTicket t, {http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final res = await c
        .get(Uri(scheme: 'http', host: t.host, port: t.port, path: '/backup', queryParameters: {'code': t.code}))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode == HttpStatus.forbidden) throw TransferException('code');
    if (res.statusCode != HttpStatus.ok) throw TransferException('network');
    return utf8.decode(res.bodyBytes, allowMalformed: true);
  } on TransferException {
    rethrow;
  } catch (_) {
    throw TransferException('network');
  } finally {
    if (client == null) c.close();
  }
}
