import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../study/personal_books.dart';
import '../app/asset_path.dart';

/// 単語帳練習の保存先。
///
/// 単語帳はこの端末の中（SharedPreferences）にだけ保存する。
/// 市販教材（LEAP・EEVI）の単語は、暗号化したもの（assets/vocab/）だけを同梱し、
/// 名前とパスワードを入れたときに開く。単語や意味はクラウドに送らない。
///
/// 学習記録（単語の番号ごとの覚えぐあい）だけは、Google でログインしていれば
/// クラウドにも保存し、アンインストールしても戻せるようにする（[onProgressSaved]）。
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
        (await rootBundle.loadString(appAsset('assets/vocab/$file.txt')))
            .trim(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 開いた単語帳の名前と合言葉（この端末の中だけ。同梱データが新しくなったら開きなおすため）
  static const _vaultKey = 'vocab_vault_keys';

  Map<String, List<String>> get _vaultKeys {
    final raw = _prefs.getString(_vaultKey);
    if (raw == null) return {};
    try {
      return {
        for (final e in (jsonDecode(raw) as Map).entries)
          '${e.key}': [for (final v in e.value as List) '$v'],
      };
    } catch (_) {
      return {};
    }
  }

  /// 名前とパスワードで単語帳を開く。ちがえば null
  Future<VocabBook?> unlock(String name, String password) async {
    if (name.trim().isEmpty || password.trim().isEmpty) return null;
    final data = await assetLoader(VocabVault.fileName(name));
    if (data == null) return null;
    // 大文字・小文字のちがいでは開けなくならないように、小文字でも試す
    var used = password;
    var opened = VocabVault.open(data, used);
    if (opened == null) {
      used = VocabVault.halfWidth(password).toLowerCase();
      opened = VocabVault.open(data, used);
    }
    if (opened == null) return null;
    final b = _apply(opened);
    await _prefs.setString(
      _vaultKey,
      jsonEncode({
        ..._vaultKeys,
        b.id: [name, used],
      }),
    );
    await _prefs.setStringList(_unlockKey, {..._unlocked, b.id}.toList());
    await saveBooks();
    return b;
  }

  /// 前に開いた単語帳を、アプリに入っている新しい版（章分け・意味の直しなど）にそろえる。
  /// 変わったものがあれば true
  Future<bool> refreshOpened() async {
    var changed = false;
    for (final MapEntry(key: id, value: v) in _vaultKeys.entries) {
      if (v.length != 2 || !_unlocked.contains(id)) continue;
      final data = await assetLoader(VocabVault.fileName(v[0]));
      if (data == null) continue;
      final opened = VocabVault.open(data, v[1]);
      if (opened == null) continue;
      String sig(List<VocabCard> cards) => jsonEncode([
        for (final c in cards) [c.id, c.term, c.meaning, c.group],
      ]);
      final before = book(id);
      if (before != null && sig(before.cards) == sig(opened.cards)) continue;
      _apply(opened);
      changed = true;
    }
    if (changed) await saveBooks();
    return changed;
  }

  /// 開いた中身を単語帳にする（前からあれば、自分で足した例文などは残して中身をそろえる）
  VocabBook _apply(
    ({String title, String worldId, List<VocabCard> cards}) opened,
  ) {
    final id = opened.title.toLowerCase();
    var b = book(id);
    if (b == null) {
      b = VocabBook(
        id: id,
        title: opened.title,
        kind: VocabBookKind.protectedImport,
        worldId: opened.worldId,
        cards: opened.cards,
      );
      books.insert(0, b);
    } else {
      // 例文など自分で足したものは残し、単語と意味・章は同梱のものにそろえる
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

  Future<void> saveProgress(String bookId) async {
    await _prefs.setString(
      '$_progressPrefix$bookId',
      jsonEncode(progress(bookId).toJson()),
    );
    onProgressSaved?.call(this, bookId);
  }

  /// 学習記録を保存したとき（クラウド同期が使う）
  static void Function(VocabStore store, String bookId)? onProgressSaved;

  /// 学習記録がある単語帳の ID（開いていない LEAP なども含む）
  Iterable<String> get progressBookIds => {
    for (final k in _prefs.getKeys())
      if (k.startsWith(_progressPrefix)) k.substring(_progressPrefix.length),
    ..._progress.keys,
  };

  /// 同じ端末の別のアプリ（同じブラウザのつづりクエストLight など）が保存した
  /// 学習記録を、読みこみ済みの記録にまぜる
  void absorbPrefs() {
    for (final id in _progress.keys) {
      final raw = _prefs.getString('$_progressPrefix$id');
      if (raw == null) continue;
      try {
        _progress[id]!.merge(
          BookProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        // 壊れていれば手元の記録のまま
      }
    }
  }

  /// クラウドの学習記録を、この端末の記録とまぜて保存する
  Future<void> mergeProgress(String bookId, BookProgress cloud) async {
    progress(bookId).merge(cloud);
    await saveProgress(bookId);
  }

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
    // 暗記カード（理科・社会など）の学習記録もふくめる
    'progress': {for (final id in progressBookIds) id: progress(id).toJson()},
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
