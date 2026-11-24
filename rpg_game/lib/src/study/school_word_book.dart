import '../vocab/vocab_book.dart';
import '../vocab/vocab_vault.dart';
import 'school_gate.dart';

/// 定期テストの範囲の単語帳（古文単語・LEAP・漢字など）。
///
/// 中身は学校のパスワードで暗号化して同梱し（assets/vocab/）、試験対策の中でだけ開く。
/// ふつうの単語帳の一覧には出さない。
class SchoolWordBook {
  const SchoolWordBook({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.vault,
  });

  final String id;

  /// 画面に出す名前（範囲つき）
  final String title;

  /// 学校の科目（ShonanSubjects の id）
  final String subjectId;

  /// 同梱ファイルの名前のもと（[VocabVault.fileName]）
  final String vault;

  String get file => VocabVault.fileName(vault);

  /// 学校のパスワードで開く。ちがえば null
  VocabBook? open(List<int> data, String password) {
    final o = VocabVault.open(data, SchoolGate.normalize(password));
    if (o == null) return null;
    return VocabBook(
      // 題名は元の単語帳と同じにしてあるので、学習記録も元の単語帳と共有する
      id: o.title.toLowerCase(),
      title: o.title,
      kind: VocabBookKind.protectedImport,
      worldId: o.worldId,
      cards: o.cards,
    );
  }
}

abstract final class SchoolWordBooks {
  static const all = <SchoolWordBook>[
    SchoolWordBook(
      id: 'kobun',
      title: '古文単語（151〜254）',
      subjectId: 'gengo_bunka',
      vault: 'school-word-1',
    ),
    SchoolWordBook(
      id: 'leap',
      title: 'LEAP（1100〜2100）',
      subjectId: 'ec1',
      vault: 'school-word-2',
    ),
    SchoolWordBook(
      id: 'kanji',
      title: '漢字・語彙（第5・6章、四字熟語①②）',
      subjectId: 'gendai_kokugo',
      vault: 'school-word-3',
    ),
    SchoolWordBook(
      id: 'keyword',
      title: '現代文キーワード（41〜70）',
      subjectId: 'gendai_kokugo',
      vault: 'school-word-4',
    ),
    SchoolWordBook(
      id: 'scramble',
      title: 'Scramble イディオム（1046〜1121）',
      subjectId: 'ronhyo1',
      vault: 'school-word-5',
    ),
    SchoolWordBook(
      id: 'kokyo-terms',
      title: '公共 用語（消費者・労働・社会保障・国際経済）',
      subjectId: 'public_economy',
      vault: 'school-word-6',
    ),
    SchoolWordBook(
      id: 'bio-terms',
      title: '生物基礎 用語（体内環境・免疫・植生・生態系）',
      subjectId: 'biology_basic',
      vault: 'school-word-7',
    ),
    SchoolWordBook(
      id: 'joho-terms',
      title: '情報Ⅰ 用語（情報デザイン・コンピュータ・プログラム）',
      subjectId: 'information1',
      vault: 'school-word-8',
    ),
    SchoolWordBook(
      id: 'chiri-terms',
      title: '地理総合 用語（気候・植生と土壌・衣食住・宗教・言語）',
      subjectId: 'geography_general',
      vault: 'school-word-9',
    ),
    SchoolWordBook(
      id: 'chem-terms',
      title: '化学基礎 用語（物質量・濃度・化学変化・酸と塩基）',
      subjectId: 'chemistry_basic',
      vault: 'school-word-10',
    ),
    SchoolWordBook(
      id: 'eci-words',
      title: 'ECⅠ Lesson5・6 新出語句',
      subjectId: 'ec1',
      vault: 'school-word-11',
    ),
  ];

  static List<SchoolWordBook> of(String subjectId) => [
        for (final b in all)
          if (b.subjectId == subjectId) b,
      ];
}
