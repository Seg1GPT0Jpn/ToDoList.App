import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'title_screen.dart';

/// つづりクエスト3D（技術検証の試作）。
///
/// 2D 版「つづりクエスト」（rpg_game_app）とは別のゲーム。問題データ・バトルの計算・
/// 成長のしくみは共通のコア（rpg_game）を使い、セーブデータは 3D 版だけのもの。
void main() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Noto Sans JP',
    ], await rootBundle.loadString('assets/fonts/OFL-NotoSansJP.txt'));
  });
  runApp(const TsuzuriQuest3DApp());
}

class TsuzuriQuest3DApp extends StatelessWidget {
  const TsuzuriQuest3DApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'つづりクエスト3D',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF3B7D4F),
      useMaterial3: true,
      fontFamily: 'NotoSansJP',
    ),
    home: const TitleScreen(),
  );
}
