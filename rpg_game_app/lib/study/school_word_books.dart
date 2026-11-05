import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../vocab/vocab_book_screen.dart';
import '../vocab/vocab_store.dart';
import 'school_exam_store.dart';

/// テスト範囲の単語帳を開く。
///
/// 学校のパスワードを覚えていればそのまま開き、まだなら（前の版から開いていた端末など）
/// パスワードを一度だけたずねる。ふつうの単語帳と同じ画面で練習する。
Future<void> openSchoolWordBook(BuildContext context, SchoolWordBook w) async {
  final books = RpgServices.of(context).personalBooks;
  final store = SchoolExamStore.of(books);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final data = await VocabStore.assetLoader(w.file);
  if (data == null) {
    messenger.showSnackBar(const SnackBar(content: Text('単語帳を読み込めませんでした')));
    return;
  }
  final saved = store.secret;
  var book = saved == null ? null : w.open(data, saved);
  if (book == null) {
    if (!context.mounted) return;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _PasswordDialog(check: (p) => w.open(data, p) != null),
    );
    if (password == null) return;
    await store.saveSecret(password);
    book = w.open(data, password);
    if (book == null) return;
  }
  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => VocabBookScreen(
        store: VocabStore.of(books),
        book: book!,
        editable: false,
      ),
    ),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.check});

  final bool Function(String password) check;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.check(_text.text)) {
      Navigator.of(context).pop(_text.text);
    } else {
      setState(() => _error = 'パスワードがちがいます');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('学校のパスワード'),
    content: TextField(
      key: const ValueKey('school-words-password'),
      controller: _text,
      obscureText: true,
      autofocus: true,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: '試験対策を開くときのパスワード',
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('やめる'),
      ),
      FilledButton(
        key: const ValueKey('school-words-open'),
        onPressed: _submit,
        child: const Text('開く'),
      ),
    ],
  );
}
