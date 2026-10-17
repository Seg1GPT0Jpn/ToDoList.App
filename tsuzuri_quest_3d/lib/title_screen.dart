import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import 'field/field3d_screen.dart';
import 'game/save3d.dart';

/// タイトル画面：冒険をはじめる・データを消す
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  Save3D? _save;

  @override
  void initState() {
    super.initState();
    Save3D.open().then((s) {
      if (mounted) setState(() => _save = s);
    });
  }

  Future<void> _play() async {
    final save = _save!;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => Field3DScreen(save: save)));
    if (mounted) setState(() {});
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('3D版のデータを消す'),
        content: const Text(
          'つづりクエスト3Dのレベル・位置・倒した敵・クエスト・学習記録を消して、最初からにします。\n'
          '2D版「つづりクエスト」のデータは消えません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('title-reset-ok'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('消す'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _save!.reset();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final save = _save;
    final p = save?.loadProgress() ?? RpgProgress.initial;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FB8EE), Color(0xFFCFE8C0), Color(0xFF6FAE5A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'つづりクエスト3D',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF26402C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '技術検証の試作版',
                    style: TextStyle(color: Color(0xFF26402C)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lv${p.level}　経験値 ${p.exp} / ${PlayerStats.expToNextLevel(p.level)}',
                    key: const ValueKey('title-level'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const ValueKey('title-play'),
                    onPressed: save == null ? null : _play,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      save?.hasField == true ? 'つづきから' : '冒険をはじめる',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const ValueKey('title-reset'),
                    onPressed: save == null ? null : _reset,
                    child: const Text('3D版のデータを消す'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
