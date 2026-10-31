import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/paper.dart';
import '../meta/design.dart';
import 'notice_backend.dart';

/// お知らせを書く・テスターの申しこみを見る（管理者だけ。設定から開く）
class NoticeAdminScreen extends StatefulWidget {
  const NoticeAdminScreen({super.key, required this.backend});

  final NoticeBackend backend;

  @override
  State<NoticeAdminScreen> createState() => _NoticeAdminScreenState();
}

class _NoticeAdminScreenState extends State<NoticeAdminScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _link = TextEditingController();
  final _linkLabel = TextEditingController();
  bool _signup = false;
  bool _enabled = true;
  String _id = '';
  bool _loaded = false;
  bool _busy = false;
  List<TesterSignup>? _signups;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_title, _body, _link, _linkLabel]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(AppNotice n) {
    _title.text = n.title;
    _body.text = n.body;
    _link.text = n.linkUrl;
    _linkLabel.text = n.linkLabel;
    _signup = n.testerSignup;
    _enabled = n.enabled;
  }

  Future<void> _load() async {
    final n = await widget.backend.load();
    List<TesterSignup>? list;
    try {
      list = await widget.backend.signups();
    } catch (_) {
      list = null;
    }
    if (!mounted) return;
    setState(() {
      if (n != null) {
        _id = n.id;
        _fill(n);
      }
      _signups = list;
      _loaded = true;
    });
  }

  /// [again] なら、前に「とじる」を押した人にもまた出す（新しい id にする）
  Future<void> _save({required bool again}) async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _snack('題名を入れてください');
      return;
    }
    setState(() => _busy = true);
    final id = again || _id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : _id;
    try {
      await widget.backend.save(
        AppNotice(
          id: id,
          title: title.characters.take(AppNotice.maxTitle).toString(),
          body: _body.text.trim().characters.take(AppNotice.maxBody).toString(),
          linkUrl: _link.text.trim(),
          linkLabel: _linkLabel.text.trim(),
          testerSignup: _signup,
          enabled: _enabled,
        ),
      );
      _id = id;
      _snack(_enabled ? 'お知らせを出しました' : 'お知らせを止めました');
    } catch (_) {
      _snack('保存できませんでした');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _copyEmails() async {
    final list = _signups ?? const [];
    await Clipboard.setData(
      ClipboardData(text: [for (final s in list) s.email].join(', ')),
    );
    _snack('${list.length}人のメールアドレスをコピーしました（Play Console のテスターの一覧に貼れます）');
  }

  Widget _field(TextEditingController c, String label, {int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: Space.m),
        child: TextField(
          controller: c,
          minLines: lines,
          maxLines: lines == 1 ? 1 : 10,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final list = _signups;
    return Scaffold(
      appBar: AppBar(title: const Text('お知らせ（管理者）')),
      body: NotebookPaper(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.margin,
                  Space.m,
                  Space.m,
                  Space.xl,
                ),
                children: [
                  const SectionTitle('ホームに出すお知らせ'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('notice-template'),
                      onPressed: () =>
                          setState(() => _fill(AppNotice.testerTemplate)),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('テスター募集のひな形を入れる'),
                    ),
                  ),
                  _field(_title, '題名'),
                  _field(_body, '本文', lines: 5),
                  _field(_link, 'リンク（なくてもよい）'),
                  _field(_linkLabel, 'リンクのボタンの文字（例：テスト版を入れる）'),
                  SwitchListTile(
                    title: const Text('「テスターに申しこむ」ボタンを出す'),
                    value: _signup,
                    onChanged: (v) => setState(() => _signup = v),
                  ),
                  SwitchListTile(
                    title: const Text('お知らせを出す'),
                    subtitle: const Text('オフにすると、だれにも出しません'),
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                  const SizedBox(height: Space.s),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        key: const ValueKey('notice-save-again'),
                        onPressed: _busy ? null : () => _save(again: true),
                        child: const Text('保存して、全員にまた出す'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('notice-save'),
                        onPressed: _busy ? null : () => _save(again: false),
                        child: const Text('文だけ直す'),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  SectionTitle('テスターの申しこみ（${list?.length ?? 0}人）'),
                  if (list == null)
                    const Text('一覧を読めませんでした（ルールの反映を待つか、管理者でログインしてください）')
                  else ...[
                    if (list.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: const ValueKey('notice-copy-emails'),
                          onPressed: _copyEmails,
                          icon: const Icon(Icons.content_copy, size: 18),
                          label: const Text('メールアドレスをまとめてコピー'),
                        ),
                      ),
                    for (final s in list)
                      ListTile(
                        dense: true,
                        title: Text(s.email),
                        subtitle: Text(
                          [
                            if (s.name.isNotEmpty) s.name,
                            if (s.at != null)
                              '${s.at!.month}/${s.at!.day} ${s.at!.hour}:${s.at!.minute.toString().padLeft(2, '0')}',
                          ].join('・'),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}
