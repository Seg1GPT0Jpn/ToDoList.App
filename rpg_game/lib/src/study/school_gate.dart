import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../vocab/vocab_vault.dart';

/// 学校専用の定期テスト対策を開く合言葉（学校名とパスワード）。
///
/// 学校名もパスワードもソースには書かず、ハッシュだけを置く（だれの学校かを
/// アプリから読み取れないようにするため）。全角・半角、大文字・小文字、空白のちがいは区別しない。
abstract final class SchoolGate {
  static const _hashes = {
    '4eec16a5a143b72e875fd096fe30983a237cb53cd563da3b9d0719130e618266',
  };

  static String _norm(String s) =>
      VocabVault.halfWidth(s).replaceAll(RegExp(r'\s+'), '').toLowerCase();

  /// 学校名とパスワードが合っているか
  static bool matches(String school, String password) => _hashes.contains(
        sha256
            .convert(utf8.encode(
                'tsuzuri-school:${_norm(school)}|${_norm(password)}'))
            .toString(),
      );
}
