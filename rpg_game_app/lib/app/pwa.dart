import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pwa_stub.dart' if (dart.library.js_interop) 'pwa_web.dart';
import 'theme.dart';

export 'pwa_stub.dart' show PwaInfo;

/// ブラウザで開いている iPhone の人に、ホーム画面に追加する方法を一度だけ案内する。
/// ホーム画面から開くと全画面になり、アプリのように使える
class AddToHomeHint extends StatefulWidget {
  const AddToHomeHint({super.key, this.info});

  /// テスト用（ふだんはブラウザから調べる）
  final PwaInfo? info;

  static const _key = 'pwa_hint_closed';

  @override
  State<AddToHomeHint> createState() => _AddToHomeHintState();
}

class _AddToHomeHintState extends State<AddToHomeHint> {
  bool _closed = true;

  @override
  void initState() {
    super.initState();
    final info = widget.info ?? pwaInfo();
    if (!info.ios || info.standalone) return;
    SharedPreferences.getInstance().then((p) {
      if (mounted && p.getBool(AddToHomeHint._key) != true) {
        setState(() => _closed = false);
      }
    });
  }

  Future<void> _close() async {
    setState(() => _closed = true);
    final p = await SharedPreferences.getInstance();
    await p.setBool(AddToHomeHint._key, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_closed) return const SizedBox.shrink();
    return Card(
      key: const ValueKey('pwa-hint'),
      color: TsuzuriColors.tint(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            const Icon(Icons.add_to_home_screen),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'ホーム画面に追加すると、アプリのように全画面で遊べます。\n'
                'Safari の下の「共有」ボタン →「ホーム画面に追加」',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
            IconButton(
              key: const ValueKey('pwa-hint-close'),
              tooltip: '閉じる',
              onPressed: _close,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
