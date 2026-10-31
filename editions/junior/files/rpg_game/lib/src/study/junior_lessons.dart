// このファイルは tool/junior/gen.py が生成しています。
// 手で直さず tool/junior/<教科>.py の lesson を直してください。
import 'inn_lessons.dart';

/// 宿の授業（小中学生版）。書いていないエリアは問題から自動で作る。
class JuniorLessons {
  const JuniorLessons._();

  static const all = <InnLesson>[
    InnLesson(
      stageId: 'english_e34_01',
      teacher: '小3・4の宿・つづり先生',
      title: 'アルファベット',
      points: [
        LessonPoint('大文字と小文字', 'アルファベットは26文字。大文字と小文字がある。', 'A a / B b / C c'),
        LessonPoint('まちがえやすい文字', 'b と d、p と q は向きに注意。', 'bed（ベッド）'),
      ],
    ),
    InnLesson(
      stageId: 'english_j1_01',
      teacher: '中1の宿・つづり先生',
      title: 'be動詞',
      points: [
        LessonPoint('be動詞の使い分け', 'I → am、you と複数 → are、それ以外の1人・1つ → is。',
            'I am / You are / He is'),
        LessonPoint('否定文と疑問文', '否定は be動詞のあとに not、疑問文は be動詞を主語の前に。',
            'Is he a student? — Yes, he is.'),
      ],
    ),
    InnLesson(
      stageId: 'english_j1_03',
      teacher: '中1の宿・つづり先生',
      title: '3人称単数現在',
      points: [
        LessonPoint('3単現の s', '主語が he / she / it や1人・1つのとき、現在の動詞に s をつける。',
            'He plays tennis.'),
        LessonPoint('does の文', '否定は doesn\'t ＋ 動詞の元の形、疑問は Does ＋ 主語 ＋ 動詞の元の形。',
            'Does she like music?'),
      ],
    ),
    InnLesson(
      stageId: 'english_j1_09',
      teacher: '中1の宿・つづり先生',
      title: '過去形',
      points: [
        LessonPoint('一般動詞の過去', 'ふつうは ed、不規則動詞は形が変わる。否定・疑問は did を使い、動詞は元の形。',
            'Did you go? — Yes, I did.'),
        LessonPoint('be動詞の過去', 'am / is → was、are → were。', 'I was busy.'),
      ],
    ),
    InnLesson(
      stageId: 'english_j2_03',
      teacher: '中2の宿・つづり先生',
      title: '不定詞',
      points: [
        LessonPoint(
            '不定詞の3つの用法',
            'to ＋ 動詞の元の形。名詞的「～すること」、副詞的「～するために／～して」、形容詞的「～するための」。',
            'I want to go. / I came to see you. / time to go'),
      ],
    ),
    InnLesson(
      stageId: 'english_j2_07',
      teacher: '中2の宿・つづり先生',
      title: '比較',
      points: [
        LessonPoint(
            '比較級と最上級',
            '2つをくらべて「より～」は ～er than、3つ以上で「いちばん～」は the ～est。長い語は more / most。',
            'taller than / the tallest'),
        LessonPoint(
            'as ～ as', '「同じくらい～」。否定は「～ほど…ない」。', 'as tall as / not as tall as'),
      ],
    ),
    InnLesson(
      stageId: 'english_j3_01',
      teacher: '中3の宿・つづり先生',
      title: '現在完了（完了・経験）',
      points: [
        LessonPoint('現在完了', 'have / has ＋ 過去分詞。過去のことが今とつながっている。',
            'I have finished. / I have been there.'),
        LessonPoint(
            '完了・経験・継続',
            'just / already / yet、ever / never / ～ times、for / since が目印。',
            'I have lived here for ten years.'),
      ],
    ),
    InnLesson(
      stageId: 'english_j3_07',
      teacher: '中3の宿・つづり先生',
      title: '関係代名詞',
      points: [
        LessonPoint(
            '関係代名詞',
            '名詞（先行詞）のあとに文をつけて説明する。人 → who、もの → which、どちらも → that。',
            'a friend who lives in Kobe'),
        LessonPoint('目的格の省略', '「名詞 ＋ 主語 ＋ 動詞」なら that / which を省略できる。',
            'the book (that) I bought'),
      ],
    ),
    InnLesson(
      stageId: 'math_e1_01',
      teacher: '小1の宿・つづり先生',
      title: '10までのかず',
      points: [
        LessonPoint('かずを かぞえる', '1つずつ ゆびで おさえながら かぞえよう。', '●●● → 3'),
        LessonPoint('10の あわせかた', '10 は 1と9、2と8、3と7、4と6、5と5。', '6 と 4 で 10'),
        LessonPoint('つぎの かず', 'かずは 1ずつ ふえて ならんでいる。', '7 の つぎは 8'),
      ],
    ),
    InnLesson(
      stageId: 'math_e1_02',
      teacher: '小1の宿・つづり先生',
      title: 'たしざん',
      points: [
        LessonPoint('あわせると いくつ', '「あわせて」「ぜんぶで」「ふえると」は たしざん。', '3 + 2 = 5'),
        LessonPoint('0 の たしざん', 'どんな かずに 0 を たしても かわらない。', '4 + 0 = 4'),
      ],
    ),
    InnLesson(
      stageId: 'math_e1_03',
      teacher: '小1の宿・つづり先生',
      title: 'ひきざん',
      points: [
        LessonPoint('のこりは いくつ', '「のこりは」「ちがいは」は ひきざん。', '7 − 3 = 4'),
      ],
    ),
    InnLesson(
      stageId: 'math_e1_05',
      teacher: '小1の宿・つづり先生',
      title: '大きいかず（100まで）',
      points: [
        LessonPoint(
            '10の まとまり', '10が いくつと ばらが いくつで 大きい かずを あらわす。', '10が3こと ばら4こで 34'),
        LessonPoint('100', '10が 10こで 100（ひゃく）。', '99 の つぎは 100'),
      ],
    ),
    InnLesson(
      stageId: 'math_e1_06',
      teacher: '小1の宿・つづり先生',
      title: 'くりあがりの ある たしざん',
      points: [
        LessonPoint(
            '10を つくる', 'たす かずを わけて、まず 10 を つくる。', '8 + 5 → 8 + 2 + 3 = 13'),
      ],
    ),
    InnLesson(
      stageId: 'math_e1_07',
      teacher: '小1の宿・つづり先生',
      title: 'くりさがりの ある ひきざん',
      points: [
        LessonPoint(
            '10から ひく', '13 − 8 は、10 − 8 = 2 と 3 を あわせて 5。', '13 − 8 = 5'),
      ],
    ),
    InnLesson(
      stageId: 'math_e2_01',
      teacher: '小2の宿・つづり先生',
      title: 'たし算のひっ算',
      points: [
        LessonPoint(
            'くらいをそろえる', '一のくらいどうし、十のくらいどうしをたてにそろえて書く。', '  36\n+ 47\n= 83'),
        LessonPoint(
            'くり上がり', '一のくらいが10をこえたら、十のくらいに1くり上げる。', '6 + 7 = 13 → 3を書いて1くり上がる'),
      ],
    ),
    InnLesson(
      stageId: 'math_e2_02',
      teacher: '小2の宿・つづり先生',
      title: 'ひき算のひっ算',
      points: [
        LessonPoint('くり下がり', 'ひけないときは十のくらいから10をかりてくる。',
            '52 − 18 → 12 − 8 = 4、4 − 1 = 3 → 34'),
        LessonPoint('たしかめ', '答え＋ひく数＝ひかれる数 になればOK。', '34 + 18 = 52'),
      ],
    ),
    InnLesson(
      stageId: 'math_e2_08',
      teacher: '小2の宿・つづり先生',
      title: 'かけ算九九（2・3・4・5のだん）',
      points: [
        LessonPoint('かけ算の意味', '同じ数ずつのものが何こ分あるかを考える。', '3こずつ4さら → 3 × 4 = 12'),
        LessonPoint('かける数が1ふえると', '答えはかけられる数だけふえる。', '4 × 5 = 20 → 4 × 6 = 24'),
      ],
    ),
    InnLesson(
      stageId: 'math_e3_02',
      teacher: '小3の宿・つづり先生',
      title: 'わり算',
      points: [
        LessonPoint('わり算の意味', '同じ数ずつ分けるとき、1人分や何人に分けられるかをもとめる。', '12 ÷ 3 = 4'),
        LessonPoint('答えの見つけ方', 'わる数のだんの九九を使う。', '3 × 4 = 12 だから 12 ÷ 3 = 4'),
      ],
    ),
    InnLesson(
      stageId: 'math_e4_02',
      teacher: '小4の宿・つづり先生',
      title: 'わり算の筆算',
      points: [
        LessonPoint('筆算の手じゅん', 'たてる → かける → ひく → おろす をくり返す。', '96 ÷ 4 = 24'),
        LessonPoint('たしかめ', 'わる数 × 商 ＋ あまり ＝ わられる数。', '4 × 24 + 0 = 96'),
      ],
    ),
    InnLesson(
      stageId: 'math_e4_08',
      teacher: '小4の宿・つづり先生',
      title: '面積',
      points: [
        LessonPoint(
            '長方形と正方形', '長方形 ＝ たて × よこ、正方形 ＝ 1辺 × 1辺。', '3cm × 5cm ＝ 15cm²'),
        LessonPoint('単位', '1m² ＝ 10000cm²、1a ＝ 100m²、1ha ＝ 10000m²。', ''),
      ],
    ),
    InnLesson(
      stageId: 'math_e5_05',
      teacher: '小5の宿・つづり先生',
      title: '倍数と約数',
      points: [
        LessonPoint(
            '倍数', 'ある数に整数をかけてできる数。公倍数のいちばん小さいものが最小公倍数。', '4と6の最小公倍数は12'),
        LessonPoint('約数', 'ある数をわりきれる整数。公約数のいちばん大きいものが最大公約数。', '12と18の最大公約数は6'),
      ],
    ),
    InnLesson(
      stageId: 'math_e5_08',
      teacher: '小5の宿・つづり先生',
      title: '単位量あたりの大きさ・速さ',
      points: [
        LessonPoint('速さの3公式', '速さ ＝ 道のり ÷ 時間、道のり ＝ 速さ × 時間、時間 ＝ 道のり ÷ 速さ。',
            '120km ÷ 2時間 ＝ 時速60km'),
        LessonPoint('こみぐあい', '1m²あたりの人数などでくらべる。', '12人 ÷ 6m² ＝ 2人'),
      ],
    ),
    InnLesson(
      stageId: 'math_e6_06',
      teacher: '小6の宿・つづり先生',
      title: '比例と反比例',
      points: [
        LessonPoint('比例', 'y ＝ きまった数 × x。グラフは0を通る直線。', 'y ＝ 3 × x'),
        LessonPoint('反比例', 'x × y ＝ きまった数。', 'y ＝ 24 ÷ x'),
      ],
    ),
    InnLesson(
      stageId: 'math_j1_01',
      teacher: '中1の宿・つづり先生',
      title: '正負の数',
      points: [
        LessonPoint('正の数・負の数', '0より大きい数が正の数、小さい数が負の数（−をつける）。', '−3 ＜ 0 ＜ +2'),
        LessonPoint('加法と減法', 'ひく数の符号を変えて、加法になおす。', '5 − (−3) ＝ 5 + 3 ＝ 8'),
      ],
    ),
    InnLesson(
      stageId: 'math_j1_03',
      teacher: '中1の宿・つづり先生',
      title: '文字と式',
      points: [
        LessonPoint('文字式のきまり', '×は省き、数は文字の前、÷は分数の形。', 'a × 3 ＝ 3a、x ÷ 2 ＝ x/2'),
        LessonPoint('式の計算', '同じ文字の項（同類項）をまとめる。', '2x + 3 + 5x ＝ 7x + 3'),
      ],
    ),
    InnLesson(
      stageId: 'math_j1_05',
      teacher: '中1の宿・つづり先生',
      title: '一次方程式',
      points: [
        LessonPoint('方程式の解き方', '①かっこ・分数をなくす ②移項 ③ax＝b ④両辺をaでわる',
            '3x + 5 ＝ 20 → 3x ＝ 15 → x ＝ 5'),
      ],
    ),
    InnLesson(
      stageId: 'math_j2_02',
      teacher: '中2の宿・つづり先生',
      title: '連立方程式',
      points: [
        LessonPoint('加減法', '係数の絶対値をそろえて、たすかひくかで1文字を消す。', ''),
        LessonPoint('代入法', '「y ＝ 〜」の式をもう一方に代入する。', ''),
      ],
    ),
    InnLesson(
      stageId: 'math_j3_01',
      teacher: '中3の宿・つづり先生',
      title: '展開と因数分解',
      points: [
        LessonPoint('乗法公式', '(x + a)(x + b)、(a ± b)²、(a + b)(a − b) の4つ。',
            '(x + 2)(x + 5) ＝ x² + 7x + 10'),
        LessonPoint('因数分解', '和と積に注目して2数をさがす。', 'x² + 5x + 6 ＝ (x + 2)(x + 3)'),
      ],
    ),
    InnLesson(
      stageId: 'japanese_e1_01',
      teacher: '小1の宿・つづり先生',
      title: 'ひらがな',
      points: [
        LessonPoint('小さい じ', '「っ」「ゃ」「ゅ」「ょ」は 小さく かく。', 'きって・きゅうり'),
        LessonPoint('のばす おと', 'おかあさん（あ）、おにいさん（い）、おとうさん（う）。', 'おおきい・とおい は「お」'),
      ],
    ),
    InnLesson(
      stageId: 'japanese_e4_03',
      teacher: '小4の宿・つづり先生',
      title: '部首',
      points: [
        LessonPoint('部首の位置', 'へん（左）・つくり（右）・かんむり（上）・あし（下）・たれ・にょう・かまえ。',
            'さんずい（へん）・うかんむり（かんむり）'),
        LessonPoint('部首と意味', '部首から漢字の意味の仲間がわかる。', 'さんずい → 水、ごんべん → 言葉'),
      ],
    ),
    InnLesson(
      stageId: 'japanese_e5_03',
      teacher: '小5の宿・つづり先生',
      title: '敬語',
      points: [
        LessonPoint('3つの敬語', '尊敬語（相手を高める）・謙譲語（自分をへりくだる）・ていねい語（です・ます）。', ''),
        LessonPoint(
            '特別な言い方', '言う → おっしゃる／申す、行く → いらっしゃる／参る、食べる → めしあがる／いただく。', ''),
      ],
    ),
    InnLesson(
      stageId: 'japanese_j1_03',
      teacher: '中1の宿・つづり先生',
      title: '文法：文節・単語・品詞',
      points: [
        LessonPoint(
            '文節と単語', '文節は「ネ」で区切れるまとまり。単語は文節をさらに分けた最小の言葉。', '本を／読む → 本／を／読む'),
        LessonPoint('品詞', '自立語：名詞・動詞・形容詞・形容動詞・副詞・連体詞・接続詞・感動詞。付属語：助詞・助動詞。', ''),
      ],
    ),
    InnLesson(
      stageId: 'japanese_j2_03',
      teacher: '中2の宿・つづり先生',
      title: '文法：用言の活用',
      points: [
        LessonPoint(
            '活用の種類の見分け方',
            '「ない」をつけて直前の音を見る。あ段→五段、い段→上一段、え段→下一段。来る→カ変、する→サ変。',
            '書か(ない)・見(ない)・食べ(ない)'),
        LessonPoint('6つの活用形', '未然形・連用形・終止形・連体形・仮定形・命令形。', ''),
      ],
    ),
    InnLesson(
      stageId: 'japanese_j3_03',
      teacher: '中3の宿・つづり先生',
      title: '文法：助詞・助動詞と敬語',
      points: [
        LessonPoint('れる・られる', '受け身・可能・自発・尊敬の4つの意味。文の内容から見分ける。', '先生が来られる（尊敬）'),
        LessonPoint('敬語の注意', '自分の身内のことを外の人に話すときは謙譲語を使う。', '父が申しておりました'),
      ],
    ),
    InnLesson(
      stageId: 'science_j1_01',
      teacher: '中1の宿・つづり先生',
      title: '植物の分類',
      points: [
        LessonPoint('種子植物', '被子植物（胚珠が子房の中）と裸子植物（胚珠がむき出し）。', 'アブラナ／マツ'),
        LessonPoint('単子葉類と双子葉類', '子葉・葉脈・根のつくりで分ける。', 'イネ（平行脈・ひげ根）'),
      ],
    ),
    InnLesson(
      stageId: 'science_j2_01',
      teacher: '中2の宿・つづり先生',
      title: '化学変化と原子・分子',
      points: [
        LessonPoint('化学式', '元素記号と数字で物質を表す。', 'H₂O、CO₂、O₂'),
        LessonPoint('質量保存の法則', '化学変化の前後で全体の質量は変わらない。', ''),
      ],
    ),
    InnLesson(
      stageId: 'science_j2_05',
      teacher: '中2の宿・つづり先生',
      title: '電流と電圧',
      points: [
        LessonPoint('オームの法則', 'V（電圧）＝ R（抵抗）× I（電流）。', '10Ω × 0.5A ＝ 5V'),
        LessonPoint('直列と並列', '直列：電流が同じ・抵抗は和。並列：電圧が同じ。', ''),
      ],
    ),
    InnLesson(
      stageId: 'science_j3_01',
      teacher: '中3の宿・つづり先生',
      title: '水溶液とイオン',
      points: [
        LessonPoint('イオン', '陽イオンは電子を失った原子、陰イオンは電子を受けとった原子。', 'Na⁺、Cl⁻'),
        LessonPoint('酸・アルカリ・中和', '酸＝H⁺、アルカリ＝OH⁻。中和で水と塩ができる。',
            'HCl + NaOH → NaCl + H₂O'),
      ],
    ),
  ];
}
