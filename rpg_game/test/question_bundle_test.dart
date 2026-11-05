import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// アプリが読むのは教科ごとのまとめファイル（assets/question_bundles）。
/// 問題ファイルを直したのにまとめ直し忘れると、アプリに反映されない。
void main() {
  final worlds = Directory('assets/questions')
      .listSync()
      .whereType<Directory>()
      .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .toList()
    ..sort();

  test('教科ごとのまとめファイルが、問題ファイルとそろっている', () {
    expect(worlds, isNotEmpty);
    for (final w in worlds) {
      final bundleFile = File('assets/question_bundles/$w.json');
      expect(
        bundleFile.existsSync(),
        isTrue,
        reason: 'python3 tool/bundle_questions.py を実行してください（$w）',
      );
      final bundle =
          jsonDecode(bundleFile.readAsStringSync()) as Map<String, dynamic>;
      final files = Directory('assets/questions/$w')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      expect(
        bundle.keys.toSet(),
        files
            .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
            .toSet(),
        reason: 'python3 tool/bundle_questions.py を実行してください（$w）',
      );
      for (final f in files) {
        final id = f.uri.pathSegments.last.replaceAll('.json', '');
        expect(
          bundle[id],
          jsonDecode(f.readAsStringSync()),
          reason: '$id がまとめファイルと食いちがっています。'
              'python3 tool/bundle_questions.py を実行してください',
        );
      }
    }
  });

  test('問題ファイルのない教科のまとめファイルは残っていない', () {
    final bundles = Directory('assets/question_bundles')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
        .toSet();
    expect(bundles, worlds.toSet());
  });
}
