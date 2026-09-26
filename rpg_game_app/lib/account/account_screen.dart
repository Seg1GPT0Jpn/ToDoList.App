import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';

/// アカウント：ユーザー名の変更と、Google アカウントの登録（連携）
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final _name = TextEditingController(
    text: RpgServices.of(context).profiles.load().userName,
  );
  String? _error;
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final error = PlayerProfile.validateName(_name.text);
    setState(() {
      _error = error;
      _saved = false;
    });
    if (error != null) return;
    final repo = RpgServices.of(context).profiles;
    await repo.save(repo.load().copyWith(userName: _name.text.trim()));
    if (mounted) setState(() => _saved = true);
  }

  Future<void> _linkGoogle() async {
    final services = RpgServices.of(context);
    final account = await services.account.signInWithGoogle(context);
    if (account == null) return;
    final p = services.profiles.load();
    await services.profiles.save(
      p.copyWith(
        googleEmail: account.email,
        googleDisplayName: account.displayName,
        linkedAt: DateTime.now(),
        // 名前がまだなければ Google の名前を仮に使う（あとで変えられる）
        userName: p.hasName
            ? null
            : account.displayName.characters
                  .take(PlayerProfile.maxNameLength)
                  .toString(),
      ),
    );
    if (!mounted) return;
    _name.text = services.profiles.load().userName;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${account.email} を登録しました')));
  }

  Future<void> _unlink() async {
    final services = RpgServices.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Google アカウントの登録を解除しますか？'),
        content: Text(
          services.account.isReal
              ? 'ログアウトします。この端末の記録も、クラウドの記録も消えません。'
                    'もう一度同じ Google アカウントで登録すると、クラウドの続きから遊べます。'
              : 'この端末の冒険の記録は消えません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('解除する'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await services.account.signOut();
    await services.profiles.save(
      services.profiles.load().copyWith(unlinkGoogle: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('アカウント', style: serif(18))),
      body: NotebookPaper(
        child: StreamBuilder<PlayerProfile>(
          stream: services.profiles.watch(),
          builder: (context, snap) {
            final p = snap.data ?? services.profiles.load();
            return ListView(
              padding: const EdgeInsets.fromLTRB(44, 16, 16, 24),
              children: [
                Text('ユーザー名', style: serif(16)),
                const SizedBox(height: 4),
                const Text(
                  'ゲームの中で呼ばれる名前です（1〜12文字）。',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: TsuzuriColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  maxLength: PlayerProfile.maxNameLength,
                  decoration: InputDecoration(
                    hintText: '例：つづり',
                    errorText: _error,
                    filled: true,
                    fillColor: TsuzuriColors.card,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _saveName(),
                ),
                Row(
                  children: [
                    if (_saved)
                      const Text(
                        '保存しました',
                        style: TextStyle(color: TsuzuriColors.correct),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _saveName,
                      child: const Text('名前を保存'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Google アカウント', style: serif(16)),
                const SizedBox(height: 4),
                const Text(
                  '登録しておくと、スマホを変えたときなどに冒険の記録を引きつげるようになります。',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: TsuzuriColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: Icon(
                      p.isGoogleLinked
                          ? Icons.verified_user
                          : Icons.account_circle_outlined,
                      color: p.isGoogleLinked
                          ? TsuzuriColors.correct
                          : TsuzuriColors.inkSoft,
                    ),
                    title: Text(
                      p.isGoogleLinked ? p.googleEmail! : 'まだ登録していません',
                    ),
                    subtitle: p.isGoogleLinked
                        ? const Text('登録ずみ')
                        : const Text('Google アカウントで登録できます'),
                    trailing: p.isGoogleLinked
                        ? TextButton(
                            onPressed: _unlink,
                            child: const Text('解除'),
                          )
                        : null,
                  ),
                ),
                if (!p.isGoogleLinked) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _linkGoogle,
                    icon: const Icon(Icons.login),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Google アカウントで登録'),
                    ),
                  ),
                ],
                if (!services.account.isReal)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      '※ Firebase が設定されていないため、Google への登録はテスト用のダミーです。'
                      '設定のしかたは README の「Firebase につなぐ」を見てください。',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: TsuzuriColors.inkSoft,
                        height: 1.5,
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
}

/// はじめて起動したときに名前を決めてもらう
Future<void> askUserName(BuildContext context) async {
  final repo = RpgServices.of(context).profiles;
  final controller = TextEditingController();
  String? error;
  final name = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (c) => StatefulBuilder(
      builder: (c, setState) => AlertDialog(
        title: const Text('ようこそ、つづりクエストへ！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('冒険者の名前を決めよう（あとで変えられます）。'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: PlayerProfile.maxNameLength,
              decoration: InputDecoration(hintText: '例：つづり', errorText: error),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('あとで'),
          ),
          FilledButton(
            onPressed: () {
              final e = PlayerProfile.validateName(controller.text);
              if (e != null) {
                setState(() => error = e);
                return;
              }
              Navigator.pop(c, controller.text.trim());
            },
            child: const Text('決定'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (name != null) await repo.save(repo.load().copyWith(userName: name));
}
