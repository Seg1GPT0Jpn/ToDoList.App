import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'music_director.dart';

/// audioplayers で音を鳴らす。
///
/// ブラウザは、画面に一度さわるまで音を出させてくれない。そのときの失敗は
/// [blocked] で知らせ、さわったあとに [MusicDirector.retry] で流しなおす。
class PlayerBackend implements AudioBackend {
  final Map<String, AudioPlayer> _channels = {};
  final Map<String, String> _assets = {};
  final List<AudioPlayer> _pool = [];
  int _next = 0;

  /// 自動再生の制限で止められた
  bool blocked = false;

  AudioPlayer _channel(String name) =>
      _channels.putIfAbsent(name, () => AudioPlayer(playerId: 'ch_$name'));

  @override
  Future<void> loop(String channel, String asset, double volume) async {
    final p = _channel(channel);
    try {
      if (_assets[channel] == asset && p.state == PlayerState.playing) {
        await p.setVolume(volume);
        return;
      }
      _assets[channel] = asset;
      await p.setReleaseMode(ReleaseMode.loop);
      await p.play(AssetSource(asset), volume: volume);
    } catch (e) {
      blocked = true;
      debugPrint('BGM を再生できませんでした: $e');
    }
  }

  @override
  Future<void> setVolume(String channel, double volume) async {
    try {
      await _channels[channel]?.setVolume(volume);
    } catch (_) {}
  }

  @override
  Future<void> stop(String channel) async {
    _assets.remove(channel);
    try {
      await _channels[channel]?.stop();
    } catch (_) {}
  }

  @override
  Future<void> once(String asset, double volume) async {
    if (_pool.length < 6) {
      _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
    }
    final p = _pool[_next++ % _pool.length];
    try {
      await p.stop();
      await p.play(AssetSource(asset), volume: volume);
    } catch (e) {
      blocked = true;
    }
  }
}
