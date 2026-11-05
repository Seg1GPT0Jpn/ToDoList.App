import 'dart:async';

import 'package:flutter/material.dart';

import '../app/edition.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'design.dart';

/// データをリセットする画面（設定から開く）。
///
/// まちがえて消さないように、ゲーム機のセーブデータの削除と同じく
/// 「開く → 数秒待つと赤いボタンが出る → 本当に削除するか聞く → 削除」の順にする。
class ResetDataScreen extends StatefulWidget {
  const ResetDataScreen({super.key});

  /// 赤いボタンが出るまで待つ時間
  static const wait = Duration(seconds: 3);

  @override
  State<ResetDataScreen> createState() => _ResetDataScreenState();
}

class _ResetDataScreenState extends State<ResetDataScreen> {
  late int _left = ResetDataScreen.wait.inSeconds;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static const _danger = Color(0xFFC62828);

  String get _what =>
      lightEdition ? '学習記録（解いた問題・正解率・連続記録など）' : 'レベル・クリア状況・購入状況・学習記録・図鑑';

  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const ValueKey('reset-confirm'),
        title: const Text('データを本当に削除しますか？'),
        content: Text('$_whatをすべて消して、最初からにします。\n削除したデータは元に戻せません。'),
        actions: [
          TextButton(
            key: const ValueKey('reset-cancel'),
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('reset-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final services = RpgServices.of(context);
    await services.repository.reset();
    await services.meta.reset();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('データをリセットしました')));
  }

  @override
  Widget build(BuildContext context) {
    final ready = _left <= 0;
    return Scaffold(
      appBar: AppBar(title: const Text('データをリセット')),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.margin,
            Space.l,
            Space.margin,
            Space.xl,
          ),
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48, color: _danger),
            const SizedBox(height: Space.m),
            Text(
              '$_whatをすべて消して、最初からにします。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: Space.s),
            const Text(
              '削除したデータは元に戻せません。',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: _danger),
            ),
            const SizedBox(height: Space.xl),
            SizedBox(
              height: 52,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ready
                    ? FilledButton.icon(
                        key: const ValueKey('reset-data'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _busy ? null : _confirm,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('データをリセット'),
                      )
                    : Column(
                        key: const ValueKey('reset-wait'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'よく確かめてください（あと$_left秒）',
                            style: TextStyle(
                              fontSize: 13,
                              color: TsuzuriColors.inkSoft,
                            ),
                          ),
                          const SizedBox(height: Space.s),
                          LinearProgressIndicator(
                            value: 1 - _left / ResetDataScreen.wait.inSeconds,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: Space.m),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('やめる'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
