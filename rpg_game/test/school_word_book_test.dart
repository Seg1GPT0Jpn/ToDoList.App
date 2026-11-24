import 'dart:convert';
import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

List<int> _data(SchoolWordBook b) =>
    base64Decode(File('../rpg_game_app/assets/vocab/${b.file}.txt')
        .readAsStringSync()
        .trim());

/// 学校のパスワードはソースに書かない。中身まで確かめるときだけ、環境変数で渡す
final _password = Platform.environment['SCHOOL_PASSWORD'];

void main() {
  test('テスト範囲の単語帳は同梱されていて、ちがうパスワードでは開かない', () {
    for (final b in SchoolWordBooks.all) {
      expect(b.open(_data(b), 'wrong'), isNull, reason: b.id);
    }
    expect(SchoolWordBooks.of('gengo_bunka').single.id, 'kobun');
    expect(SchoolWordBooks.of('ronhyo1').single.id, 'scramble');
    expect({for (final b in SchoolWordBooks.all) b.file}.length, 11);
    expect(SchoolWordBooks.of('information1').single.id, 'joho-terms');
  });

  test('学校のパスワードで開いた単語帳を、ふつうの単語帳として使える', () {
    final cards = [
      const VocabCard(id: 'a', term: '輪郭', meaning: '物語の［リンカク］', group: '第5章'),
    ];
    final sealed = VocabVault.seal('漢字', cards, 'test-pw', worldId: 'japanese');
    final b = SchoolWordBooks.all.first;
    // 全角・大文字で入れても開く
    final book = b.open(sealed, 'ＴＥＳＴ－ＰＷ')!;
    expect(book.id, '漢字');
    expect(book.isTerms, isTrue);
    expect(book.kind, VocabBookKind.protectedImport);
    expect(book.cards.single.term, '輪郭');
  });

  test('（パスワードがあるときだけ）範囲の番号どおりに取り出してある', () {
    VocabBook open(String id) {
      final b = SchoolWordBooks.all.firstWhere((b) => b.id == id);
      return b.open(_data(b), _password!)!;
    }

    final kobun = open('kobun').cards.map((c) => c.number!).toList();
    expect([kobun.length, kobun.first, kobun.last], [104, 151, 254]);
    final leap = open('leap');
    expect(leap.isTerms, isFalse);
    final n = leap.cards.map((c) => c.number!).toList();
    expect([n.length, n.first, n.last], [1001, 1100, 2100]);
    // 例文：すべての単語に意味ごとの例文があり、ほとんどは穴埋めにも使える
    expect(leap.cards.every((c) => c.examples.isNotEmpty), isTrue);
    expect(leap.cards.where((c) => c.hasExample).length,
        greaterThanOrEqualTo(1000));
    final kanji = open('kanji');
    expect(kanji.isTerms, isTrue);
    expect(kanji.cards.length, 670);
    expect(kanji.cards.first.term, '輪郭');
    expect(kanji.cards.first.meaning, contains('［リンカク］'));
    expect({for (final c in kanji.cards) c.group},
        containsAll(['第5章 漢字①', '第6章 同音異義語①', '付録 四字熟語②']));
    final kw = open('keyword');
    expect(kw.cards.length, 188);
    expect(kw.cards.first.term, 'オリエンタリズム');
    // キーワードの説明では、答えの語を伏せてある
    expect(kw.cards.first.meaning, isNot(contains('オリエンタリズム')));
    expect({for (final c in kw.cards) c.group}.length, 30);
    final scramble = open('scramble');
    expect(scramble.isTerms, isFalse);
    final sn = scramble.cards.map((c) => c.number!).toList();
    expect([sn.length, sn.first, sn.last], [76, 1046, 1121]);
    expect(scramble.cards.every((c) => c.example.isNotEmpty), isTrue);
    expect(scramble.cards.where((c) => c.hasExample).length,
        greaterThanOrEqualTo(72));
    // 公共・生物基礎・情報Ⅰ・地理総合の用語帳（説明に答えの語を入れていない）
    for (final (id, n) in [
      ('kokyo-terms', 418),
      ('bio-terms', 191),
      ('joho-terms', 84),
      ('chiri-terms', 161),
      ('chem-terms', 54),
    ]) {
      final b = open(id);
      expect(b.isTerms, isTrue, reason: id);
      expect(b.cards.length, n, reason: id);
      for (final c in b.cards) {
        expect(c.meaning, isNot(contains(c.term)), reason: c.term);
        expect(c.group, isNotEmpty);
      }
    }
    final eci = open('eci-words');
    expect(eci.isTerms, isFalse);
    expect(eci.cards.length, 127);
    expect(
        eci.cards.where((c) => c.hasExample).length, greaterThanOrEqualTo(100));
    expect({for (final c in eci.cards) c.group}.length, 8);
    for (final c in [...kanji.cards, ...kw.cards]) {
      expect(c.term.trim(), isNotEmpty);
      expect(c.meaning, isNot(contains('読み取れず')));
    }
  }, skip: _password == null ? 'SCHOOL_PASSWORD がないので中身は確かめない' : false);
}
