import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/cloud/cloud_sync.dart';

void main() {
  test('端末のキャッシュの分はとばし、サーバーから届いた最初のものを返して見張りをやめる', () async {
    var cancelled = false;
    final c = StreamController<(String, bool)>(
      onCancel: () => cancelled = true,
    );
    final got = firstFromServer(c.stream, (x) => x.$2);
    c.add(('cache', true));
    c.add(('server', false));
    c.add(('later', false));
    expect((await got).$1, 'server');
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, isTrue);
  });

  test('エラーはそのまま伝える', () async {
    final c = StreamController<int>();
    final got = firstFromServer(c.stream, (_) => false);
    c.addError(StateError('permission-denied'));
    await expectLater(got, throwsStateError);
  });

  test('サーバーから届かなければ（オフライン）時間切れで失敗し、見張りをやめる', () async {
    var cancelled = false;
    final c = StreamController<int>(onCancel: () => cancelled = true);
    final got = firstFromServer(
      c.stream,
      (_) => true,
      limit: const Duration(milliseconds: 50),
    );
    c.add(1);
    await expectLater(got, throwsA(isA<TimeoutException>()));
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, isTrue);
  });
}
