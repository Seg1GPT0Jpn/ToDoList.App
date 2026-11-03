import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../audio/music_scope.dart';
import '../field/field_screen.dart';
import '../vocab/vocab_book_screen.dart';
import '../vocab/vocab_store.dart';
import '../vocab/word_forest_screen.dart' show loadWordList;
import 'gate_screen.dart';

/// 英検の単語帳1冊を、単語帳の画面で開ける形にする（毎回同梱のファイルから作る。保存しない）
Future<VocabBook> eikenBook(EikenList l) async {
  final list = await loadWordList(l.id);
  return VocabBook(
    id: l.id,
    title: l.title,
    kind: VocabBookKind.custom,
    cards: [
      for (final (i, w) in list.words.indexed)
        VocabCard(
          id: '${l.id}:${w.term}',
          number: w.number ?? i + 1,
          term: w.term,
          meaning: w.meaning,
          example: w.example,
          exampleJa: w.exampleJa,
        ),
    ],
  );
}

/// 英検の扉の向こう：級ごとの単語帳と、単語のバトル（英検の世界）
class EikenDoorScreen extends StatefulWidget {
  const EikenDoorScreen({super.key});

  @override
  State<EikenDoorScreen> createState() => _EikenDoorScreenState();
}

class _EikenDoorScreenState extends State<EikenDoorScreen> {
  late final Future<RpgProgress> _progress = RpgServices.of(context).repository
      .load();

  Future<void> _openBook(EikenList l) async {
    final services = RpgServices.of(context);
    final nav = Navigator.of(context);
    final book = await eikenBook(l);
    await nav.push(
      MaterialPageRoute<void>(
        builder: (_) => VocabBookScreen(
          store: VocabStore.of(services.personalBooks),
          book: book,
          editable: false,
        ),
      ),
    );
  }

  Future<void> _battle() async {
    final progress = await _progress;
    if (!mounted) return;
    final world = RpgCatalog.world(Eiken.worldId);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MusicScope(
          music: 'field_english',
          child: FieldScreen(world: world, progress: progress),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GateColors.sky,
      appBar: AppBar(
        backgroundColor: GateColors.sky,
        foregroundColor: GateColors.text,
        title: Text('英検の世界', style: serif(18, color: GateColors.text)),
      ),
      body: FutureBuilder<RpgProgress>(
        future: _progress,
        builder: (context, snap) {
          final progress = snap.data;
          final stages = RpgCatalog.world(Eiken.worldId).stages;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const Text(
                '英検の準2級・2級・準1級・1級の単語帳。実際に使われる頻度の高い単語から級ごとに選んだ。'
                '単語帳で覚えて、単語のバトルで力試しをしよう。',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: GateColors.soft,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('eiken-battle'),
                style: FilledButton.styleFrom(
                  backgroundColor: GateColors.gold,
                  foregroundColor: GateColors.sky,
                ),
                onPressed: _battle,
                icon: const Icon(Icons.sports_martial_arts),
                label: Text(
                  progress == null
                      ? '単語のバトルへ（英検の世界）'
                      : '単語のバトルへ（クリア ${stages.where((s) => progress.clearedStageIds.contains(s.id)).length} / ${stages.length}）',
                ),
              ),
              const SizedBox(height: 16),
              for (final MapEntry(key: route, value: name)
                  in Eiken.levels.entries)
                if (Eiken.ofLevel(route).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: GateColors.deep,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '英検$name（${Eiken.wordCount(route)}語）',
                              style: serif(17, color: GateColors.text),
                            ),
                            const SizedBox(height: 6),
                            for (final l in Eiken.ofLevel(route))
                              ListTile(
                                key: ValueKey('eiken-book-${l.id}'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.menu_book,
                                  color: GateColors.gold,
                                ),
                                title: Text(
                                  l.title,
                                  style: const TextStyle(
                                    color: GateColors.text,
                                  ),
                                ),
                                subtitle: Text(
                                  l.description,
                                  style: const TextStyle(
                                    color: GateColors.soft,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: GateColors.glow,
                                ),
                                onTap: () => _openBook(l),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
