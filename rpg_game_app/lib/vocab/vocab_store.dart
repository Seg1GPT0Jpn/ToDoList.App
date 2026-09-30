import 'dart:convert';

import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../study/personal_books.dart';

/// 単語帳練習の保存先。
///
/// 単語帳も学習記録も、この端末の中（SharedPreferences）にだけ保存する。
/// 市販教材（LEAP・EEVI）の単語はアプリや GitHub には含めず、利用者が
/// 自分で貼り付けたものだけを置く。クラウドにも送らない。
class VocabStore {
  VocabStore(this._prefs) {
    _load();
  }

  factory VocabStore.of(PersonalBooks books) =>
      _cache[books] ??= VocabStore(books.prefs).._migrate(books);

  static final _cache = Expando<VocabStore>();

  final SharedPreferences _prefs;

  static const _booksKey = 'vocab_books';
  static const _unlockKey = 'vocab_unlocked';
  static const _progressPrefix = 'vocab_progress_';
  static const _voiceKey = 'vocab_voice';

  /// パスワードで保護する単語帳（市販教材を自分で取り込む枠）
  static const presets = [('leap', 'LEAP'), ('eevi', 'EEVI')];

  final List<VocabBook> books = [];
  final Map<String, BookProgress> _progress = {};

  void _load() {
    final raw = _prefs.getString(_booksKey);
    if (raw != null) {
      for (final b in jsonDecode(raw) as List) {
        books.add(VocabBook.fromJson(b as Map<String, dynamic>));
      }
    }
    for (final (id, title) in presets.reversed) {
      if (!books.any((b) => b.id == id)) {
        books.insert(
          0,
          VocabBook(
            id: id,
            title: title,
            kind: VocabBookKind.protectedImport,
            cards: [],
          ),
        );
      }
    }
  }

  /// 以前の「LEAP」タブに取り込んだ単語を引きつぐ
  void _migrate(PersonalBooks old) {
    final text = old.leapText;
    final leap = book('leap');
    if (text == null || leap == null || leap.cards.isNotEmpty) return;
    leap.cards = VocabParser.parse(text);
    saveBooks();
  }

  VocabBook? book(String id) {
    for (final b in books) {
      if (b.id == id) return b;
    }
    return null;
  }

  bool get unlocked => _prefs.getBool(_unlockKey) ?? false;

  bool tryUnlock(String input) {
    final ok = VocabGate.check(input);
    if (ok) _prefs.setBool(_unlockKey, true);
    return ok;
  }

  Future<void> lock() => _prefs.remove(_unlockKey);

  /// 開ける単語帳（鍵がかかっていれば保護された単語帳は除く）
  List<VocabBook> get visibleBooks => [
    for (final b in books)
      if (unlocked || !b.isProtected) b,
  ];

  Future<void> saveBooks() => _prefs.setString(
    _booksKey,
    jsonEncode([for (final b in books) b.toJson()]),
  );

  BookProgress progress(String bookId) => _progress[bookId] ??= () {
    final raw = _prefs.getString('$_progressPrefix$bookId');
    return raw == null
        ? BookProgress()
        : BookProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }();

  Future<void> saveProgress(String bookId) => _prefs.setString(
    '$_progressPrefix$bookId',
    jsonEncode(progress(bookId).toJson()),
  );

  Future<VocabBook> createBook(String title) async {
    var n = books.length;
    while (book('my$n') != null) {
      n++;
    }
    final b = VocabBook(
      id: 'my$n',
      title: title,
      kind: VocabBookKind.custom,
      cards: [],
    );
    books.add(b);
    await saveBooks();
    return b;
  }

  /// 単語帳を消す（LEAP・EEVI は中身だけ空にする）
  Future<void> deleteBook(String id) async {
    final b = book(id);
    if (b == null) return;
    if (b.isProtected) {
      b.cards = [];
    } else {
      books.remove(b);
    }
    _progress.remove(id);
    await _prefs.remove('$_progressPrefix$id');
    await saveBooks();
  }

  /// 発音の設定（'en-US' / 'en-GB'、速さ 0.3〜1.0）
  (String, double) get voice {
    final v = _prefs.getString(_voiceKey)?.split('|');
    if (v == null || v.length != 2) return ('en-US', 0.5);
    return (v[0], double.tryParse(v[1]) ?? 0.5);
  }

  Future<void> setVoice(String lang, double rate) =>
      _prefs.setString(_voiceKey, '$lang|$rate');

  /// 別の端末に移すためのバックアップ（学習記録と自作の単語帳。LEAP・EEVI の単語は含めない）
  String exportBackup() => jsonEncode({
    'v': 1,
    'books': [
      for (final b in books)
        if (!b.isProtected) b.toJson(),
    ],
    'progress': {for (final b in books) b.id: progress(b.id).toJson()},
  });

  /// バックアップを読み込む。読めなければ false
  Future<bool> importBackup(String text) async {
    try {
      final j = jsonDecode(text.trim()) as Map<String, dynamic>;
      for (final raw in j['books'] as List) {
        final b = VocabBook.fromJson(raw as Map<String, dynamic>);
        final old = book(b.id);
        if (old == null) {
          books.add(b);
        } else if (!old.isProtected) {
          old.merge(b.cards);
        }
      }
      for (final e in (j['progress'] as Map).entries) {
        _progress[e.key as String] = BookProgress.fromJson(
          e.value as Map<String, dynamic>,
        );
        await saveProgress(e.key as String);
      }
      await saveBooks();
      return true;
    } catch (_) {
      return false;
    }
  }
}
