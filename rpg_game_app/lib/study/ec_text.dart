import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 英語コミュニケーションⅠ（Lesson 5〜7）の本文。
///
/// 教科書の文章なので、暗号化したもの（assets/texts/）だけを同梱し、
/// パスワードを知っている人だけが開ける。開いたパスワードはこの端末に覚えておく。
class EcText {
  EcText._();

  static const name = 'ec104';
  static const key = 'ec104_text_password_v1';

  /// テストで差し替えられるように
  static Future<List<int>?> Function(String file) assetLoader = _loadAsset;

  static Future<List<int>?> _loadAsset(String file) async {
    try {
      return base64Decode(
        (await rootBundle.loadString('assets/texts/$file.txt')).trim(),
      );
    } catch (_) {
      return null;
    }
  }

  static List<Passage>? _cache;

  /// パスワードで開く。ちがえば null。開けたら覚えておく
  static Future<List<Passage>?> unlock(
    SharedPreferences prefs,
    String password,
  ) async {
    final data = await assetLoader(VocabVault.fileName(name));
    if (data == null) return null;
    final r = VocabVault.open(data, password);
    if (r == null) return null;
    await prefs.setString(key, password.trim());
    return _cache = [
      for (final c in r.cards)
        Passage(id: c.id, title: c.term, paragraphs: c.meaning.split('\n')),
    ];
  }

  /// 前に開いたことがあれば本文を返す
  static Future<List<Passage>?> saved(SharedPreferences prefs) async {
    if (_cache != null) return _cache;
    final pw = prefs.getString(key);
    if (pw == null) return null;
    return unlock(prefs, pw);
  }

  static Future<void> forget(SharedPreferences prefs) async {
    _cache = null;
    await prefs.remove(key);
  }

  /// 問題のタグ（lesson5・section2 など）から本文を探す
  static Passage? passageFor(QuizQuestion q, List<Passage> passages) {
    String? tag(String prefix) {
      for (final t in q.tags) {
        if (t.startsWith(prefix)) return t.substring(prefix.length);
      }
      return null;
    }

    final l = tag('lesson'), s = tag('section');
    if (l == null || s == null) return null;
    for (final p in passages) {
      if (p.id == 'ec1_l${l}_s$s') return p;
    }
    return null;
  }

  /// 本文がある問題には本文をつける（バトル画面で巻物として出る）
  static List<QuizQuestion> attach(
    List<QuizQuestion> questions,
    List<Passage> passages,
  ) => [for (final q in questions) _with(q, passages)];

  static QuizQuestion _with(QuizQuestion q, List<Passage> passages) {
    final p = q.passage == null ? passageFor(q, passages) : null;
    if (p == null) return q;
    return QuizQuestion.fromJson(
      {...q.toJson(), 'passageId': p.id},
      passages: {p.id: p},
    );
  }
}
