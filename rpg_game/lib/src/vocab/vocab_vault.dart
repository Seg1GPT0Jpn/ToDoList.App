import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'vocab_book.dart';

/// 名前とパスワードで開く、暗号化された単語帳。
///
/// 市販教材（LEAP・EEVI）の単語は、平文ではアプリにも GitHub にも置かない。
/// パスワードから鍵を作り（PBKDF2-HMAC-SHA256）、HMAC-SHA256 の
/// カウンターモードで暗号化したものだけを同梱する。
/// パスワードを知らない人には、中身は読めない（パスワードはソースに書かない）。
///
/// 形式: 'TQV1' | salt(16) | nonce(16) | mac(32) | 暗号文
class VocabVault {
  const VocabVault._();

  static const iterations = 4000;
  static final _magic = ascii.encode('TQV1');

  /// 名前から同梱ファイルの名前を決める（名前の一覧もソースに置かない）
  static String fileName(String name) => sha256
      .convert(utf8.encode('tsuzuri-vocab-name:${name.trim().toLowerCase()}'))
      .toString()
      .substring(0, 16);

  static List<int> _pbkdf2(List<int> password, List<int> salt, int length) {
    final hmac = Hmac(sha256, password);
    final out = <int>[];
    for (var block = 1; out.length < length; block++) {
      var u = hmac.convert([...salt, ..._u32(block)]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.addAll(t);
    }
    return out.sublist(0, length);
  }

  static List<int> _u32(int v) =>
      [(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255];

  static Uint8List _xor(List<int> key, List<int> nonce, List<int> data) {
    final hmac = Hmac(sha256, key);
    final out = Uint8List(data.length);
    for (var i = 0, block = 0; i < data.length; block++) {
      final ks = hmac.convert([...nonce, ..._u32(block)]).bytes;
      for (var j = 0; j < ks.length && i < data.length; j++, i++) {
        out[i] = data[i] ^ ks[j];
      }
    }
    return out;
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var d = 0;
    for (var i = 0; i < a.length; i++) {
      d |= a[i] ^ b[i];
    }
    return d == 0;
  }

  /// 単語帳を暗号化する（同梱データを作る道具用）
  static Uint8List seal(
    String title,
    List<VocabCard> cards,
    String password, {
    Random? random,
  }) {
    final rnd = random ?? Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final nonce = List<int>.generate(16, (_) => rnd.nextInt(256));
    final keys = _pbkdf2(utf8.encode(password), salt, 64);
    final plain = utf8.encode(jsonEncode({
      'title': title,
      'cards': [for (final c in cards) c.toJson()],
    }));
    final cipher = _xor(keys.sublist(0, 32), nonce, plain);
    final mac = Hmac(sha256, keys.sublist(32))
        .convert([...salt, ...nonce, ...cipher]).bytes;
    return Uint8List.fromList(
        [..._magic, ...salt, ...nonce, ...mac, ...cipher]);
  }

  /// 開く。パスワードがちがう・壊れているときは null
  static ({String title, List<VocabCard> cards})? open(
    List<int> data,
    String password,
  ) {
    if (data.length < 68 || !_same(data.sublist(0, 4), _magic)) return null;
    final salt = data.sublist(4, 20);
    final nonce = data.sublist(20, 36);
    final mac = data.sublist(36, 68);
    final cipher = data.sublist(68);
    final keys = _pbkdf2(utf8.encode(password.trim()), salt, 64);
    final check = Hmac(sha256, keys.sublist(32))
        .convert([...salt, ...nonce, ...cipher]).bytes;
    if (!_same(check, mac)) return null;
    final j = jsonDecode(utf8.decode(_xor(keys.sublist(0, 32), nonce, cipher)))
        as Map<String, dynamic>;
    return (
      title: j['title'] as String,
      cards: [
        for (final c in j['cards'] as List)
          VocabCard.fromJson(c as Map<String, dynamic>),
      ],
    );
  }
}
