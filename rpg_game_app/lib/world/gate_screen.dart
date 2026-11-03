import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../audio/music_scope.dart';
import '../field/field_screen.dart';
import 'eiken_door_screen.dart';

/// 異世界の門の色
abstract final class GateColors {
  static const sky = Color(0xFF1E1B3A);
  static const deep = Color(0xFF3A2A6B);
  static const glow = Color(0xFFB79CFF);
  static const gold = Color(0xFFE8C66A);
  static const text = Color(0xFFF3EEFF);
  static const soft = Color(0xFFC9BEE8);
}

/// 異世界の門の向こうにある扉（資格ごと）。ルートのない扉は準備中
class GateDoor {
  const GateDoor({
    required this.id,
    required this.title,
    required this.subtitle,
    this.worldId,
    this.routeId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? worldId;
  final String? routeId;

  bool get ready => worldId != null;

  static const all = <GateDoor>[
    GateDoor(
      id: 'takken',
      title: '宅建の扉',
      subtitle: '宅地建物取引士試験。権利関係・宅建業法・法令上の制限・税その他の16エリア',
      worldId: ShikakuCatalog.worldId,
      routeId: 'takken',
    ),
    GateDoor(
      id: 'eiken',
      title: '英検の扉',
      subtitle: '英検 準2級・2級・準1級・1級の単語帳と、単語のバトル',
      worldId: Eiken.worldId,
    ),
    GateDoor(
      id: 'national',
      title: '三大国家試験の扉',
      subtitle: '司法試験・医師国家試験・公認会計士試験（準備中）',
    ),
  ];
}

/// ホームに出す、異世界の門への入口
class GateBanner extends StatelessWidget {
  const GateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('gate-banner'),
      borderRadius: BorderRadius.circular(16),
      color: GateColors.sky,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MusicScope(
              music: 'field_information',
              child: GateScreen(),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GateColors.glow, width: 1.5),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 40,
                height: 44,
                child: CustomPaint(painter: _ArchPainter(small: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '追加コンテンツ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GateColors.gold,
                      ),
                    ),
                    Text('異世界の門', style: serif(18, color: GateColors.text)),
                    const Text(
                      'ノートの世界とは別の場所へ。資格試験（宅建など）の世界につながっている',
                      style: TextStyle(fontSize: 12, color: GateColors.soft),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: GateColors.glow),
            ],
          ),
        ),
      ),
    );
  }
}

/// 異世界の門：資格ごとの扉が並ぶ
class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  late final Future<RpgProgress> _progress = RpgServices.of(context).repository
      .load();

  Future<void> _open(GateDoor door) async {
    final progress = await _progress;
    if (!mounted || !door.ready) return;
    final world = RpgCatalog.world(door.worldId!);
    RpgServices.of(context).music.se('se_magic');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => door.id == 'eiken'
            ? const EikenDoorScreen()
            : MusicScope(
                music: 'field_information',
                child: FieldScreen(world: world, progress: progress),
              ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GateColors.sky,
      appBar: AppBar(
        backgroundColor: GateColors.sky,
        foregroundColor: GateColors.text,
        title: Text('異世界の門', style: serif(18, color: GateColors.text)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
          FutureBuilder<RpgProgress>(
            future: _progress,
            builder: (context, snap) {
              final progress = snap.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const SizedBox(
                    height: 170,
                    child: CustomPaint(painter: _ArchPainter()),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ノートの世界の6つの国とは関係のない、別の世界へつながる門。'
                    '扉ごとに、資格試験の世界が広がっている。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: GateColors.soft,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final d in GateDoor.all)
                    _DoorCard(
                      door: d,
                      progress: progress,
                      onTap: d.ready ? () => _open(d) : null,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DoorCard extends StatelessWidget {
  const _DoorCard({required this.door, required this.progress, this.onTap});

  final GateDoor door;
  final RpgProgress? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ready = door.ready;
    String? count;
    if (ready && progress != null) {
      final stages = RpgCatalog.world(door.worldId!).stages
          .where((s) => door.routeId == null || s.branch == door.routeId)
          .toList();
      final cleared = stages
          .where((s) => progress!.clearedStageIds.contains(s.id))
          .length;
      count = 'クリア $cleared / ${stages.length}';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ready ? GateColors.deep : GateColors.deep.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('gate-door-${door.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  ready ? Icons.door_front_door : Icons.lock_outline,
                  color: ready ? GateColors.gold : GateColors.soft,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        door.title,
                        style: serif(
                          17,
                          color: ready ? GateColors.text : GateColors.soft,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        door.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: GateColors.soft,
                        ),
                      ),
                      if (count != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            count,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: GateColors.gold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (ready)
                  const Icon(Icons.chevron_right, color: GateColors.glow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 夜空の星
class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas c, Size size) {
    final rnd = Random(7);
    final p = Paint()..color = Colors.white;
    for (var i = 0; i < 70; i++) {
      p.color = Colors.white.withValues(alpha: 0.25 + rnd.nextDouble() * 0.6);
      c.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.6 + rnd.nextDouble() * 1.4,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}

/// 光る石の門
class _ArchPainter extends CustomPainter {
  const _ArchPainter({this.small = false});

  final bool small;

  @override
  void paint(Canvas c, Size size) {
    final h = size.height, w = min(size.width, h * 0.8);
    final cx = size.width / 2;
    final rect = Rect.fromLTWH(cx - w / 2, 0, w, h);
    final inner = rect.deflate(w * 0.16);
    Path arch(Rect r) => Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + r.width / 2)
      ..arcToPoint(
        Offset(r.right, r.top + r.width / 2),
        radius: Radius.circular(r.width / 2),
      )
      ..lineTo(r.right, r.bottom)
      ..close();
    // 光
    if (!small) {
      c.drawCircle(
        inner.center,
        w * 0.7,
        Paint()
          ..color = GateColors.glow.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }
    c.drawPath(arch(rect), Paint()..color = const Color(0xFF8E86A8));
    c.drawPath(
      arch(rect),
      Paint()
        ..color = const Color(0xFF2B2440)
        ..style = PaintingStyle.stroke
        ..strokeWidth = small ? 1.5 : 3,
    );
    c.drawPath(
      arch(inner),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFFFF), GateColors.glow, Color(0xFF5B3FA8)],
          stops: [0.0, 0.45, 1.0],
        ).createShader(inner),
    );
    // うずまき
    if (!small) {
      final swirl = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 1; i <= 3; i++) {
        c.drawArc(
          Rect.fromCircle(center: inner.center, radius: inner.width * 0.12 * i),
          i * 1.3,
          4.0,
          false,
          swirl,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ArchPainter old) => false;
}
