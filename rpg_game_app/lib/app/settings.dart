import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 遊びやすさの設定（端末ごと。クラウドには上げない）
@immutable
class AppSettings {
  const AppSettings({
    this.bgm = true,
    this.se = true,
    this.bgmVolume = 0.6,
    this.seVolume = 0.8,
    this.textScale = 1.0,
    this.reduceMotion = false,
    this.adaptiveMusic = true,
  });

  final bool bgm;
  final bool se;
  final double bgmVolume;
  final double seVolume;

  /// 文字の大きさ（1.0 / 1.15 / 1.3）
  final double textScale;

  /// 画面のゆれ・点滅をおさえる
  final bool reduceMotion;

  /// 正解するほど、バトルの音楽に楽器が増える
  final bool adaptiveMusic;

  static const textScales = [1.0, 1.15, 1.3];

  AppSettings copyWith({
    bool? bgm,
    bool? se,
    double? bgmVolume,
    double? seVolume,
    double? textScale,
    bool? reduceMotion,
    bool? adaptiveMusic,
  }) => AppSettings(
    bgm: bgm ?? this.bgm,
    se: se ?? this.se,
    bgmVolume: bgmVolume ?? this.bgmVolume,
    seVolume: seVolume ?? this.seVolume,
    textScale: textScale ?? this.textScale,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    adaptiveMusic: adaptiveMusic ?? this.adaptiveMusic,
  );

  Map<String, dynamic> toMap() => {
    'bgm': bgm,
    'se': se,
    'bgmVolume': bgmVolume,
    'seVolume': seVolume,
    'textScale': textScale,
    'reduceMotion': reduceMotion,
    'adaptiveMusic': adaptiveMusic,
  };

  factory AppSettings.fromMap(Map<String, dynamic> m) {
    double d(String k, double def) => (m[k] as num?)?.toDouble() ?? def;
    return AppSettings(
      bgm: m['bgm'] as bool? ?? true,
      se: m['se'] as bool? ?? true,
      bgmVolume: d('bgmVolume', 0.6).clamp(0, 1),
      seVolume: d('seVolume', 0.8).clamp(0, 1),
      textScale: d('textScale', 1.0).clamp(0.8, 1.5),
      reduceMotion: m['reduceMotion'] as bool? ?? false,
      adaptiveMusic: m['adaptiveMusic'] as bool? ?? true,
    );
  }
}

/// 設定の保存場所。変わると聞いている画面に知らせる
class SettingsStore extends ValueNotifier<AppSettings> {
  SettingsStore(SharedPreferences prefs) : _prefs = prefs, super(_read(prefs));

  /// テスト用（保存しない）
  SettingsStore.memory([super.value = const AppSettings()]) : _prefs = null;

  static const _key = 'rpg_settings_v1';
  final SharedPreferences? _prefs;

  static AppSettings _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const AppSettings();
    }
  }

  Future<void> update(AppSettings next) async {
    value = next;
    await _prefs?.setString(_key, jsonEncode(next.toMap()));
  }
}
