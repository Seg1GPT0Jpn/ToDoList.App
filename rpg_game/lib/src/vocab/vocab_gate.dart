import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 市販教材を取り込む単語帳（LEAP・EEVI）のパスワード。
///
/// パスワードそのものはソースに書かず、ハッシュ値だけを持つ。
/// アプリの中で照合するしくみなので、強い保護ではない。
class VocabGate {
  const VocabGate._();

  static const _salt = 'tsuzuri-vocab:';
  static const _hash =
      '98be3649c255eb4999bec7b2071fec645e693abc237c92addeee928d9f4c1ac0';

  static bool check(String input) {
    final v = input.trim();
    if (v.isEmpty) return false;
    return sha256.convert(utf8.encode('$_salt$v')).toString() == _hash;
  }
}
