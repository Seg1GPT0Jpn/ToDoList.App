// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const musicCurriculum = CurriculumNode(
  id: 'music',
  name: '音楽',
  level: CurriculumLevel.subject,
  gameName: '音楽の虹',
  curriculumReference: '高等学校学習指導要領（平成30年告示）第2章第7節 芸術（音楽Ⅰ 共通事項）',
  source: '文部科学省 高等学校学習指導要領（平成30年告示）',
  sourceUrl: 'https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm',
  children: [
    CurriculumNode(
      id: 'music.theory',
      name: '楽典',
      level: CurriculumLevel.course,
      gameName: '音楽の虹',
      description: '譜と音・調と音階・和音・音楽用語',
      curriculumReference: '音楽Ⅰ〔共通事項〕',
      grade: '1',
      children: [
        CurriculumNode(
          id: 'music.theory.notation',
          name: '譜と音',
          level: CurriculumLevel.field,
          curriculumReference: '音楽Ⅰ〔共通事項〕(1)イ 音符・休符・記号など',
          children: [
            CurriculumNode(
              id: 'music.theory.notation.clef',
              name: '音部記号と譜表',
              level: CurriculumLevel.unit,
              description: 'ト音・ヘ音・ハ音記号と譜表',
              children: [
                CurriculumNode(
                  id: 'music.theory.notation.clef.clef',
                  name: '音部記号のしくみ',
                  level: CurriculumLevel.subUnit,
                  keywords: ['音部記号', 'ト音', 'ヘ音', 'ハ音'],
                ),
                CurriculumNode(
                  id: 'music.theory.notation.clef.staff',
                  name: '譜表と中央ド',
                  level: CurriculumLevel.subUnit,
                  keywords: ['譜表', '大譜表', '中央ド'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.notation.name',
              name: '音名と変化記号',
              level: CurriculumLevel.unit,
              description: 'ドイツ音名・変化記号・異名同音',
              children: [
                CurriculumNode(
                  id: 'music.theory.notation.name.natural',
                  name: 'ドイツ音名（幹音）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['幹音', 'ドイツ音名'],
                ),
                CurriculumNode(
                  id: 'music.theory.notation.name.derived',
                  name: 'ドイツ音名（派生音）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['派生音', 'is', 'es'],
                ),
                CurriculumNode(
                  id: 'music.theory.notation.name.accidental',
                  name: '変化記号と異名同音',
                  level: CurriculumLevel.subUnit,
                  keywords: ['シャープ', 'フラット', 'ナチュラル', '異名同音', '変化記号'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.notation.interval',
              name: '音程',
              level: CurriculumLevel.unit,
              description: '度数・協和・増減・転回',
              prerequisites: ['music.theory.notation.name'],
              children: [
                CurriculumNode(
                  id: 'music.theory.notation.interval.basic',
                  name: '音程の基礎（度数）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['度', '音程'],
                ),
                CurriculumNode(
                  id: 'music.theory.notation.interval.consonance',
                  name: '協和音程と不協和音程',
                  level: CurriculumLevel.subUnit,
                  keywords: ['協和', '不協和'],
                ),
                CurriculumNode(
                  id: 'music.theory.notation.interval.natural',
                  name: '音程を答える（幹音）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['幹音', '長', '短', '完全'],
                ),
                CurriculumNode(
                  id: 'music.theory.notation.interval.altered',
                  name: '音程を答える（派生音・増減）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['増', '減', '重増'],
                ),
                CurriculumNode(
                  id: 'music.theory.notation.interval.inversion',
                  name: '音程の転回',
                  level: CurriculumLevel.subUnit,
                  keywords: ['転回'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.notation.rhythm',
              name: '音符と拍子',
              level: CurriculumLevel.unit,
              description: '音符と休符・付点・拍子',
              children: [
                CurriculumNode(
                  id: 'music.theory.notation.rhythm.note',
                  name: '音符と休符・付点',
                  level: CurriculumLevel.subUnit,
                  keywords: ['音符', '休符', '付点'],
                ),
                CurriculumNode(
                  id: 'music.theory.notation.rhythm.meter',
                  name: '拍子',
                  level: CurriculumLevel.subUnit,
                  keywords: ['拍子'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'music.theory.key',
          name: '調と音階',
          level: CurriculumLevel.field,
          curriculumReference: '音楽Ⅰ〔共通事項〕(1)イ 調・音階',
          children: [
            CurriculumNode(
              id: 'music.theory.key.signature',
              name: '調号と主音',
              level: CurriculumLevel.unit,
              description: '調号から調を判断する',
              children: [
                CurriculumNode(
                  id: 'music.theory.key.signature.mechanism',
                  name: '調号のしくみ',
                  level: CurriculumLevel.subUnit,
                  keywords: ['調号'],
                ),
                CurriculumNode(
                  id: 'music.theory.key.signature.sharp',
                  name: '♯系の長調',
                  level: CurriculumLevel.subUnit,
                  keywords: ['♯', 'シャープ'],
                ),
                CurriculumNode(
                  id: 'music.theory.key.signature.flat',
                  name: '♭系の長調',
                  level: CurriculumLevel.subUnit,
                  keywords: ['♭', 'フラット'],
                ),
                CurriculumNode(
                  id: 'music.theory.key.signature.minor',
                  name: '短調の調号',
                  level: CurriculumLevel.subUnit,
                  keywords: ['短調'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.key.relation',
              name: '関係調',
              level: CurriculumLevel.unit,
              description: '同主調・平行調・属調・下属調・近親調',
              prerequisites: ['music.theory.key.signature'],
              children: [
                CurriculumNode(
                  id: 'music.theory.key.relation.parallel',
                  name: '同主調と平行調',
                  level: CurriculumLevel.subUnit,
                  keywords: ['同主調', '平行調'],
                ),
                CurriculumNode(
                  id: 'music.theory.key.relation.dominant',
                  name: '属調・下属調と近親調',
                  level: CurriculumLevel.subUnit,
                  keywords: ['属調', '下属調', '近親調'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.key.scale',
              name: '音階',
              level: CurriculumLevel.unit,
              description: '長音階・3種の短音階・音階の音の名前',
              children: [
                CurriculumNode(
                  id: 'music.theory.key.scale.major',
                  name: '長音階のしくみ',
                  level: CurriculumLevel.subUnit,
                  keywords: ['長音階'],
                ),
                CurriculumNode(
                  id: 'music.theory.key.scale.minor',
                  name: '短音階（自然・和声・旋律）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['自然短音階', '和声短音階', '旋律短音階', '短音階'],
                ),
                CurriculumNode(
                  id: 'music.theory.key.scale.degree',
                  name: '主音・属音・下属音・導音',
                  level: CurriculumLevel.subUnit,
                  keywords: ['主音', '属音', '下属音', '導音'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.key.world',
              name: '世界の音階',
              level: CurriculumLevel.unit,
              description: '教会旋法・日本と世界の音階',
              children: [
                CurriculumNode(
                  id: 'music.theory.key.world.mode',
                  name: '教会旋法',
                  level: CurriculumLevel.subUnit,
                  keywords: ['旋法', 'ドリア', 'フリギア', 'リディア', 'ミクソリディア'],
                ),
                CurriculumNode(
                  id: 'music.theory.key.world.ethnic',
                  name: '日本と世界の音階',
                  level: CurriculumLevel.subUnit,
                  keywords: ['民謡', '都節', '律', '琉球', 'ペンタトニック', '五音'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'music.theory.harmony',
          name: '和音',
          level: CurriculumLevel.field,
          curriculumReference: '音楽Ⅰ〔共通事項〕(1)イ 和音',
          children: [
            CurriculumNode(
              id: 'music.theory.harmony.triad',
              name: '和音の種類',
              level: CurriculumLevel.unit,
              description: '三和音・転回形・七の和音',
              children: [
                CurriculumNode(
                  id: 'music.theory.harmony.triad.basic',
                  name: '和音の基礎',
                  level: CurriculumLevel.subUnit,
                  keywords: ['和音'],
                ),
                CurriculumNode(
                  id: 'music.theory.harmony.triad.kind',
                  name: '三和音の種類（長・短・増・減）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['長三和音', '短三和音', '増三和音', '減三和音'],
                ),
                CurriculumNode(
                  id: 'music.theory.harmony.triad.inversion',
                  name: '和音の転回形',
                  level: CurriculumLevel.subUnit,
                  keywords: ['転回形', '第1転回', '第2転回'],
                ),
                CurriculumNode(
                  id: 'music.theory.harmony.triad.seventh',
                  name: '属七の和音と減七の和音',
                  level: CurriculumLevel.subUnit,
                  keywords: ['属七', '減七', '七の和音'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.harmony.degree',
              name: '音階と和音',
              level: CurriculumLevel.unit,
              description: '長調・短調の各度の和音',
              prerequisites: ['music.theory.harmony.triad'],
              children: [
                CurriculumNode(
                  id: 'music.theory.harmony.degree.major',
                  name: '長調の各度の和音',
                  level: CurriculumLevel.subUnit,
                  keywords: ['長調'],
                ),
                CurriculumNode(
                  id: 'music.theory.harmony.degree.minor',
                  name: '短調の各度の和音',
                  level: CurriculumLevel.subUnit,
                  keywords: ['短調'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.harmony.function',
              name: '和音の機能と進行',
              level: CurriculumLevel.unit,
              description: 'T・D・S とカデンツ',
              prerequisites: ['music.theory.harmony.degree'],
              children: [
                CurriculumNode(
                  id: 'music.theory.harmony.function.function',
                  name: '和音の機能（T・D・S）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['トニック', 'ドミナント', 'サブドミナント', '機能'],
                ),
                CurriculumNode(
                  id: 'music.theory.harmony.function.cadence',
                  name: '終止（カデンツ）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['終止', 'カデンツ', '偽終止', '半終止'],
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'music.theory.terms',
          name: '音楽用語',
          level: CurriculumLevel.field,
          curriculumReference: '音楽Ⅰ〔共通事項〕(1)イ 用語・記号',
          children: [
            CurriculumNode(
              id: 'music.theory.terms.expression',
              name: '速度・強弱・発想',
              level: CurriculumLevel.unit,
              description: '速度記号・強弱記号・発想記号',
              children: [
                CurriculumNode(
                  id: 'music.theory.terms.expression.tempo',
                  name: '速度記号',
                  level: CurriculumLevel.subUnit,
                  keywords: ['速度', 'Allegro', 'Andante', 'Adagio', 'Moderato'],
                ),
                CurriculumNode(
                  id: 'music.theory.terms.expression.dynamics',
                  name: '強弱記号',
                  level: CurriculumLevel.subUnit,
                  keywords: ['強弱', 'f', 'p', 'crescendo'],
                ),
                CurriculumNode(
                  id: 'music.theory.terms.expression.expression',
                  name: '発想記号',
                  level: CurriculumLevel.subUnit,
                  keywords: ['発想', 'cantabile', 'dolce', 'espressivo'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.terms.performance',
              name: '奏法と反復記号',
              level: CurriculumLevel.unit,
              description: '奏法の記号・反復記号',
              children: [
                CurriculumNode(
                  id: 'music.theory.terms.performance.articulation',
                  name: '奏法の記号',
                  level: CurriculumLevel.subUnit,
                  keywords: ['スタッカート', 'スラー', 'テヌート', 'アクセント', '奏法'],
                ),
                CurriculumNode(
                  id: 'music.theory.terms.performance.repeat',
                  name: '反復記号',
                  level: CurriculumLevel.subUnit,
                  keywords: ['反復', 'D.C.', 'D.S.', 'Coda', 'Fine'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.terms.chord',
              name: 'コードネーム',
              level: CurriculumLevel.unit,
              description: 'コードネームの読み方',
              prerequisites: ['music.theory.harmony.triad'],
              children: [
                CurriculumNode(
                  id: 'music.theory.terms.chord.triad',
                  name: 'コードネーム（三和音）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['コードネーム', 'm', 'aug', 'dim'],
                ),
                CurriculumNode(
                  id: 'music.theory.terms.chord.seventh',
                  name: 'コードネーム（七の和音・sus4）',
                  level: CurriculumLevel.subUnit,
                  keywords: ['7', 'M7', 'sus4'],
                ),
              ],
            ),
            CurriculumNode(
              id: 'music.theory.terms.instrument',
              name: '楽器と声',
              level: CurriculumLevel.unit,
              description: '楽器の分類・声の種類',
              children: [
                CurriculumNode(
                  id: 'music.theory.terms.instrument.instrument',
                  name: '楽器の分類',
                  level: CurriculumLevel.subUnit,
                  keywords: ['楽器', '弦楽器', '管楽器', '打楽器'],
                ),
                CurriculumNode(
                  id: 'music.theory.terms.instrument.voice',
                  name: '声の種類',
                  level: CurriculumLevel.subUnit,
                  keywords: ['ソプラノ', 'アルト', 'テノール', 'バス', '声'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
