import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../account/account_screen.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../app/usage_meter.dart';
import '../art/paper.dart';
import 'matchmaking.dart';
import 'online_room.dart';
import 'random_matcher.dart';
import 'versus_screen.dart';

class RandomMatchText {
  const RandomMatchText._();

  static const title = 'ランダム対戦';
  static const intro =
      'いま対戦したい人をさがして、全教科の早押しクイズで対戦します（10問）。'
      '20秒たってもだれもいなければ、ほかの人の記録（ゴースト）と対戦します。';
  static const safety =
      '相手に見えるのはニックネームと対戦の様子だけ。送れるのは決まったスタンプだけで、文字は送れません。'
      'いやな相手は、対戦のあとで報告・ブロックできます。';
  static const noBackend = 'この版では、ランダム対戦は使えません（サーバーの設定がありません）';
  static const needLogin = 'ランダム対戦は、Google でログインすると遊べます';
}

/// ブロックした人（この端末の中だけ）
class BlockedPlayers {
  const BlockedPlayers._();

  static const _key = 'blocked_players';

  static Future<Set<String>> load() async => {
    ...?(await SharedPreferences.getInstance()).getStringList(_key),
  };

  static Future<void> add(String uid) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, {...?p.getStringList(_key), uid}.toList());
  }
}

/// ランダム対戦の出題：全教科から、各教科2エリアぶん
VersusRoomConfig randomMatchConfig([Random? random]) {
  final r = random ?? Random();
  final setIds = <String>[];
  for (final w in RpgCatalog.worlds) {
    if (w.isComingSoon) continue;
    final stages = [...w.stages.where((s) => !s.isBoss)]..shuffle(r);
    setIds.addAll(stages.take(2).map((s) => s.questionSetIds.first));
  }
  return VersusRoomConfig(setIds: setIds, seed: r.nextInt(1 << 30), rounds: 10);
}

class RandomMatchScreen extends StatefulWidget {
  const RandomMatchScreen({
    super.key,
    this.queue,
    this.rooms,
    this.wait = const Duration(seconds: 20),
  });

  /// テスト用（ふだんは RpgServices から）
  final MatchmakingBackend? queue;
  final VersusRoomBackend? rooms;
  final Duration wait;

  @override
  State<RandomMatchScreen> createState() => _RandomMatchScreenState();
}

class _RandomMatchScreenState extends State<RandomMatchScreen> {
  final _name = TextEditingController();
  RandomMatcher? _matcher;
  Timer? _clock;
  String? _error;

  MatchmakingBackend? get _queue =>
      widget.queue ?? RpgServices.of(context).matchmaking;
  VersusRoomBackend? get _rooms =>
      widget.rooms ?? RpgServices.of(context).versusRooms;

  @override
  void initState() {
    super.initState();
    UsageMeter.mark(context, 'versus');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_name.text.isEmpty) {
      _name.text = RpgServices.of(context).classroomStore.nickname;
    }
  }

  @override
  void dispose() {
    _matcher?.cancel();
    _clock?.cancel();
    _name.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final queue = _queue!, rooms = _rooms!;
    final services = RpgServices.of(context);
    final name = Classroom.cleanName(_name.text, fallback: 'なまえ');
    await services.classroomStore.setNickname(name);
    final matcher = RandomMatcher(
      queue: queue,
      rooms: rooms,
      name: name,
      newConfig: randomMatchConfig,
      blocked: await BlockedPlayers.load(),
      wait: widget.wait,
    );
    setState(() {
      _matcher = matcher;
      _error = null;
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    MatchResult? result;
    try {
      result = await matcher.run();
    } catch (e) {
      if (mounted) setState(() => _error = 'さがせませんでした：$e');
    }
    _clock?.cancel();
    if (!mounted) return;
    setState(() => _matcher = null);
    switch (result) {
      case FoundPlayer(:final room, :final side, :final opponentId):
        await _playPerson(room, side, opponentId, name);
      case FoundGhost(:final ghost):
        await _playGhost(ghost, name);
      case null:
        break;
    }
  }

  void _cancel() {
    _matcher?.cancel();
    _clock?.cancel();
    setState(() => _matcher = null);
  }

  /// 自分の答え方をゴーストとして残す（最後まで遊んだときだけ）
  void _saveGhost(VersusMatch m, int side, String name, VersusRoomConfig c) {
    if (!m.isOver) return;
    final run = GhostRun.fromMatch(
      m,
      side: side,
      name: name,
      setIds: c.setIds,
      seed: c.seed,
    );
    if (run.usable) unawaited(_queue?.saveGhost(run).catchError((_) {}));
  }

  Future<void> _playPerson(
    OnlineRoom room,
    int side,
    String? opponentId,
    String name,
  ) async {
    final services = RpgServices.of(context);
    final questions = await loadVersusQuestions(services, room.config.setIds);
    if (!mounted) return;
    if (questions.isEmpty) {
      setState(() => _error = '問題を読みこめませんでした');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VersusScreen(
          questions: questions,
          names: [room.hostName, room.guestName ?? 'あいて'],
          rounds: room.config.rounds,
          online: OnlineLink(
            backend: _rooms!,
            code: room.code,
            localSide: side,
            seed: room.config.seed,
          ),
          onFinished: (m) => _saveGhost(m, side, name, room.config),
          resultExtra: opponentId == null
              ? null
              : (_) => _ReportBlock(uid: opponentId, queue: _queue!),
        ),
      ),
    );
  }

  Future<void> _playGhost(GhostRun ghost, String name) async {
    final services = RpgServices.of(context);
    var questions = await loadVersusQuestions(services, ghost.setIds);
    var g = ghost;
    if (questions.isEmpty) {
      // 古い版のゴーストで問題が読めなければ、CPU のゴーストにする
      g = RandomMatcher.cpuGhost(randomMatchConfig(), Random());
      questions = await loadVersusQuestions(services, g.setIds);
    }
    if (!mounted || questions.isEmpty) return;
    final config = VersusRoomConfig(
      setIds: g.setIds,
      seed: g.seed,
      rounds: g.rounds,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VersusScreen(
          questions: questions,
          names: [name, g.name == 'CPU' ? 'CPU（ゴースト）' : '${g.name}のゴースト'],
          rounds: g.rounds,
          ghost: g,
          onFinished: (m) => _saveGhost(m, 0, name, config),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = _queue, rooms = _rooms;
    final matcher = _matcher;
    return Scaffold(
      appBar: AppBar(title: Text(RandomMatchText.title, style: serif(18))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
          children: [
            const Text(RandomMatchText.intro, style: TextStyle(height: 1.6)),
            const SizedBox(height: 6),
            Text(
              RandomMatchText.safety,
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 16),
            if (queue == null || rooms == null)
              const Text(RandomMatchText.noBackend)
            else if (queue.userId == null) ...[
              const Text(RandomMatchText.needLogin),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('random-login'),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountScreen(),
                    ),
                  );
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.login),
                label: const Text('ログインする'),
              ),
            ] else if (matcher != null)
              Card(
                key: const ValueKey('random-searching'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('対戦相手をさがしています…', style: serif(17)),
                      const SizedBox(height: 8),
                      Text('${matcher.elapsedSeconds}秒'),
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        key: const ValueKey('random-cancel'),
                        onPressed: _cancel,
                        child: const Text('やめる'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              TextField(
                key: const ValueKey('random-name'),
                controller: _name,
                maxLength: Classroom.maxName,
                decoration: const InputDecoration(
                  labelText: 'ニックネーム（相手に見えます）',
                  isDense: true,
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('random-search'),
                onPressed: _search,
                icon: const Icon(Icons.travel_explore),
                label: const Text('対戦相手をさがす'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 対戦のあとの、報告・ブロック
class _ReportBlock extends StatefulWidget {
  const _ReportBlock({required this.uid, required this.queue});
  final String uid;
  final MatchmakingBackend queue;

  @override
  State<_ReportBlock> createState() => _ReportBlockState();
}

class _ReportBlockState extends State<_ReportBlock> {
  String? _done;

  Future<void> _report() async {
    final reason = await showDialog<PlayerReportReason>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('この人を報告する'),
        children: [
          for (final r in PlayerReportReason.values)
            SimpleDialogOption(
              key: ValueKey('report-${r.name}'),
              onPressed: () => Navigator.of(context).pop(r),
              child: Text(r.label),
            ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await widget.queue.report(widget.uid, reason);
    } catch (_) {
      // 送れなくても、ブロックはする
    }
    await BlockedPlayers.add(widget.uid);
    if (mounted) setState(() => _done = '報告しました。この人とはもう対戦しません');
  }

  Future<void> _block() async {
    await BlockedPlayers.add(widget.uid);
    if (mounted) setState(() => _done = 'ブロックしました。この人とはもう対戦しません');
  }

  @override
  Widget build(BuildContext context) {
    if (_done != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_done!, style: const TextStyle(fontSize: 12)),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          key: const ValueKey('versus-block'),
          onPressed: _block,
          child: const Text('ブロック'),
        ),
        TextButton(
          key: const ValueKey('versus-report'),
          onPressed: _report,
          child: const Text('報告'),
        ),
      ],
    );
  }
}
