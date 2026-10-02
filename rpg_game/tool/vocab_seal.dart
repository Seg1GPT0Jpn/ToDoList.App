// 貼り付けた単語一覧を、名前とパスワードで暗号化した同梱データにする。
//
//   dart run tool/vocab_seal.dart <名前> <パスワード> <一覧.txt> <出力フォルダ> [題名]
//
// 一覧が .json なら VocabCard.toJson の配列として読む（例文・豆知識つきの単語帳用）。
//
// 平文の一覧はコミットしないこと。出力（暗号化したもの）だけを assets/vocab/ に置く。
import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';

void main(List<String> args) {
  if (args.length != 4 && args.length != 5) {
    stderr.writeln(
        'usage: vocab_seal.dart <name> <password> <list> <outDir> [title]');
    exit(64);
  }
  final [name, password, input, outDir, ...rest] = args;
  final text = File(input).readAsStringSync();
  final cards = input.endsWith('.json')
      ? [
          for (final c in jsonDecode(text) as List)
            VocabCard.fromJson(c as Map<String, dynamic>),
        ]
      : VocabParser.parse(text);
  final data =
      VocabVault.seal(rest.isEmpty ? name : rest.first, cards, password);
  final out = File('$outDir/${VocabVault.fileName(name)}.txt')
    ..writeAsStringSync(base64Encode(data));
  stdout.writeln('${cards.length} words -> ${out.path}');
}
