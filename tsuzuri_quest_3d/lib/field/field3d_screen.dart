import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart'
    show PointerDeviceKind, PointerScrollEvent;
import 'package:flutter/material.dart' hide BoxShape;
import 'package:flutter/services.dart';
import 'package:flutter_scene/kit.dart' show VirtualJoystick;
import 'package:flutter_scene/scene.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../battle/battle3d_screen.dart';
import '../game/field3d.dart';
import '../game/questions.dart';
import '../game/save3d.dart';
import 'field3d_memory.dart';
import 'field3d_world.dart';

/// 3D フィールド（試作）。
///
/// 草原を歩き、NPC と話し、スライムに触れるとバトル画面になる。
/// 位置・倒した敵・レベルは、この端末の 3D 版のデータ（[Save3D]）にだけ保存する。
class Field3DScreen extends StatefulWidget {
  const Field3DScreen({
    super.key,
    required this.save,
    this.region = Field3DRegion.meadow,
  });

  final Save3D save;
  final Field3DRegion region;

  @override
  State<Field3DScreen> createState() => _Field3DScreenState();
}

class _Field3DScreenState extends State<Field3DScreen> {
  final _focus = FocusNode();
  final _load = Stopwatch()..start();
  late Field3DState _state;
  Field3DWorld? _world;
  String? _error;
  Save3D get _save => widget.save;

  // 入力
  vm.Vector2 _stick = vm.Vector2.zero();
  final _touchCamera = <int, Offset>{};
  bool _mouseDragging = false;

  // カメラ
  double _camYaw = 0;
  double _camPitch = 0.42;
  double _camDist = 6.5;

  // 会話・バトル
  Npc3D? _talking;
  int _line = 0;
  bool _busy = false;
  String? _toast;

  // 画質
  String _quality = 'standard';

  void _setQuality(String q) {
    _quality = q;
    _world?.setQuality(q);
    _save.setQuality(q);
    _frameTimes.clear();
    _say('画質：${_qualityName(q)}');
  }

  static String _qualityName(String q) => switch (q) {
    'high' => '高（影あり）',
    'light' => '軽量（影なし・解像度70%）',
    _ => '標準（影あり）',
  };

  // 計測
  Duration? _firstFrame;
  final _frameTimes = <double>[];
  double _fps = 0;
  double _avgMs = 0;
  double _worstMs = 0;
  int? _memoryMb;
  double _sinceHud = 0;
  double _sinceSave = 0;

  @override
  void initState() {
    super.initState();
    _state = Field3DState.start(widget.region);
    _start();
  }

  @override
  void dispose() {
    _saveNow();
    _world?.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      _state = _save.loadField(widget.region);
      _camYaw = _state.cameraYaw;
      final world = await Field3DWorld.create(widget.region, _state);
      if (!mounted) {
        world.dispose();
        return;
      }
      _quality = _save.quality;
      world.setQuality(_quality);
      setState(() => _world = world);
    } catch (e, st) {
      debugPrint('3D フィールドを開けませんでした: $e\n$st');
      if (mounted) setState(() => _error = '$e');
    }
  }

  // ---- 保存 ----

  void _captureState() {
    final w = _world;
    if (w == null) return;
    final p = w.playerFeet;
    _state = _state.copyWith(
      x: p.x,
      y: math.max(0, p.y),
      z: p.z,
      heading: w.heading,
      cameraYaw: _camYaw,
    );
  }

  void _saveNow() {
    _captureState();
    if (_world != null) _save.saveField(_state);
  }

  Future<void> _reset() async {
    final r = widget.region;
    _state = Field3DState.start(r);
    _world?.teleport(r.spawnX, r.spawnZ, heading: 0);
    _world?.showDefeated(const {});
    _camYaw = 0;
    await _save.saveField(_state);
    _say('草原をはじめからにしました（レベルはそのまま）');
  }

  // ---- 毎フレーム ----

  void _tick(Duration elapsed, double dt) {
    final w = _world;
    if (w == null) return;
    _firstFrame ??= _load.elapsed;
    _measure(dt);

    // 入力（キーボード＋仮想スティック）
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    var ix = _stick.x, iy = -_stick.y;
    if (_talking == null && !_busy) {
      if (keys.contains(LogicalKeyboardKey.keyW) ||
          keys.contains(LogicalKeyboardKey.arrowUp)) {
        iy += 1;
      }
      if (keys.contains(LogicalKeyboardKey.keyS) ||
          keys.contains(LogicalKeyboardKey.arrowDown)) {
        iy -= 1;
      }
      if (keys.contains(LogicalKeyboardKey.keyD) ||
          keys.contains(LogicalKeyboardKey.arrowRight)) {
        ix += 1;
      }
      if (keys.contains(LogicalKeyboardKey.keyA) ||
          keys.contains(LogicalKeyboardKey.arrowLeft)) {
        ix -= 1;
      }
      if (keys.contains(LogicalKeyboardKey.keyQ)) _camYaw -= 1.8 * dt;
      if (keys.contains(LogicalKeyboardKey.keyE) && _nearNpc == null) {
        _camYaw += 1.8 * dt;
      }
    } else {
      ix = 0;
      iy = 0;
    }
    final run =
        keys.contains(LogicalKeyboardKey.shiftLeft) || _stick.length > 0.95;
    w.setMoveInput(ix, iy, cameraYaw: _camYaw, run: run);

    // 敵に触れたか
    if (!_busy && _talking == null) {
      final p = w.playerFeet;
      final e = widget.region.touchedEnemy(p.x, p.z, _state.defeated);
      if (e != null) unawaited(_battle(e));
    }

    // ときどき保存・表示の更新
    _sinceSave += dt;
    if (_sinceSave > 3) {
      _sinceSave = 0;
      _saveNow();
    }
    _sinceHud += dt;
    if (_sinceHud > 0.5) {
      _sinceHud = 0;
      _memoryMb = Field3DMemory.usedMb();
      if (mounted) setState(() {});
    }
  }

  void _measure(double dt) {
    if (dt <= 0) return;
    _frameTimes.add(dt * 1000);
    if (_frameTimes.length > 120) _frameTimes.removeAt(0);
    final sum = _frameTimes.fold<double>(0, (a, b) => a + b);
    _avgMs = sum / _frameTimes.length;
    _fps = 1000 / _avgMs;
    _worstMs = _frameTimes.fold<double>(0, math.max);
  }

  PerspectiveCamera _camera(Duration elapsed) {
    final w = _world!;
    final target = w.playerFeet + vm.Vector3(0, 1.1, 0);
    final dir = vm.Vector3(
      math.sin(_camYaw) * math.cos(_camPitch),
      -math.sin(_camPitch),
      math.cos(_camYaw) * math.cos(_camPitch),
    );
    // 木や岩にカメラが埋まらないように、間に物があれば近づける
    final dist = w.cameraDistance(target, -dir, _camDist);
    var eye = target - dir * dist;
    if (eye.y < 0.3) eye = vm.Vector3(eye.x, 0.3, eye.z);
    return PerspectiveCamera(position: eye, target: target);
  }

  // ---- NPC ----

  Npc3D? get _nearNpc {
    final w = _world;
    if (w == null) return null;
    final p = w.playerFeet;
    return widget.region.npcInRange(p.x, p.z);
  }

  void _talk() {
    if (_talking != null) {
      if (_line + 1 < _talking!.lines.length) {
        setState(() => _line++);
      } else {
        setState(() => _talking = null);
      }
      return;
    }
    final n = _nearNpc;
    if (n == null || _busy) return;
    _world?.facePoint(n.x, n.z);
    setState(() {
      _talking = n;
      _line = 0;
      _state = _state.copyWith(talked: {..._state.talked, n.id});
      _world?.markTalked(n.id);
    });
    _saveNow();
  }

  // ---- バトル ----

  Future<void> _battle(Enemy3D e) async {
    _busy = true;
    _saveNow();
    final world = RpgCatalog.world(e.worldId);
    final stage = world.stages.firstWhere((s) => s.id == e.stageId);
    final questions = await Questions3D.forStage(stage);
    if (!mounted) return;
    if (questions == null) {
      _say('このスライムの問題はまだ用意できていません');
      _retreat(e);
      _busy = false;
      return;
    }
    _world?.setMoveInput(0, 0, cameraYaw: _camYaw, run: false);
    final result = await Navigator.of(context).push(
      MaterialPageRoute<Battle3DResult>(
        builder: (_) => Battle3DScreen(
          save: _save,
          world: world,
          stage: stage,
          questions: questions,
          enemyLabel: _enemyName(e),
          color: Field3DWorld.enemyColor(e.worldId),
        ),
      ),
    );
    if (!mounted) return;
    // 戦い終わったら、元の場所から再開する（シーンは画面が持ち続けている）
    if (result?.won ?? false) {
      _state = _state.copyWith(defeated: {..._state.defeated, e.id});
      _world?.showDefeated(_state.defeated);
      final exp = result!.clear?.expResult;
      _say(
        exp != null && exp.leveledUp
            ? '${_enemyName(e)}をたおした！ Lv${exp.after.level} にあがった！'
            : '${_enemyName(e)}をたおした！',
      );
    } else {
      _retreat(e);
      _say('いったん はなれて立て直そう');
    }
    _saveNow();
    _busy = false;
    _focus.requestFocus();
  }

  void _retreat(Enemy3D e) {
    final p = _world!.playerFeet;
    final (x, z) = widget.region.retreatFrom(e, p.x, p.z);
    _world!.teleport(x, z);
  }

  String _enemyName(Enemy3D e) => switch (e.worldId) {
    'english' => '英語スライム',
    'math' => '数学スライム',
    'social' => '社会スライム',
    _ => 'スライム',
  };

  void _say(String text) {
    setState(() => _toast = text);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && _toast == text) setState(() => _toast = null);
    });
  }

  // ---- 入力（マウス・タッチ） ----

  bool _isJoystickArea(Offset p, Size size) =>
      p.dx < size.width * 0.45 && p.dy > size.height * 0.45;

  void _pointerDown(PointerDownEvent e, Size size) {
    _focus.requestFocus();
    if (e.kind == PointerDeviceKind.mouse) {
      _mouseDragging = true;
    } else if (!_isJoystickArea(e.localPosition, size)) {
      _touchCamera[e.pointer] = e.localPosition;
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    final drag = _mouseDragging || _touchCamera.containsKey(e.pointer);
    if (!drag) return;
    _camYaw += e.delta.dx * 0.008;
    _camPitch = (_camPitch + e.delta.dy * 0.006).clamp(0.08, 1.25);
  }

  void _pointerUp(PointerEvent e) {
    if (e.kind == PointerDeviceKind.mouse) _mouseDragging = false;
    _touchCamera.remove(e.pointer);
  }

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.space ||
        k == LogicalKeyboardKey.enter ||
        (k == LogicalKeyboardKey.keyE &&
            (_nearNpc != null || _talking != null))) {
      _talk();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---- 画面 ----

  @override
  Widget build(BuildContext context) {
    final w = _world;
    return Scaffold(
      backgroundColor: const Color(0xFF9CC7EE),
      body: _error != null
          ? _ErrorView(message: _error!)
          : w == null
          ? const _Loading()
          : LayoutBuilder(
              builder: (context, c) {
                final size = c.biggest;
                return Focus(
                  focusNode: _focus,
                  autofocus: true,
                  onKeyEvent: _key,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Listener(
                          onPointerDown: (e) => _pointerDown(e, size),
                          onPointerMove: _pointerMove,
                          onPointerUp: _pointerUp,
                          onPointerCancel: _pointerUp,
                          onPointerSignal: (e) {
                            if (e is PointerScrollEvent) {
                              _camDist = (_camDist + e.scrollDelta.dy * 0.01)
                                  .clamp(3.0, 12.0);
                            }
                          },
                          child: SceneView(
                            w.scene,
                            cameraBuilder: _camera,
                            onTick: _tick,
                          ),
                        ),
                      ),
                      _hud(context),
                      if (!_touchFree) _touchControls(),
                      if (_talking != null) _dialog(),
                      if (_toast != null) _toastView(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// PC（マウスあり）では仮想スティックを出さない。Web のスマホは出す
  bool get _touchFree {
    final platform = Theme.of(context).platform;
    final desktop =
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
    return desktop;
  }

  Widget _hud(BuildContext context) {
    final near = _nearNpc;
    final mem = _memoryMb;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _chip(
                    IconButton(
                      key: const ValueKey('field3d-back'),
                      tooltip: 'もどる',
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _chip(
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Lv${_save.loadProgress().level}　${widget.region.name}　たおした ${_state.defeated.length}/${widget.region.enemies.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _chip(
                    PopupMenuButton<String>(
                      key: const ValueKey('field3d-menu'),
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (v) {
                        if (v == 'reset') _reset();
                        if (v == 'credits') _credits();
                        if (v.startsWith('q:')) _setQuality(v.substring(2));
                      },
                      itemBuilder: (_) => [
                        for (final q in ['high', 'standard', 'light'])
                          CheckedPopupMenuItem(
                            value: 'q:$q',
                            checked: _quality == q,
                            child: Text('画質：${_qualityName(q)}'),
                          ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'reset',
                          child: Text('この試作をはじめから'),
                        ),
                        PopupMenuItem(
                          value: 'credits',
                          child: Text('素材のクレジット'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 計測（試作なので常に出す）
            Align(
              alignment: Alignment.topRight,
              child: _chip(
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    key: const ValueKey('field3d-stats'),
                    '${_fps.toStringAsFixed(0)} fps　平均 ${_avgMs.toStringAsFixed(1)}ms　最大 ${_worstMs.toStringAsFixed(0)}ms\n'
                    '初回表示 ${_firstFrame == null ? '-' : '${(_firstFrame!.inMilliseconds / 1000).toStringAsFixed(1)}秒'}'
                    '　メモリ ${mem == null ? '-' : '${mem}MB'}${kIsWeb ? '（JS）' : ''}'
                    '\n画質 ${_qualityName(_quality)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            if (_touchFree)
              Align(
                alignment: Alignment.bottomLeft,
                child: _chip(
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'WASD/矢印：移動　Shift：走る　ドラッグ・Q/E：カメラ　ホイール：距離\nSpace/E：はなす　Esc：もどる',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            if (near != null && _talking == null)
              Align(
                alignment: const Alignment(0, 0.55),
                child: FilledButton.icon(
                  key: const ValueKey('field3d-talk'),
                  onPressed: _talk,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('${near.name}と はなす'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _touchControls() => Positioned(
    left: 24,
    bottom: 24,
    child: SafeArea(
      child: VirtualJoystick(radius: 64, onChanged: (d) => _stick = d),
    ),
  );

  Widget _dialog() {
    final n = _talking!;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SafeArea(
        child: GestureDetector(
          onTap: _talk,
          child: Container(
            key: const ValueKey('field3d-dialog'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xEE1E2A3A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white70),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  n.name,
                  style: const TextStyle(
                    color: Color(0xFFFFE08A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  n.lines[_line],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _line + 1 < n.lines.length ? '▼ タップ / Space' : '× とじる',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toastView() => Align(
    alignment: const Alignment(0, -0.6),
    child: _chip(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(_toast!, style: const TextStyle(color: Colors.white)),
      ),
    ),
  );

  Widget _chip(Widget child) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0x99000000),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  void _credits() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('素材のクレジット'),
      content: const SingleChildScrollView(
        child: Text(
          'キツネのモデル「Fox」（Khronos glTF Sample Assets）\n'
          '・モデル：PixelMannen（CC0 1.0）\n'
          '・リグとアニメーション：tomkranis（CC BY 4.0）\n'
          '・glTF への変換：@AsoboStudio・@scurest（CC BY 4.0）\n\n'
          '3D 描画：flutter_scene（MIT）\n物理：Rapier（flutter_scene_rapier、MIT）',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('とじる')),
      ],
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('3D の草原を準備しています…'),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '3D フィールドを開けませんでした',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('もどる'),
          ),
        ],
      ),
    ),
  );
}
