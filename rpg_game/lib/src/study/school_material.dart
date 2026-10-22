import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// 学校の配布資料（要点まとめなど）をページごとの画像にして同梱したもの。
///
/// 画像はそのまま置かず、かんたんな暗号化をしてある（Web 版のファイルを直接開いても
/// 資料として読めないようにするため。強い保護ではない）。試験対策で学校の対策を開いた
/// 端末でだけ一覧に出す。
class SchoolMaterial {
  const SchoolMaterial({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.pages,
  });

  /// 同梱フォルダの名前（assets/materials/<id>/）
  final String id;
  final String title;

  /// 学校の科目（ShonanSubjects の id）
  final String subjectId;
  final int pages;

  /// [page] ページ目（1から）の同梱ファイル
  String asset(int page) =>
      'assets/materials/$id/${page.toString().padLeft(2, '0')}.bin';
}

abstract final class SchoolMaterials {
  static const all = <SchoolMaterial>[
    SchoolMaterial(
      id: 'kokyo_print3',
      title: '公共 完全マスター 要点まとめ＆全単語辞書（公共プリント№3）',
      subjectId: 'public_economy',
      pages: 47,
    ),
  ];

  static List<SchoolMaterial> of(String subjectId) => [
        for (final m in all)
          if (m.subjectId == subjectId) m
      ];

  static final _magic = ascii.encode('TQB1');
  static final _key = sha256.convert(utf8.encode('tsuzuri-material-v1')).bytes;

  static List<int> _u32(int v) =>
      [(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255];

  static Uint8List _xor(List<int> nonce, List<int> data) {
    final hmac = Hmac(sha256, _key);
    final out = Uint8List(data.length);
    for (var i = 0, block = 0; i < data.length; block++) {
      final ks = hmac.convert([...nonce, ..._u32(block)]).bytes;
      for (var j = 0; j < ks.length && i < data.length; j++, i++) {
        out[i] = data[i] ^ ks[j];
      }
    }
    return out;
  }

  /// 同梱用に暗号化する（道具用）
  static Uint8List seal(List<int> data, List<int> nonce) =>
      Uint8List.fromList([..._magic, ...nonce, ..._xor(nonce, data)]);

  /// 同梱ファイルを画像のバイト列に戻す（形式がちがえば null）
  static Uint8List? open(List<int> data) {
    if (data.length < 20) return null;
    for (var i = 0; i < 4; i++) {
      if (data[i] != _magic[i]) return null;
    }
    return _xor(data.sublist(4, 20), data.sublist(20));
  }
}
