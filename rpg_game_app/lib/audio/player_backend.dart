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

  AudioPlayer _channel(String name) => _channels.putIfAbsent(
    name,
    () => _quiet(AudioPlayer(playerId: 'ch_$name')),
  );

  /// 再生位置を調べない。audioplayers は鳴っている間、位置を知らせるために
  /// 毎フレーム画面の描きなおしを予約するので、何もしていない画面でも毎秒60回描いてしまう
  /// （このアプリは再生位置を使わない）
  static AudioPlayer _quiet(AudioPlayer p) => p..positionUpdater = null;

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
      _pool.add(_quiet(AudioPlayer())..setReleaseMode(ReleaseMode.stop));
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
