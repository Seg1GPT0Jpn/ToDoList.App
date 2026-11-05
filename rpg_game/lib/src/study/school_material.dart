import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../vocab/vocab_vault.dart';
import 'school_gate.dart';

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
    this.locked = false,
  });

  /// 同梱フォルダの名前（assets/materials/<id>/）
  final String id;
  final String title;

  /// 学校の科目（ShonanSubjects の id）
  final String subjectId;
  final int pages;

  /// 教科書・問題集の文章をふくむ資料。学校のパスワードから作った鍵で暗号化してあり、
  /// パスワードを知らないと開けない（鍵はアプリの中に置かない）
  final bool locked;

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
    SchoolMaterial(
      id: 'gendai_kaihatsu78',
      title: '読解力開発講座 第7問・第8問（解答つき）',
      subjectId: 'gendai_kokugo',
      pages: 16,
      locked: true,
    ),
    SchoolMaterial(
      id: 'gendai_zeitaku',
      title: '現代の国語⑧ 贅沢の条件・引用の妥当性（解答例つき）',
      subjectId: 'gendai_kokugo',
      pages: 17,
      locked: true,
    ),
    SchoolMaterial(
      id: 'gendai_democracy',
      title: '現代の国語⑦ 複数テキストの読解（解答例つき）',
      subjectId: 'gendai_kokugo',
      pages: 22,
      locked: true,
    ),
    SchoolMaterial(
      id: 'gengo_koji',
      title: '故事成語「狐借虎威」ほか（漁夫之利・五十歩百歩）',
      subjectId: 'gengo_bunka',
      pages: 12,
      locked: true,
    ),
    SchoolMaterial(
      id: 'gengo_kundoku',
      title: '漢文訓読の基本',
      subjectId: 'gengo_bunka',
      pages: 15,
      locked: true,
    ),
    SchoolMaterial(
      id: 'kw_matome',
      title: '現代文キーワード 41〜70 重要語句まとめ',
      subjectId: 'gendai_kokugo',
      pages: 14,
      locked: true,
    ),
    SchoolMaterial(
      id: 'kw_mondai',
      title: '現代文キーワード 41〜70 対策問題（解答つき）',
      subjectId: 'gendai_kokugo',
      pages: 6,
      locked: true,
    ),
    SchoolMaterial(
      id: 'kw_book',
      title: '現代文キーワード 41〜70（本）',
      subjectId: 'gendai_kokugo',
      pages: 30,
      locked: true,
    ),
    SchoolMaterial(
      id: 'kanji_goi',
      title: '漢字・語彙 第5・6章・四字熟語（文字起こし）',
      subjectId: 'gendai_kokugo',
      pages: 28,
      locked: true,
    ),
    SchoolMaterial(
      id: 'bio_prints',
      title: '生物基礎 授業プリントNo.10〜15（解答例つき）',
      subjectId: 'biology_basic',
      pages: 17,
      locked: true,
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

  static Uint8List _xor(List<int> nonce, List<int> data, {List<int>? key}) {
    final hmac = Hmac(sha256, key ?? _key);
    final out = Uint8List(data.length);
    for (var i = 0, block = 0; i < data.length; block++) {
      final ks = hmac.convert([...nonce, ..._u32(block)]).bytes;
      for (var j = 0; j < ks.length && i < data.length; j++, i++) {
        out[i] = data[i] ^ ks[j];
      }
    }
    return out;
  }

  /// 同梱用に暗号化する（道具・テスト用）。[key] を渡すと鍵つきの形式にする
  static Uint8List seal(List<int> data, List<int> nonce, {List<int>? key}) =>
      Uint8List.fromList([
        ...(key == null ? _magic : _magic2),
        ...nonce,
        ..._xor(nonce, data, key: key),
      ]);

  static final _magic2 = ascii.encode('TQB2');

  /// 鍵のかかった資料の鍵（学校のパスワードから作る。時間がかかるので一度だけ作る）
  static List<int> keyFor(String password) => VocabVault.pbkdf2(
        utf8.encode(SchoolGate.normalize(password)),
        utf8.encode('tsuzuri-material-v2'),
        32,
      );

  /// 同梱ファイルを画像のバイト列に戻す（形式がちがう・鍵がないときは null）。
  /// 鍵がちがうと、画像として読めないバイト列になる（[looksLikeImage] で確かめる）
  static Uint8List? open(List<int> data, {List<int>? key}) {
    if (data.length < 20) return null;
    var v1 = true, v2 = true;
    for (var i = 0; i < 4; i++) {
      if (data[i] != _magic[i]) v1 = false;
      if (data[i] != _magic2[i]) v2 = false;
    }
    if (v1) return _xor(data.sublist(4, 20), data.sublist(20));
    if (v2 && key != null) {
      return _xor(data.sublist(4, 20), data.sublist(20), key: key);
    }
    return null;
  }

  /// WebP の画像か
  static bool looksLikeImage(List<int> b) =>
      b.length > 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP';
}
