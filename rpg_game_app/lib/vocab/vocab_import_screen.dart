import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';
import 'vocab_store.dart';

/// AI（Claude や ChatGPT など）に単語帳を作ってもらうときのたのみ方
String aiPrompt({String source = '（ここに単語・プリント・PDF・写真の内容を入れる）'}) =>
    '次の資料から英単語を抜き出して、単語帳を作ってください。\n'
    '出力は CSV だけにして、1行目は見出し「term,meaning,pron,example,translation」にしてください。\n'
    '- term: 英単語（原形）\n'
    '- meaning: 日本語の意味（[名][動][形][副] などの品詞をはじめに付ける）\n'
    '- pron: 発音記号（/…/）\n'
    '- example: その単語を使った短い英語の例文（高校生向け）\n'
    '- translation: 例文の日本語訳\n'
    'カンマをふくむ項目は " で囲んでください。\n\n'
    '資料:\n$source';

/// 単語帳に単語を取り込む画面（貼り付け・CSV・Excel のコピー・AI の出力）
class VocabImportScreen extends StatefulWidget {
  const VocabImportScreen({super.key, required this.store, required this.book});

  final VocabStore store;
  final VocabBook book;

  @override
  State<VocabImportScreen> createState() => _VocabImportScreenState();
}

class _VocabImportScreenState extends State<VocabImportScreen> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final skipped = <int>[];
    final cards = VocabParser.parse(_text.text, skipped: skipped);
    if (cards.isEmpty) {
      setState(() => _error = '単語を読み取れませんでした。一覧をそのまま貼り付けてください。');
      return;
    }
    final r = widget.book.merge(cards);
    await widget.store.saveBooks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${r.added}語を追加しました'
          '${r.updated > 0 ? '（${r.updated}語に例文などを追加）' : ''}'
          '${skipped.isEmpty ? '' : '　読めなかった行: ${skipped.length}行'}',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final protected = widget.book.isProtected;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TsuzuriColors.paper,
        title: Text('「${widget.book.title}」に取り込む', style: serif(17)),
      ),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(40, 16, 16, 24),
          children: [
            Text(
              '次のどれでも、そのまま貼り付けられます。\n'
              '・「番号<TAB>単語<TAB>意味」の一覧（LEAP など）\n'
              '・「番号」「単語」「■品詞：意味」が1行ずつ並んだ一覧（STEP など）\n'
              '・Excel やスプレッドシートの表をコピーしたもの\n'
              '・CSV（見出し term, meaning, pron, example, translation）\n'
              '同じ単語がすでにあるときは、例文や発音の空いている所だけ埋めます。',
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: TsuzuriColors.inkSoft,
              ),
            ),
            if (protected) ...[
              const SizedBox(height: 6),
              Text(
                'この単語帳には、例文や発音記号を足せます。足したものはこの端末の中にだけ保存されます。'
                '市販教材の単語帳なので、個人の学習用にだけ使ってください。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: TsuzuriColors.stamp,
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('vocab-import-text'),
              controller: _text,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '1\tagree\t[自] ①賛成する ...',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: TsuzuriColors.wrong)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.download),
              label: const Text('取り込む'),
            ),
            const SizedBox(height: 24),
            Text('AI に単語帳を作ってもらう', style: serif(15)),
            const SizedBox(height: 4),
            Text(
              '学校のプリント・PDF・写真・模試で間違えた単語などは、下のたのみ方をコピーして '
              'Claude や ChatGPT に資料と一緒に送ってください。返ってきた CSV を上に貼り付ければ、'
              '品詞・発音記号・例文・訳つきの単語帳になります。',
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: TsuzuriColors.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: aiPrompt()));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('たのみ方をコピーしました')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('たのみ方をコピー'),
            ),
            if (widget.book.cards.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final missing = [
                    for (final c in widget.book.cards)
                      if (c.example.isEmpty) c.term,
                  ];
                  await Clipboard.setData(
                    ClipboardData(
                      text: aiPrompt(source: missing.take(100).join('\n')),
                    ),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '例文のない${missing.take(100).length}語の例文をたのむ文をコピーしました',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('例文のない単語の例文をたのむ（100語ずつ）'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
