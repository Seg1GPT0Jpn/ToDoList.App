// 貼り付けた単語一覧を、名前とパスワードで暗号化した同梱データにする。
//
//   dart run tool/vocab_seal.dart <名前> <パスワード> <一覧.txt> <出力フォルダ>
//
// 平文の一覧はコミットしないこと。出力（暗号化したもの）だけを assets/vocab/ に置く。
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';

void main(List<String> args) {
  if (args.length != 4) {
    stderr.writeln(
        'usage: vocab_seal.dart <name> <password> <list.txt> <outDir>');
    exit(64);
  }
  final [name, password, input, outDir] = args;
  final cards = VocabParser.parse(File(input).readAsStringSync());
  final data = VocabVault.seal(name, cards, password);
  final out = File('$outDir/${VocabVault.fileName(name)}.bin')
    ..writeAsBytesSync(data);
  stdout.writeln('${cards.length} words -> ${out.path}');
}
