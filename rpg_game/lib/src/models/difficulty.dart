/// 問題・ステージの難易度（内部4段階）。
///
/// 通常のステージは basic〜advanced の3段階。
/// challenge は隠しステージ・ボス・高難度の問題用。
enum Difficulty {
  basic('基本'),
  standard('標準'),
  advanced('応用'),
  challenge('挑戦');

  const Difficulty(this.label);
  final String label;

  /// 文字列から読む（未知の値や null は null）
  static Difficulty? tryParse(String? value) {
    if (value == null) return null;
    for (final d in values) {
      if (d.name == value) return d;
    }
    return null;
  }

  /// エリア名（例：「整式（標準）」）から難易度を読み取る
  static Difficulty? fromTheme(String theme) {
    if (theme.contains('（基本）')) return basic;
    if (theme.contains('（標準）')) return standard;
    if (theme.contains('（応用）')) return advanced;
    if (theme.contains('（挑戦）')) return challenge;
    return null;
  }
}
