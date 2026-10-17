import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/classroom/class_reminders.dart';
import 'package:rpg_game_app/classroom/classroom_backend.dart';
import 'package:rpg_game_app/classroom/classroom_screens.dart';
import 'package:rpg_game_app/classroom/classroom_store.dart';
import 'package:rpg_game_app/vocab/vocab_session_screen.dart';
import 'package:rpg_game_app/vocab/vocab_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

Future<void> _frames(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// 番号つきの単語帳を入れておく
Future<VocabBook> _addBook(RpgServices s, {String title = 'LEAP'}) async {
  final store = VocabStore.of(s.personalBooks);
  final b = VocabBook(
    id: title.toLowerCase(),
    title: title,
    kind: VocabBookKind.custom,
    cards: [
      for (var i = 1; i <= 300; i++)
        VocabCard(id: 'w$i', number: i, term: 'word$i', meaning: '意味$i'),
    ],
  );
  store.books.add(b);
  await store.saveBooks();
  return b;
}

ClassTask _task({DateTime? date}) {
  final now = DateTime.now();
  return ClassTask(
    id: 't1',
    kind: ClassTaskKind.quiz,
    title: '第7回',
    bookKey: ClassBooks.normalize('LEAP'),
    bookTitle: 'LEAP',
    from: 101,
    to: 200,
    date: date ?? DateTime(now.year, now.month, now.day + 5),
  );
}

void main() {
  testWidgets('サーバーがない版・ログインしていないときは、その説明を出す', (t) async {
    await openScreen(t, const ClassroomHubScreen(), frames: 5);
    expect(find.text(ClassText.noBackend), findsOneWidget);
    await openScreen(
      t,
      const ClassroomHubScreen(),
      frames: 5,
      classrooms: MemoryClassroomBackend(MemoryClassroomHub(), userId: null),
    );
    expect(find.text(ClassText.needLogin), findsOneWidget);
    expect(find.byKey(const ValueKey('class-login')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('クラスを作ると、コードが出て、一覧にも入る', (t) async {
    final hub = MemoryClassroomHub();
    final s = await openScreen(
      t,
      const ClassroomHubScreen(),
      frames: 5,
      classrooms: MemoryClassroomBackend(hub, userId: 'alice'),
    );
    await t.tap(find.byKey(const ValueKey('class-create')));
    await _frames(t, 3);
    await t.enterText(
      find.byKey(const ValueKey('class-create-name')),
      '英語 小テスト組',
    );
    await t.enterText(find.byKey(const ValueKey('class-create-nick')), 'あり');
    await t.tap(find.byKey(const ValueKey('class-create-ok')));
    await _frames(t);
    final code = hub.rooms.keys.single;
    expect(Classroom.validCode(code), isTrue);
    expect(find.text('コード $code'), findsOneWidget);
    expect(s.classroomStore.codes, [code]);
    expect(hub.rooms[code]!.members, {'alice': 'あり'});
    expect(t.takeException(), isNull);
  });

  testWidgets('作った人が範囲を追加すると、入った友だちの画面に出て、自分の単語帳で練習できる', (t) async {
    final hub = MemoryClassroomHub();
    // 作った人
    final owner = await openScreen(
      t,
      const SizedBox(),
      frames: 2,
      classrooms: MemoryClassroomBackend(hub, userId: 'alice'),
    );
    await _addBook(owner);
    final room = await owner.classrooms!.create('英語', 'あり');
    await openScreen(
      t,
      ClassroomScreen(code: room.code),
      frames: 5,
      keepPrefs: true,
      classrooms: MemoryClassroomBackend(hub, userId: 'alice'),
      size: const Size(420, 1200),
    );
    await t.tap(find.byKey(const ValueKey('class-add-task')));
    await _frames(t, 3);
    await t.enterText(find.byKey(const ValueKey('class-task-title')), '第7回');
    await t.enterText(find.byKey(const ValueKey('class-task-from')), '101');
    await t.enterText(find.byKey(const ValueKey('class-task-to')), '200');
    await t.tap(find.byKey(const ValueKey('class-task-save')));
    await _frames(t);
    final task = hub.rooms[room.code]!.tasks.single;
    expect(task.from, 101);
    expect(task.bookKey, ClassBooks.normalize('LEAP'));

    // 友だち：同じ単語帳を持っている
    SharedPreferences.setMockInitialValues({});
    final friend = await openScreen(
      t,
      const SizedBox(),
      frames: 2,
      classrooms: MemoryClassroomBackend(hub, userId: 'bob'),
    );
    await _addBook(friend);
    await friend.classrooms!.join(room.code, 'ぼぶ');
    await friend.classroomStore.add(room.code);
    await openScreen(
      t,
      ClassroomScreen(code: room.code),
      frames: 5,
      keepPrefs: true,
      classrooms: MemoryClassroomBackend(hub, userId: 'bob'),
      size: const Size(420, 1200),
    );
    expect(find.textContaining('第7回'), findsWidgets);
    expect(find.textContaining('覚えた単語 0 / 100'), findsOneWidget);
    // 範囲を変えたり足したりはできない（作った人だけ）
    expect(find.byKey(const ValueKey('class-add-task')), findsNothing);
    await t.tap(find.byKey(ValueKey('class-study-${task.id}')));
    await _frames(t);
    expect(find.byType(VocabSessionScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('単語帳を持っていない人には、開けば参加できると出す', (t) async {
    final hub = MemoryClassroomHub();
    final b = MemoryClassroomBackend(hub, userId: 'alice');
    final room = await b.create('英語', 'あり');
    await b.saveTasks(room.code, [_task()]);
    await openScreen(
      t,
      ClassroomScreen(code: room.code),
      frames: 5,
      classrooms: b,
      size: const Size(420, 1200),
    );
    expect(find.textContaining('「LEAP」を開く'), findsOneWidget);
    expect(find.byKey(const ValueKey('class-study-t1')), findsNothing);
    expect(t.takeException(), isNull);
  });

  group('自分の分の記録', () {
    test('正解数を共闘ボスに送り、自分の分を覚えておく。送れなければためて、あとで送る', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = ClassroomStore(prefs);
      final hub = MemoryClassroomHub();
      final alice = MemoryClassroomBackend(hub, userId: 'alice');
      final room = await alice.create('英語', 'あり');
      await store.contribute(alice, room.code, 't1', 250);
      expect(hub.boss[room.code]!['t1'], 250);
      expect(store.mine(room.code, 't1'), 250);
      expect(store.pending(room.code, 't1'), 0);
      // メンバーでない（送れない）ときは、ためておく
      final stranger = MemoryClassroomBackend(hub, userId: 'zed');
      await store.contribute(stranger, room.code, 't1', 5);
      expect(store.pending(room.code, 't1'), 5);
      expect(hub.boss[room.code]!['t1'], 250);
      await store.flush(alice, room.code);
      expect(store.pending(room.code, 't1'), 0);
      expect(hub.boss[room.code]!['t1'], 255);
    });

    test('コードを作り直すと、記録も新しいコードへ移る', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ClassroomStore(await SharedPreferences.getInstance());
      final hub = MemoryClassroomHub();
      final alice = MemoryClassroomBackend(hub, userId: 'alice');
      final room = await alice.create('英語', 'あり');
      await store.add(room.code);
      await store.contribute(alice, room.code, 't1', 3);
      final next = await alice.renew(room.code);
      await store.rename(room.code, next);
      expect(store.codes, [next]);
      expect(store.mine(next, 't1'), 3);
      expect(hub.rooms[room.code]!.closed, isTrue);
      expect(hub.rooms[next]!.members.keys, ['alice']);
    });
  });

  group('クラスのきまり（メモリ版）', () {
    test('閉じた・満員のクラスには入れない。作った人は抜けられない', () async {
      final hub = MemoryClassroomHub();
      final alice = MemoryClassroomBackend(hub, userId: 'alice');
      final room = await alice.create('英語', 'あり');
      await expectLater(
        alice.leave(room.code),
        throwsA(isA<ClassroomException>()),
      );
      final bob = MemoryClassroomBackend(hub, userId: 'bob');
      await expectLater(
        bob.saveTasks(room.code, [_task()]),
        throwsA(isA<ClassroomException>()),
      );
      await alice.close(room.code);
      await expectLater(
        bob.join(room.code, 'ぼぶ'),
        throwsA(isA<ClassroomException>()),
      );
    });
  });

  test('お知らせ：前日20時と当日7時。過ぎたものは出さない', () {
    final room = Classroom(
      code: '123456',
      name: '英語',
      ownerId: 'a',
      ownerName: 'あ',
      members: const {'a': 'あ'},
      tasks: const [],
    );
    final t = _task(date: DateTime(2026, 10, 23));
    final plan = ClassReminders.plan([(room, t)], DateTime(2026, 10, 20));
    expect(plan.map((r) => r.at), [
      DateTime(2026, 10, 22, 20),
      DateTime(2026, 10, 23, 7),
    ]);
    expect(plan.first.title, contains('明日'));
    final late = ClassReminders.plan([(room, t)], DateTime(2026, 10, 22, 21));
    expect(late.map((r) => r.at), [DateTime(2026, 10, 23, 7)]);
    expect(ClassReminders.plan([(room, t)], DateTime(2026, 10, 24)), isEmpty);
  });
}
