import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'speech.dart';

/// Web版：ブラウザの読み上げ（speechSynthesis）を直接使う
Speaker? createPlatformSpeaker() => WebSpeaker();

class WebSpeaker implements Speaker {
  final _voices = <String, web.SpeechSynthesisVoice>{};

  web.SpeechSynthesis? get _synth {
    try {
      return web.window.speechSynthesis;
    } catch (_) {
      return null;
    }
  }

  /// 声の一覧はページを開いた直後は空のことがあるので、少し待つ
  Future<List<web.SpeechSynthesisVoice>> _list(
    web.SpeechSynthesis synth,
  ) async {
    var list = synth.getVoices().toDart;
    if (list.isNotEmpty) return list;
    final done = Completer<void>();
    synth.onvoiceschanged = ((web.Event _) {
      if (!done.isCompleted) done.complete();
    }).toJS;
    await done.future.timeout(
      const Duration(milliseconds: 1500),
      onTimeout: () {},
    );
    return synth.getVoices().toDart;
  }

  Future<web.SpeechSynthesisVoice?> _voice(
    web.SpeechSynthesis synth,
    String lang,
  ) async {
    final cached = _voices[lang];
    if (cached != null) return cached;
    final list = await _list(synth);
    final picked = SpeechText.pickVoice([
      for (final v in list) {'name': v.name, 'locale': v.lang},
    ], lang);
    if (picked == null) return null;
    for (final v in list) {
      if (v.name == picked['name'] && v.lang == picked['locale']) {
        return _voices[lang] = v;
      }
    }
    return null;
  }

  @override
  Future<void> speak(
    String text, {
    required String lang,
    required double rate,
  }) async {
    final synth = _synth;
    if (synth == null) return;
    try {
      // 前の読み上げを止める。止めた直後に話すと無視されるブラウザがあるので少し待つ
      if (synth.speaking || synth.pending) {
        synth.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      final u = web.SpeechSynthesisUtterance(SpeechText.clean(text, lang));
      u.lang = lang;
      final v = await _voice(synth, lang);
      if (v != null) {
        u.voice = v;
        u.lang = v.lang;
      }
      // アプリの速さは flutter_tts の基準（0.5＝ふつう）。ブラウザは 1.0＝ふつう
      u.rate = (rate * 2).clamp(0.5, 2.0);
      u.pitch = 1;
      u.volume = 1;
      synth.resume();
      synth.speak(u);
    } catch (_) {
      // 読み上げが使えないブラウザでは何もしない
    }
  }

  @override
  Future<void> stop() async {
    try {
      _synth?.cancel();
    } catch (_) {}
  }
}
