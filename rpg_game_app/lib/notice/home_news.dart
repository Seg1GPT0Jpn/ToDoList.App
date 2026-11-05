import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart' show juniorEdition;
import 'package:shared_preferences/shared_preferences.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../meta/design.dart';
import 'feedback_screen.dart';

/// お知らせの詳しい画面にあるボタン
enum HomeNewsAction { none, feedback }

/// アプリに入れておくお知らせ（新しいものを上に。ホームには上から [HomeNews.shown] 件だけ出す）
class HomeNewsItem {
  const HomeNewsItem({
    required this.id,
    required this.date,
    required this.title,
    required this.body,
    this.action = HomeNewsAction.none,
    this.highSchoolOnly = false,
  });

  final String id;

  /// 表示する日付（例：11/3）
  final String date;
  final String title;

  /// 詳しい画面の本文（段落ごと）。「見出し：」で始まる段落は見出しつきで出す
  final List<String> body;
  final HomeNewsAction action;

  /// 高校生版だけで出す（小中学生版では出さない）
  final bool highSchoolOnly;

  static const all = <HomeNewsItem>[
    HomeNewsItem(
      id: 'shinken-2026-11',
      date: '11/3',
      title: '【湘南生向け】模試の予想問題が追加されました',
      highSchoolOnly: true,
      body: [
        '11月の進研模試（高1）の形式の予想問題を追加しました。国語・数学・英語の3教科です。',
        '本番と同じ時間（国語80分・数学100分・英語80分）で解いて、その場で採点できます。英語はリスニングの音声も聞けます。',
        '開き方：定期テストの海 →「試験対策」→「湘南高校104回生 定期テスト対策」→「11月 進研模試」→「予想問題を解く（進研模試）」。学校名とパスワードが必要です。',
        '実際の試験問題ではありません。',
      ],
    ),
    HomeNewsItem(
      id: 'feedback-2026-11',
      date: '11/3',
      title: 'フィードバック機能が使えるようになりました',
      action: HomeNewsAction.feedback,
      body: [
        '使ってみた感想・ほしい機能・まちがいの報告などを、アプリから送れるようになりました。ホーム右上の「︙」メニューや、設定からも開けます。',
        '他校の方へ：自分の学校の予想問題がほしいなどあれば、ご連絡ください。',
        '湘南生の方へ：ご要望・ご意見があれば、連絡してください。',
      ],
    ),
    HomeNewsItem(
      id: 'contest-2026-10',
      date: '10/29',
      title: '週替わり単語バトルを追加しました',
      highSchoolOnly: true,
      body: [
        'LEAP は毎週日曜、EEVI は毎週金曜に、みんなで同じ範囲の単語にいどむ「週替わり単語バトル」を追加しました。',
        '4種類×100問の総合得点で順位が決まります。分野ごとにも、まとめて一気にも挑戦できます。',
        '受付が終わると最終ランキングを発表します。上位に入賞すると、EXP と称号の報酬がもらえます。',
        '開き方：ホームの「対戦・クラスルーム」→「週替わり単語バトル（LEAP・EEVI）」。参加には Google ログインが必要です。',
      ],
    ),
  ];
}

/// ホームの「お知らせ」。タップで詳しい画面を開く。開いていないものには NEW をつける
class HomeNews extends StatefulWidget {
  const HomeNews({super.key, this.items});

  /// テスト用。ふだんは [HomeNewsItem.all]
  final List<HomeNewsItem>? items;

  /// ホームに出す件数
  static const shown = 3;

  /// 開いたお知らせの id
  static const readKey = 'home_news_read_v1';

  static List<HomeNewsItem> visible([List<HomeNewsItem>? items]) => [
    for (final i in items ?? HomeNewsItem.all)
      if (!(juniorEdition && i.highSchoolOnly)) i,
  ].take(shown).toList();

  @override
  State<HomeNews> createState() => _HomeNewsState();
}

class _HomeNewsState extends State<HomeNews> {
  Set<String> _read = const {};

  @override
  void initState() {
    super.initState();
    _loadRead();
  }

  Future<void> _loadRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final read = prefs.getStringList(HomeNews.readKey) ?? const [];
      if (mounted) setState(() => _read = read.toSet());
    } catch (_) {}
  }

  Future<void> _open(HomeNewsItem item) async {
    setState(() => _read = {..._read, item.id});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(HomeNews.readKey, _read.toList());
    } catch (_) {}
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => HomeNewsScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    final items = HomeNews.visible(widget.items);
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('home-news'),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        decoration: BoxDecoration(
          color: TsuzuriColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TsuzuriColors.exp, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  color: TsuzuriColors.exp,
                  size: 20,
                ),
                const SizedBox(width: 6),
                const Text(
                  'お知らせ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            for (final i in items)
              InkWell(
                key: ValueKey('home-news-${i.id}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => _open(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          i.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: TsuzuriColors.inkSoft,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          i.title,
                          style: const TextStyle(fontSize: 13.5, height: 1.4),
                        ),
                      ),
                      if (!_read.contains(i.id))
                        Container(
                          key: ValueKey('home-news-new-${i.id}'),
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: TsuzuriColors.exp,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: TsuzuriColors.inkSoft,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// お知らせの詳しい画面
class HomeNewsScreen extends StatelessWidget {
  const HomeNewsScreen({super.key, required this.item});

  final HomeNewsItem item;

  @override
  Widget build(BuildContext context) {
    final canFeedback = RpgServices.of(context).notices != null;
    return Scaffold(
      appBar: AppBar(title: const Text('お知らせ')),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.margin,
            Space.m,
            Space.m,
            Space.xl,
          ),
          children: [
            Text(
              item.date,
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Space.m),
            for (final p in item.body) _paragraph(p),
            if (item.action == HomeNewsAction.feedback && canFeedback) ...[
              const SizedBox(height: Space.m),
              FilledButton.icon(
                key: const ValueKey('home-news-feedback'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FeedbackScreen(),
                  ),
                ),
                icon: const Icon(Icons.send),
                label: const Text('フィードバックを送る'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 「〜の方へ：」「開き方：」のような見出しは太字にする
  static Widget _paragraph(String p) {
    final k = p.indexOf('：');
    final head = k > 0 && k <= 10 ? p.substring(0, k + 1) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s + 4),
      child: Text.rich(
        TextSpan(
          children: [
            if (head != null)
              TextSpan(
                text: '$head\n',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            TextSpan(text: head == null ? p : p.substring(head.length)),
          ],
        ),
        style: const TextStyle(fontSize: 14.5, height: 1.7),
      ),
    );
  }
}
