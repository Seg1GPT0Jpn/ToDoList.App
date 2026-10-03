import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../study/personal_books.dart';

/// 単語帳練習の保存先。
///
/// 単語帳も学習記録も、この端末の中（SharedPreferences）にだけ保存する。
/// 市販教材（LEAP・EEVI）の単語は、暗号化したもの（assets/vocab/）だけを同梱し、
/// 名前とパスワードを入れたときに開く。クラウドにも送らない。
class VocabStore {
  VocabStore(this._prefs) {
    _load();
  }

  factory VocabStore.of(PersonalBooks books) =>
      _cache[books] ??= VocabStore(books.prefs);

  static final _cache = Expando<VocabStore>();

  final SharedPreferences _prefs;

  static const _booksKey = 'vocab_books';
  static const _unlockKey = 'vocab_unlocked_books';
  static const _progressPrefix = 'vocab_progress_';
  static const _voiceKey = 'vocab_voice';

  final List<VocabBook> books = [];
  final Map<String, BookProgress> _progress = {};

  void _load() {
    final raw = _prefs.getString(_booksKey);
    if (raw == null) return;
    for (final b in jsonDecode(raw) as List) {
      final book = VocabBook.fromJson(b as Map<String, dynamic>);
      // 以前の版の、空の LEAP・EEVI の枠は使わない
      if (book.isProtected && book.cards.isEmpty) continue;
      books.add(book);
    }
  }

  VocabBook? book(String id) {
    for (final b in books) {
      if (b.id == id) return b;
    }
    return null;
  }

  Set<String> get _unlocked => {...?_prefs.getStringList(_unlockKey)};

  /// 名前とパスワードで開いた単語帳があるか
  bool get unlocked => _unlocked.isNotEmpty;

  /// 同梱された暗号化ファイルを読む（見つからなければ null）
  static Future<List<int>?> Function(String file) assetLoader = _loadAsset;

  static Future<List<int>?> _loadAsset(String file) async {
    try {
      // ウェブでもそのまま配れるように、暗号文を base64 のテキストで置いている
      return base64Decode(
        (await rootBundle.loadString('assets/vocab/$file.txt')).trim(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 名前とパスワードで単語帳を開く。ちがえば null
  Future<VocabBook?> unlock(String name, String password) async {
    if (name.trim().isEmpty || password.trim().isEmpty) return null;
    final data = await assetLoader(VocabVault.fileName(name));
    if (data == null) return null;
    final opened = VocabVault.open(data, password);
    if (opened == null) return null;
    final id = opened.title.toLowerCase();
    var b = book(id);
    if (b == null) {
      b = VocabBook(
        id: id,
        title: opened.title,
        kind: VocabBookKind.protectedImport,
        cards: opened.cards,
      );
      books.insert(0, b);
    } else {
      // 例文など自分で足したものは残し、単語と意味は同梱のものにそろえる
      final mine = {for (final c in b.cards) c.id: c};
      b.cards = [
        for (final c in opened.cards)
          mine[c.id] == null
              ? c
              : c.copyWith(
                  pron: mine[c.id]!.pron.isEmpty ? null : mine[c.id]!.pron,
                  example: mine[c.id]!.example.isEmpty
                      ? null
                      : mine[c.id]!.example,
                  exampleJa: mine[c.id]!.exampleJa.isEmpty
                      ? null
                      : mine[c.id]!.exampleJa,
                ),
      ];
    }
    await _prefs.setStringList(_unlockKey, [..._unlocked, id]);
    await saveBooks();
    return b;
  }

  /// LEAP・EEVI を隠す（学習記録は残る）
  Future<void> lock() => _prefs.remove(_unlockKey);

  /// 開ける単語帳（名前とパスワードで開いていない単語帳は除く）
  List<VocabBook> get visibleBooks {
    final open = _unlocked;
    return [
      for (final b in books)
        if (!b.isProtected || open.contains(b.id)) b,
    ];
  }

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
