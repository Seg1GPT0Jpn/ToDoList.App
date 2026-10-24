import 'package:flutter/material.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'account_screen.dart';

/// はじめての起動：Google でログインするか、ログインせずにはじめるかを選ぶ。
///
/// Google でログインすると記録がクラウドに保存され、別の端末でも続きができる。
/// どちらを選んでも閉じれば冒険（ワールドマップ）がはじまる。
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    final account = await linkGoogleAccount(context);
    if (!mounted) return;
    setState(() => _busy = false);
    if (account != null) Navigator.of(context).pop();
  }

  Future<void> _guest() async {
    await askUserName(context);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final real = RpgServices.of(context).account.isReal;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: NotebookPaper(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.auto_stories, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'つづりクエスト',
                        textAlign: TextAlign.center,
                        style: serif(30),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '問題を解いて魔物をたおす、学びの冒険へようこそ！',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: TsuzuriColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (real) ...[
                        FilledButton.icon(
                          key: const ValueKey('welcome-google'),
                          onPressed: _busy ? null : _google,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: const Text('Google でログイン'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '記録がクラウドに保存され、別の端末でも続きから遊べます。'
                          '購入したワールドの復元にも使います。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: TsuzuriColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      OutlinedButton(
                        key: const ValueKey('welcome-guest'),
                        onPressed: _busy ? null : _guest,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('ログインせずにはじめる'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '記録はこの端末の中だけに保存されます。'
                        'あとから「アカウント」でいつでもログインできます。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: TsuzuriColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
