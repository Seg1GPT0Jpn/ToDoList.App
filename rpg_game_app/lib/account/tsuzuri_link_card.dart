import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../cloud/tsuzuri_link.dart';
import '../study/sea_home_screen.dart';
import 'tsuzuri_test_prep.dart';

/// つづり（学校生活アプリ）を開く
Future<void> openTsuzuri() => launchUrl(
  Uri.parse(TsuzuriLink.tsuzuriUrl),
  mode: LaunchMode.externalApplication,
);

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'たった今';
  if (d.inHours < 1) return '${d.inMinutes}分前';
  if (d.inDays < 1) return '${d.inHours}時間前';
  return '${d.inDays}日前';
}

/// アカウント画面の「つづりと連携」
class TsuzuriLinkCard extends StatelessWidget {
  const TsuzuriLinkCard({super.key});

  @override
  Widget build(BuildContext context) {
    final link = RpgServices.of(context).tsuzuri;
    return Card(
      key: const ValueKey('tsuzuri-link'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: link == null
            ? const _Body(link: null)
            : ListenableBuilder(
                listenable: link,
                builder: (_, _) => _Body(link: link),
              ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.link});

  final TsuzuriLinkController? link;

  @override
  Widget build(BuildContext context) {
    final link = this.link;
    final small = TextStyle(
      fontSize: 12,
      height: 1.5,
      color: TsuzuriColors.inkSoft,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.link, size: 20),
            const SizedBox(width: 6),
            Text('つづりと連携', style: serif(16)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'つづり（時間割・テスト・目標の学校生活アプリ）と同じ Google アカウントでつなぐと、'
          'つづりに登録したテスト予定がここに出て、クエストで勉強した時間と成果が'
          'つづりの勉強記録に入ります。送るのは教科・時間・問題数・苦手な単元の名前だけです。',
          style: small,
        ),
        const SizedBox(height: 10),
        if (link == null)
          Text('この版ではつづりと連携できません（Web 版で使えます）。', style: small)
        else if (!link.connected) ...[
          FilledButton.icon(
            key: const ValueKey('tsuzuri-connect'),
            onPressed: link.busy ? null : link.connect,
            icon: const Icon(Icons.login),
            label: const Text('つづりのアカウントでつなぐ'),
          ),
        ] else ...[
          Text(
            'つないでいるアカウント：${link.email}',
            key: const ValueKey('tsuzuri-email'),
          ),
          Text(
            link.busy
                ? '同期しています…'
                : link.syncedAt == null
                ? 'まだ同期していません'
                : '最後の同期：${_ago(link.syncedAt!)}'
                      '　テスト予定 ${link.upcoming.length}件',
            style: small,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('tsuzuri-sync'),
                onPressed: link.busy ? null : link.sync,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('今すぐ同期'),
              ),
              TextButton(
                key: const ValueKey('tsuzuri-disconnect'),
                onPressed: link.busy ? null : link.disconnect,
                child: const Text('連携をやめる'),
              ),
            ],
          ),
        ],
        if (link?.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              link!.error!,
              style: const TextStyle(color: TsuzuriColors.wrong, fontSize: 12),
            ),
          ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: openTsuzuri,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('つづりを開く'),
        ),
      ],
    );
  }
}

/// ホームの「つづり」カード：今日の授業（復習）・テスト予定（対策）・目標の進み具合。
/// つないでいて、出すものがあるときだけ出す
class TsuzuriUpcomingCard extends StatelessWidget {
  const TsuzuriUpcomingCard({super.key, this.limit = 4});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final link = services.tsuzuri;
    if (link == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: link,
      builder: (context, _) {
        final now = DateTime.now();
        final items = link.upcoming.where((u) => u.isTest).toList();
        // 夕方からは、明日の授業を出す
        final lessonDay = now.hour >= 17
            ? DateTime(now.year, now.month, now.day + 1)
            : now;
        final lessons = link.lessonsOn(lessonDay);
        final goals = link.goals.take(2).toList();
        if (!link.connected ||
            (items.isEmpty && lessons.isEmpty && goals.isEmpty)) {
          return const SizedBox.shrink();
        }
        final small = TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft);
        return Card(
          key: const ValueKey('tsuzuri-upcoming'),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('つづり', style: serif(16))),
                    TextButton(
                      onPressed: openTsuzuri,
                      child: const Text('つづりを開く'),
                    ),
                  ],
                ),
                if (lessons.isNotEmpty) ...[
                  Text(
                    lessonDay.day == now.day ? '今日の授業の復習' : '明日の授業の予習',
                    style: small,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final l in lessons)
                        ActionChip(
                          key: ValueKey('tsuzuri-lesson-${l.period}'),
                          visualDensity: VisualDensity.compact,
                          label: Text('${l.period}限 ${l.subject}'),
                          onPressed: l.worldId == null
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SeaHomeScreen(
                                      personalBooks: services.personalBooks,
                                      initialSubject: l.worldId,
                                    ),
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (items.isNotEmpty) ...[
                  Text('テスト予定', style: small),
                  for (final u in items.take(limit))
                    _UpcomingRow(
                      item: u,
                      today: now,
                      prepMinutes: link.prepMinutes(u),
                    ),
                  const SizedBox(height: 4),
                ],
                for (final g in goals)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Column(
                      key: ValueKey('tsuzuri-goal-${g.title}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '目標：${g.title}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(g.label, style: small),
                          ],
                        ),
                        const SizedBox(height: 2),
                        LinearProgressIndicator(
                          value: g.ratio,
                          minHeight: 5,
                          color: TsuzuriColors.correct,
                          backgroundColor: TsuzuriColors.tint(0xFFE8E0D2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.item,
    required this.today,
    required this.prepMinutes,
  });

  final TsuzuriUpcoming item;
  final DateTime today;

  /// クエストで対策した時間（分）
  final int prepMinutes;

  @override
  Widget build(BuildContext context) {
    final n = item.daysFrom(today);
    final when = switch (n) {
      0 => '今日',
      1 => '明日',
      _ => 'あと$n日',
    };
    final sub = [
      ?item.detail,
      if (prepMinutes > 0) '対策 $prepMinutes分',
    ].join('　');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              when,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: n <= 2 ? TsuzuriColors.wrong : TsuzuriColors.inkSoft,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
              ],
            ),
          ),
          if (item.worldId != null)
            TextButton(
              key: ValueKey('tsuzuri-practice-${item.title}'),
              onPressed: () => startTsuzuriPrep(context, item),
              child: const Text('対策'),
            ),
        ],
      ),
    );
  }
}
