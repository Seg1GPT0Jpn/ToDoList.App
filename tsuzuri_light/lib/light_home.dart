import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/theme.dart';
import 'package:rpg_game_app/art/paper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'light_pages.dart' deferred as pages;

/// 画面のプログラムを読みこんでから開く（はじめて開くときだけ少し待つ）
Future<void> openPage(BuildContext context, Widget Function() page) async {
  await pages.loadLibrary();
  if (!context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => page()));
}

/// つづりクエストLight のホーム：必要な入口だけを並べる（絵や動きは置かない）
class LightHome extends StatelessWidget {
  const LightHome({super.key});

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return Scaffold(
      body: NotebookPaper(
        child: SafeArea(
          child: ListView(
            key: const ValueKey('light-home'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'つづりクエストLight',
                          style: serif(24, color: TsuzuriColors.accent),
                        ),
                        Text(
                          '定期テスト対策・単語帳・クラスルームの軽い版',
                          style: TextStyle(
                            fontSize: 12,
                            color: TsuzuriColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('light-settings'),
                    tooltip: '設定',
                    onPressed: () => openPage(context, () => pages.settings()),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _AccountRow(),
              const SizedBox(height: 10),
              const _TodayPlan(),
              const SizedBox(height: 12),
              _Entry(
                id: 'sea',
                icon: Icons.sailing,
                title: '定期テストの海',
                subtitle: '教科・単元ごとの問題と単語帳。上の「試験対策」から学校の範囲へ',
                onTap: () =>
                    openPage(context, () => pages.sea(services.personalBooks)),
              ),
              _Entry(
                id: 'exam',
                icon: Icons.school_outlined,
                title: '試験対策（学校の定期テスト）',
                subtitle: '範囲表からの演習・授業・テスト範囲の単語帳',
                onTap: () => openPage(context, () => pages.exam()),
              ),
              _Entry(
                id: 'vocab',
                icon: Icons.style_outlined,
                title: '単語帳',
                subtitle: 'つづ単・自分の単語帳・苦手な単語',
                onTap: () => openPage(
                  context,
                  () => pages.vocab(services.personalBooks),
                ),
              ),
              _Entry(
                id: 'class',
                icon: Icons.groups_outlined,
                title: 'クラスルーム',
                subtitle: services.classrooms == null
                    ? 'インターネットにつながると使えます'
                    : '先生の課題・クラスの範囲',
                onTap: () => openPage(context, () => pages.classroom()),
              ),
              ListenableBuilder(
                listenable: services.meta,
                builder: (context, _) {
                  final today = RpgServices.today();
                  final due = services.meta.record.stats.values
                      .where((s) => s.isDue(today))
                      .length;
                  return _Entry(
                    id: 'review',
                    icon: Icons.replay,
                    title: due > 0 ? '復習（$due問）' : '復習',
                    subtitle: 'まちがえた問題・忘れかけた問題をもう一度',
                    highlight: due > 0,
                    onTap: () => openPage(context, () => pages.review()),
                  );
                },
              ),
              _Entry(
                id: 'status',
                icon: Icons.insights,
                title: '学習ステータス',
                subtitle: '教科ごとの正解率と、学習した日',
                onTap: () => openPage(context, () => pages.status()),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  key: const ValueKey('light-full'),
                  onPressed: () => launchUrl(
                    Uri.base.resolve('/'),
                    webOnlyWindowName: '_self',
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('冒険もできる「つづりクエスト」を開く（記録は同じ）'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 今日やること（ホームを出したあとで読みこむ）
class _TodayPlan extends StatefulWidget {
  const _TodayPlan();

  @override
  State<_TodayPlan> createState() => _TodayPlanState();
}

class _TodayPlanState extends State<_TodayPlan> {
  var _ready = false;

  @override
  void initState() {
    super.initState();
    pages.loadLibrary().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      _ready ? pages.todayPlan() : const SizedBox(height: 120);
}

/// 名前と、ほかのアプリ・端末との同期のようす
class _AccountRow extends StatelessWidget {
  const _AccountRow();

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return StreamBuilder<PlayerProfile>(
      stream: services.profiles.watch(),
      builder: (context, snap) {
        final p = snap.data ?? services.profiles.load();
        final linked = p.isGoogleLinked;
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            key: const ValueKey('light-account'),
            leading: Icon(
              linked ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: linked ? TsuzuriColors.correct : TsuzuriColors.inkSoft,
            ),
            title: Text(p.displayName, style: serif(15)),
            subtitle: Text(
              linked
                  ? 'つづりクエストと同じ記録（自動で同期中）'
                  : 'この端末ではつづりクエストと同じ記録。Google でログインすると別の端末・アプリとも同期',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openPage(context, () => pages.account()),
          ),
        );
      },
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: highlight
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: TsuzuriColors.accent, width: 1.5),
            )
          : null,
      child: ListTile(
        key: ValueKey('light-$id'),
        leading: Icon(icon, color: TsuzuriColors.accent),
        title: Text(title, style: serif(16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
