import 'dart:async';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

/// ランダム対戦で、相手を待っている人
class QueueEntry {
  const QueueEntry({
    required this.uid,
    required this.name,
    required this.since,
    required this.ping,
    this.room,
    this.by,
  });

  /// 部屋を知らせてくれた人の ID
  final String? by;

  final String uid;
  final String name;

  /// 待ちはじめた時刻（先に待っていた人が、あとから来た人に見つけてもらう）
  final DateTime since;

  /// まだ待っている合図（古い人は、もういないとみなす）
  final DateTime ping;

  /// 見つけてくれた人が作った部屋の番号
  final String? room;
}

/// 報告の理由
enum PlayerReportReason {
  name('名前が不適切'),
  cheat('ずるをしている'),
  other('そのほか');

  const PlayerReportReason(this.label);
  final String label;
}

/// ランダム対戦の待ち合わせとゴーストの置き場所
abstract class MatchmakingBackend {
  String? get userId;

  /// 待ちはじめる（すでにあれば、まっさらにしなおす）
  Future<void> enter(String name, DateTime now);

  /// まだ待っている合図を送る
  Future<void> ping(DateTime now);

  /// 待っている人たち（新しい合図の順）
  Future<List<QueueEntry>> waiting();

  /// [uid] の人に、部屋 [room] を知らせる（先にほかの人が見つけていたら false）
  Future<bool> claim(String uid, String room);

  /// 自分の待ち合わせの様子（部屋が届くと room が入る）
  Stream<QueueEntry?> watchMine();

  /// 待つのをやめる
  Future<void> leave();

  /// ゴーストを1つ、ランダムに選ぶ（なければ null）
  Future<GhostRun?> randomGhost(Random random);

  /// 自分の答え方をゴーストとして残す
  Future<void> saveGhost(GhostRun run);

  /// 相手を報告する
  Future<void> report(String uid, PlayerReportReason reason);
}

/// テスト用：端末の中だけの待ち合わせ
class MemoryMatchmakingHub {
  final Map<String, QueueEntry> queue = {};
  final List<GhostRun> ghosts = [];
  final List<(String, String, PlayerReportReason)> reports = [];
  final _changes = StreamController<void>.broadcast();
}

class MemoryMatchmaking implements MatchmakingBackend {
  MemoryMatchmaking(this.hub, {this.userId = 'me'});

  final MemoryMatchmakingHub hub;

  @override
  final String? userId;

  String get _uid => userId!;

  @override
  Future<void> enter(String name, DateTime now) async {
    hub.queue[_uid] = QueueEntry(uid: _uid, name: name, since: now, ping: now);
    hub._changes.add(null);
  }

  @override
  Future<void> ping(DateTime now) async {
    final e = hub.queue[_uid];
    if (e == null) return;
    hub.queue[_uid] = QueueEntry(
      uid: e.uid,
      name: e.name,
      since: e.since,
      ping: now,
      room: e.room,
    );
  }

  @override
  Future<List<QueueEntry>> waiting() async =>
      hub.queue.values.toList()..sort((a, b) => b.ping.compareTo(a.ping));

  @override
  Future<bool> claim(String uid, String room) async {
    final e = hub.queue[uid];
    if (e == null || e.room != null) return false;
    hub.queue[uid] = QueueEntry(
      uid: e.uid,
      name: e.name,
      since: e.since,
      ping: e.ping,
      room: room,
      by: _uid,
    );
    hub._changes.add(null);
    return true;
  }

  @override
  Stream<QueueEntry?> watchMine() {
    StreamSubscription<void>? changes;
    late final StreamController<QueueEntry?> out;
    out = StreamController<QueueEntry?>(
      onListen: () {
        out.add(hub.queue[_uid]);
        changes = hub._changes.stream.listen((_) => out.add(hub.queue[_uid]));
      },
      onCancel: () => changes?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<void> leave() async {
    hub.queue.remove(_uid);
    hub._changes.add(null);
  }

  @override
  Future<GhostRun?> randomGhost(Random random) async =>
      hub.ghosts.isEmpty ? null : hub.ghosts[random.nextInt(hub.ghosts.length)];

  @override
  Future<void> saveGhost(GhostRun run) async => hub.ghosts.add(run);

  @override
  Future<void> report(String uid, PlayerReportReason reason) async =>
      hub.reports.add((_uid, uid, reason));
}
