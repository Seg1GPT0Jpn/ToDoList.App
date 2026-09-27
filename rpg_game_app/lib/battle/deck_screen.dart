import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';

/// デッキづくり（持っているカードから 10 枚を選んでバトルに持っていく）と仲間の一覧
class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key, required this.progress});

  final RpgProgress progress;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  late RpgProgress _progress = widget.progress;
  late List<String> _deck = [..._progress.battleDeck];

  Map<String, int> _count(List<String> ids) {
    final m = <String, int>{};
    for (final id in ids) {
      m[id] = (m[id] ?? 0) + 1;
    }
    return m;
  }

  Future<void> _save() async {
    final repo = RpgServices.of(context).repository;
    final latest = await repo.load();
    final updated = latest.copyWith(activeDeck: _deck);
    await repo.save(updated);
    if (!mounted) return;
    setState(() => _progress = updated);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('デッキを保存しました（${_deck.length}枚）')));
  }

  @override
  Widget build(BuildContext context) {
    final owned = _count(_progress.deck);
    final inDeck = _count(_deck);
    final types = _count([for (final id in _deck) CardDef.byId(id).type.name]);
    final dirty = _deck.join(',') != _progress.battleDeck.join(',');
    return Scaffold(
      appBar: AppBar(title: Text('デッキと仲間', style: serif(18))),
      floatingActionButton: dirty
          ? FloatingActionButton.extended(
              onPressed: _deck.isEmpty ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('このデッキで戦う'),
            )
          : null,
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(44, 16, 16, 96),
          children: [
            Text(
              'デッキ（${_deck.length} / ${CardDef.deckSize}枚）',
              style: serif(16),
            ),
            const SizedBox(height: 4),
            Text(
              '持っているカードから10枚まで選んで、バトルに持っていく。'
              'バトルでは3枚を手札に持ち、回答の前にタップするとその問題に効果がつく（1問に1枚）。',
              style: TextStyle(
                fontSize: 12.5,
                color: TsuzuriColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final t in CardType.values)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${t.icon}${t.label} ${types[t.name] ?? 0}'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('おまかせで組む', style: serif(14)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in DeckStyle.values)
                  Tooltip(
                    message: s.description,
                    child: OutlinedButton(
                      onPressed: () => setState(
                        () => _deck = DeckBuilder.preset(_progress.deck, s),
                      ),
                      child: Text(s.label),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (final card in CardDef.all)
              if (owned[card.id] != null)
                _CardRow(
                  card: card,
                  owned: owned[card.id]!,
                  inDeck: inDeck[card.id] ?? 0,
                  onAdd:
                      _deck.length < CardDef.deckSize &&
                          (inDeck[card.id] ?? 0) < owned[card.id]!
                      ? () => setState(() => _deck = [..._deck, card.id])
                      : null,
                  onRemove: (inDeck[card.id] ?? 0) > 0
                      ? () => setState(() {
                          final next = [..._deck];
                          next.remove(card.id);
                          _deck = next;
                        })
                      : null,
                ),
            const SizedBox(height: 8),
            Text(
              'カードは、ステージの初回クリア・強敵・宝箱（知識の封印）・実績・連続学習で増える。'
              'ガチャはない。',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 20),
            Text(
              '仲間（${_progress.companions.length}/${CompanionDef.all.length}）',
              style: serif(16),
            ),
            const SizedBox(height: 4),
            Text(
              'ボスに負けると、仲間になるはずの子が檻に捕まってしまう。リベンジして勝てば助け出せて、ずっと力を貸してくれる。',
              style: TextStyle(
                fontSize: 12.5,
                color: TsuzuriColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            for (final c in CompanionDef.all)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _progress.companions.contains(c.id)
                        ? Icons.favorite
                        : Icons.lock_outline,
                    color: _progress.companions.contains(c.id)
                        ? const Color(0xFFD64545)
                        : TsuzuriColors.inkSoft,
                  ),
                  title: Text(
                    _progress.companions.contains(c.id) ? c.name : '？？？',
                  ),
                  subtitle: Text(
                    _progress.companions.contains(c.id)
                        ? c.description
                        : 'まだ出会っていない',
                  ),
                ),
              ),
            if (_progress.springBuff)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.water_drop, color: Color(0xFF3B8FB5)),
                  title: Text('泉の加護'),
                  subtitle: Text('次のバトルで最大HP +30%'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.owned,
    required this.inDeck,
    required this.onAdd,
    required this.onRemove,
  });

  final CardDef card;
  final int owned;
  final int inDeck;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final rare = card.rarity == CardRarity.rare;
    final color = rare ? const Color(0xFF6A4BA8) : TsuzuriColors.accent;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Text(card.type.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${card.name}${rare ? '（レア）' : ''}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: color),
                  ),
                  Text(
                    card.description,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                  Text(
                    '${card.type.label}・持っている $owned 枚',
                    style: TextStyle(
                      fontSize: 11,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'デッキから外す',
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$inDeck', style: serif(16)),
            IconButton(
              tooltip: 'デッキに入れる',
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
