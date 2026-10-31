// 同梱の単語帳から番号の範囲だけを取り出し、別の名前・パスワードで暗号化しなおす。
//
//   dart run tool/vocab_subset.dart <元の名前> <元のパスワード> <最初の番号> <最後の番号> <新しい名前> <新しいパスワード> <出力フォルダ>
//
// 題名と単語の ID は元のままにする（学習記録を元の単語帳と共有するため）。
// 名前・パスワードはソースに書かないこと。
import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';

void main(List<String> args) {
  if (args.length != 7) {
    stderr.writeln(
        'usage: vocab_subset.dart <name> <password> <from> <to> <newName> <newPassword> <outDir>');
    exit(64);
  }
  final [name, password, from, to, newName, newPassword, outDir] = args;
  final dir = outDir;
  final src = File('$dir/${VocabVault.fileName(name)}.txt');
  final opened =
      VocabVault.open(base64Decode(src.readAsStringSync().trim()), password);
  if (opened == null) {
    stderr.writeln('cannot open $name');
    exit(1);
  }
  final lo = int.parse(from), hi = int.parse(to);
  final cards = [
    for (final c in opened.cards)
      if (c.number != null && c.number! >= lo && c.number! <= hi) c,
  ];
  final data = VocabVault.seal(opened.title, cards, newPassword,
      worldId: opened.worldId);
  final out = File('$dir/${VocabVault.fileName(newName)}.txt')
    ..writeAsStringSync(base64Encode(data));
  stdout.writeln(
      '${opened.title}: ${cards.length} words ($lo-$hi) -> ${out.path}');
}
