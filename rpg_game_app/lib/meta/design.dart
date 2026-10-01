import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';

/// 画面をまたいで使う見た目の決まりごと（デザイントークン）
class Space {
  const Space._();
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;

  /// ノートの赤い余白線をよける左の余白
  static const margin = 40.0;
}

class Radii {
  const Radii._();
  static const card = 14.0;
  static const chip = 8.0;
}

/// 教科の色とアイコン
const subjectColors = <String, Color>{
  'japanese': Color(0xFFC0504D),
  'math': Color(0xFF3F7CAC),
  'english': Color(0xFF5B9A5B),
  'science': Color(0xFF8E6BBF),
  'social': Color(0xFFD9822B),
  'information': Color(0xFF4A8C8C),
  'music': Color(0xFFD45D8C),
};

const subjectIcons = <String, IconData>{
  'japanese': Icons.menu_book,
  'math': Icons.functions,
  'english': Icons.translate,
  'science': Icons.science_outlined,
  'social': Icons.public,
  'information': Icons.memory,
  'music': Icons.music_note,
};

/// レア度の色（色だけに頼らず、★の数でも見分けられるようにする）
Color rarityColor(Rarity r) => switch (r) {
  Rarity.common => const Color(0xFF8D8478),
  Rarity.rare => const Color(0xFF3F7CAC),
  Rarity.epic => const Color(0xFF8E4BBF),
  Rarity.legendary => const Color(0xFFC98A00),
};

String stars(Rarity r) => '★' * r.stars + '☆' * (4 - r.stars);

/// ノート風のカード
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.color,
    this.border,
    this.padding = const EdgeInsets.all(Space.m),
  });

  final Widget child;

  /// 地の色（なければカードの色）
  final Color? color;

  /// ふちの色（なければこげ茶）
  final Color? border;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? TsuzuriColors.card,
      borderRadius: BorderRadius.circular(Radii.card),
      border: Border.all(color: border ?? TsuzuriColors.accent, width: 1.5),
    ),
    child: child,
  );
}

/// 小見出し
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Space.s),
    child: Row(
      children: [
        Expanded(child: Text(text, style: serif(16))),
        ?trailing,
      ],
    ),
  );
}
