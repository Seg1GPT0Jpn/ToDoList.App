import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/services.dart';
import '../app/theme.dart';
import 'notice_backend.dart';

/// ホームに出す、管理者からのお知らせ（なければ何も出さない）。
/// 「とじる」を押すと、同じお知らせはこの端末では出さない
class NoticeCard extends StatefulWidget {
  const NoticeCard({super.key});

  /// 「とじる」を押したお知らせの id
  static const dismissedKey = 'notice_dismissed_v1';

  @override
  State<NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<NoticeCard> {
  NoticeBackend? _backend;
  AppNotice? _notice;
  TesterSignup? _mine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final b = RpgServices.of(context).notices;
    if (b != _backend) {
      _backend = b;
      _load();
    }
  }

  Future<void> _load() async {
    final b = _backend;
    if (b == null) return;
    final n = await b.load();
    final prefs = await SharedPreferences.getInstance();
    final mine = n?.testerSignup == true ? await b.mySignup() : null;
    if (!mounted || b != _backend) return;
    setState(() {
      _notice =
          n == null ||
              !n.enabled ||
              prefs.getString(NoticeCard.dismissedKey) == n.id
          ? null
          : n;
      _mine = mine;
    });
  }

  Future<void> _dismiss() async {
    final n = _notice;
    if (n == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NoticeCard.dismissedKey, n.id);
    if (mounted) setState(() => _notice = null);
  }

  Future<void> _signup() async {
    final b = _backend;
    if (b == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (b.userId == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('申しこむには、ホームの名前から Google ログインしてください')),
      );
      return;
    }
    final name = RpgServices.of(context).profiles.load().userName;
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => TesterSignupDialog(
        backend: b,
        name: name,
        initial: _mine?.email ?? b.email ?? '',
      ),
    );
    if (sent == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('申しこみを受けつけました。ありがとうございます！')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _notice;
    if (n == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: const ValueKey('notice-card'),
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
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
                Icon(Icons.campaign_outlined, color: TsuzuriColors.exp),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    n.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('notice-dismiss'),
                  tooltip: 'とじる',
                  visualDensity: VisualDensity.compact,
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                n.body,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            if (n.testerSignup || n.linkUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (n.testerSignup)
                      FilledButton.icon(
                        key: const ValueKey('notice-signup'),
                        onPressed: _signup,
                        icon: Icon(
                          _mine == null ? Icons.how_to_reg : Icons.check,
                          size: 18,
                        ),
                        label: Text(
                          _mine == null ? 'テスターに申しこむ' : '申しこみずみ（変える）',
                        ),
                      ),
                    if (n.linkUrl.isNotEmpty)
                      OutlinedButton.icon(
                        key: const ValueKey('notice-link'),
                        onPressed: () => launchUrl(
                          Uri.parse(n.linkUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(n.linkLabel.isEmpty ? 'ひらく' : n.linkLabel),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// テスターに申しこむ（Google Play で使う Gmail を送る）
class TesterSignupDialog extends StatefulWidget {
  const TesterSignupDialog({
    super.key,
    required this.backend,
    required this.name,
    required this.initial,
  });

  final NoticeBackend backend;
  final String name;
  final String initial;

  @override
  State<TesterSignupDialog> createState() => _TesterSignupDialogState();
}

class _TesterSignupDialogState extends State<TesterSignupDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (!TesterSignup.validEmail(email)) {
      setState(() => _error = 'メールアドレスの形になっていません');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.backend.signup(email, widget.name);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '送れませんでした。インターネットにつながっているか確かめてください';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('テスターに申しこむ'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Android のスマホの Google Play で使っている Gmail を入れてください。'
          '学校のアカウントでは参加できないことがあります。',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('tester-email'),
          controller: _ctrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Gmail',
            hintText: 'example@gmail.com',
            errorText: _error,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('やめる'),
      ),
      FilledButton(
        key: const ValueKey('tester-send'),
        onPressed: _busy ? null : _send,
        child: const Text('送る'),
      ),
    ],
  );
}
