import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 1つのお知らせ
class ClassReminder {
  const ClassReminder(this.id, this.at, this.title, this.body);
  final int id;
  final DateTime at;
  final String title;
  final String body;
}

/// クラスの小テスト・定期テストのお知らせ（前日の夜と当日の朝の「最終チェック」）。
/// Android・iOS だけ。Web では何もしない。
class ClassReminders {
  const ClassReminders._();

  static const _base = 7100;

  /// 一度に予定するお知らせの数（近い試験から）
  static const maxCount = 20;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// 予定するお知らせ（これから先のものだけ）
  static List<ClassReminder> plan(
    Iterable<(Classroom, ClassTask)> tasks,
    DateTime now,
  ) {
    final out = <ClassReminder>[];
    final sorted = [...tasks]..sort((a, b) => a.$2.date.compareTo(b.$2.date));
    for (final (room, t) in sorted) {
      if (t.over(now)) continue;
      final d = t.date;
      final name = t.title.isEmpty ? t.kind.label : t.title;
      final eve = DateTime(d.year, d.month, d.day - 1, 20);
      final morning = DateTime(d.year, d.month, d.day, 7);
      if (eve.isAfter(now)) {
        out.add(
          ClassReminder(
            0,
            eve,
            '明日は「$name」',
            '${room.name}：${t.bookTitle} ${t.from}〜${t.to}。寝る前に最終チェックをしよう',
          ),
        );
      }
      if (morning.isAfter(now)) {
        out.add(
          ClassReminder(
            0,
            morning,
            '今日は「$name」',
            '${t.bookTitle} ${t.from}〜${t.to}。5分の最終チェックで仕上げよう',
          ),
        );
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return [
      for (final (i, r) in out.take(maxCount).indexed)
        ClassReminder(_base + i, r.at, r.title, r.body),
    ];
  }

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// お知らせを予定しなおす（前に予定したものは消す）。
  /// 通知の許可がなければ、許可は求めずに何もしない（設定の「毎日のお知らせ」で許可する）
  static Future<void> sync(Iterable<(Classroom, ClassTask)> tasks) async {
    if (!supported) return;
    try {
      if (!_ready) {
        tzdata.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
        await _plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
        );
        _ready = true;
      }
      for (var i = 0; i < maxCount; i++) {
        await _plugin.cancel(id: _base + i);
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null && await android.areNotificationsEnabled() != true) {
        return;
      }
      for (final r in plan(tasks, DateTime.now())) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          scheduledDate: tz.TZDateTime.from(r.at, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'class_tests',
              'クラスの小テスト・定期テスト',
              channelDescription: '試験の前日の夜と当日の朝に、最終チェックをお知らせします',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // お知らせが使えない端末では何もしない
    }
  }
}
