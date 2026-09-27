import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../account/account_screen.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'online_room.dart';
import 'versus_screen.dart';

/// オンライン対戦の入口：部屋をつくる・部屋に入る
class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({
    super.key,
    required this.name,
    required this.setIds,
    required this.rounds,
    this.backend,
  });

  /// 自分の名前
  final String name;

  /// 部屋をつくるときの出題（問題セット）
  final List<String> setIds;
  final int rounds;

  /// テスト用（ふだんは RpgServices.versusRooms）
  final VersusRoomBackend? backend;

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  /// 自分がつくって、相手を待っている部屋
  String? _waiting;
  StreamSubscription<OnlineRoom?>? _sub;

  VersusRoomBackend? get _backend =>
      widget.backend ?? RpgServices.of(context).versusRooms;

  @override
  void dispose() {
    _sub?.cancel();
    final code = _waiting;
    if (code != null) _backend?.close(code);
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final backend = _backend!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final config = VersusRoomConfig(
        setIds: widget.setIds,
        seed: Random().nextInt(1 << 30),
        rounds: widget.rounds,
      );
      final code = await backend.create(config, widget.name);
      if (!mounted) return;
      setState(() => _waiting = code);
      _sub = backend.watch(code).listen((room) {
        if (room != null && room.full && mounted) _begin(room, 0);
      });
    } on RoomException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '部屋を作れませんでした（$e）');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final backend = _backend!;
    final code = _code.text.trim();
    if (code.length != 4) {
      setState(() => _error = '4けたの部屋番号を入れてください');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final room = await backend.join(code, widget.name);
      if (!mounted) return;
      await _begin(room, 1);
    } on RoomException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '部屋に入れませんでした（$e）');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _started = false;

  /// 2人そろったら、対戦をはじめる
  Future<void> _begin(OnlineRoom room, int side) async {
    if (_started) return;
    _started = true;
    final services = RpgServices.of(context);
    final backend = _backend!;
    await _sub?.cancel();
    _sub = null;
    final questions = await loadVersusQuestions(services, room.config.setIds);
    if (!mounted) return;
    if (questions.isEmpty) {
      setState(() => _error = '問題を読みこめませんでした');
      return;
    }
    // 対戦の画面にうつったら、部屋を閉じるのは対戦の画面にまかせる
    _waiting = null;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VersusScreen(
          questions: questions,
          names: [room.hostName, room.guestName ?? 'ゲスト'],
          rounds: room.config.rounds,
          online: OnlineLink(
            backend: backend,
            code: room.code,
            localSide: side,
            seed: room.config.seed,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final backend = _backend;
    return Scaffold(
      appBar: AppBar(title: Text('オンライン対戦', style: serif(18))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
          children: [
            if (backend == null)
              const _Notice(
                'この端末では Firebase が設定されていないため、オンライン対戦は使えません。'
                '「CPU」か「この端末で2人」で遊んでください。',
              )
            else if (backend.userId == null) ...[
              const _Notice(
                'オンライン対戦は、Google でログインすると遊べます。'
                'アカウントの画面からログインしてから、もう一度来てください。',
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountScreen(),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: const Text('アカウントの画面へ'),
              ),
            ] else if (_waiting != null)
              _waitingCard(_waiting!)
            else ...[
              Text('部屋をつくる', style: serif(16)),
              const SizedBox(height: 4),
              Text(
                '${widget.rounds}問・${widget.setIds.length}エリアぶんの問題で対戦します。'
                '部屋番号を相手に伝えてください。',
                style: const TextStyle(fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.add_home_outlined),
                label: const Text('部屋をつくる'),
              ),
              const SizedBox(height: 24),
              Text('部屋に入る', style: serif(16)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '部屋番号（4けた）',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _busy ? null : _join,
                    child: const Text('入る'),
                  ),
                ],
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: TsuzuriColors.wrong),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _waitingCard(String code) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('部屋番号'),
          Text(code, style: serif(44, color: TsuzuriColors.stamp)),
          const SizedBox(height: 8),
          const Text('相手がこの番号で入るのを待っています…'),
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF8E1),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Text(text, style: const TextStyle(height: 1.6)),
    ),
  );
}
