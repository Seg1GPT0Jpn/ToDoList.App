import 'package:flutter/material.dart';
import 'package:rpg_game_app/app/services.dart';
import 'package:rpg_game_app/app/settings.dart';
import 'package:rpg_game_app/app/theme.dart';
import 'package:rpg_game_app/app/toast.dart';

import 'light_home.dart';
import 'light_pages.dart' deferred as pages;
import 'main.dart' show inviteClassCode;

class LightApp extends StatefulWidget {
  const LightApp({super.key});

  @override
  State<LightApp> createState() => _LightAppState();
}

class _LightAppState extends State<LightApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => setState(() {});

  bool _isDark(AppSettings s) => switch (s.theme) {
    'dark' => true,
    'light' => false,
    _ =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  void _rebuildAll() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    final settings = RpgServices.of(context).settings;
    return ValueListenableBuilder<AppSettings>(
      valueListenable: settings,
      builder: (context, s, _) {
        final dark = _isDark(s);
        if (dark != TsuzuriColors.dark) {
          TsuzuriColors.dark = dark;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _rebuildAll();
          });
        }
        return MaterialApp(
          title: 'つづりクエストLight',
          debugShowCheckedModeBanner: false,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          scaffoldMessengerKey: rootMessengerKey,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              // 軽くするため、画面の切りかえなどの動きはいつも止める
              data: mq.copyWith(
                textScaler: TextScaler.linear(s.textScale),
                disableAnimations: true,
              ),
              child: child!,
            );
          },
          home: const _FirstRun(child: LightHome()),
        );
      },
    );
  }
}

/// はじめての起動でログイン画面を出す。招待リンクならクラスルームを開く
class _FirstRun extends StatefulWidget {
  const _FirstRun({required this.child});
  final Widget child;

  @override
  State<_FirstRun> createState() => _FirstRunState();
}

class _FirstRunState extends State<_FirstRun> {
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) return;
    _asked = true;
    final p = RpgServices.of(context).profiles.load();
    final code = inviteClassCode();
    final welcome = !p.hasName && !p.isGoogleLinked;
    if (code == null && !welcome) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await pages.loadLibrary();
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (code != null) {
        nav.push(
          MaterialPageRoute<void>(builder: (_) => pages.classroom(code)),
        );
      }
      if (welcome) {
        nav.push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => pages.welcome(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
