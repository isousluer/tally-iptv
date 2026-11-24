import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/xtream_client.dart';

void main() {
  test('reads the subscription from the login answer', () {
    final a = XtreamClient.parseAccount({
      'user_info': {
        'auth': 1,
        'status': 'Active',
        'exp_date': '1798761600',
        'is_trial': '0',
        'active_cons': '1',
        'max_connections': '2',
        'created_at': '1767225600',
      },
    });
    expect(a.isActive, isTrue);
    expect(a.expires, DateTime.fromMillisecondsSinceEpoch(1798761600 * 1000));
    expect(a.activeConnections, 1);
    expect(a.maxConnections, 2);
    expect(a.trial, isFalse);
    expect(a.daysLeft(a.expires!.subtract(const Duration(days: 3, hours: 2))), 3);
  });

  test('a subscription without an end date never runs out', () {
    final a = XtreamClient.parseAccount({
      'user_info': {'auth': '1', 'status': 'Active', 'exp_date': null, 'is_trial': '1'},
    });
    expect(a.expires, isNull);
    expect(a.daysLeft(DateTime.now()), isNull);
    expect(a.trial, isTrue);
  });

  test('a rejected login throws', () {
    expect(
      () => XtreamClient.parseAccount({
        'user_info': {'auth': 0},
      }),
      throwsA(isA<XtreamException>()),
    );
  });
}
