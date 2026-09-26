import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';

/// デッキ（バトルで引くカード）と仲間の一覧
class DeckScreen extends StatelessWidget {
  const DeckScreen({super.key, required this.progress});

  final RpgProgress progress;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final id in progress.deck) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(title: Text('デッキと仲間', style: serif(18))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
          children: [
            Text('デッキ（${progress.deck.length}枚）', style: serif(16)),
            const SizedBox(height: 4),
            const Text(
              'バトルでは3枚を手札に持つ。回答の前にタップすると、その問題に効果がつく（1問に1枚）。'
              '使ったカードは山札に戻って、また引ける。',
              style: TextStyle(
                fontSize: 12.5,
                color: TsuzuriColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final card in CardDef.all)
              if (counts[card.id] != null)
                _tile(
                  icon: Icons.style,
                  color: card.rarity == CardRarity.rare
                      ? const Color(0xFF6A4BA8)
                      : TsuzuriColors.accent,
                  title: '${card.name} ×${counts[card.id]}',
                  body: card.description,
                  badge: card.rarity == CardRarity.rare ? 'レア' : null,
                ),
            const SizedBox(height: 8),
            const Text(
              'カードはステージの初回クリアや、フィールドの宝箱（難問に正解）で増える。',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 20),
            Text(
              '仲間（${progress.companions.length}/${CompanionDef.all.length}）',
              style: serif(16),
            ),
            const SizedBox(height: 4),
            const Text(
              'ボスに負けると、仲間になるはずの子が檻に捕まってしまう。リベンジして勝てば助け出せて、ずっと力を貸してくれる。',
              style: TextStyle(
                fontSize: 12.5,
                color: TsuzuriColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final c in CompanionDef.all)
              progress.companions.contains(c.id)
                  ? _tile(
                      icon: Icons.favorite,
                      color: const Color(0xFFD64545),
                      title: c.name,
                      body: c.description,
                    )
                  : _tile(
                      icon: Icons.lock_outline,
                      color: TsuzuriColors.inkSoft,
                      title: '？？？',
                      body: 'まだ出会っていない',
                    ),
            if (progress.springBuff) ...[
              const SizedBox(height: 20),
              _tile(
                icon: Icons.water_drop,
                color: const Color(0xFF3B8FB5),
                title: '泉の加護',
                body: '次のバトルで最大HP +30%',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    String? badge,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(body),
    ),
  );
}
