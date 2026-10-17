import '../app/settings.dart';

/// 音を鳴らす部分（本物は audioplayers、テストでは記録するだけ）
abstract class AudioBackend {
  /// [channel] で [asset] をくり返し再生する（すでに同じ曲なら音量だけ変える）
  Future<void> loop(String channel, String asset, double volume);
  Future<void> setVolume(String channel, double volume);
  Future<void> stop(String channel);

  /// 1回だけ鳴らす（効果音・ジングル）
  Future<void> once(String asset, double volume);
}

/// どの BGM を、どの楽器パートで鳴らすかを決める。
///
/// - 画面に入ると [enter]、出ると [leave]。いちばん上の画面の曲が流れる
/// - バトルの曲はピアノ・ベース・打楽器・ストリングスの4パートに分かれていて、
///   正解を続けるほどパートが増え、まちがえると1つ減る（学ぶほど曲が完成する）
/// - ボス戦は最初から全部のパート
class MusicDirector {
  MusicDirector(this._backend, [this._settings = const AppSettings()]);

  final AudioBackend _backend;
  AppSettings _settings;
  final List<String> _stack = [];
  String? _playing;
  int _layers = 1;

  /// 1つのファイルにした曲（assets/audio/bgm_battle.mp3 など）。
  /// バトル・ボスの曲をこのファイルで置いたときは、4パートに分けずにそのまま流す
  /// （自分で作った曲を入れやすくするため）。起動時にアセットの一覧から決める。
  Set<String> singleTracks = {};

  bool _layered(String key) =>
      (key == battle || key == boss) && !singleTracks.contains(key);

  static const battle = 'battle';
  static const boss = 'boss';
  static const layerNames = ['piano', 'bass', 'drums', 'strings'];

  /// 曲の名前 → ファイル
  static String bgmAsset(String key) => 'audio/bgm_$key.mp3';
  static String layerAsset(String music, int i) =>
      'audio/bgm_${music}_${layerNames[i]}.mp3';

  /// ワールドのフィールド曲（ないワールドはホームの曲）
  static String fieldKey(String worldId) {
    const known = {
      'japanese',
      'math',
      'english',
      'science',
      'social',
      'information',
    };
    return known.contains(worldId) ? 'field_$worldId' : 'home';
  }

  String? get current => _stack.isEmpty ? null : _stack.last;
  int get layers => _layers;
  AppSettings get settings => _settings;

  bool get _isLayered => current != null && _layered(current!);

  Future<void> enter(String key) async {
    _stack.add(key);
    if (key == battle) _layers = _settings.adaptiveMusic ? 1 : 4;
    if (key == boss) _layers = 4;
    await _refresh();
  }

  Future<void> leave(String key) async {
    final i = _stack.lastIndexOf(key);
    if (i < 0) return;
    _stack.removeAt(i);
    await _refresh();
  }

  /// 回答のたびに呼ぶ
  Future<void> answer({required bool correct, required int combo}) async {
    if (current != battle || !_settings.adaptiveMusic) return;
    final next = correct
        ? (1 +
                  (combo >= 1 ? 1 : 0) +
                  (combo >= 3 ? 1 : 0) +
                  (combo >= 5 ? 1 : 0))
              .clamp(_layers, 4)
        : (_layers - 1).clamp(1, 4);
    if (next == _layers) return;
    _layers = next;
    await _applyLayerVolumes();
  }

  Future<void> applySettings(AppSettings s) async {
    final wasOn = _settings.bgm;
    _settings = s;
    if (!s.adaptiveMusic && current == battle) _layers = 4;
    if (wasOn != s.bgm) {
      await _restart();
    } else if (_isLayered) {
      await _applyLayerVolumes();
    } else if (_playing != null) {
      await _backend.setVolume('bgm', s.bgmVolume);
    }
  }

  Future<void> se(String key) async {
    if (!_settings.se) return;
    await _backend.once('audio/$key.mp3', _settings.seVolume);
  }

  Future<void> jingle(String key) async {
    if (!_settings.bgm) return;
    await _backend.once('audio/jingle_$key.mp3', _settings.bgmVolume);
  }

  /// 再生を止められていた（ブラウザの自動再生の制限など）ときに、もう一度流す
  Future<void> retry() => _restart();

  Future<void> _restart() async {
    await _stopPlaying();
    await _refresh();
  }

  Future<void> _stopPlaying() async {
    final playing = _playing;
    if (playing != null && _layered(playing)) {
      for (var i = 0; i < 4; i++) {
        await _backend.stop('layer$i');
      }
    } else if (_playing != null) {
      await _backend.stop('bgm');
    }
    _playing = null;
  }

  Future<void> _refresh() async {
    final want = _settings.bgm ? current : null;
    if (want == _playing) return;
    await _stopPlaying();
    _playing = want;
    if (want == null) return;
    if (_layered(want)) {
      for (var i = 0; i < 4; i++) {
        await _backend.loop('layer$i', layerAsset(want, i), _layerVolume(i));
      }
    } else {
      await _backend.loop('bgm', bgmAsset(want), _settings.bgmVolume);
    }
  }

  double _layerVolume(int i) => i < _layers ? _settings.bgmVolume : 0;

  Future<void> _applyLayerVolumes() async {
    if (!_settings.bgm) return;
    for (var i = 0; i < 4; i++) {
      await _backend.setVolume('layer$i', _layerVolume(i));
    }
  }
}

/// 何も鳴らさない（テスト・音を使えない環境）
class SilentBackend implements AudioBackend {
  @override
  Future<void> loop(String channel, String asset, double volume) async {}
  @override
  Future<void> once(String asset, double volume) async {}
  @override
  Future<void> setVolume(String channel, double volume) async {}
  @override
  Future<void> stop(String channel) async {}
}
