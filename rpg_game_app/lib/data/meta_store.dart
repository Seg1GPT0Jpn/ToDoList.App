import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 学習記録（問題ごとの正誤・復習の予定）と冒険の記録（図鑑・実績・クエスト）を
/// 端末に保存する。
///
/// Firebase につながっているときは、保存のたびに [onLearningSaved] /
/// [onJournalSaved] でクラウドにも書き込む（`CloudSync`）。
/// 学習記録には問題 ID と数値だけが入る。個人用単語帳（LEAP など）の問題は記録しない。
class MetaStore extends ChangeNotifier {
  MetaStore(this._prefs)
    : _record = _readRecord(_prefs),
      _journal = _readJournal(_prefs);

  static const _learningKey = 'rpg_learning_v1';
  static const _journalKey = 'rpg_journal_v1';
  final SharedPreferences _prefs;

  LearningRecord _record;
  PlayerJournal _journal;

  LearningRecord get record => _record;
  PlayerJournal get journal => _journal;

  Future<void> Function(LearningRecord record)? onLearningSaved;
  Future<void> Function(PlayerJournal journal)? onJournalSaved;

  static LearningRecord _readRecord(SharedPreferences p) {
    final raw = p.getString(_learningKey);
    if (raw == null) return LearningRecord.empty;
    try {
      return LearningRecord.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return LearningRecord.empty;
    }
  }

  static PlayerJournal _readJournal(SharedPreferences p) {
    final raw = p.getString(_journalKey);
    if (raw == null) return PlayerJournal.empty;
    try {
      return PlayerJournal.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerJournal.empty;
    }
  }

  Future<void> save({LearningRecord? record, PlayerJournal? journal}) async {
    await replaceLocal(record: record, journal: journal);
    if (record != null) await onLearningSaved?.call(record);
    if (journal != null) await onJournalSaved?.call(journal);
  }

  /// 端末内だけを書きかえる（クラウドから読み込んだときに使う）
  Future<void> replaceLocal({
    LearningRecord? record,
    PlayerJournal? journal,
  }) async {
    if (record != null) {
      _record = record;
      await _prefs.setString(_learningKey, jsonEncode(record.toMap()));
    }
    if (journal != null) {
      _journal = journal;
      await _prefs.setString(_journalKey, jsonEncode(journal.toMap()));
    }
    notifyListeners();
  }

  Future<void> reset() async {
    await save(record: LearningRecord.empty, journal: PlayerJournal.empty);
  }
}
