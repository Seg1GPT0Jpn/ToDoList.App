import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../cloud/cloud_sync.dart';
import '../cloud/sync_status.dart';

/// 同期のようす：クラウドにつながっているか・ログインしているアカウント・最後に送った／受けとった時刻・
/// エラー。同期がうまくいかないとき、どこで止まっているかを見るために出す
class SyncStatusCard extends StatefulWidget {
  const SyncStatusCard({super.key});

  @override
  State<SyncStatusCard> createState() => _SyncStatusCardState();
}

class _SyncStatusCardState extends State<SyncStatusCard> {
  var _busy = false;

  static String _time(DateTime? t) {
    if (t == null) return 'まだ';
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final day = t.year == now.year && t.month == now.month && t.day == now.day
        ? ''
        : '${t.month}/${t.day} ';
    return '$day${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  Future<void> _syncNow() async {
    final sync = CloudSync.instance;
    if (sync == null) return;
    setState(() => _busy = true);
    try {
      await sync.syncNow().timeout(const Duration(seconds: 20));
    } catch (e) {
      syncError('今すぐ同期', e);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: syncStatus,
      builder: (context, s, _) {
        final ok = s.connected == true && s.email != null && s.error == null;
        final rows = <(String, String)>[
          (
            'クラウド',
            switch (s.connected) {
              null => 'つないでいます…',
              true => 'つながっています',
              false => 'つながっていません',
            },
          ),
          ('ログイン', s.email ?? 'していません（同期するには Google でログイン）'),
          ('最後に送った', _time(s.lastSent)),
          ('最後に受けとった', _time(s.lastReceived)),
          ('最後にまとめて読んだ', _time(s.lastPulled)),
        ];
        return Card(
          key: const ValueKey('sync-status'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      ok ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                      color: ok ? TsuzuriColors.correct : TsuzuriColors.wrong,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('同期のようす', style: serif(15))),
                  ],
                ),
                const SizedBox(height: 6),
                for (final (k, v) in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 118,
                          child: Text(
                            k,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: TsuzuriColors.inkSoft,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            v,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (s.error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '問題：${s.error}（${_time(s.errorAt)}）',
                    key: const ValueKey('sync-error'),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: TsuzuriColors.wrong,
                      height: 1.5,
                    ),
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const ValueKey('sync-now'),
                    onPressed: CloudSync.instance == null || _busy
                        ? null
                        : _syncNow,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: const Text('今すぐ同期'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
