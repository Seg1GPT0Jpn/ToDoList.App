import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

/// 問題データ（2D 版と同じ rpg_game の問題のまとめファイル）を読む
class Questions3D {
  Questions3D._();

  static final source = JsonQuestionSource(_loadSet);
  static final Map<String, Future<Map<String, dynamic>?>> _bundles = {};

  static Future<String?> _loadSet(String setId) async {
    final world = setId.split('_').first;
    final bundle = await (_bundles[world] ??= _loadBundle(world));
    if (bundle == null) _bundles.remove(world);
    final set = bundle?[setId];
    return set == null ? null : jsonEncode(set);
  }

  static Future<Map<String, dynamic>?> _loadBundle(String world) async {
    try {
      final data = await rootBundle.load(
        'packages/rpg_game/assets/question_bundles/$world.json',
      );
      return jsonDecode(
        utf8.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        ),
      ) as Map<String, dynamic>;
    } on FlutterError {
      return null;
    }
  }

  /// ステージの問題をまとめて読む。3D 版の試作のバトル画面で出せる問題
  /// （4択・図なし・本文なし・聞き取りなし・自作の問題）だけを残す。読めなければ null
  static Future<List<QuizQuestion>?> forStage(StageDef stage) async {
    final out = <QuizQuestion>[];
    final seen = <String>{};
    for (final id in stage.questionSetIds) {
      final set = await source.load(id);
      if (set == null || !set.origin.usableInRpg) continue;
      for (final q in set.questions) {
        if (playable(q) && seen.add(q.id)) out.add(q);
      }
    }
    return out.length < 4 ? null : out;
  }

  static bool playable(QuizQuestion q) =>
      q.isChoice &&
      q.choices.length >= 2 &&
      q.figure == null &&
      q.passage == null &&
      !q.listen;
}
