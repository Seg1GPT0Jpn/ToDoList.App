import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../study/personal_books.dart';
import 'vocab_book_screen.dart';
import 'vocab_import_screen.dart';
import 'vocab_session_screen.dart';
import 'vocab_store.dart';

/// 単語帳練習のホーム（定期テストの海の「単語帳練習」タブ）
class VocabHome extends StatefulWidget {
  const VocabHome({super.key, required this.books});

  final PersonalBooks books;

  @override
  State<VocabHome> createState() => _VocabHomeState();
}

class _VocabHomeState extends State<VocabHome> {
  late final VocabStore store = VocabStore.of(widget.books);
  final _password = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  void _unlock() {
    setState(() {
      _message = store.tryUnlock(_password.text) ? null : 'パスワードがちがいます';
      if (_message == null) _password.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final books = store.visibleBooks;
    final totals = {for (final s in CardStatus.values) s: 0};
    var due = 0, streak = 0, minutes = 0;
    VocabBook? best;
    var bestCount = 0;
    for (final b in books) {
      if (b.cards.isEmpty) continue;
      final p = store.progress(b.id);
      p.counts(b, now).forEach((k, v) => totals[k] = totals[k]! + v);
      due += p.dueCount(now);
      if (p.streak(now) > streak) streak = p.streak(now);
      minutes += (p.days[BookProgress.dayKey(now)]?.seconds ?? 0) ~/ 60;
      final plan = VocabPlanner.today(b, p, now).length;
      if (plan > bestCount) {
        bestCount = plan;
        best = b;
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 12, 16, 24),
      children: [
        Card(
          color: TsuzuriColors.tint(0xFFFFF8E1),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日のあなた', style: serif(17)),
                const SizedBox(height: 4),
                Text(
                  '🔴 弱点 ${totals[CardStatus.weak]}語　🟠 あやふや ${totals[CardStatus.shaky]}語　'
                  '🟢 安定 ${totals[CardStatus.stable]}語',
                ),
                Text('今日の復習予定 $due問　🔥 $streak日連続　今日 $minutes分'),
                if (best != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const ValueKey('vocab-home-today'),
                    onPressed: () {
                      final b = best!;
                      _open(
                        VocabSessionScreen(
                          store: store,
                          book: b,
                          title: '${b.title} 今日の最適学習',
                          tasks: VocabPlanner.today(
                            b,
                            store.progress(b.id),
                            DateTime.now(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text('今日の最適学習（${best.title}・$bestCount問）'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('単語帳', style: serif(16)),
        const SizedBox(height: 6),
        for (final b in books) _bookTile(b, now),
        if (!store.unlocked) _gate(),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final name = await askText(context, '新しい単語帳の名前', '英検2級');
            if (name == null || name.isEmpty) return;
            final b = await store.createBook(name);
            if (!mounted) return;
            await _open(VocabImportScreen(store: store, book: b));
          },
          icon: const Icon(Icons.add),
          label: const Text('単語帳をつくる'),
        ),
        const SizedBox(height: 16),
        _settings(),
      ],
    );
  }

  Widget _bookTile(VocabBook b, DateTime now) {
    final p = store.progress(b.id);
    final c = p.counts(b, now);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(b.isProtected ? Icons.lock_open : Icons.menu_book),
        title: Text(b.title),
        subtitle: Text(
          b.cards.isEmpty
              ? 'まだ単語がありません（タップして取り込む）'
              : '${b.cards.length}語　🟢${c[CardStatus.stable]} 🟠${c[CardStatus.shaky]} 🔴${c[CardStatus.weak]}　復習 ${p.dueCount(now)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(
          b.cards.isEmpty
              ? VocabImportScreen(store: store, book: b)
              : VocabBookScreen(store: store, book: b),
        ),
      ),
    );
  }

  Widget _gate() {
    return Card(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, size: 18),
                const SizedBox(width: 6),
                Text('LEAP・EEVI', style: serif(15)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '市販教材の単語を自分で取り込んで使う単語帳です。パスワードを入れると開きます。',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('vocab-password'),
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'パスワード',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _unlock, child: const Text('ひらく')),
              ],
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _message!,
                  style: const TextStyle(color: TsuzuriColors.wrong),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _settings() {
    final (lang, rate) = store.voice;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('設定・バックアップ', style: serif(15)),
      children: [
        Row(
          children: [
            const Text('発音'),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en-US', label: Text('米音')),
                ButtonSegment(value: 'en-GB', label: Text('英音')),
              ],
              selected: {lang},
              onSelectionChanged: (s) async {
                await store.setVoice(s.first, rate);
                setState(() {});
              },
            ),
          ],
        ),
        Row(
          children: [
            const Text('速さ'),
            Expanded(
              child: Slider(
                value: rate,
                min: 0.2,
                max: 1.0,
                divisions: 8,
                label: rate.toStringAsFixed(1),
                onChanged: (v) async {
                  await store.setVoice(lang, v);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '単語帳と学習記録はこの端末の中にだけ保存されます（電波がなくても使えます）。'
            '別の端末に移すときは、バックアップをコピーして、移す先で「読み込む」に貼り付けてください。'
            'LEAP・EEVI の単語はバックアップに入らないので、移す先でもう一度取り込んでください。',
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: TsuzuriColors.inkSoft,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: store.exportBackup()),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('バックアップをコピーしました')));
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('コピー'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final text = await askText(context, 'バックアップを貼り付け');
                if (text == null || text.isEmpty) return;
                final ok = await store.importBackup(text);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? '読み込みました' : '読み込めませんでした')),
                );
                setState(() {});
              },
              icon: const Icon(Icons.paste, size: 18),
              label: const Text('読み込む'),
            ),
          ],
        ),
        if (store.unlocked)
          TextButton(
            onPressed: () async {
              await store.lock();
              setState(() {});
            },
            child: const Text('LEAP・EEVI に鍵をかける'),
          ),
      ],
    );
  }
}
