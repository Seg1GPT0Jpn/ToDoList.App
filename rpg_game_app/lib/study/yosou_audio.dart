import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:rpg_game/rpg_game.dart';

import 'yosou_crop_view.dart';
import 'yosou_exam_store.dart';

/// 予想問題のリスニングの音声（暗号化して同梱した mp3）を流す
abstract final class YosouAudio {
  static AudioPlayer? _player;
  static final _cache = <String, Future<Uint8List?>>{};

  /// 流す（テストで差しかえる）。うまく流せたら true
  static Future<bool> Function(String spec) play = _play;

  /// 「<同梱フォルダ>:<名前>」の音声を開く（鍵がない・ちがうときは null）
  static Future<Uint8List?> bytes(String spec) => _cache[spec] ??= () async {
    final key = YosouImages.key;
    final i = spec.indexOf(':');
    if (key == null || i < 0) return null;
    try {
      final data = SchoolMaterials.open(
        await YosouExamFiles.loader(
          'assets/mock_exams/${spec.substring(0, i)}/${spec.substring(i + 1)}.bin',
        ),
        key: key,
      );
      return data == null ? null : Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }();

  static Future<bool> _play(String spec) async {
    final data = await bytes(spec);
    if (data == null) return false;
    try {
      final p = _player ??= AudioPlayer(playerId: 'yosou_listening')
        ..positionUpdater = null;
      await p.stop();
      await p.play(BytesSource(data, mimeType: 'audio/mpeg'));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }
}
