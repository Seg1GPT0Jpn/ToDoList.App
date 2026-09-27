import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/practice.dart';
import '../app/theme.dart';
import 'review_tower_screen.dart';

/// 学習ナビゲーター：「今日のあなた」の分析と、今日のおすすめ
class NavigatorCard extends StatelessWidget {
  const NavigatorCard({super.key, required this.record, required this.today});

  final LearningRecord record;
  final int today;

  static Color _color(Signal s) => switch (s) {
    Signal.red => TsuzuriColors.wrong,
    Signal.yellow => TsuzuriColors.exp,
    Signal.green => TsuzuriColors.correct,
    Signal.none => TsuzuriColors.inkSoft,
  };

  @override
  Widget build(BuildContext context) {
    final signals = StudyNavigator.signals(record).take(3).toList();
    final insights = StudyNavigator.insights(record, today: today);
    final recs = StudyNavigator.today(record, today: today);
    if (signals.isEmpty && insights.isEmpty && recs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 今日のあなた（学習ナビ）',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          for (final s in signals)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 10, color: _color(s.signal)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${RpgCatalog.world(s.subject).subject}・${s.field}　正答率 ${s.score}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          for (final t in insights)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: TsuzuriColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ),
          if (recs.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              '今日のおすすめ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            for (final r in recs)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '・${r.text}',
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => r.stage != null
                        ? startPractice(context, r.stage!)
                        : Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ReviewTowerScreen(),
                            ),
                          ),
                    child: Text(r.review ? '塔へ' : '練習'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
