import '../data/catalog.dart';
import 'science_lessons.dart';

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

  /// 手書きの授業があればそれ、なければ要点が空の授業（アプリ側で問題から作る）
  static InnLesson forStage(String stageId) =>
      all.where((l) => l.stageId == stageId).firstOrNull ??
      ScienceLessons.all.where((l) => l.stageId == stageId).firstOrNull ??
      InnLesson(
        stageId: stageId,
        teacher: '${RpgCatalog.stage(stageId).name}の宿・先生',
        title: RpgCatalog.stage(stageId).grammarTheme,
        points: const [],
      );

  static const all = <InnLesson>[
    InnLesson(
        stageId: 'english_01',
        teacher: '草原の宿・つづり先生',
        title: '文型と時制',
        points: [
          LessonPoint('補語には形容詞', 'look / become / keep の後ろは主語の様子を表す補語。副詞は置かない。',
              'She looks happy.'),
          LessonPoint('5つの文型', '目的語が2つなら SVOO、「O = C」なら SVOC。',
              'We named our dog Max.'),
          LessonPoint(
              '現在完了と過去形',
              '具体的な過去の時点（yesterday など）があれば過去形。since / for は現在完了。',
              'I have lived here since 2015.'),
          LessonPoint(
              '過去完了・未来完了',
              '過去より前は had + 過去分詞、未来のある時点までは will have + 過去分詞。',
              'The train had already left.'),
        ]),
    InnLesson(
        stageId: 'english_02',
        teacher: '草原の宿・つづり先生',
        title: '助動詞',
        points: [
          LessonPoint(
              '推量の強さ',
              'must be（〜にちがいない）⇔ can\'t be（〜のはずがない）、may / might（〜かもしれない）。',
              'He can\'t be at home.'),
          LessonPoint('義務と不要', 'must not は禁止、don\'t have to は「〜する必要はない」。',
              'You don\'t have to come.'),
          LessonPoint(
              '助動詞 + have 過去分詞',
              'should have done（〜すべきだったのに）、must have done（〜したにちがいない）。',
              'You should have told me.'),
        ]),
    InnLesson(
        stageId: 'english_03',
        teacher: '草原の宿・つづり先生',
        title: '不定詞（基本）',
        points: [
          LessonPoint('3つの用法', '名詞的（〜すること）、形容詞的（〜するための）、副詞的（〜するために／〜して）。',
              'I have a lot of homework to do.'),
          LessonPoint('疑問詞 + to do', 'how to do（〜のしかた）、what to do（何をすべきか）。',
              'Please tell me how to use it.'),
          LessonPoint(
              'too / enough',
              'too 〜 to do（〜すぎて…できない）、〜 enough to do（…するほど〜）。',
              'She is kind enough to help us.'),
        ]),
    InnLesson(
        stageId: 'english_04',
        teacher: '草原の宿・つづり先生',
        title: '不定詞（応用）',
        points: [
          LessonPoint('完了不定詞', '述語動詞より前のことは to have + 過去分詞。',
              'He seems to have been rich.'),
          LessonPoint('受動の不定詞', '「〜されること」は to be + 過去分詞。',
              'Everyone wants to be loved.'),
          LessonPoint('意味上の主語', 'ふつうは for 〜、人の性質を表す形容詞のときは of 〜。',
              'It was careless of you to leave the door open.'),
        ]),
    InnLesson(
        stageId: 'english_05',
        teacher: '草原の宿・つづり先生',
        title: '動名詞',
        points: [
          LessonPoint('前置詞の後ろは -ing', 'look forward to / be good at などの後ろは動名詞。',
              'Thank you for helping me.'),
          LessonPoint(
              '目的語は to do？ -ing？',
              'enjoy / finish / mind / avoid / give up は -ing。want / decide / hope は to do。',
              'He gave up smoking.'),
          LessonPoint(
              'remember / forget / stop',
              'to do は「これから」、-ing は「過去にしたこと」。stop to do は「〜するために立ち止まる」。',
              'Remember to lock the door.'),
        ]),
    InnLesson(
        stageId: 'english_06',
        teacher: '海岸の宿・しおり先生',
        title: '分詞',
        points: [
          LessonPoint('-ing と過去分詞', '名詞が「する」側なら -ing、「される」側なら過去分詞。',
              'a letter written in English'),
          LessonPoint(
              '感情の分詞',
              '物が人を「わくわくさせる」なら exciting、人が「わくわくさせられる」なら excited。',
              'I was surprised at the news.'),
          LessonPoint('SVOC の分詞', 'have + 物 + 過去分詞（〜してもらう）、keep + O + 過去分詞。',
              'I had my hair cut.'),
        ]),
    InnLesson(
        stageId: 'english_07',
        teacher: '海岸の宿・しおり先生',
        title: '分詞構文',
        points: [
          LessonPoint('分詞で始める', '主語が「する」側なら -ing、「される」側なら過去分詞で始める。',
              'Seen from the plane, the island looked like a heart.'),
          LessonPoint('完了・否定', '先に起きたことは Having + 過去分詞。否定は Not を前に置く。',
              'Not knowing what to do, I asked for help.'),
          LessonPoint(
              'with + O + 分詞', '「O を〜した状態で」という付帯状況。', 'with her eyes closed'),
        ]),
    InnLesson(
        stageId: 'english_08',
        teacher: '海岸の宿・しおり先生',
        title: '比較',
        points: [
          LessonPoint('3つの形', 'as 〜 as（同じくらい）、比較級 + than、the + 最上級。',
              'He runs faster than I do.'),
          LessonPoint('最上級の言いかえ', 'No other + 単数名詞 + 比較級 + than 〜 = 最上級。',
              'No other mountain is higher than Mt. Fuji.'),
          LessonPoint('比較の慣用表現', 'the + 比較級, the + 比較級（〜すればするほど）、倍数 + as 〜 as。',
              'The more you read, the more you learn.'),
        ]),
    InnLesson(
        stageId: 'english_09',
        teacher: '海岸の宿・しおり先生',
        title: '関係詞（基本）',
        points: [
          LessonPoint(
              '後ろが欠けているか',
              '目的語などが欠けていれば関係代名詞、完全な文なら関係副詞（where / when）。',
              'the town where I was born'),
          LessonPoint('whose', '「その〜の」という所有の関係は whose。',
              'the man whose car was stolen'),
          LessonPoint('that が好まれるとき', 'the only / the first / 最上級 などが付く先行詞。',
              'He is the only person that knows it.'),
        ]),
    InnLesson(
        stageId: 'english_10',
        teacher: '海岸の宿・しおり先生',
        title: '関係詞（応用）',
        points: [
          LessonPoint('非制限用法', 'カンマの後ろの関係詞は that を使わない。前の文全体を which で受けることもある。',
              'He said nothing, which made her angry.'),
          LessonPoint('前置詞 + 関係代名詞', '前置詞の後ろは which / whom。that は置けない。',
              'the house in which he lives'),
          LessonPoint(
              'what と複合関係詞',
              'what は「〜すること・もの」。whoever / wherever は「〜する人は誰でも／どこへでも」。',
              'What he said was not true.'),
        ]),
    InnLesson(
        stageId: 'english_11',
        teacher: '洞窟の宿・索引じいさん',
        title: '仮定法（基本）',
        points: [
          LessonPoint('仮定法過去', '今の事実と反対は If + 過去形, would + 原形。be動詞は were。',
              'If I were you, I would take the train.'),
          LessonPoint(
              'wish / as if',
              'I wish + 過去形で「〜ならいいのに」、as if + 過去形で「まるで〜のように」。',
              'I wish I could speak French.'),
          LessonPoint('直説法との区別', '実際に起こりうる条件は現在形（If it is fine tomorrow, ...）。',
              'If it is fine tomorrow, we will go.'),
        ]),
    InnLesson(
        stageId: 'english_12',
        teacher: '洞窟の宿・索引じいさん',
        title: '仮定法（応用）',
        points: [
          LessonPoint('仮定法過去完了', '過去の事実と反対は If + had 過去分詞, would have 過去分詞。',
              'If I had studied harder, I would have passed.'),
          LessonPoint('混合仮定法', '過去の仮定 ＋ 今の結果は、主節を would + 原形に。',
              'If I had taken the medicine, I would feel better now.'),
          LessonPoint(
              'if の省略・but for',
              'Had I known 〜 / Were it not for 〜 / But for 〜。',
              'But for your help, I would have failed.'),
        ]),
    InnLesson(
        stageId: 'english_13',
        teacher: '洞窟の宿・索引じいさん',
        title: '倒置・強調・省略',
        points: [
          LessonPoint('否定語で倒置', 'Never / Little / Only 〜 が文頭に来ると疑問文の語順。',
              'Little did he know the truth.'),
          LessonPoint('強調構文', 'It is 〜 that … で「…なのは〜だ」。do / did で動詞を強調。',
              'It was Tom that broke the window.'),
          LessonPoint(
              '省略',
              'While (I was) staying 〜、if (it is) possible など、主語 + be動詞はよく省略される。',
              'If possible, come with us.'),
        ]),
    InnLesson(
        stageId: 'english_14',
        teacher: '洞窟の宿・索引じいさん',
        title: '高度な構文運用',
        points: [
          LessonPoint(
              '部分否定・二重否定',
              'not all（すべてが〜というわけではない）、no 〜 without …（…なしの〜はない）。',
              'Not all students like math.'),
          LessonPoint('無生物主語', '「物が人に〜させる」は「物のせいで人が〜する」と訳すと自然。',
              'The heavy rain prevented us from going out.'),
          LessonPoint(
              '使役・知覚動詞',
              'make / let / have + O + 原形、see / hear + O + 原形・分詞。',
              'I heard someone call my name.'),
        ]),
    InnLesson(
        stageId: 'english_15',
        teacher: '洞窟の宿・索引じいさん',
        title: '長文での複雑な文構造',
        points: [
          LessonPoint('形式主語 it', 'It is 〜 that … の that 以下が本当の主語。',
              'It is known that smoking is bad.'),
          LessonPoint(
              '名詞節・同格',
              'that / whether / what がつくる名詞節、名詞の内容を説明する同格の that。',
              'the idea that the earth is round'),
          LessonPoint('長い文の読み方', 'まず主語と動詞を見つけ、挿入や修飾部分をかっこでくくる。',
              'This is, as far as I know, the best restaurant.'),
        ]),
    InnLesson(
        stageId: 'english_16',
        teacher: '炎の宿・賢者',
        title: '文法総合（基本）',
        points: [
          LessonPoint(
              '迷ったら品詞', '空所に入るのが名詞・形容詞・副詞・動詞のどれかを先に考える。', 'She looks (happy).'),
          LessonPoint(
              '時制のヒント',
              'yesterday → 過去形、since → 現在完了、by the time → 完了形。',
              'I have lived here since 2015.'),
          LessonPoint(
              '語法は動詞とセット',
              'enjoy -ing、want to do、look forward to -ing などは動詞ごとに覚える。',
              'I enjoy listening to music.'),
        ]),
    InnLesson(
        stageId: 'english_17',
        teacher: '炎の宿・賢者',
        title: '文法総合（応用）',
        points: [
          LessonPoint(
              '仮定法の見分け方',
              '主節の would / could / might、if の省略（Had / Were / Should）が目印。',
              'Had I known the truth, ...'),
          LessonPoint('倒置の見分け方', '否定語・Only・So 〜 が文頭なら語順が変わる。',
              'Only then did I realize it.'),
          LessonPoint(
              '完了形の不定詞・動名詞',
              '「それより前」を表すときは to have done / having done。',
              'He is proud of having been the champion.'),
        ]),
    InnLesson(
        stageId: 'english_18',
        teacher: '炎の宿・賢者',
        title: '長文読解（基本）',
        points: [
          LessonPoint('先に設問を見る', '何を聞かれているかを確認してから本文を読むと、探す場所がはっきりする。',
              'Why did many students become interested?'),
          LessonPoint('指示語は直前を見る', 'it / this / them が指すものは、たいてい直前の文にある。',
              'The cooks used them（= the tomatoes）.'),
          LessonPoint('言いかえに注意', '正解の選択肢は、本文の表現を別の言葉で言いかえていることが多い。',
              'took turns → 交代で行った'),
        ]),
    InnLesson(
        stageId: 'english_19',
        teacher: '炎の宿・賢者',
        title: '長文読解（応用）',
        points: [
          LessonPoint('段落の役割', '主張 → 具体例 → 理由 → まとめ、という流れを意識する。',
              'However, research suggests ...'),
          LessonPoint(
              '逆接のあとが大事',
              'However / Yet / On the other hand の後ろに筆者の言いたいことが来やすい。',
              'Yet a growing body of research shows ...'),
          LessonPoint('要旨問題は最後の段落', '筆者の主張は、最後の段落でまとめられていることが多い。',
              'The point is that study and sleep work together.'),
        ]),
    InnLesson(
        stageId: 'english_20',
        teacher: '最後の宿・大賢者',
        title: '全範囲',
        points: [
          LessonPoint(
              'ここまでの総復習',
              '文法・単語・長文、すべての力が試される。苦手な分野は定期テストの海で復習してから挑もう。',
              '定期テストの海 → 単元を選ぶ'),
          LessonPoint(
              '時間配分', '長文の設問は時間が長め。文法問題は素早く答えるとダメージが上がる。', 'すばやい！ ＋20%'),
          LessonPoint('あきらめない', '負けても正解した分の経験値はもらえる。宿で授業を受けてレベルを上げよう。',
              '宿の練習問題 → 正解1問 2 EXP'),
        ]),
  ];
}
