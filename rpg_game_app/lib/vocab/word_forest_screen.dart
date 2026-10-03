import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/enemy_painter.dart';
import '../art/paper.dart';
import '../battle/battle_screen.dart';
import '../meta/design.dart';

/// 単語の森で最初に読む単語リスト（すべて自作）
const wordForestLists = ['words_j1', 'words_j2', 'words_j3', 'idioms_j'];


Future<WordList> loadWordList(String id) async {
  // バイト列を読んでその場で文字に直す（loadString は大きいファイルを
  // 別の isolate で直すうえ、結果を覚えておくので使わない）
  final data = await rootBundle.load('packages/rpg_game/assets/words/$id.json');
  final raw = utf8.decode(data.buffer.asUint8List());
  return WordList.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// 単語の森：単語のモンスターと戦って覚える。忘れかけの単語は忘却の塔へ。
/// 覚えた単語（★2以上）はコレクションに入る。
class WordForestScreen extends StatefulWidget {
  const WordForestScreen({super.key});

  @override
  State<WordForestScreen> createState() => _WordForestScreenState();
}

class _WordForestScreenState extends State<WordForestScreen> {
  final Map<String, WordList> _lists = {};
  String _selected = wordForestLists.first;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      for (final id in wordForestLists) {
        _lists[id] = await loadWordList(id);
      }
    } catch (e) {
      _error = '単語リストを読み込めませんでした';
    }
    if (mounted) setState(() {});
  }

  Future<void> _battle(WordList list, {required bool tower}) async {
    final services = RpgServices.of(context);
    final record = services.meta.record;
    final today = RpgServices.today();
    final words = WordBattle.nextWords(list, record, today, reviewOnly: tower);
    if (words.isEmpty) return;
    final questions = [
      for (final w in words) ...WordBattle.questionsFor(list, w),
    ];
    // 学習記録に残るよう、作った問題をセットとして登録する（自作の単語だけ）
    services.questions.adopt(
      QuestionSet(
        setId: WordBattle.setId(list),
        worldId: 'english',
        origin: list.origin,
        version: 1,
        questions: [
          for (final w in list.words) ...WordBattle.questionsFor(list, w),
        ],
      ),
    );
    final progress = await services.repository.load();
    if (!mounted || questions.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BattleScreen(
          world: RpgCatalog.world(RpgCatalog.englishWorldId),
          stage: WordBattle.stage(list, words, progress.level, tower: tower),
          questions: questions,
          progress: progress,
          trial: true,
          mode: BattleMode.review,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final list = _lists[_selected];
    return Scaffold(
      appBar: AppBar(title: Text('単語の森', style: serif(18))),
      body: NotebookPaper(
        child: _error != null
            ? Center(child: Text(_error!))
            : list == null
            ? const Center(child: CircularProgressIndicator())
            : ListenableBuilder(
                listenable: services.meta,
                builder: (context, _) {
                  final today = RpgServices.today();
                  final memories = [
                    for (final w in list.words)
                      WordBattle.memoryOf(list, w, services.meta.record, today),
                  ];
                  final collected = memories.where((m) => m.collected).length;
                  final fading = memories.where((m) => m.fading).length;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Space.margin,
                      Space.m,
                      Space.l,
                      Space.xl,
                    ),
                    children: [
                      Wrap(
                        spacing: Space.s,
                        runSpacing: Space.xs,
                        children: [
                          for (final id in wordForestLists)
                            if (_lists[id] case final l?)
                              ChoiceChip(
                                key: ValueKey('wordlist-$id'),
                                label: Text(l.title),
                                selected: id == _selected,
                                onSelected: (_) =>
                                    setState(() => _selected = id),
                              ),
                        ],
                      ),
                      const SizedBox(height: Space.m),
                      PaperCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(list.title, style: serif(17)),
                            const SizedBox(height: 4),
                            Text(
                              '単語が魔物になって5体ずつ現れる。英→日・日→英・スペル・発音の'
                              'いろいろな形で問われ、正解すると攻撃！ まちがえた単語は'
                              '「忘却の塔」で、間をあけてもう一度出てくる。',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.6,
                                color: TsuzuriColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: Space.s),
                            Text(
                              'コレクション $collected / ${list.words.length}語'
                              '${fading > 0 ? '・忘れかけ $fading語' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: Space.s),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    key: const ValueKey('forest-battle'),
                                    onPressed: () =>
                                        _battle(list, tower: false),
                                    icon: const Icon(Icons.forest),
                                    label: const Text('森で戦う'),
                                  ),
                                ),
                                const SizedBox(width: Space.s),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: const ValueKey('forest-tower'),
                                    onPressed: fading == 0
                                        ? null
                                        : () => _battle(list, tower: true),
                                    icon: const Icon(Icons.castle_outlined),
                                    label: Text(
                                      fading == 0 ? '忘却の塔' : '忘却の塔（$fading）',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.m),
                      const SectionTitle('単語コレクション'),
                      Text(
                        '★1：正答率60%以上　★2：3つ以上の形で正解　★3：間をあけて正解し続けている',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: TsuzuriColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: Space.s),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final m in memories) _WordChip(memory: m),
                        ],
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.memory});

  final WordMemory memory;

  @override
  Widget build(BuildContext context) {
    final m = memory;
    final met = m.attempts > 0;
    final color = m.fading
        ? TsuzuriColors.wrong
        : m.collected
        ? TsuzuriColors.exp
        : TsuzuriColors.accent;
    return Tooltip(
      message: met
          ? '${m.word.term}：${m.word.shortMeaning}\n正答率${m.accuracy}%・'
                '${m.formatsCleared.map((f) => f.label).join('・')}'
          : 'まだ出会っていない単語',
      child: Container(
        key: ValueKey('word-${m.word.term}'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: met ? color.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(
            color: met ? color : TsuzuriColors.inkSoft.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (met)
              SizedBox(
                width: 18,
                height: 18,
                child: CustomPaint(painter: _MiniMonster(m.word)),
              ),
            Text(
              met ? m.word.term : '？？？',
              style: TextStyle(
                fontSize: 13,
                color: met ? null : TsuzuriColors.inkSoft,
              ),
            ),
            if (met) ...[
              const SizedBox(width: 4),
              Text(
                '★' * m.stars + '☆' * (3 - m.stars),
                style: TextStyle(fontSize: 10, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniMonster extends CustomPainter {
  _MiniMonster(this.word);
  final WordEntry word;

  @override
  void paint(Canvas canvas, Size size) {
    final e = WordBattle.monster(word, 1, 1);
    paintEnemy(canvas, size.shortestSide, e.look, 0);
  }

  @override
  bool shouldRepaint(_MiniMonster old) => old.word.term != word.term;
}
