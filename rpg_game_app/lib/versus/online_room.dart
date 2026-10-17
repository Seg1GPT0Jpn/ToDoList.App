import 'dart:async';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

/// オンライン対戦の部屋の状態
class OnlineRoom {
  const OnlineRoom({
    required this.code,
    required this.config,
    required this.hostName,
    required this.hostId,
    this.guestName,
    this.guestId,
    this.events = const [],
    this.closed = false,
    this.stamps = const {},
  });

  /// 送られたスタンプ（側 → (スタンプの番号, 何回目か)）。文字は送れない
  final Map<int, (int, int)> stamps;

  /// 部屋の番号（4けた）
  final String code;
  final VersusRoomConfig config;
  final String hostName;
  final String hostId;
  final String? guestName;
  final String? guestId;

  /// これまでの出来事（答え・時間切れ）。この順番で当てはめる
  final List<VersusEvent> events;

  /// どちらかが部屋を出た
  final bool closed;

  bool get full => guestId != null;

  Map<String, dynamic> toMap() => {
    'code': code,
    ...config.toMap(),
    'host': hostId,
    'hostName': hostName,
    'guest': guestId,
    'guestName': guestName,
    'events': [for (final e in events) e.toMap()],
    'closed': closed,
    'stamps': {
      for (final e in stamps.entries)
        '${e.key}': {'i': e.value.$1, 'n': e.value.$2},
    },
  };

  factory OnlineRoom.fromMap(Map<String, dynamic> m) => OnlineRoom(
    code: m['code'] as String? ?? '',
    config: VersusRoomConfig.fromMap(m),
    hostId: m['host'] as String? ?? '',
    hostName: m['hostName'] as String? ?? 'ホスト',
    guestId: m['guest'] as String?,
    guestName: m['guestName'] as String?,
    events: [
      for (final e in (m['events'] as List? ?? const []))
        VersusEvent.fromMap(Map<String, dynamic>.from(e as Map)),
    ],
    closed: m['closed'] as bool? ?? false,
    stamps: {
      if (m['stamps'] is Map)
        for (final e in (m['stamps'] as Map).entries)
          if (int.tryParse('${e.key}') != null &&
              e.value is Map &&
              (e.value as Map)['i'] is num &&
              (e.value as Map)['n'] is num)
            int.parse('${e.key}'): (
              ((e.value as Map)['i'] as num).toInt(),
              ((e.value as Map)['n'] as num).toInt(),
            ),
    },
  );

  OnlineRoom copyWith({
    String? guestName,
    String? guestId,
    List<VersusEvent>? events,
    bool? closed,
    Map<int, (int, int)>? stamps,
  }) => OnlineRoom(
    code: code,
    config: config,
    hostName: hostName,
    hostId: hostId,
    guestName: guestName ?? this.guestName,
    guestId: guestId ?? this.guestId,
    events: events ?? this.events,
    closed: closed ?? this.closed,
    stamps: stamps ?? this.stamps,
  );
}

/// 部屋に入れなかった理由
class RoomException implements Exception {
  const RoomException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// オンライン対戦の部屋の置き場所（Firestore。テストではメモリ）
abstract class VersusRoomBackend {
  /// ログインしている人の ID（ログインしていなければ null）
  String? get userId;

  /// 部屋を作り、部屋の番号を返す
  Future<String> create(VersusRoomConfig config, String hostName);

  /// 番号の部屋に入る
  Future<OnlineRoom> join(String code, String guestName);

  /// 部屋の変化を見守る（部屋がなくなると null）
  Stream<OnlineRoom?> watch(String code);

  /// 出来事を送る。[accepts] で、今までの出来事に続けてよいかを確かめてから書きこむ
  /// （2人がほぼ同時に答えても、先に書きこめた1人だけが通る）。
  Future<bool> send(
    String code,
    VersusEvent event,
    bool Function(List<VersusEvent> before) accepts,
  );

  /// 部屋を閉じる
  Future<void> close(String code);

  /// スタンプを送る（[count] は自分が送った回数。同じスタンプを続けて送っても届く）
  Future<void> stamp(String code, int side, int stamp, int count);

  /// 4けたの部屋番号
  static String newCode([Random? random]) =>
      (1000 + (random ?? Random()).nextInt(9000)).toString();
}

/// メモリの中の部屋の置き場所（テスト用）。2人ぶんの [MemoryVersusBackend] で共有する
class MemoryRoomHub {
  final Map<String, OnlineRoom> rooms = {};
  final Map<String, StreamController<OnlineRoom?>> streams = {};
}

/// メモリの中の部屋（テスト用）
class MemoryVersusBackend implements VersusRoomBackend {
  MemoryVersusBackend(this._hub, {this.userId = 'me'});

  final MemoryRoomHub _hub;

  @override
  final String? userId;

  Map<String, OnlineRoom> get _rooms => _hub.rooms;
  Map<String, StreamController<OnlineRoom?>> get _streams => _hub.streams;

  void _emit(String code) {
    _streams[code]?.add(_rooms[code]);
  }

  @override
  Future<String> create(VersusRoomConfig config, String hostName) async {
    var code = VersusRoomBackend.newCode();
    while (_rooms.containsKey(code)) {
      code = VersusRoomBackend.newCode();
    }
    _rooms[code] = OnlineRoom(
      code: code,
      config: config,
      hostName: hostName,
      hostId: userId!,
    );
    return code;
  }

  @override
  Future<OnlineRoom> join(String code, String guestName) async {
    final room = _rooms[code];
    if (room == null || room.closed) {
      throw const RoomException('その番号の部屋は見つかりません');
    }
    if (room.full && room.guestId != userId) {
      throw const RoomException('その部屋はもう満員です');
    }
    final joined = room.copyWith(guestId: userId, guestName: guestName);
    _rooms[code] = joined;
    _emit(code);
    return joined;
  }

  @override
  Stream<OnlineRoom?> watch(String code) {
    final c = _streams.putIfAbsent(
      code,
      () => StreamController<OnlineRoom?>.broadcast(),
    );
    scheduleMicrotask(() => c.add(_rooms[code]));
    return c.stream;
  }

  @override
  Future<bool> send(
    String code,
    VersusEvent event,
    bool Function(List<VersusEvent> before) accepts,
  ) async {
    final room = _rooms[code];
    if (room == null || !accepts(room.events)) return false;
    _rooms[code] = room.copyWith(events: [...room.events, event]);
    _emit(code);
    return true;
  }

  @override
  Future<void> close(String code) async {
    final room = _rooms[code];
    if (room == null) return;
    _rooms[code] = room.copyWith(closed: true);
    _emit(code);
  }

  @override
  Future<void> stamp(String code, int side, int stamp, int count) async {
    final room = _rooms[code];
    if (room == null) return;
    _rooms[code] = room.copyWith(
      stamps: {...room.stamps, side: (stamp, count)},
    );
    _emit(code);
  }
}
