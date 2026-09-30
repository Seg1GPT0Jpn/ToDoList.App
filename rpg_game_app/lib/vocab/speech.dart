import 'package:flutter_tts/flutter_tts.dart';

/// 単語や例文を読み上げる
abstract class Speaker {
  Future<void> speak(String text, {required String lang, required double rate});
  Future<void> stop();
}

class TtsSpeaker implements Speaker {
  FlutterTts? _tts;

  @override
  Future<void> speak(
    String text, {
    required String lang,
    required double rate,
  }) async {
    try {
      final tts = _tts ??= FlutterTts();
      await tts.setLanguage(lang);
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
