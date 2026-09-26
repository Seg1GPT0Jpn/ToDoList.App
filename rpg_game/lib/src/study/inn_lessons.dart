/// 宿で受けられる授業（次の敵の文法テーマの要点）。
class LessonPoint {
  const LessonPoint(this.heading, this.body, this.example);
  final String heading;
  final String body;
  final String example;
}

class InnLesson {
  const InnLesson({
    required this.stageId,
    required this.teacher,
    required this.title,
    required this.points,
  });

  /// 次に戦うステージ
  final String stageId;
  final String teacher;
  final String title;
  final List<LessonPoint> points;
}

class InnLessons {
  const InnLessons._();

  static InnLesson forStage(String stageId) =>
      all.firstWhere((l) => l.stageId == stageId);

  static const all = <InnLesson>[
    InnLesson(
      stageId: 'english_01',
      teacher: '宿の主人・つづり先生',
      title: '文型と使役動詞',
      points: [
        LessonPoint(
            '補語には形容詞',
            'look / become / keep の後ろは「主語の様子」を表す補語。副詞ではなく形容詞を置く。',
            'She looks happy.（×happily）'),
        LessonPoint(
            'SVOO と SVOC',
            'give + 人 + 物 は「人に物を与える」。make + O + C は「O を C にする」。',
            'The news made him happy.'),
        LessonPoint(
            '使役動詞',
            'make / let / have + 人 + 動詞の原形。「物を〜してもらう」は have + 物 + 過去分詞。',
            'I had my hair cut.'),
        LessonPoint('後ろから修飾', '2語以上で名詞を説明するときは名詞の後ろ。「〜している」は -ing、「〜された」は過去分詞。',
            'a letter written in English'),
      ],
    ),
    InnLesson(
      stageId: 'english_02',
      teacher: '宿の主人・つづり先生',
      title: '不定詞・動名詞・分詞',
      points: [
        LessonPoint(
            '目的語は to do？ -ing？',
            'want / hope / decide は to do、enjoy / finish / mind / avoid は -ing をとる。',
            'I enjoy listening to music.'),
        LessonPoint('前置詞の後ろは -ing', 'look forward to の to は前置詞。後ろは動名詞。',
            "I'm looking forward to seeing you."),
        LessonPoint('remember / forget', 'to do は「これから」、-ing は「過去にしたこと」。',
            'Remember to lock the door.'),
        LessonPoint('分詞構文', '主語が「する」側なら -ing、「される」側なら過去分詞で始める。',
            'Hearing the news, she cried.'),
      ],
    ),
    InnLesson(
      stageId: 'english_03',
      teacher: '宿のおかみ・しおり先生',
      title: '関係詞と接続詞',
      points: [
        LessonPoint(
            '後ろが欠けているか',
            '目的語などが欠けていれば関係代名詞（which / who）、完全な文なら関係副詞（where / when）。',
            'the town where I was born / the town which I visited'),
        LessonPoint(
            'whose', '「その〜の」という所有の関係は whose。', 'the man whose car was stolen'),
        LessonPoint('what', 'what は先行詞を含み「〜するもの・こと」。前に名詞は置かない。',
            'What I want is time.'),
        LessonPoint('間接疑問', '文の中に入った疑問文は「疑問詞 + 主語 + 動詞」の語順。',
            'Do you know where he lives?'),
      ],
    ),
    InnLesson(
      stageId: 'english_04',
      teacher: '宿のおかみ・しおり先生',
      title: '助動詞と仮定法過去',
      points: [
        LessonPoint('推量の強さ', 'must be（〜にちがいない）⇔ can\'t be（〜のはずがない）。',
            'He can\'t be at home.'),
        LessonPoint('依頼と勧誘', 'Could you 〜?（ていねいな依頼）、Shall we 〜?（一緒に〜しよう）。',
            'Shall we go for a walk?'),
        LessonPoint('仮定法過去', '今の事実と反対のことは過去形で。be動詞は were が基本。',
            'If I were you, I would take the train.'),
        LessonPoint(
            'wish / as if',
            'I wish + 過去形で「〜ならいいのに」。as if + 過去形で「まるで〜のように」。',
            'I wish I could speak French.'),
      ],
    ),
    InnLesson(
      stageId: 'english_05',
      teacher: '宿の番人・索引じいさん',
      title: '完了形と仮定法過去完了',
      points: [
        LessonPoint('since と for', 'since は「起点」、for は「期間」。どちらも現在完了とよく使う。',
            'I have lived here since 2015.'),
        LessonPoint('大過去', '過去のある時点よりさらに前のことは had + 過去分詞。',
            'the train had already left'),
        LessonPoint('仮定法過去完了', '過去の事実と反対は If + had 過去分詞, would have 過去分詞。',
            'If it had not been for your help, I would have failed.'),
        LessonPoint('if の省略', 'if を省くと Had / Were / Should が文頭に出る。',
            'Had the weather been fine, ...'),
      ],
    ),
    InnLesson(
      stageId: 'english_06',
      teacher: '最後の宿の賢者',
      title: '比較と倒置',
      points: [
        LessonPoint('最上級の言いかえ', 'No other + 単数名詞 + 比較級 + than 〜 は最上級と同じ意味。',
            'No other student runs faster than Ken.'),
        LessonPoint('比較級の強調', 'much / far で強める。very は使えない。',
            'much longer than that one'),
        LessonPoint('否定語で倒置', 'Never / Little / Only 〜 が文頭に来ると疑問文の語順になる。',
            'Little did he know that ...'),
        LessonPoint('場所の倒置', '場所を表す語句が文頭のときは「動詞 + 主語」。疑問文の形にはしない。',
            'On the hill stands an old castle.'),
      ],
    ),
  ];
}
