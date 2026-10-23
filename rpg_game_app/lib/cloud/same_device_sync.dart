import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/meta_store.dart';
import '../data/prefs_progress_repository.dart';
import '../study/personal_books.dart';
import '../study/school_exam_store.dart';
import '../study/school_lesson_store.dart';
import '../vocab/vocab_store.dart';
import 'storage_events_stub.dart'
    if (dart.library.js_interop) 'storage_events_web.dart';

/// 同じ端末で使っている、もう一方のアプリの保存を取りこむ。
///
/// Web 版のつづりクエストとつづりクエストLight は同じサイトにあるので、
/// ブラウザの保存場所を共有している。ほかのタブで保存されたとき（Web）と、
/// アプリにもどってきたときに保存場所を読みなおし、記録をまぜる。
/// ログインしていれば、[onResume] でクラウドの記録もまぜる。
class SameDeviceSync with WidgetsBindingObserver {
  SameDeviceSync({
    required this.prefs,
    required this.meta,
    required this.progress,
    required this.books,
    this.onResume,
  });

  final SharedPreferences prefs;
  final MetaStore meta;
  final PrefsProgressRepository progress;
  final PersonalBooks books;

  /// アプリにもどってきたとき（クラウドの記録を読みなおす）
  final Future<void> Function()? onResume;

  Timer? _timer;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    onOtherTabSaved(() => schedule());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      schedule();
      unawaited(onResume?.call());
    }
  }

  /// 続けて保存されることが多いので、少し待ってからまとめて読みなおす
  void schedule() {
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(absorb()),
    );
  }

  /// 保存場所を読みなおして、もう一方のアプリの記録をまぜる
  Future<void> absorb() async {
    try {
      await prefs.reload();
    } catch (_) {
      return;
    }
    await meta.absorbPrefs();
    progress.refresh();
    VocabStore.of(books).absorbPrefs();
    SchoolLessonStore.of(books).refresh();
    SchoolExamStore.of(books).refresh();
  }
}
