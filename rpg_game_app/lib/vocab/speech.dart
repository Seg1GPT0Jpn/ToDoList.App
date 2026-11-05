import 'package:flutter_tts/flutter_tts.dart';

import '../app/edition.dart';
import 'speech_web_stub.dart' if (dart.library.js_interop) 'speech_web.dart';

/// 単語や例文を読み上げる
abstract class Speaker {
  Future<void> speak(String text, {required String lang, required double rate});
  Future<void> stop();
}

/// 声の選び方・読み上げる文の整え方（端末によらず共通）
class SpeechText {
  SpeechText._();

  static String _norm(Object? l) => '$l'.toLowerCase().replaceAll('_', '-');

  /// おもしろ声（macOS・iOS の Bad News など）。発音の練習には使わない
  static const _novelty = [
    'albert',
    'bad news',
    'bahh',
    'bells',
    'boing',
    'bubbles',
    'cellos',
    'good news',
    'jester',
    'organ',
    'superstar',
    'trinoids',
    'whisper',
    'wobble',
    'zarvox',
    'deranged',
    'hysterical',
    'pipe organ',
    'junior',
    'ralph',
    'fred',
    'kathy',
    'grandma',
    'grandpa',
    'eddy',
    'flo',
    'reed',
    'rocko',
    'sandy',
    'shelley',
  ];

  /// 声の点数。高いほど自然に聞こえやすい。言語が合わなければ 0
  static int score(Map<Object?, Object?> v, String lang) {
    final want = _norm(lang);
    final locale = _norm(v['locale']);
    final name = '${v['name']}'.toLowerCase();
    var s = locale == want
        ? 20
        : locale.split('-').first == want.split('-').first
        ? 10
        : 0;
    if (s == 0) return 0;
    if (_novelty.any((n) => name == n || name.startsWith('$n '))) s -= 15;
    // 高品質な声
    for (final k in ['natural', 'neural', 'enhanced', 'premium', 'wavenet']) {
      if (name.contains(k)) s += 4;
    }
    if (name.startsWith('google')) s += 3;
    if (name.contains('samantha') || name.contains('aaron')) s += 2;
    // Android：入っていない声・通信が必要な声は避ける
    final features = '${v['features'] ?? ''}'.toLowerCase();
    if (features.contains('notinstalled')) s -= 12;
    if ('${v['network_required']}' == '1' || name.contains('network')) s -= 2;
    if (name.contains('local')) s += 1;
    return s < 1 ? 1 : s;
  }

  /// 端末の声の一覧から、その言語でいちばんよい声を選ぶ（なければ null）。
  ///
  /// 日本語の端末だと、言語を指定しても日本語の声のまま英語を読むことがあるので、
  /// 英語なら英語の声（en-US がなければ en-GB など）を名前で指定する。
  static Map<String, String>? pickVoice(List<Object?> voices, String lang) {
    Map<String, String>? best;
    var bestScore = 0;
    for (final v in voices) {
      if (v is! Map) continue;
      final s = score(v, lang);
      if (s > bestScore) {
        bestScore = s;
        best = {'name': '${v['name']}', 'locale': '${v['locale']}'};
      }
    }
    return best;
  }

  /// 英語として読み上げる文に整える。
  ///
  /// 単語帳の見出しには「～」「（日本語のメモ）」「A / B」「sth」などが入るので、
  /// そのまま読ませると記号や日本語を読んでしまう。
  static String clean(String text, String lang) {
    if (!_norm(lang).startsWith('en')) return text.trim();
    var t = text;
    // 日本語を含むかっこは中身ごと消す（英語のかっこは外すだけ）
    t = t.replaceAll(
      RegExp(r'[（(\[【［][^）)\]】］]*[぀-ヿ一-鿿][^）)\]】］]*[）)\]】］]'),
      ' ',
    );
    t = t.replaceAll(RegExp(r'[（）()\[\]【】［］{}<>〈〉《》]'), ' ');
    t = t.replaceAll(RegExp(r'[～〜~]\s*ing\b'), 'doing');
    t = t.replaceAll(RegExp(r'[぀-ヿ一-鿿　-〿～〜~…]+'), ' ');
    t = t.replaceAll(RegExp(r'\.{2,}'), ' ');
    t = t.replaceAll(RegExp(r'\s*/\s*'), ', ');
    t = t.replaceAll(RegExp(r'\bsth\b', caseSensitive: false), 'something');
    t = t.replaceAll(RegExp(r'\bsb\b', caseSensitive: false), 'somebody');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAll(RegExp(r'^[,;:\s]+|[,;:\s]+$'), '');
    return t.isEmpty ? text.trim() : t;
  }
}

/// Android・iOS など（flutter_tts）
class TtsSpeaker implements Speaker {
  FlutterTts? _tts;

  /// 言語ごとに選んだ声
  final _voices = <String, Map<String, String>>{};

  /// テスト用（前と同じ名前で使えるように）
  static Map<String, String>? pickVoice(List<Object?> voices, String lang) =>
      SpeechText.pickVoice(voices, lang);

  Future<void> _useVoice(FlutterTts tts, String lang) async {
    if (!_voices.containsKey(lang)) {
      try {
        final list = await tts.getVoices;
        final v = list is List ? SpeechText.pickVoice(list, lang) : null;
        // 見つからないときは覚えない（声の一覧があとから届く端末がある）
        if (v != null) _voices[lang] = v;
      } catch (_) {}
    }
    final v = _voices[lang];
    if (v != null) await tts.setVoice(v);
  }

  @override
  Future<void> speak(
    String text, {
    required String lang,
    required double rate,
  }) async {
    try {
      final tts = _tts ??= FlutterTts();
      // 前の読み上げが残っていると、次が読まれないことがある
      await tts.stop();
      await tts.setLanguage(lang);
      await _useVoice(tts, lang);
      await tts.setSpeechRate(rate);
      await tts.setPitch(1.0);
      await tts.speak(SpeechText.clean(text, lang));
    } catch (_) {
      // 読み上げが使えない端末では何もしない
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

class SilentSpeaker implements Speaker {
  final spoken = <String>[];
  @override
  Future<void> speak(
    String text, {
    required String lang,
    required double rate,
  }) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

/// テストでは [SilentSpeaker] に差し替える。
/// Web版はブラウザの読み上げを直接使う（flutter_tts の Web 版は止まりやすく、速さの基準もちがう）
Speaker speaker = lightEdition
    // つづりクエストLight は音声を使わない（読み上げのプログラムも入れない）
    ? SilentSpeaker()
    : createPlatformSpeaker() ?? TtsSpeaker();
