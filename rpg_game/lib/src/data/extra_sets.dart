/// 定期テストの海の「追加問題」タブで練習できる問題セット。
/// RPG のエリアには入れず、単元ごとの練習としてだけ使う。
class ExtraSet {
  const ExtraSet(this.subject, this.id, this.title);

  /// 教科（english / math / japanese / science / social）
  final String subject;

  /// 問題セット ID（assets/questions/<subject>/<id>.json）
  final String id;
  final String title;
}

abstract final class ExtraSets {
  /// 小中学生版では、まだ追加問題のセットはない（RPG のエリアの問題で練習する）
  static const all = <ExtraSet>[];

  static List<ExtraSet> of(String subject) => [
        for (final s in all)
          if (s.subject == subject) s
      ];
}
