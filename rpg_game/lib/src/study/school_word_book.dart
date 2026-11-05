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
      title: 'Scramble イディオム（1046〜1143）',
      subjectId: 'ronhyo1',
      vault: 'school-word-5',
    ),
  ];

  static List<SchoolWordBook> of(String subjectId) => [
        for (final b in all)
          if (b.subjectId == subjectId) b,
      ];
}
