// 予想問題（ページ画像と解答用紙）を暗号化して、アプリに同梱するファイルを作る。
//
//   dart run tool/mock_exam_seal.dart <パスワード> <sheet.json> <ページ画像のフォルダ> <出力フォルダ>
//
// ページ画像のフォルダには 01.webp, 02.webp … を問題冊子→解答・解説の順に置く。
// パスワードも、暗号化する前のファイルも、リポジトリには入れないこと。
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

void main(List<String> args) {
  if (args.length != 4) {
    stderr.writeln(
      '使い方: dart run tool/mock_exam_seal.dart <パスワード> <sheet.json> <画像フォルダ> <出力フォルダ>',
    );
    exit(64);
  }
  final key = SchoolMaterials.keyFor(args[0]);
  final r = Random.secure();
  List<int> nonce() => [for (var i = 0; i < 16; i++) r.nextInt(256)];
  final json = File(args[1]).readAsStringSync();
  final sheet = MockSheet.fromJson(json); // 読めるか確かめる
  final out = Directory(args[3])..createSync(recursive: true);
  File('${out.path}/sheet.bin').writeAsBytesSync(
    SchoolMaterials.seal(utf8.encode(json), nonce(), key: key),
  );
  final pages = Directory(args[2])
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.webp'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (var i = 0; i < pages.length; i++) {
    final name = (i + 1).toString().padLeft(2, '0');
    File('${out.path}/$name.bin').writeAsBytesSync(
      SchoolMaterials.seal(pages[i].readAsBytesSync(), nonce(), key: key),
    );
  }
  stdout.writeln(
    '${pages.length} ページ・${sheet.items.length} 欄（${sheet.total} 点）',
  );
}
