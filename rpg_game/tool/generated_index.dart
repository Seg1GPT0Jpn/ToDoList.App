// 自動で作る問題の索引（lib/src/generated/generated_index.dart）を作り直す。
// 問題ファイルを足したり単元を変えたりしたら実行する（テストが古い索引を見つける）。
//   dart run tool/generated_index.dart
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:rpg_game/src/generated/generated_index_builder.dart';

void main() {
  final sets = [
    for (final f in Directory('assets/questions')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json')))
      JsonQuestionSource.parse(f.readAsStringSync()),
  ];
  File('lib/src/generated/generated_index.dart')
      .writeAsStringSync(GeneratedIndexBuilder.source(sets));
  stdout.writeln('generated_index.dart を作り直しました');
}
