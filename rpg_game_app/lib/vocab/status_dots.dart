import 'package:flutter/material.dart';

/// 覚えぐあいの色（🔴弱点・🟠あやふや・🟢安定・⚪未学習）
const statusDotColors = {
  '🔴': Color(0xFFE53935),
  '🟠': Color(0xFFFB8C00),
  '🟢': Color(0xFF43A047),
  '⚪': Color(0xFFFFFFFF),
};

final _dots = RegExp('(🔴|🟠|🟢|⚪)');

/// 🔴🟠🟢⚪ を、色を塗った丸として描く文字。
/// 絵文字のまま描くと、絵文字のフォント（約150KB）をネットから取りに行き、オフラインでは出ないため
class DotText extends StatelessWidget {
  const DotText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final size =
        (style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14) *
        0.8;
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _dots.allMatches(text)) {
      if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
      final color = statusDotColors[m.group(0)]!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: color == const Color(0xFFFFFFFF)
                  ? Border.all(color: const Color(0xFFBDBDBD))
                  : null,
            ),
          ),
        ),
      );
      at = m.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
    );
  }
}
