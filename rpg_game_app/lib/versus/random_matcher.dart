import 'dart:async';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

import 'matchmaking.dart';
import 'online_room.dart';

/// 見つかった結果
sealed class MatchResult {
  const MatchResult();
}

/// 人が見つかった（[side] 0 = 部屋を作った、1 = 入った）
class FoundPlayer extends MatchResult {
  const FoundPlayer(this.room, this.side);
  final OnlineRoom room;
  final int side;

  /// 相手の ID
  String? get opponentId => side == 0 ? room.guestId : room.hostId;
}

/// だれもいなかったので、ゴーストと対戦する
class FoundGhost extends MatchResult {
  const FoundGhost(this.ghost);
  final GhostRun ghost;
}

/// ランダム対戦の相手さがし。
///
/// 1. 待ち合わせの列に入る
/// 2. 自分より先に待っていた人がいれば、部屋を作ってその人に知らせる（自分が部屋を作る側）
/// 3. あとから来た人に見つけてもらえたら、その部屋に入る
/// 4. [wait] たってもだれもいなければ、ゴーストと対戦する
class RandomMatcher {
  RandomMatcher({
    required this.queue,
    required this.rooms,
    required this.name,
    required this.newConfig,
    this.blocked = const {},
    this.wait = const Duration(seconds: 20),
    this.tick = const Duration(seconds: 2),
    this.joinWait = const Duration(seconds: 10),
    Random? random,
  }) : _random = random ?? Random();

  final MatchmakingBackend queue;
  final VersusRoomBackend rooms;
  final String name;

  /// 部屋を作るときの出題
  final VersusRoomConfig Function() newConfig;

  /// ブロックした人（マッチしない）
  final Set<String> blocked;
  final Duration wait;
  final Duration tick;
  final Random _random;

  /// 待っている人とみなす、合図の新しさ
  static const fresh = Duration(seconds: 15);

  /// 部屋を作ってから、相手が入ってくるのを待つ時間
  final Duration joinWait;

  bool _cancelled = false;
  DateTime _since = DateTime.now();

  /// 待った秒数（画面に出す）
  int elapsedSeconds = 0;

  void cancel() => _cancelled = true;

  Future<MatchResult?> run() async {
    final me = queue.userId!;
    final since = _since = DateTime.now();
    await queue.enter(name, since);
    String? assigned;
    final sub = queue.watchMine().listen((e) {
      if (e?.room == null) return;
      // ブロックした人の部屋には入らない（相手は待ちくたびれて、ほかをさがす）
      if (blocked.contains(e!.by)) {
        unawaited(queue.enter(name, since));
        return;
      }
      assigned ??= e.room;
    });
    try {
      var ticks = 0;
      final maxTicks = (wait.inMilliseconds / tick.inMilliseconds).ceil();
      while (true) {
        if (_cancelled) {
          await queue.leave();
          return null;
        }
        // 見つけてもらえた：その部屋に入る
        final code = assigned;
        if (code != null) {
          assigned = null;
          await queue.leave();
          try {
            return FoundPlayer(await rooms.join(code, name), 1);
          } on RoomException {
            // 部屋がなくなっていた
          }
          await queue.enter(name, since);
        }
        if (ticks >= maxTicks) {
          await queue.leave();
          if (assigned != null) continue;
          return FoundGhost(
            await queue.randomGhost(_random) ?? cpuGhost(newConfig(), _random),
          );
        }
        // 先に待っていた人を見つける
        final now = DateTime.now();
        final others = [
          for (final e in await queue.waiting())
            if (e.uid != me &&
                e.room == null &&
                now.difference(e.ping) < fresh &&
                !blocked.contains(e.uid) &&
                e.since.isBefore(since))
              e,
        ]..sort((a, b) => a.since.compareTo(b.since));
        for (final other in others.take(1)) {
          final room = await _host(other);
          if (room != null) return FoundPlayer(room, 0);
        }
        if (ticks % 2 == 1) await queue.ping(DateTime.now());
        await Future<void>.delayed(tick);
        ticks++;
        elapsedSeconds = ticks * tick.inSeconds;
      }
    } finally {
      await sub.cancel();
    }
  }

  /// 部屋を作って [other] に知らせ、入ってくるのを待つ
  Future<OnlineRoom?> _host(QueueEntry other) async {
    final code = await rooms.create(newConfig(), name);
    if (!await queue.claim(other.uid, code)) {
      await rooms.close(code);
      return null;
    }
    await queue.leave();
    try {
      final room = await rooms
          .watch(code)
          .firstWhere((r) => r == null || r.full || r.closed)
          .timeout(joinWait);
      if (room != null && room.full && !room.closed) return room;
    } on TimeoutException {
      // 相手が来なかった
    } on StateError {
      // 見守りが終わった
    }
    await rooms.close(code);
    await queue.enter(name, _since);
    return null;
  }

  /// ゴーストがまだないときの、CPU のゴースト（ふつうくらいの強さ）
  static GhostRun cpuGhost(VersusRoomConfig config, Random random) => GhostRun(
    name: 'CPU',
    setIds: config.setIds,
    seed: config.seed,
    rounds: config.rounds,
    answers: [
      for (var i = 0; i < config.rounds; i++)
        GhostAnswer(
          2500 + random.nextInt(3500),
          random.nextDouble() < CpuLevel.normal.accuracy,
        ),
    ],
  );
}
