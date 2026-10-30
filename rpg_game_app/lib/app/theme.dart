import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// つづり（school_planner）の lib/app/theme.dart に合わせた配色。
/// 移植時は school_planner 側のテーマをそのまま使う。
class TsuzuriColors {
  const TsuzuriColors._();

  /// ダークモードで表示しているか（アプリの一番上で、設定と端末の設定から決める）
  static bool dark = false;

  /// 色を使わず白黒で描くか（つづりクエストLight）
  static bool mono = false;

  static Color _pick(int light, int darkColor) =>
      _gray(Color(dark ? darkColor : light));

  /// mono のとき、同じ明るさの灰色にする
  static Color _gray(Color c) {
    if (!mono) return c;
    final v = ((0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255).round();
    return Color.fromARGB((c.a * 255).round(), v, v, v);
  }

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
    return _gray(dark ? Color.lerp(c, const Color(0xFF2A241F), 0.84)! : c);
  }
}

/// 見出しも本文と同じフォント（Noto Sans JP）で描き、明朝体（約2MB）を読みこまない。
/// つづりクエストLight で使う
bool sansOnly = false;

/// 本文のフォントを読みこみ終わるまで待つ。読みこむ前に字を描くと、足りない字を
/// ネットの別のフォント（中国語用の Noto など）から何度も取りに行って通信が増える
Future<void> loadBodyFont() async {
  GoogleFonts.notoSansJp();
  await GoogleFonts.pendingFonts();
}

/// 見出しの文字（太字）。sansOnly のときは本文のフォントを太く描く（別の太さのファイルは読みこまない）
TextStyle _heading(TextStyle? base) => sansOnly
    ? (base ?? const TextStyle()).copyWith(fontWeight: FontWeight.w700)
    : GoogleFonts.notoSerifJp(textStyle: base, fontWeight: FontWeight.w700);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final mono = TsuzuriColors.mono;
  final scheme = mono
      ? ColorScheme.fromSeed(
          seedColor: const Color(0xFF808080),
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
          primary: dark ? Colors.white : Colors.black,
          surface: dark ? Colors.black : Colors.white,
        )
      : ColorScheme.fromSeed(
          seedColor: TsuzuriColors.accent,
          brightness: brightness,
          primary: dark ? const Color(0xFFD7B8A8) : const Color(0xFF6D4C41),
          surface: dark ? const Color(0xFF2A241F) : const Color(0xFFFFFDF8),
        );
  final base = ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: mono
        ? scheme.surface
        : dark
        ? TsuzuriColors.darkBg
        : const Color(0xFFFAF6EE),
  );
  // 本文のフォントは Regular の1つだけを持つ（読みこみを軽くするため、中くらいの太さも Regular で描く）
  final body = GoogleFonts.notoSansJpTextTheme(_regularOnly(base.textTheme));
  return base.copyWith(
    textTheme: body.copyWith(
      headlineLarge: _heading(body.headlineLarge),
      headlineMedium: _heading(body.headlineMedium),
      headlineSmall: _heading(body.headlineSmall),
      titleLarge: _heading(body.titleLarge),
      titleMedium: _heading(body.titleMedium),
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

/// 見出し用（Noto Serif JP）。フォントは Bold の1つだけを持つので、太さは Bold にそろえる
/// （ほかの太さを指定すると、そのフォントをネットから取りに行って重くなる）
TextStyle serif(
  double size, {
  FontWeight weight = FontWeight.w700,
  Color? color,
}) => sansOnly
    ? GoogleFonts.notoSansJp(
        fontSize: size,
        color: color,
      ).copyWith(fontWeight: FontWeight.w700)
    : GoogleFonts.notoSerifJp(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

/// Material の文字の太さのうち、Regular より細い・中くらいのものを Regular にする
TextTheme _regularOnly(TextTheme t) {
  TextStyle? r(TextStyle? s) =>
      s == null || (s.fontWeight ?? FontWeight.w400).value >= 600
      ? s
      : s.copyWith(fontWeight: FontWeight.w400);
  return TextTheme(
    displayLarge: r(t.displayLarge),
    displayMedium: r(t.displayMedium),
    displaySmall: r(t.displaySmall),
    headlineLarge: r(t.headlineLarge),
    headlineMedium: r(t.headlineMedium),
    headlineSmall: r(t.headlineSmall),
    titleLarge: r(t.titleLarge),
    titleMedium: r(t.titleMedium),
    titleSmall: r(t.titleSmall),
    bodyLarge: r(t.bodyLarge),
    bodyMedium: r(t.bodyMedium),
    bodySmall: r(t.bodySmall),
    labelLarge: r(t.labelLarge),
    labelMedium: r(t.labelMedium),
    labelSmall: r(t.labelSmall),
  );
}
