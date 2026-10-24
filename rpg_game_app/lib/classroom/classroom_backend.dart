import 'dart:async';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

/// クラスルームでできなかったこと（画面にそのまま出す）
class ClassroomException implements Exception {
  const ClassroomException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// クラスルームの置き場所（Firestore の classrooms/{コード}。テストではメモリ）
abstract class ClassroomBackend {
  /// ログインしている人の ID（ログインしていなければ null）
  String? get userId;

  /// クラスを作る（作った人はメンバーにもなる）
  Future<Classroom> create(String name, String ownerName);

  /// コードのクラスに入る
  Future<Classroom> join(String code, String nickname);

  /// クラスの今の内容（なければ null）
  Future<Classroom?> fetch(String code);

  /// クラスの変化を見守る（なくなる・入れなくなると null）
  Stream<Classroom?> watch(String code);

  /// 範囲を保存する（作った人だけ）
  Future<void> saveTasks(String code, List<ClassTask> tasks);

  /// クラスの名前を変える（作った人だけ）
  Future<void> rename(String code, String name);

  /// クラスを抜ける（作った人は抜けられない。閉じる）
  Future<void> leave(String code);

  /// メンバーを外す（作った人だけ）
  Future<void> remove(String code, String userId);

  /// クラスを閉じる（作った人だけ。新しく入れなくなる）
  Future<void> close(String code);

  /// コードを作り直す（作った人だけ）。範囲とメンバーを新しいコードへ移し、古いコードは閉じる
  Future<String> renew(String code);

  /// 共闘ボスに与えたダメージ（範囲のID → 合計）
  Stream<Map<String, int>> watchBoss(String code);

  /// 共闘ボスに正解数を足す
  Future<void> hit(String code, String taskId, int amount);
}

/// メモリの中のクラスルーム（テスト用）。複数の [MemoryClassroomBackend] で共有する
class MemoryClassroomHub {
  final Map<String, Classroom> rooms = {};
  final Map<String, Map<String, int>> boss = {};
  final _rooms = StreamController<String>.broadcast();
  final _boss = StreamController<String>.broadcast();
}

class MemoryClassroomBackend implements ClassroomBackend {
  MemoryClassroomBackend(this.hub, {this.userId = 'me', Random? random})
    : _random = random ?? Random(1);

  final MemoryClassroomHub hub;
  final Random _random;

  @override
  final String? userId;

  String _uid() {
    final u = userId;
    if (u == null) {
      throw const ClassroomException('クラスルームは、Google でログインすると使えます');
    }
    return u;
  }

  Classroom _room(String code) {
    final r = hub.rooms[code];
    if (r == null) throw const ClassroomException('そのコードのクラスは見つかりません');
    return r;
  }

  void _put(Classroom r) {
    hub.rooms[r.code] = r;
    hub._rooms.add(r.code);
  }

  void _owner(Classroom r) {
    if (!r.isOwner(userId)) {
      throw const ClassroomException('これは作った人だけができます');
    }
  }

  @override
  Future<Classroom> create(String name, String ownerName) async {
    final uid = _uid();
    var code = Classroom.newCode(_random);
    while (hub.rooms.containsKey(code)) {
      code = Classroom.newCode(_random);
    }
    final r = Classroom(
      code: code,
      name: Classroom.cleanName(name),
      ownerId: uid,
      ownerName: Classroom.cleanName(ownerName, fallback: 'なまえ'),
      members: {uid: Classroom.cleanName(ownerName, fallback: 'なまえ')},
      tasks: const [],
      expiresAt: DateTime.now().add(Classroom.lifetime),
    );
    _put(r);
    return r;
  }

  @override
  Future<Classroom> join(String code, String nickname) async {
    final uid = _uid();
    final r = _room(code);
    if (r.isMember(uid)) return r;
    if (r.closed || r.expired(DateTime.now())) {
      throw const ClassroomException('このクラスは、もう新しく入れません');
    }
    if (r.full) throw const ClassroomException('このクラスは満員です');
    final joined = r.copyWith(
      members: {
        ...r.members,
        uid: Classroom.cleanName(nickname, fallback: 'なまえ'),
      },
    );
    _put(joined);
    return joined;
  }

  @override
  Future<Classroom?> fetch(String code) async => hub.rooms[code];

  @override
  Stream<Classroom?> watch(String code) async* {
    yield hub.rooms[code];
    await for (final c in hub._rooms.stream) {
      if (c == code) yield hub.rooms[code];
    }
  }

  @override
  Future<void> saveTasks(String code, List<ClassTask> tasks) async {
    final r = _room(code);
    _owner(r);
    _put(r.copyWith(tasks: tasks.take(Classroom.maxTasks).toList()));
  }

  @override
  Future<void> rename(String code, String name) async {
    final r = _room(code);
    _owner(r);
    _put(r.copyWith(name: Classroom.cleanName(name)));
  }

  @override
  Future<void> leave(String code) async {
    final uid = _uid();
    final r = _room(code);
    if (r.isOwner(uid)) {
      throw const ClassroomException('作った人は抜けられません。クラスを閉じてください');
    }
    _put(r.copyWith(members: {...r.members}..remove(uid)));
  }

  @override
  Future<void> remove(String code, String userId) async {
    final r = _room(code);
    _owner(r);
    if (userId == r.ownerId) return;
    _put(r.copyWith(members: {...r.members}..remove(userId)));
  }

  @override
  Future<void> close(String code) async {
    final r = _room(code);
    _owner(r);
    _put(r.copyWith(closed: true));
  }

  @override
  Future<String> renew(String code) async {
    final r = _room(code);
    _owner(r);
    var next = Classroom.newCode(_random);
    while (hub.rooms.containsKey(next)) {
      next = Classroom.newCode(_random);
    }
    _put(
      Classroom(
        code: next,
        name: r.name,
        ownerId: r.ownerId,
        ownerName: r.ownerName,
        members: r.members,
        tasks: r.tasks,
        expiresAt: DateTime.now().add(Classroom.lifetime),
      ),
    );
    hub.boss[next] = {...?hub.boss[code]};
    _put(r.copyWith(closed: true));
    return next;
  }

  @override
  Stream<Map<String, int>> watchBoss(String code) async* {
    yield {...?hub.boss[code]};
    await for (final c in hub._boss.stream) {
      if (c == code) yield {...?hub.boss[code]};
    }
  }

  @override
  Future<void> hit(String code, String taskId, int amount) async {
    final uid = _uid();
    if (!_room(code).isMember(uid)) {
      throw const ClassroomException('このクラスのメンバーではありません');
    }
    if (amount <= 0) return;
    final m = hub.boss.putIfAbsent(code, () => {});
    m[taskId] = (m[taskId] ?? 0) + amount;
    hub._boss.add(code);
  }
}
