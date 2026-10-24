import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 毎日の学習リマインダー（Android・iOS の通知）。Web では使えない。
class Reminders {
  static const _on = 'reminder_on',
      _hour = 'reminder_hour',
      _min = 'reminder_min';
  static const _id = 7001;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<(bool, TimeOfDay)> load() async {
    final p = await SharedPreferences.getInstance();
    return (
      p.getBool(_on) ?? false,
      TimeOfDay(hour: p.getInt(_hour) ?? 19, minute: p.getInt(_min) ?? 0),
    );
  }

  static Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // 日本の学校向けのアプリなので日本時間で予定する
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _ready = true;
  }

  /// 設定を保存して、通知を予定しなおす。許可されなければ false。
  static Future<bool> set(bool on, TimeOfDay time) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_on, on);
    await p.setInt(_hour, time.hour);
    await p.setInt(_min, time.minute);
    if (!supported) return !on;
    try {
      await _init();
      await _plugin.cancel(id: _id);
      if (!on) return true;
      final granted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
      if (!granted) return false;
      final now = tz.TZDateTime.now(tz.local);
      var at = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: _id,
        title: 'つづりクエスト',
        body: '今日の冒険に出かけよう！ 復習の問題が待っています。',
        scheduledDate: at,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_reminder',
            '学習リマインダー',
            channelDescription: '毎日決まった時刻に学習をお知らせします',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 設定画面の「毎日のお知らせ」
class ReminderTile extends StatefulWidget {
  const ReminderTile({super.key});

  @override
  State<ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends State<ReminderTile> {
  bool _on = false;
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    Reminders.load().then((v) {
      if (mounted) {
        setState(() {
          _on = v.$1;
          _time = v.$2;
        });
      }
    });
  }

  Future<void> _apply(bool on, TimeOfDay time) async {
    setState(() {
      _on = on;
      _time = time;
    });
    final ok = await Reminders.set(on, time);
    if (!mounted || ok) return;
    setState(() => _on = false);
    await Reminders.set(false, time);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Reminders.supported
              ? '通知が許可されていません。端末の設定から許可してください。'
              : 'お知らせはスマホのアプリ版で使えます。',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = '${_time.hour}:${_time.minute.toString().padLeft(2, '0')}';
    return Column(
      children: [
        SwitchListTile(
          key: const ValueKey('reminder-switch'),
          title: const Text('毎日のお知らせ'),
          subtitle: Text(
            Reminders.supported ? '毎日 $label に学習をお知らせします' : 'スマホのアプリ版で使えます',
          ),
          value: _on,
          onChanged: (v) => _apply(v, _time),
        ),
        if (_on)
          ListTile(
            title: const Text('お知らせの時刻'),
            trailing: Text(label, style: const TextStyle(fontSize: 16)),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (t != null) await _apply(true, t);
            },
          ),
      ],
    );
  }
}
