import 'package:flutter/material.dart';

import '../app/services.dart';
import '../app/settings.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'design.dart';

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
              SwitchListTile(
                title: const Text('動きをへらす'),
                subtitle: const Text('画面のゆれ・点滅・大きな動きをおさえます'),
                value: s.reduceMotion,
                onChanged: (v) => store.update(s.copyWith(reduceMotion: v)),
              ),
              const SizedBox(height: Space.l),
              const Text(
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
