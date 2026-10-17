import 'dart:math';

import '../curriculum/curriculum.dart';
import '../learning/learning_record.dart';
import '../learning/question_stat.dart';
import '../models/enemy.dart';
import '../models/player_stats.dart';
import '../models/question.dart';
import '../models/stage.dart';
import '../study/word_list.dart';

/// 単語の問い方。同じ単語を、いくつもの形で出す。
enum WordFormat {
  meaning('英→日', '英語を見て意味を選ぶ'),
  recall('日→英', '意味を見て英語を選ぶ'),
  spelling('スペル', '意味を見て英語を書く'),
  listening('発音', '読み上げを聞いて意味を選ぶ');

  const WordFormat(this.label, this.description);
  final String label;
  final String description;
}

/// 1語の覚えぐあい（覚えた／覚えていないの二択ではなく、形式ごとの記録から決める）
class WordMemory {
  const WordMemory({
    required this.word,
    required this.attempts,
    required this.correct,
    required this.formatsCleared,
    required this.lastCorrect,
    required this.due,
    required this.box,
  });

  final WordEntry word;
  final int attempts;
  final int correct;

  /// 1回以上正解した形式
  final Set<WordFormat> formatsCleared;

  /// 直近の答えが正解だったか（まだ答えていなければ null）
  final bool? lastCorrect;

  /// 復習の日が来ている
  final bool due;

  /// 形式のなかでいちばん進んだ復習の箱
  final int box;

  int get accuracy => attempts == 0 ? 0 : (correct * 100 / attempts).round();

  /// 定着度（0〜3の★）：正答率・形式の数・復習の間隔から
  int get stars {
    if (attempts == 0) return 0;
    var s = 0;
    if (accuracy >= 60) s++;
    if (formatsCleared.length >= 3) s++;
    if (box >= 3 && lastCorrect == true) s++;
    return s;
  }

  /// コレクションに入った（★2以上）
  bool get collected => stars >= 2;

  /// 忘れかけ：まちがえたまま・正答率が低い・復習の日が来た
  bool get fading =>
      attempts > 0 && (lastCorrect == false || accuracy < 60 || due);
}

/// 単語の森：単語のモンスターと戦って覚える。
///
/// 1回のバトルで5語。1語ごとに単語のモンスターが現れ、英→日・日→英・スペル・発音の
/// いろいろな形で問われる。正解すると攻撃、3問ほどでその単語のモンスターを倒せる。
/// まちがえた単語は「忘却の塔（単語）」で、間をあけてくり返し出てくる。
abstract final class WordBattle {
  static const wordsPerBattle = 5;

  /// 問題の ID（学習記録はこの ID で残る）
  static String questionId(WordList list, WordEntry w, WordFormat f) =>
      '${list.listId}_w${w.number ?? list.words.indexOf(w)}_${f.name}';

  /// 問題セットの ID（学習記録の「どのセットか」）
  static String setId(WordList list) => '${list.listId}_forest';

  /// 1語を [formats] の形で出す問題
  static List<QuizQuestion> questionsFor(
    WordList list,
    WordEntry w, {
    Set<WordFormat> formats = const {...WordFormat.values},
    Random? random,
  }) {
    final r = random ?? Random();
    final unit = Curriculum.unitForGeneratedSet(list.listId);
    final others = [...list.words.where((o) => o.term != w.term)]..shuffle(r);
    others.sort((a, b) =>
        (a.partOfSpeech == w.partOfSpeech ? 0 : 1) -
        (b.partOfSpeech == w.partOfSpeech ? 0 : 1));
    List<String> pick(String Function(WordEntry) label, String answer) {
      final wrong = <String>[];
      for (final o in others) {
        final l = label(o);
        if (l != answer && !wrong.contains(l)) wrong.add(l);
        if (wrong.length == 3) break;
      }
      return [answer, ...wrong]..shuffle(r);
    }

    final out = <QuizQuestion>[];
    final explanation = '${w.term}：${w.meaning}';
    for (final f in formats) {
      final id = questionId(list, w, f);
      switch (f) {
        case WordFormat.meaning || WordFormat.listening:
          final choices = pick((o) => o.shortMeaning, w.shortMeaning);
          if (choices.length < 4) continue;
          out.add(QuizQuestion(
            id: id,
            unit: unit,
            category: QuestionCategory.meaning,
            prompt: f == WordFormat.listening
                ? '読み上げられた単語の意味は？'
                : '「${w.term}」の意味は？',
            sentence: f == WordFormat.listening ? w.term : null,
            listen: f == WordFormat.listening,
            choices: choices,
            answerIndex: choices.indexOf(w.shortMeaning),
            explanation: explanation,
          ));
        case WordFormat.recall:
          final choices = pick((o) => o.term, w.term);
          if (choices.length < 4) continue;
          out.add(QuizQuestion(
            id: id,
            unit: unit,
            category: QuestionCategory.meaning,
            prompt: '「${w.shortMeaning}」を表す英語は？',
            choices: choices,
            answerIndex: choices.indexOf(w.term),
            explanation: explanation,
          ));
        case WordFormat.spelling:
          final choices = pick((o) => o.term, w.term);
          if (choices.length < 4) continue;
          out.add(QuizQuestion(
            id: id,
            unit: unit,
            category: QuestionCategory.meaning,
            prompt:
                '「${w.shortMeaning}」を英語で書こう（${w.term[0]}で始まる${w.term.length}文字）',
            choices: choices,
            answerIndex: choices.indexOf(w.term),
            accepted: [w.term],
            explanation: explanation,
          ));
      }
    }
    return out;
  }

  /// 単語ごとの覚えぐあい
  static WordMemory memoryOf(
      WordList list, WordEntry w, LearningRecord record, int today) {
    var attempts = 0, correct = 0, box = 0, lastDay = -1;
    bool? last;
    var due = false;
    final cleared = <WordFormat>{};
    for (final f in WordFormat.values) {
      final QuestionStat? s = record[questionId(list, w, f)];
      if (s == null || s.attempts == 0) continue;
      attempts += s.attempts;
      correct += s.correct;
      box = max(box, s.box);
      if (s.correct > 0) cleared.add(f);
      if (s.isDue(today)) due = true;
      if (s.lastDay >= lastDay) {
        lastDay = s.lastDay;
        last = s.streak > 0;
      }
    }
    return WordMemory(
      word: w,
      attempts: attempts,
      correct: correct,
      formatsCleared: cleared,
      lastCorrect: last,
      due: due,
      box: box,
    );
  }

  /// 次のバトルの5語：まだ出会っていない語を中心に、忘れかけの語をまぜる
  static List<WordEntry> nextWords(
    WordList list,
    LearningRecord record,
    int today, {
    Random? random,
    bool reviewOnly = false,
  }) {
    final r = random ?? Random();
    final memories = [
      for (final w in list.words) memoryOf(list, w, record, today)
    ];
    final fading = memories.where((m) => m.fading).map((m) => m.word).toList()
      ..shuffle(r);
    if (reviewOnly) return fading.take(wordsPerBattle).toList();
    final fresh =
        memories.where((m) => m.attempts == 0).map((m) => m.word).toList();
    final learning = memories
        .where((m) => m.attempts > 0 && !m.fading && !m.collected)
        .map((m) => m.word)
        .toList()
      ..shuffle(r);
    final out = <WordEntry>[
      ...fading.take(2),
      ...fresh.take(wordsPerBattle),
      ...learning,
    ];
    final seen = <String>{};
    final picked = [
      for (final w in out)
        if (seen.add(w.term)) w
    ];
    if (picked.length < wordsPerBattle) {
      final rest = [...list.words]..shuffle(r);
      for (final w in rest) {
        if (seen.add(w.term)) picked.add(w);
        if (picked.length >= wordsPerBattle) break;
      }
    }
    return picked.take(wordsPerBattle).toList();
  }

  /// 単語のモンスター（見た目は単語ごとに決まった文房具）
  static const _looks = [
    'pencil',
    'eraser',
    'sticky',
    'notebook',
    'glue',
    'tape',
    'clip',
    'pushpin',
    'brush',
    'correction',
    'inkpot',
    'page',
    'crayon',
    'marker',
  ];

  static EnemyDef monster(WordEntry w, int hp, int attack,
      {String prefix = ''}) {
    final look =
        _looks[w.term.codeUnits.fold<int>(0, (a, c) => a + c) % _looks.length];
    return EnemyDef(
      id: 'word_${w.term}',
      name: '$prefix${w.term}',
      look: look,
      maxHp: hp,
      attack: attack,
      ability: EnemyAbility.normal,
      description: '単語「${w.term}」（${w.shortMeaning}）が魔物になった姿。',
      introLine: '${w.term}…おぼえているか？',
      defeatLine: '${w.term}は、もうきみのものだ…',
    );
  }

  /// 5語の単語のモンスターと順に戦うステージ。1語あたり約3問の正解で倒せる
  static StageDef stage(
    WordList list,
    List<WordEntry> words,
    int level, {
    bool tower = false,
  }) {
    final p = PlayerStats.forLevel(level);
    final hp = (p.attack * 2.6).round();
    final atk = (p.maxHp / 6 + p.defense / 2).ceil();
    final lineup = [
      for (final w in words) monster(w, hp, atk, prefix: tower ? '忘却の' : ''),
    ];
    return StageDef(
      id: tower ? '${list.listId}_tower' : setId(list),
      worldId: 'english',
      order: 1,
      name: tower ? '忘却の塔（単語）' : '単語の森：${list.title}',
      region: '単語の森',
      grammarTheme: list.title,
      questionSetIds: [setId(list)],
      expReward: 0,
      timeLimitSeconds: 15,
      readingTimeLimitSeconds: 30,
      enemy: lineup.first,
      reinforcements: lineup.skip(1).toList(),
    );
  }
}
