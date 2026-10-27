// 学校のドライブのリンクを暗号化して、lib/src/study/school_drive.dart に貼る文字列を出す。
//
//   dart run tool/drive_seal.dart <パスワード> <links.json>
//
// links.json は [{"t": "名前", "u": "https://drive.google.com/...", "g": "教科"}, ...]。
// パスワードもリンクの一覧も、リポジトリには入れないこと。
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:rpg_game/rpg_game.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('使い方: dart run tool/drive_seal.dart <パスワード> <links.json>');
    exit(64);
  }
  final list = jsonDecode(File(args[1]).readAsStringSync()) as List;
  final links = [
    for (final m in list) SchoolDriveLink.fromMap(m)!,
  ];
  final key = SchoolMaterials.keyFor(args[0]);
  final r = Random.secure();
  final sealed = SchoolDrive.seal(
    links,
    [for (var i = 0; i < 16; i++) r.nextInt(256)],
    key,
  );
  if (SchoolDrive.open(key, data: sealed)?.length != links.length) {
    stderr.writeln('開きなおせませんでした');
    exit(1);
  }
  stdout.writeln(sealed);
}
