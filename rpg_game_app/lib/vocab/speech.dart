import 'package:flutter_tts/flutter_tts.dart';

/// 単語や例文を読み上げる
abstract class Speaker {
  Future<void> speak(String text, {required String lang, required double rate});
  Future<void> stop();
}

class TtsSpeaker implements Speaker {
  FlutterTts? _tts;

  /// 言語ごとに選んだ声（見つからなければ null）
  final _voices = <String, Map<String, String>?>{};

  /// 端末の声の一覧から、その言語の声を選ぶ。
  ///
  /// 日本語の端末だと、言語を指定しても日本語の声のまま英語を読むことがあるので、
  /// 英語なら英語の声（en-US がなければ en-GB など）を名前で指定する。
  static Map<String, String>? pickVoice(List<Object?> voices, String lang) {
    String norm(Object? l) => '$l'.toLowerCase().replaceAll('_', '-');
    final want = norm(lang);
    final base = want.split('-').first;
    Map<String, String>? best;
    var bestScore = 0;
    for (final v in voices) {
      if (v is! Map) continue;
      final locale = norm(v['locale']);
      final score = locale == want
          ? 2
          : locale.split('-').first == base
          ? 1
          : 0;
      if (score > bestScore) {
        bestScore = score;
        best = {'name': '${v['name']}', 'locale': '${v['locale']}'};
      }
    }
    return best;
  }

  Future<void> _useVoice(FlutterTts tts, String lang) async {
    if (!_voices.containsKey(lang)) {
      try {
        final list = await tts.getVoices;
        _voices[lang] = list is List ? pickVoice(list, lang) : null;
      } catch (_) {
        _voices[lang] = null;
      }
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
      await tts.setLanguage(lang);
      await _useVoice(tts, lang);
      await tts.setSpeechRate(rate);
      await tts.speak(text);
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

/// テストでは [SilentSpeaker] に差し替える
Speaker speaker = TtsSpeaker();
