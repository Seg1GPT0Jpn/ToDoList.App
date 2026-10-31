import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';

/// プロモーションコードを入力して、有料の5教科を受け取る。
Future<void> showPromoCodeDialog(BuildContext context) async {
  final services = RpgServices.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final got = await showDialog<List<WorldDef>>(
    context: context,
    builder: (_) => _PromoDialog(services: services),
  );
  if (got == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        got.isEmpty
            ? 'コードは正しいですが、もう全部受け取っています'
            : '${got.map((w) => w.name).join('・')}を受け取りました！',
      ),
    ),
  );
}

class _PromoDialog extends StatefulWidget {
  const _PromoDialog({required this.services});
  final RpgServices services;

  @override
  State<_PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<_PromoDialog> {
  // 何度もまちがえたら少し待ってもらう（総当たりの手間を増やす）
  static int _misses = 0;
  static DateTime? _lockedUntil;

  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final until = _lockedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      final s = until.difference(DateTime.now()).inSeconds + 1;
      setState(() => _error = 'まちがいが続いたので、$s秒待ってからもう一度入力してください');
      return;
    }
    setState(() => _busy = true);
    final got = <WorldDef>[];
    final outcome = await widget.services.unlock.redeemPromoCode(
      _code.text,
      RpgCatalog.worlds,
      newlyUnlocked: got,
    );
    if (!mounted) return;
    if (outcome == PromoOutcome.invalid) {
      _misses++;
      if (_misses >= 5) {
        _misses = 0;
        _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
      }
      setState(() {
        _busy = false;
        _error = 'コードがちがいます';
      });
      return;
    }
    _misses = 0;
    Navigator.pop(context, got);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.card_giftcard, size: 36),
      title: const Text('プロモーションコード'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'コードを入力すると、算数・数学・国語・理科・社会の4つのワールドを受け取れます。',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'コード',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _busy ? null : _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('やめる'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('受け取る'),
        ),
      ],
    );
  }
}
