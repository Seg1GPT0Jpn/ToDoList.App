import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'practice_view.dart';

/// 定期テストの海：1単元・1単語帳の練習
class SeaQuizScreen extends StatefulWidget {
  const SeaQuizScreen({
    super.key,
    required this.title,
    required this.recordId,
    required this.questions,
    this.count,
  });

  final String title;

  /// 最高正答率を記録するキー
  final String recordId;
  final List<QuizQuestion> questions;
  final int? count;

  @override
  State<SeaQuizScreen> createState() => _SeaQuizScreenState();
}

class _SeaQuizScreenState extends State<SeaQuizScreen> {
  late PracticeSession _session = _newSession(widget.questions);
  bool _done = false;
  int? _prevBest;

  PracticeSession _newSession(List<QuizQuestion> qs) =>
      PracticeSession(qs, count: widget.count);

  Future<void> _finish() async {
    final repo = RpgServices.of(context).repository;
    final p = await repo.load();
    _prevBest = p.seaBest[widget.recordId];
    await repo.save(
      Progression.recordSea(p, widget.recordId, _session.percent),
    );
    if (mounted) setState(() => _done = true);
  }

  void _restart(List<QuizQuestion> qs) => setState(() {
    _session = _newSession(qs);
    _done = false;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TsuzuriColors.paper,
        title: Text(widget.title, style: serif(17)),
      ),
      body: NotebookPaper(
        child: SafeArea(
          top: false,
          child: _done
              ? PracticeSummary(
                  session: _session,
                  extra: [
                    if (_prevBest == null || _session.percent > _prevBest!)
                      const Center(
                        child: Text(
                          '自己ベスト更新！',
                          style: TextStyle(
                            color: Color(0xFFB8860B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          '自己ベスト ${_prevBest!}%',
                          style: const TextStyle(color: TsuzuriColors.inkSoft),
                        ),
                      ),
                  ],
                  actions: [
                    if (_session.missed.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => _restart(_session.missed),
                        icon: const Icon(Icons.replay),
                        label: const Text('間違えた問題だけもう一度'),
                      ),
                    OutlinedButton(
                      onPressed: () => _restart(widget.questions),
                      child: const Text('もう一度（問題を入れかえて）'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('一覧にもどる'),
                    ),
                  ],
                )
              : PracticeView(
                  key: ObjectKey(_session),
                  session: _session,
                  onFinished: _finish,
                ),
        ),
      ),
    );
  }
}
