import 'dart:convert';

import 'package:crypto/crypto.dart';

/// プロモーションコード。課金しない人が、コードを入力して有料ワールドを受け取る。
///
/// コードそのものはソースに書かず、ハッシュ値だけを持つ。
/// ただし Web やアプリの中で照合するしくみなので、強い保護ではない
/// （本格的に配るときは Cloud Functions でサーバー側で照合する）。
class PromoCodes {
  const PromoCodes._();

  static const _salt = 'tsuzuri-promo:';

  /// 有料の5教科（理科・社会・国語・数学・情報）をまとめて受け取れるコード
  static const _allSubjectsHash =
      '85c5bd199f582cf7778e1ff64b9d0d718a5c4c67951084ee54e0826f6c8f2e1b';

  /// 全角数字・空白・ハイフンのゆれをそろえる
  static String normalize(String input) {
    final buf = StringBuffer();
    for (final r in input.runes) {
      if (r >= 0xFF10 && r <= 0xFF19) {
        buf.writeCharCode(r - 0xFF10 + 0x30); // 全角数字 → 半角
      } else if (r >= 0xFF21 && r <= 0xFF3A) {
        buf.writeCharCode(r - 0xFF21 + 0x41); // 全角英大文字 → 半角
      } else if (r >= 0xFF41 && r <= 0xFF5A) {
        buf.writeCharCode(r - 0xFF41 + 0x41); // 全角英小文字 → 半角大文字
      } else if (' 　-‐－ー'.runes.contains(r)) {
        continue;
      } else {
        buf.writeCharCode(r);
      }
    }
    return buf.toString().toUpperCase();
  }

  /// 有料の5教科をまとめて受け取れるコードかどうか
  static bool unlocksAllSubjects(String input) {
    final code = normalize(input);
    if (code.isEmpty) return false;
    final hash = sha256.convert(utf8.encode('$_salt$code')).toString();
    return hash == _allSubjectsHash;
  }
}
