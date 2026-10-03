// このファイルは tool/junior/gen.py が生成しています。
// 手で直さず tool/junior/<教科>.py の lesson を直してください。
import 'inn_lessons.dart';

/// 宿の授業（小中学生版）。書いていないエリアは問題から自動で作る。
class JuniorLessons {
  const JuniorLessons._();

  static const all = <InnLesson>[
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
        LessonPoint('10の まとまり', '10が いくつと ばらが いくつで 大きい かずを あらわす。', '10が3こと ばら4こで 34'),
        LessonPoint('100', '10が 10こで 100（ひゃく）。', '99 の つぎは 100'),
      ],
    ),
    InnLesson(
      stageId: 'math_e1_06',
      teacher: '小1の宿・つづり先生',
      title: 'くりあがりの ある たしざん',
      points: [
        LessonPoint('10を つくる', 'たす かずを わけて、まず 10 を つくる。', '8 + 5 → 8 + 2 + 3 = 13'),
      ],
    ),
    InnLesson(
      stageId: 'math_e1_07',
      teacher: '小1の宿・つづり先生',
      title: 'くりさがりの ある ひきざん',
      points: [
        LessonPoint('10から ひく', '13 − 8 は、10 − 8 = 2 と 3 を あわせて 5。', '13 − 8 = 5'),
      ],
    ),
    InnLesson(
      stageId: 'math_e2_01',
      teacher: '小2の宿・つづり先生',
      title: 'たし算のひっ算',
      points: [
        LessonPoint('くらいをそろえる', '一のくらいどうし、十のくらいどうしをたてにそろえて書く。', '  36\n+ 47\n= 83'),
        LessonPoint('くり上がり', '一のくらいが10をこえたら、十のくらいに1くり上げる。', '6 + 7 = 13 → 3を書いて1くり上がる'),
      ],
    ),
    InnLesson(
      stageId: 'math_e2_02',
      teacher: '小2の宿・つづり先生',
      title: 'ひき算のひっ算',
      points: [
        LessonPoint('くり下がり', 'ひけないときは十のくらいから10をかりてくる。', '52 − 18 → 12 − 8 = 4、4 − 1 = 3 → 34'),
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
        LessonPoint('長方形と正方形', '長方形 ＝ たて × よこ、正方形 ＝ 1辺 × 1辺。', '3cm × 5cm ＝ 15cm²'),
        LessonPoint('単位', '1m² ＝ 10000cm²、1a ＝ 100m²、1ha ＝ 10000m²。', ''),
      ],
    ),
    InnLesson(
      stageId: 'math_e5_05',
      teacher: '小5の宿・つづり先生',
      title: '倍数と約数',
      points: [
        LessonPoint('倍数', 'ある数に整数をかけてできる数。公倍数のいちばん小さいものが最小公倍数。', '4と6の最小公倍数は12'),
        LessonPoint('約数', 'ある数をわりきれる整数。公約数のいちばん大きいものが最大公約数。', '12と18の最大公約数は6'),
      ],
    ),
    InnLesson(
      stageId: 'math_e5_08',
      teacher: '小5の宿・つづり先生',
      title: '単位量あたりの大きさ・速さ',
      points: [
        LessonPoint('速さの3公式', '速さ ＝ 道のり ÷ 時間、道のり ＝ 速さ × 時間、時間 ＝ 道のり ÷ 速さ。', '120km ÷ 2時間 ＝ 時速60km'),
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
        LessonPoint('方程式の解き方', '①かっこ・分数をなくす ②移項 ③ax＝b ④両辺をaでわる', '3x + 5 ＝ 20 → 3x ＝ 15 → x ＝ 5'),
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
        LessonPoint('乗法公式', '(x + a)(x + b)、(a ± b)²、(a + b)(a − b) の4つ。', '(x + 2)(x + 5) ＝ x² + 7x + 10'),
        LessonPoint('因数分解', '和と積に注目して2数をさがす。', 'x² + 5x + 6 ＝ (x + 2)(x + 3)'),
      ],
    ),
  ];
}
