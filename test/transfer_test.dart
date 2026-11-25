import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/transfer.dart';

void main() {
  test('a ticket survives the QR code', () {
    const t = TransferTicket(host: '192.168.1.20', port: 41234, code: 'ABCD2345');
    final back = TransferTicket.parse(t.encode())!;
    expect((back.host, back.port, back.code), ('192.168.1.20', 41234, 'ABCD2345'));
    expect(t.displayCode, 'ABCD-2345');
  });

  test('takes an address and code typed by hand', () {
    final t = TransferTicket.parse(' 10.0.0.5:8080 ', code: 'abcd-2345')!;
    expect((t.host, t.port, t.code), ('10.0.0.5', 8080, 'ABCD2345'));
    expect(TransferTicket.parse('not a ticket'), isNull);
    expect(TransferTicket.parse('example.com:80', code: 'X'), isNull);
  });

  test('serves the backup once to the right code only', () async {
    final server = (await TransferServer.start(() async => '{"app":"tally"}', host: '127.0.0.1'))!;
    addTearDown(server.close);
    final t = server.ticket;
    await expectLater(
      fetchTransfer(TransferTicket(host: t.host, port: t.port, code: 'WRONG234')),
      throwsA(isA<TransferException>().having((e) => e.reason, 'reason', 'code')),
    );
    expect(await fetchTransfer(t), '{"app":"tally"}');
    await server.sent;
  });
}
