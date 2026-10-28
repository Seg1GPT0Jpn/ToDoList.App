import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/theme.dart';

/// はじめのころのバトルで、1つずつ出す「バトルの心得」。
///
/// 1回のバトルで出すのは1つだけ。読み終えるまで1問目は始まらない（時間はへらない）。
enum BattleTip {
  answer(
    '⚔️ バトルの基本',
    '正しい答えをタップすると攻撃！\n'
        'まちがえたり時間切れになったりすると、敵の反撃を受けます。\n'
        '敵のHPを0にすれば勝ち。はやく答えるほど会心の一撃が出やすくなります。',
  ),
  cards(
    '🃏 カードを使ってみよう',
    '下に並ぶカードは、答える前にタップすると、その問題に効果がつきます。\n'
        '「強打の構文」は正解でダメージ2倍、「守りの辞書」はまちがえてもダメージなし。\n'
        '使ったカードは、山札からまた補充されます。',
  ),
  weakness(
    '🎯 弱点をねらおう',
    '画面の上に出ている「弱点」の種類の問題に正解すると、ダメージが1.5倍になります。\n'
        '3問続けて正解すると「チェイン」でさらに強くなります。',
  ),
  confidence(
    '🎲 自信ベット',
    'カードの右の「ふつう」をタップすると、「自信あり」「あやふや」に切りかわります。\n'
        '自信ありは当たると強く、外すと痛い。あやふやは控えめ。迷ったら「ふつう」のままで大丈夫です。',
  );

  const BattleTip(this.title, this.body);

  final String title;
  final String body;
}

/// 読んだ心得（端末ごと）
class BattleTipStore {
  BattleTipStore(this._prefs);

  static const key = 'battle_tips_seen_v1';
  final SharedPreferences _prefs;

  Set<String> get _seen => {...?_prefs.getStringList(key)};

  bool seen(BattleTip t) => _seen.contains(t.name);

  Future<void> markSeen(BattleTip t) =>
      _prefs.setStringList(key, {..._seen, t.name}.toList());

  /// このバトルで出す心得。[basic] は、はじめてのバトル（カードやベットはまだ出さない）
  BattleTip? pick({required bool basic, required bool hasWeakness}) {
    for (final t in BattleTip.values) {
      if (seen(t)) continue;
      final ok = switch (t) {
        BattleTip.answer => true,
        BattleTip.cards => !basic,
        BattleTip.weakness => !basic && hasWeakness,
        BattleTip.confidence => !basic,
      };
      if (ok) return t;
    }
    return null;
  }
}

/// 心得のカード（画面の中央に出す）
class BattleTipCard extends StatelessWidget {
  const BattleTipCard({super.key, required this.tip, required this.onOk});

  final BattleTip tip;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black.withValues(alpha: 0.35),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          key: ValueKey('battle-tip-${tip.name}'),
          color: TsuzuriColors.card,
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title, style: serif(18)),
                const SizedBox(height: 10),
                Text(
                  tip.body,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: const ValueKey('battle-tip-ok'),
                    onPressed: onOk,
                    child: const Text('わかった！'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
