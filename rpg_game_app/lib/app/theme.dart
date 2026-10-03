import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// つづり（school_planner）の lib/app/theme.dart に合わせた配色。
/// 移植時は school_planner 側のテーマをそのまま使う。
class TsuzuriColors {
  const TsuzuriColors._();

  /// ダークモードで表示しているか（アプリの一番上で、設定と端末の設定から決める）
  static bool dark = false;

  static Color _pick(int light, int darkColor) =>
      Color(dark ? darkColor : light);

  static Color get accent => _pick(0xFF6D4C41, 0xFFC9A48C); // こげ茶
  static Color get paper => _pick(0xFFFAF6EE, 0xFF1E1A16); // 背景（生成り）
  static Color get card => _pick(0xFFFFFDF8, 0xFF2A241F);
  static const darkBg = Color(0xFF1E1A16);
  static Color get ink => _pick(0xFF2E2A33, 0xFFEDE6DA);
  static Color get inkSoft => _pick(0xFF6B6259, 0xFFB5A99A);
  static Color get gridLine => _pick(0xFFCFDDEA, 0xFF2F3944); // 方眼の青線
  static Color get marginLine => _pick(0xFFE8A5A5, 0xFF7A3B3B); // ノートの赤い余白線
  static Color get kraft => _pick(0xFFD9C7A5, 0xFF5A4A36);

  /// 絵（フィールド・魔物など）の線と紙。ダークモードでも変えない
  static const pen = Color(0xFF2E2A33);
  static const penPaper = Color(0xFFFFFDF8);
  static const penKraft = Color(0xFFD9C7A5);

  static const hp = Color(0xFF7CB342);
  static const hpLow = Color(0xFFE57373);
  static const exp = Color(0xFFF2B84B);
  static const correct = Color(0xFF5B9A5B);
  static const wrong = Color(0xFFC0504D);
  static const stamp = Color(0xFFC62828);

  /// 明るい背景の色（カードの地色など）。ダークモードでは、色味を残したまま暗くする
  static Color tint(int argb) {
    final c = Color(argb);
    return dark ? Color.lerp(c, const Color(0xFF2A241F), 0.84)! : c;
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: TsuzuriColors.accent,
    brightness: brightness,
    primary: dark ? const Color(0xFFD7B8A8) : const Color(0xFF6D4C41),
    surface: dark ? const Color(0xFF2A241F) : const Color(0xFFFFFDF8),
  );
  final base = ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: dark
        ? TsuzuriColors.darkBg
        : const Color(0xFFFAF6EE),
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
