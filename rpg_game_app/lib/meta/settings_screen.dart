import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/edition.dart';
import '../app/services.dart';
import '../app/settings.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'design.dart';
import 'reminder.dart';
import 'reset_data_screen.dart';

/// 設定（音・文字の大きさ・動き）
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final store = services.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: NotebookPaper(
        child: ValueListenableBuilder<AppSettings>(
          valueListenable: store,
          builder: (context, s, _) => ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.margin,
              Space.m,
              Space.m,
              Space.xl,
            ),
            children: [
              // Light のむずかしさは、1回に解く問題の量（定期テストの海・復習など）
              if (lightEdition) ...[
                const SectionTitle('むずかしさ（1回の問題の量）'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: SegmentedButton<String>(
                    key: const ValueKey('quiz-amount'),
                    segments: [
                      for (final (id, label) in const [
                        ('easy', 'かんたん'),
                        ('normal', 'ふつう'),
                        ('hard', 'むずかしい'),
                      ])
                        ButtonSegment(
                          value: id,
                          label: Text(
                            '$label\n${AppSettings.quizAmounts[id]}問',
                          ),
                        ),
                    ],
                    selected: {s.quizAmount},
                    onSelectionChanged: (v) =>
                        store.update(s.copyWith(quizAmount: v.first)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '定期テストの海・復習などで、1回に解く問題の数です（まちがえた問題はもう一度出ます）',
                    style: TextStyle(
                      fontSize: 12,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ),
                const SizedBox(height: Space.l),
              ],
              // Light は音を使わないので、音の設定は出さない
              if (!lightEdition) ...[
                const SectionTitle('音'),
                SwitchListTile(
                  title: const Text('BGM'),
                  value: s.bgm,
                  onChanged: (v) => store.update(s.copyWith(bgm: v)),
                ),
                _slider(
                  'BGM の音量',
                  s.bgmVolume,
                  s.bgm,
                  (v) => store.update(s.copyWith(bgmVolume: v)),
                ),
                SwitchListTile(
                  title: const Text('効果音'),
                  value: s.se,
                  onChanged: (v) => store.update(s.copyWith(se: v)),
                ),
                _slider('効果音の音量', s.seVolume, s.se, (v) {
                  store.update(s.copyWith(seVolume: v));
                }, onEnd: () => services.music.se('se_correct')),
                SwitchListTile(
                  title: const Text('学ぶほど曲が完成する'),
                  subtitle: const Text('バトルで正解を続けると、ベース・打楽器・ストリングスが加わります'),
                  value: s.adaptiveMusic,
                  onChanged: (v) => store.update(s.copyWith(adaptiveMusic: v)),
                ),
                const SizedBox(height: Space.l),
              ],
              const SectionTitle('見やすさ'),
              ListTile(
                title: const Text('文字の大きさ'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: Space.s),
                  child: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 1.0, label: Text('ふつう')),
                      ButtonSegment(value: 1.15, label: Text('大きい')),
                      ButtonSegment(value: 1.3, label: Text('とても大きい')),
                    ],
                    selected: {
                      AppSettings.textScales.reduce(
                        (a, b) =>
                            (a - s.textScale).abs() <= (b - s.textScale).abs()
                            ? a
                            : b,
                      ),
                    },
                    onSelectionChanged: (v) =>
                        store.update(s.copyWith(textScale: v.first)),
                  ),
                ),
              ),
              ListTile(
                title: const Text('画面の明るさ'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: Space.s),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'system',
                        icon: Icon(Icons.brightness_auto),
                        label: Text('端末に合わせる'),
                      ),
                      ButtonSegment(
                        value: 'light',
                        icon: Icon(Icons.light_mode),
                        label: Text('ライト'),
                      ),
                      ButtonSegment(
                        value: 'dark',
                        icon: Icon(Icons.dark_mode),
                        label: Text('ダーク'),
                      ),
                    ],
                    selected: {s.theme},
                    onSelectionChanged: (v) =>
                        store.update(s.copyWith(theme: v.first)),
                  ),
                ),
              ),
              // Light は動き・バトル・振動・冒険の手帳がないので、これらの設定は出さない
              if (!lightEdition) ...[
                SwitchListTile(
                  title: const Text('動きをへらす'),
                  subtitle: const Text('画面のゆれ・点滅・大きな動きをおさえます'),
                  value: s.reduceMotion,
                  onChanged: (v) => store.update(s.copyWith(reduceMotion: v)),
                ),
                ListTile(
                  title: const Text('バトルのむずかしさ'),
                  subtitle: Text(
                    s.difficulty == 'hard'
                        ? '敵のHP・攻撃が上がり、答える時間が短くなります。経験値は1.3倍、クリアしたエリアに👑がつきます'
                        : '正答率が5割くらいでも、少しずつ進めるむずかしさです',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SegmentedButton<String>(
                    key: const ValueKey('difficulty'),
                    segments: [
                      for (final d in BattleDifficulty.values)
                        ButtonSegment(
                          value: d.name,
                          label: Text(d.label),
                          icon: Icon(
                            d == BattleDifficulty.hard
                                ? Icons.local_fire_department
                                : Icons.sentiment_satisfied,
                          ),
                        ),
                    ],
                    selected: {BattleDifficulty.byName(s.difficulty).name},
                    onSelectionChanged: (v) =>
                        store.update(s.copyWith(difficulty: v.first)),
                  ),
                ),
                SwitchListTile(
                  key: const ValueKey('vibration'),
                  title: const Text('振動'),
                  subtitle: const Text('正解・ダメージ・勝利のときに、端末を軽くふるわせます'),
                  value: s.vibration,
                  onChanged: (v) => store.update(s.copyWith(vibration: v)),
                ),
                SwitchListTile(
                  key: const ValueKey('all-features'),
                  title: const Text('すべての機能を表示'),
                  subtitle: const Text('ホームの「冒険の手帳」に、冒険を進めると出てくる機能も最初から全部出します'),
                  value: s.allFeatures,
                  onChanged: (v) => store.update(s.copyWith(allFeatures: v)),
                ),
              ],
              SwitchListTile(
                key: const ValueKey('share-usage'),
                title: const Text('使った機能の回数を送る'),
                subtitle: const Text(
                  'どの機能が使われているかを、名前やIDを付けずに日ごとの回数だけ送ります（アプリの改善に使います）',
                ),
                value: s.shareUsage,
                onChanged: (v) => store.update(s.copyWith(shareUsage: v)),
              ),
              const SectionTitle('お知らせ'),
              const ReminderTile(),
              const SectionTitle('学習レポート'),
              ListTile(
                key: const ValueKey('copy-report'),
                leading: const Icon(Icons.content_copy),
                title: const Text('学習レポートをコピー'),
                subtitle: const Text('保護者や先生に、LINE やメールで送れます'),
                onTap: () async {
                  final text = StudyReport.text(
                    services.meta.record,
                    RpgServices.today(),
                  );
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) return;
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('コピーしました'),
                      content: SingleChildScrollView(child: Text(text)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('とじる'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SectionTitle('データ'),
              ListTile(
                key: const ValueKey('reset-data-open'),
                leading: const Icon(Icons.delete_outline),
                title: const Text('データをリセット'),
                subtitle: const Text('記録をすべて消して、最初からにします'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ResetDataScreen(),
                  ),
                ),
              ),
              const SizedBox(height: Space.l),
              Text(
                '設定はこの端末だけに保存されます。',
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    bool enabled,
    ValueChanged<double> onChanged, {
    VoidCallback? onEnd,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Space.l),
    child: Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value,
            label: '${(value * 100).round()}',
            divisions: 10,
            onChanged: enabled ? onChanged : null,
            onChangeEnd: onEnd == null ? null : (_) => onEnd(),
          ),
        ),
      ],
    ),
  );
}
