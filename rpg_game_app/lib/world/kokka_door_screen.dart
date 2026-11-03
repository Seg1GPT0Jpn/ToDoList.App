import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../audio/music_scope.dart';
import '../field/field_screen.dart';
import '../study/term_cards.dart';
import 'gate_screen.dart';

/// 三大国家試験の扉の向こう：司法試験・医師国家試験・公認会計士試験のバトルと用語帳
class KokkaDoorScreen extends StatelessWidget {
  const KokkaDoorScreen({super.key});

  static const _icons = {
    'shiho': Icons.gavel,
    'ishi': Icons.medical_services_outlined,
    'kaikei': Icons.calculate_outlined,
  };

  Future<void> _battle(BuildContext context, RpgProgress progress) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MusicScope(
          music: 'field_information',
          child: FieldScreen(
            world: RpgCatalog.world(KokkaCatalog.worldId),
            progress: progress,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = RpgCatalog.world(KokkaCatalog.worldId);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: GateColors.sky,
        appBar: AppBar(
          backgroundColor: GateColors.sky,
          foregroundColor: GateColors.text,
          title: Text('三大国家試験の世界', style: serif(18, color: GateColors.text)),
          bottom: const TabBar(
            labelColor: GateColors.gold,
            unselectedLabelColor: GateColors.soft,
            indicatorColor: GateColors.gold,
            tabs: [
              Tab(icon: Icon(Icons.sports_martial_arts, size: 18), text: 'バトル'),
              Tab(icon: Icon(Icons.style, size: 18), text: '用語帳'),
            ],
          ),
        ),
        body: StreamBuilder<RpgProgress>(
          stream: RpgServices.of(context).repository.watch(),
          builder: (context, snap) {
            final progress = snap.data ?? RpgProgress.initial;
            return TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    const Text(
                      '司法試験・医師国家試験・公認会計士試験の基礎を、3つの道・24エリアのバトルで。'
                      '上は司法試験、左は医師国家試験、右は公認会計士の道。'
                      '用語帳のタブでは、試験に出る用語をカードで覚えられる。',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: GateColors.soft,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final r in KokkaCatalog.routes)
                      _RouteCard(
                        route: r,
                        icon: _icons[r.info.id] ?? Icons.school,
                        cleared: world.stages
                            .where(
                              (s) =>
                                  s.branch == r.info.id &&
                                  progress.clearedStageIds.contains(s.id),
                            )
                            .length,
                        total: world.stages
                            .where((s) => s.branch == r.info.id)
                            .length,
                      ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const ValueKey('kokka-battle'),
                      style: FilledButton.styleFrom(
                        backgroundColor: GateColors.gold,
                        foregroundColor: GateColors.sky,
                      ),
                      onPressed: () => _battle(context, progress),
                      icon: const Icon(Icons.sports_martial_arts),
                      label: const Text('バトルへ（三大国家試験の世界）'),
                    ),
                  ],
                ),
                NotebookPaper(
                  child: TermCardsTab(world: world, progress: progress),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.icon,
    required this.cleared,
    required this.total,
  });

  final RouteSpec route;
  final IconData icon;
  final int cleared;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        key: ValueKey('kokka-route-${route.info.id}'),
        color: GateColors.deep,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: GateColors.gold, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route.info.name}の道',
                      style: serif(17, color: GateColors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [for (final a in route.areas) a.theme].join('・'),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: GateColors.soft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'クリア $cleared / $total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: GateColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
