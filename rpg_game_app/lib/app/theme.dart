import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// つづり（school_planner）の lib/app/theme.dart に合わせた配色。
/// 移植時は school_planner 側のテーマをそのまま使う。
class TsuzuriColors {
  const TsuzuriColors._();

  static const accent = Color(0xFF6D4C41); // こげ茶
  static const paper = Color(0xFFFAF6EE); // ライト背景（生成り）
  static const card = Color(0xFFFFFDF8);
  static const darkBg = Color(0xFF1E1A16);
  static const ink = Color(0xFF2E2A33);
  static const inkSoft = Color(0xFF6B6259);
  static const gridLine = Color(0xFFCFDDEA); // 方眼の青線
  static const marginLine = Color(0xFFE8A5A5); // ノートの赤い余白線
  static const kraft = Color(0xFFD9C7A5);
  static const hp = Color(0xFF7CB342);
  static const hpLow = Color(0xFFE57373);
  static const exp = Color(0xFFF2B84B);
  static const correct = Color(0xFF5B9A5B);
  static const wrong = Color(0xFFC0504D);
  static const stamp = Color(0xFFC62828);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: TsuzuriColors.accent,
    brightness: brightness,
    primary: dark ? const Color(0xFFD7B8A8) : TsuzuriColors.accent,
    surface: dark ? const Color(0xFF2A241F) : TsuzuriColors.card,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: dark ? TsuzuriColors.darkBg : TsuzuriColors.paper,
  );
  final body = GoogleFonts.notoSansJpTextTheme(base.textTheme);
  return base.copyWith(
    textTheme: body.copyWith(
      headlineLarge: GoogleFonts.notoSerifJp(
        textStyle: body.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.notoSerifJp(
        textStyle: body.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.notoSerifJp(
        textStyle: body.headlineSmall,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.notoSerifJp(
        textStyle: body.titleLarge,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.notoSerifJp(
        textStyle: body.titleMedium,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
  );
}

/// 見出し用（Noto Serif JP）
TextStyle serif(
  double size, {
  FontWeight weight = FontWeight.w700,
  Color? color,
}) => GoogleFonts.notoSerifJp(fontSize: size, fontWeight: weight, color: color);
