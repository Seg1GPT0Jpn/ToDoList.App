import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/practice.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/enemy_painter.dart';
import '../art/paper.dart';
import 'design.dart';

/// 魔物図鑑。出会った魔物は姿が、倒した魔物は説明が見える。
class BestiaryScreen extends StatelessWidget {
  const BestiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meta = RpgServices.of(context).meta;
    return Scaffold(
      appBar: AppBar(title: const Text('魔物図鑑')),
      body: NotebookPaper(
        child: ListenableBuilder(
          listenable: meta,
          builder: (context, _) {
            final j = meta.journal;
            final all = EnemySpeciesCatalog.all;
            final found = all.where((s) => (j.seenLooks[s.look] ?? 0) > 0);
            final beaten = all.where((s) => (j.defeatedLooks[s.look] ?? 0) > 0);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.margin + 4,
                    Space.m,
                    Space.l,
                    Space.s,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '発見 ${found.length} / ${all.length}　討伐 ${beaten.length} / ${all.length}',
                      style: TextStyle(color: TsuzuriColors.inkSoft),
                    ),
                  ),
                ),
                for (final cat in SpeciesCategory.values) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.margin + 4,
                      Space.m,
                      Space.l,
                      Space.xs,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text('${cat.mark} ${cat.label}', style: serif(15)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.margin,
                      0,
                      Space.m,
                      Space.s,
                    ),
                    sliver: SliverGrid.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: Space.s,
                      crossAxisSpacing: Space.s,
                      childAspectRatio: 0.78,
                      children: [
                        for (final s in all.where((s) => s.category == cat))
                          _SpeciesTile(
                            species: s,
                            seen: j.seenLooks[s.look] ?? 0,
                            defeated: j.defeatedLooks[s.look] ?? 0,
                          ),
                      ],
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SpeciesTile extends StatelessWidget {
  const _SpeciesTile({
    required this.species,
    required this.seen,
    required this.defeated,
  });

  final EnemySpecies species;
  final int seen;
  final int defeated;

  @override
  Widget build(BuildContext context) {
    final known = seen > 0;
    final color = rarityColor(species.rarity);
    return Semantics(
      label: known ? species.name : 'まだ出会っていない魔物',
      button: known,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: known ? () => _detail(context) : null,
        child: Container(
          decoration: BoxDecoration(
            color: TsuzuriColors.card,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(
              color: known ? color : TsuzuriColors.kraft,
              width: known ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(Space.xs + 2),
          child: Column(
            children: [
              Expanded(
                child: _EnemyIcon(look: species.look, silhouette: !known),
              ),
              Text(
                known ? species.name : '？？？',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: serif(12),
              ),
              Text(
                stars(species.rarity),
                style: TextStyle(fontSize: 10, color: color),
              ),
              if (defeated > 0)
                Text(
                  '討伐 $defeated',
                  style: TextStyle(fontSize: 10, color: TsuzuriColors.inkSoft),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _detail(BuildContext context) {
    final beaten = defeated > 0;
    final record = RpgServices.of(context).meta.record;
    final ability = EnemyAbility.forLook(species.look);
    final winRate = seen == 0 ? null : (defeated * 100 / seen).round();
    // この種族が出てくる単元のうち、いちばん苦手なもの
    final units =
        [
            for (final w in RpgCatalog.worlds)
              for (final st in w.stages)
                if (st.enemy.look == species.look)
                  (st, Proficiency.ofStage(record, st)),
          ].where((e) => e.$2.rated).toList()
          ..sort((a, b) => a.$2.score.compareTo(b.$2.score));
    final weakest = units.isEmpty ? null : units.first;
    final struggling =
        (winRate != null && seen >= 3 && winRate < 60) ||
        (weakest != null && weakest.$2.score < 60);
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(species.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                child: Center(child: _EnemyIcon(look: species.look)),
              ),
              Text(
                '${stars(species.rarity)} ${species.rarity.label}　'
                '${species.category.label}・${species.size.label}',
                style: TextStyle(color: rarityColor(species.rarity)),
              ),
              const SizedBox(height: Space.s),
              Text('モチーフ：${species.motif}'),
              Text('出会った回数：$seen　倒した回数：$defeated'),
              if (winRate != null) Text('勝率：$winRate%'),
              if (ability != EnemyAbility.none)
                Text('能力：${ability.label}（${ability.description}）'),
              if (weakest != null)
                Text(
                  '弱点の単元：${RpgCatalog.world(weakest.$1.worldId).subject}・${weakest.$1.grammarTheme}（あなたの熟練度 ${weakest.$2.score}）',
                ),
              if (struggling && weakest != null) ...[
                const SizedBox(height: Space.s),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TsuzuriColors.tint(0xFFFFF1E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'この魔物に苦戦しています。',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          startPractice(context, weakest.$1);
                        },
                        child: Text('「${weakest.$1.grammarTheme}」を復習'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Space.s),
              if (beaten) ...[
                Text('性格：${species.personality}'),
                Text('攻撃：${species.attack}'),
                const SizedBox(height: Space.s),
                Text(species.lore, style: const TextStyle(height: 1.6)),
              ] else
                Text(
                  '倒すと、くわしい説明が読めるようになります。',
                  style: TextStyle(color: TsuzuriColors.inkSoft),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              RpgServices.of(context).music.se(species.sound);
            },
            child: const Text('鳴き声'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('とじる'),
          ),
        ],
      ),
    );
  }
}

class _EnemyIcon extends StatelessWidget {
  const _EnemyIcon({required this.look, this.silhouette = false});
  final String look;
  final bool silhouette;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(painter: _IconPainter(look, silhouette)),
  );
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.look, this.silhouette);
  final String look;
  final bool silhouette;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    if (!silhouette) {
      paintEnemy(canvas, s, look, 0);
      return;
    }
    // まだ出会っていない魔物は影だけ
    canvas.saveLayer(Offset.zero & size, Paint());
    paintEnemy(canvas, s, look, 0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFF3A3530)
        ..blendMode = BlendMode.srcIn,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.look != look || old.silhouette != silhouette;
}
