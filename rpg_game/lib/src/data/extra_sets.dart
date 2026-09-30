/// 定期テストの海の「追加問題」タブで練習できる問題セット。
/// RPG のエリアには入れず、単元ごとの練習としてだけ使う。
class ExtraSet {
  const ExtraSet(this.subject, this.id, this.title);

  /// 教科（english / science / social / japanese / math / information）
  final String subject;

  /// 問題セット ID（assets/questions/<subject>/<id>.json）
  final String id;
  final String title;
}

abstract final class ExtraSets {
  static const all = [
    ExtraSet('english', 'english_stage_exam_01', '語彙・熟語・英作文・長文'),
    ExtraSet('english', 'english_applied_reading_01', 'リスニング・図表・複数の英文'),
    ExtraSet('science', 'science_physics_rlc_01', '電磁気・交流・RLC 回路'),
    ExtraSet('social', 'social_current_2426_01', '最新時事（2024〜2026年）'),
    ExtraSet('japanese', 'japanese_ronri_01', '評論の論理構造・要旨'),
    ExtraSet('japanese', 'japanese_reading_comp_01', '小説・実用文・複数文章・古文・漢文'),
    ExtraSet('math', 'math_m1_stat_01', '統計（箱ひげ図・標準偏差・相関）'),
    ExtraSet('math', 'math_m1_logic_01', '集合と命題'),
    ExtraSet('math', 'math_quadratic_app_01', '2次関数の応用'),
    ExtraSet('information', 'information_prog_algo_01', 'プログラミング・アルゴリズム'),
    ExtraSet('information', 'information_prog_algo_02', 'プログラムのトレース・データの活用'),
    ExtraSet('information', 'information_data_db_01', 'データベース・データの活用'),
  ];

  static List<ExtraSet> of(String subject) => [
        for (final s in all)
          if (s.subject == subject) s
      ];
}
