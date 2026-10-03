// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const scienceCurriculum = CurriculumNode(
  id: 'science',
  name: '理科',
  level: CurriculumLevel.subject,
  gameName: '理の国',
  curriculumReference: '小学校 理科・中学校 理科',
  source: '文部科学省 小学校・中学校学習指導要領（平成29年告示）',
  sourceUrl: 'https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm',
  children: [
    CurriculumNode(
      id: 'science.e3',
      name: '小3',
      level: CurriculumLevel.course,
      gameName: '小3の道',
      description: 'しぜんのかんさつ・こん虫・植物・風とゴム・光と音・電気と磁石・重さ',
      grade: '小3',
      children: [
        CurriculumNode(
          id: 'science.e3.s1',
          name: '生き物のかんさつ',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.e3.s1.a01',
              name: 'こん虫のからだ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e3.s1.a01.main',
                  name: 'こん虫のからだ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e3.s1.a02',
              name: '植物の育ち方',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e3.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'science.e3.s1.a02.main',
                  name: '植物の育ち方',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e3.s1.a03',
              name: '太陽とかげ',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e3.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'science.e3.s1.a03.main',
                  name: '太陽とかげ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e3.s1.a04',
              name: '生き物と太陽の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e3.s1.a04.main',
                  name: '生き物と太陽の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'science.e3.s2',
          name: 'もののせいしつ',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.e3.s2.a05',
              name: '風とゴムの力',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e3.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'science.e3.s2.a05.main',
                  name: '風とゴムの力',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e3.s2.a06',
              name: '光と音',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e3.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'science.e3.s2.a06.main',
                  name: '光と音',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e3.s2.a07',
              name: '電気の通り道と じしゃく',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e3.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'science.e3.s2.a07.main',
                  name: '電気の通り道と じしゃく',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e3.s2.a08',
              name: 'ものの重さ',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e3.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'science.e3.s2.a08.main',
                  name: 'ものの重さ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e3.s2.a09',
              name: '3年生の理科の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e3.s2.a09.main',
                  name: '3年生の理科の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'science.e4',
      name: '小4',
      level: CurriculumLevel.course,
      gameName: '小4の道',
      description: '季節と生き物・天気・電流・空気と水・体のつくり・月と星・もののあたたまり方',
      grade: '小4',
      children: [
        CurriculumNode(
          id: 'science.e4.s1',
          name: '天気と生き物',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.e4.s1.a01',
              name: '季節と生き物',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e4.s1.a01.main',
                  name: '季節と生き物',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e4.s1.a02',
              name: '天気と気温・水のゆくえ',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e4.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'science.e4.s1.a02.main',
                  name: '天気と気温・水のゆくえ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e4.s1.a03',
              name: '月と星',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e4.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'science.e4.s1.a03.main',
                  name: '月と星',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e4.s1.a04',
              name: '天気と星の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e4.s1.a04.main',
                  name: '天気と星の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'science.e4.s2',
          name: 'ものと体',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.e4.s2.a05',
              name: '電流のはたらき',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e4.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'science.e4.s2.a05.main',
                  name: '電流のはたらき',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e4.s2.a06',
              name: '空気と水・ものの温度',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e4.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'science.e4.s2.a06.main',
                  name: '空気と水・ものの温度',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e4.s2.a07',
              name: '人の体のつくりと運動',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e4.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'science.e4.s2.a07.main',
                  name: '人の体のつくりと運動',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e4.s2.a08',
              name: '4年生の理科の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e4.s2.a08.main',
                  name: '4年生の理科の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'science.e5',
      name: '小5',
      level: CurriculumLevel.course,
      gameName: '小5の道',
      description: '天気の変化・植物の発芽と成長・魚と人のたんじょう・流れる水・ふりこ・電磁石・もののとけ方',
      grade: '小5',
      children: [
        CurriculumNode(
          id: 'science.e5.s1',
          name: '生命のつながり',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.e5.s1.a01',
              name: '植物の発芽と成長',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e5.s1.a01.main',
                  name: '植物の発芽と成長',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e5.s1.a02',
              name: '花から実へ',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e5.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'science.e5.s1.a02.main',
                  name: '花から実へ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e5.s1.a03',
              name: '魚と人のたんじょう',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e5.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'science.e5.s1.a03.main',
                  name: '魚と人のたんじょう',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e5.s1.a04',
              name: '生命のつながりの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e5.s1.a04.main',
                  name: '生命のつながりの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'science.e5.s2',
          name: '天気と流れる水・もの',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.e5.s2.a05',
              name: '天気の変化',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e5.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'science.e5.s2.a05.main',
                  name: '天気の変化',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e5.s2.a06',
              name: '流れる水のはたらき',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e5.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'science.e5.s2.a06.main',
                  name: '流れる水のはたらき',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e5.s2.a07',
              name: 'ふりこと 電磁石',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e5.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'science.e5.s2.a07.main',
                  name: 'ふりこと 電磁石',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e5.s2.a08',
              name: 'もののとけ方',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e5.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'science.e5.s2.a08.main',
                  name: 'もののとけ方',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e5.s2.a09',
              name: '5年生の理科の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e5.s2.a09.main',
                  name: '5年生の理科の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'science.e6',
      name: '小6',
      level: CurriculumLevel.course,
      gameName: '小6の道',
      description: 'ものの燃え方・人の体・植物の養分・生き物と環境・月と太陽・大地・水よう液・てこ・電気の利用',
      grade: '小6',
      children: [
        CurriculumNode(
          id: 'science.e6.s1',
          name: '人と生き物・地球',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.e6.s1.a01',
              name: 'ものの燃え方と空気',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e6.s1.a01.main',
                  name: 'ものの燃え方と空気',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e6.s1.a02',
              name: '人の体のはたらき',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e6.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'science.e6.s1.a02.main',
                  name: '人の体のはたらき',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e6.s1.a03',
              name: '植物の養分と水・生き物と環境',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e6.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'science.e6.s1.a03.main',
                  name: '植物の養分と水・生き物と環境',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e6.s1.a04',
              name: '人と生き物の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e6.s1.a04.main',
                  name: '人と生き物の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'science.e6.s2',
          name: 'ものとエネルギー',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.e6.s2.a05',
              name: '月と太陽・大地のつくり',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e6.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'science.e6.s2.a05.main',
                  name: '月と太陽・大地のつくり',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e6.s2.a06',
              name: '水よう液の性質',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e6.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'science.e6.s2.a06.main',
                  name: '水よう液の性質',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e6.s2.a07',
              name: 'てこと 電気の利用',
              level: CurriculumLevel.unit,
              prerequisites: ['science.e6.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'science.e6.s2.a07.main',
                  name: 'てこと 電気の利用',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.e6.s2.a08',
              name: '小学校理科の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.e6.s2.a08.main',
                  name: '小学校理科の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'science.j1',
      name: '中1',
      level: CurriculumLevel.course,
      gameName: '中1の道',
      description: '植物と動物の分類・身のまわりの物質・光と音と力・大地の変化',
      grade: '中1',
      children: [
        CurriculumNode(
          id: 'science.j1.s1',
          name: 'いろいろな生物と 物質',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.j1.s1.a01',
              name: '植物の分類',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j1.s1.a01.main',
                  name: '植物の分類',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j1.s1.a02',
              name: '動物の分類',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j1.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'science.j1.s1.a02.main',
                  name: '動物の分類',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j1.s1.a03',
              name: '身のまわりの物質',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j1.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'science.j1.s1.a03.main',
                  name: '身のまわりの物質',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j1.s1.a04',
              name: '生物と物質の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j1.s1.a04.main',
                  name: '生物と物質の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'science.j1.s2',
          name: '光・音・力と 大地',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.j1.s2.a05',
              name: '光と音',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j1.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'science.j1.s2.a05.main',
                  name: '光と音',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j1.s2.a06',
              name: '力のはたらき',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j1.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'science.j1.s2.a06.main',
                  name: '力のはたらき',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j1.s2.a07',
              name: '大地の変化',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j1.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'science.j1.s2.a07.main',
                  name: '大地の変化',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j1.s2.a08',
              name: '中1理科の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j1.s2.a08.main',
                  name: '中1理科の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'science.j2',
      name: '中2',
      level: CurriculumLevel.course,
      gameName: '中2の道',
      description: '化学変化と原子・分子・生物の体のつくり・電流と磁界・天気とその変化',
      grade: '中2',
      children: [
        CurriculumNode(
          id: 'science.j2.s1',
          name: '化学変化と 生物の体',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.j2.s1.a01',
              name: '化学変化と原子・分子',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j2.s1.a01.main',
                  name: '化学変化と原子・分子',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j2.s1.a02',
              name: '化学反応式と熱',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j2.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'science.j2.s1.a02.main',
                  name: '化学反応式と熱',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j2.s1.a03',
              name: '生物の体のつくりとはたらき',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j2.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'science.j2.s1.a03.main',
                  name: '生物の体のつくりとはたらき',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j2.s1.a04',
              name: '化学変化と生物の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j2.s1.a04.main',
                  name: '化学変化と生物の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'science.j2.s2',
          name: '電流と 天気',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.j2.s2.a05',
              name: '電流と電圧',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j2.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'science.j2.s2.a05.main',
                  name: '電流と電圧',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j2.s2.a06',
              name: '電流と磁界',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j2.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'science.j2.s2.a06.main',
                  name: '電流と磁界',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j2.s2.a07',
              name: '天気とその変化',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j2.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'science.j2.s2.a07.main',
                  name: '天気とその変化',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j2.s2.a08',
              name: '中2理科の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j2.s2.a08.main',
                  name: '中2理科の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'science.j3',
      name: '中3',
      level: CurriculumLevel.course,
      gameName: '中3の道',
      description: '化学変化とイオン・生命の連続性・運動とエネルギー・地球と宇宙・自然と人間',
      grade: '中3',
      children: [
        CurriculumNode(
          id: 'science.j3.s1',
          name: 'イオンと 生命の連続性',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.j3.s1.a01',
              name: '水溶液とイオン',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j3.s1.a01.main',
                  name: '水溶液とイオン',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j3.s1.a02',
              name: '生物のふえ方と遺伝',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j3.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'science.j3.s1.a02.main',
                  name: '生物のふえ方と遺伝',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j3.s1.a03',
              name: '自然と人間',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j3.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'science.j3.s1.a03.main',
                  name: '自然と人間',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j3.s1.a04',
              name: 'イオンと生命の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j3.s1.a04.main',
                  name: 'イオンと生命の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'science.j3.s2',
          name: '運動・エネルギーと 宇宙',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'science.j3.s2.a05',
              name: '物体の運動',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j3.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'science.j3.s2.a05.main',
                  name: '物体の運動',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j3.s2.a06',
              name: '仕事とエネルギー',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j3.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'science.j3.s2.a06.main',
                  name: '仕事とエネルギー',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j3.s2.a07',
              name: '地球と宇宙',
              level: CurriculumLevel.unit,
              prerequisites: ['science.j3.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'science.j3.s2.a07.main',
                  name: '地球と宇宙',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'science.j3.s2.a08',
              name: '中学理科の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'science.j3.s2.a08.main',
                  name: '中学理科の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
