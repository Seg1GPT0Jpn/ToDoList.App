import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import '../meta/design.dart';
import 'notice_backend.dart';

/// フィードバック（意見・不具合の報告）を送る画面
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  static const other = 'その他';

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _school = AppFeedback.schools.isEmpty
      ? FeedbackScreen.other
      : AppFeedback.schools.first;
  String? _class;
  final _schoolOther = TextEditingController();
  final _classOther = TextEditingController();
  final _nickname = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nickname.text.isEmpty) {
      final name = RpgServices.of(context).profiles.load().userName;
      if (name.isNotEmpty) _nickname.text = name;
    }
  }

  @override
  void dispose() {
    for (final c in [_schoolOther, _classOther, _nickname, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _schoolValue =>
      _school == FeedbackScreen.other ? _schoolOther.text.trim() : _school;

  String get _classValue =>
      _class == FeedbackScreen.other ? _classOther.text.trim() : (_class ?? '');

  Future<void> _send(NoticeBackend backend) async {
    final err = _schoolValue.isEmpty
        ? '高校名を入れてください'
        : _classValue.isEmpty
        ? 'クラスを選んでください'
        : _body.text.trim().isEmpty
        ? '内容を入れてください'
        : null;
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String cut(String s, int n) => s.characters.take(n).toString();
    try {
      await backend.sendFeedback(
        AppFeedback(
          school: cut(_schoolValue, AppFeedback.maxSchool),
          className: cut(_classValue, AppFeedback.maxClass),
          nickname: cut(_nickname.text.trim(), AppFeedback.maxNickname),
          body: cut(_body.text.trim(), AppFeedback.maxBody),
          platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        ),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('フィードバックを送りました。ありがとうございます！')),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '送れませんでした。インターネットにつながっているか確かめてください';
        });
      }
    }
  }

  InputDecoration _deco(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: const OutlineInputBorder(),
  );

  Widget _chips(
    List<String> values,
    String? selected,
    ValueChanged<String> onSelect,
    String keyPrefix,
  ) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final v in [...values, FeedbackScreen.other])
        ChoiceChip(
          key: ValueKey('$keyPrefix-$v'),
          label: Text(v),
          selected: selected == v,
          onSelected: (_) => onSelect(v),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final backend = RpgServices.of(context).notices;
    return Scaffold(
      appBar: AppBar(title: const Text('フィードバックを送る')),
      body: NotebookPaper(
        child: backend == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'インターネットにつながっていないため、今は送れません。',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.margin,
                  Space.m,
                  Space.m,
                  Space.xl,
                ),
                children: [
                  Text(
                    '使ってみた感想・ほしい機能・まちがいの報告など、なんでも送ってください。',
                    style: TextStyle(
                      fontSize: 13,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                  const SectionTitle('高校名'),
                  _chips(
                    AppFeedback.schools,
                    _school,
                    (v) => setState(() => _school = v),
                    'fb-school',
                  ),
                  if (_school == FeedbackScreen.other)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.s),
                      child: TextField(
                        key: const ValueKey('fb-school-other'),
                        controller: _schoolOther,
                        maxLength: AppFeedback.maxSchool,
                        decoration: _deco('高校名', hint: '〇〇高校'),
                      ),
                    ),
                  const SectionTitle('クラス'),
                  _chips(
                    AppFeedback.classes,
                    _class,
                    (v) => setState(() => _class = v),
                    'fb-class',
                  ),
                  if (_class == FeedbackScreen.other)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.s),
                      child: TextField(
                        key: const ValueKey('fb-class-other'),
                        controller: _classOther,
                        maxLength: AppFeedback.maxClass,
                        decoration: _deco('クラス', hint: '2-3、先生 など'),
                      ),
                    ),
                  const SectionTitle('ニックネーム'),
                  TextField(
                    key: const ValueKey('fb-nickname'),
                    controller: _nickname,
                    maxLength: AppFeedback.maxNickname,
                    decoration: _deco('ニックネーム（なくてもよい）'),
                  ),
                  const SectionTitle('内容'),
                  TextField(
                    key: const ValueKey('fb-body'),
                    controller: _body,
                    minLines: 5,
                    maxLines: 12,
                    maxLength: AppFeedback.maxBody,
                    decoration: _deco('内容'),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.s),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: TsuzuriColors.wrong),
                      ),
                    ),
                  FilledButton.icon(
                    key: const ValueKey('fb-send'),
                    onPressed: _busy ? null : () => _send(backend),
                    icon: const Icon(Icons.send),
                    label: const Text('送る'),
                  ),
                  const SizedBox(height: Space.s),
                  Text(
                    '送った内容を読めるのは、つづりクエストの管理者だけです。',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 届いたフィードバックの一覧（管理者だけ。設定から開く）
class FeedbackListScreen extends StatelessWidget {
  const FeedbackListScreen({super.key, required this.backend});

  final NoticeBackend backend;

  static String _when(DateTime? t) => t == null
      ? ''
      : '${t.month}/${t.day} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('フィードバック（管理者）')),
    body: NotebookPaper(
      child: FutureBuilder<List<AppFeedback>>(
        future: backend.feedbacks(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data;
          if (list == null) {
            return const Center(child: Text('読めませんでした（管理者でログインしてください）'));
          }
          if (list.isEmpty) {
            return const Center(child: Text('まだ届いていません'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.margin,
              Space.m,
              Space.m,
              Space.xl,
            ),
            children: [
              Text('${list.length}件'),
              for (final f in list)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            f.school,
                            f.className,
                            if (f.nickname.isNotEmpty) f.nickname,
                          ].join('・'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(f.body),
                        const SizedBox(height: 4),
                        Text(
                          [
                            _when(f.at),
                            f.platform,
                            if (f.uid.isNotEmpty) 'ログインあり',
                          ].where((s) => s.isNotEmpty).join('・'),
                          style: TextStyle(
                            fontSize: 11,
                            color: TsuzuriColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
