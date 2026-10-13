import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

/// 委員会の新作問題（setId に `_shonan_` を含むセット）と、全セット共通の決まりを確かめる。
/// 新作問題の追加手順は docs/SHONAN_EXAM_MODE.md。
void main() {
  final files = Directory('assets/questions')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();
  final bundles = <String, Map<String, dynamic>>{};
  Map<String, dynamic> bundle(String world) => bundles[world] ??=
      jsonDecode(File('assets/question_bundles/$world.json').readAsStringSync())
          as Map<String, dynamic>;

  test('すべての問題セットは、setId の先頭・worldId・置き場所の教科が一致する', () {
    for (final f in files) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final world = f.parent.path.split(Platform.pathSeparator).last;
      expect(m['worldId'], world, reason: f.path);
      expect((m['setId'] as String).startsWith('${m['worldId']}_'), isTrue,
          reason: f.path);
    }
  });

  final school = [
    for (final f in files)
      if (f.path.contains('_shonan_')) f,
  ];

  test('委員会の新作セットは決まりどおり（${school.length}セット）', () {
    final seen = <String, String>{};
    for (final f in school) {
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final set = QuestionSet.fromJson(m);
      final where = f.path;
      expect(set.origin, QuestionOrigin.original, reason: where);
      expect(set.setId, f.uri.pathSegments.last.replaceAll('.json', ''),
          reason: where);
      // 問題バンドルに入っていないと、アプリで読めない
      expect(bundle(set.worldId).containsKey(set.setId), isTrue,
          reason: '$where がバンドルにありません（tool/bundle_questions.py を実行）');
      for (final q in set.questions) {
        expect(seen[q.id], isNull, reason: '問題ID ${q.id} が ${seen[q.id]} と重複');
        seen[q.id] = set.setId;
        expect(q.explanation?.trim(), isNotEmpty, reason: '${q.id} に解説がない');
        expect(q.prompt.trim(), isNotEmpty, reason: q.id);
      }
    }
  });
}
