// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const mathCurriculum = CurriculumNode(
  id: 'math',
  name: '算数・数学',
  level: CurriculumLevel.subject,
  gameName: '数の国',
  curriculumReference: '小学校 算数・中学校 数学',
  source: '文部科学省 小学校・中学校学習指導要領（平成29年告示）',
  sourceUrl: 'https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm',
  children: [
    CurriculumNode(
      id: 'math.e1',
      name: '小1',
      level: CurriculumLevel.course,
      gameName: '小1の道',
      description: '10までの数・たし算ひき算・大きい数・とけい・かたち',
      grade: '小1',
      children: [
        CurriculumNode(
          id: 'math.e1.s1',
          name: 'かずとけいさん',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e1.s1.a01',
              name: '10までのかず',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e1.s1.a01.main',
                  name: '10までのかず',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e1.s1.a02',
              name: 'たしざん',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e1.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.e1.s1.a02.main',
                  name: 'たしざん',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e1.s1.a03',
              name: 'ひきざん',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e1.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.e1.s1.a03.main',
                  name: 'ひきざん',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e1.s1.a04',
              name: 'かずとけいさんの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e1.s1.a04.main',
                  name: 'かずとけいさんの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.e1.s2',
          name: '大きいかずと くりあがり・くりさがり',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e1.s2.a05',
              name: '大きいかず（100まで）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e1.s2.a05.main',
                  name: '大きいかず（100まで）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e1.s2.a06',
              name: 'くりあがりの ある たしざん',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e1.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'math.e1.s2.a06.main',
                  name: 'くりあがりの ある たしざん',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e1.s2.a07',
              name: 'くりさがりの ある ひきざん',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e1.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.e1.s2.a07.main',
                  name: 'くりさがりの ある ひきざん',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e1.s2.a08',
              name: 'とけい',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e1.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.e1.s2.a08.main',
                  name: 'とけい',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e1.s2.a09',
              name: 'かたちと ながさくらべ',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e1.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'math.e1.s2.a09.main',
                  name: 'かたちと ながさくらべ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e1.s2.a10',
              name: '1ねんせいの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e1.s2.a10.main',
                  name: '1ねんせいの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'math.e2',
      name: '小2',
      level: CurriculumLevel.course,
      gameName: '小2の道',
      description: 'ひっ算・1000までの数・長さとかさ・時こく・九九・三角形と四角形',
      grade: '小2',
      children: [
        CurriculumNode(
          id: 'math.e2.s1',
          name: 'ひっ算と大きい数',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e2.s1.a01',
              name: 'たし算のひっ算',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e2.s1.a01.main',
                  name: 'たし算のひっ算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s1.a02',
              name: 'ひき算のひっ算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e2.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.e2.s1.a02.main',
                  name: 'ひき算のひっ算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s1.a03',
              name: '1000までの数',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e2.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.e2.s1.a03.main',
                  name: '1000までの数',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s1.a04',
              name: 'ひっ算と大きい数のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e2.s1.a04.main',
                  name: 'ひっ算と大きい数のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.e2.s2',
          name: 'はかり方とかけ算',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e2.s2.a05',
              name: '長さ（mm・cm・m）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e2.s2.a05.main',
                  name: '長さ（mm・cm・m）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s2.a06',
              name: 'かさ（L・dL・mL）',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e2.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'math.e2.s2.a06.main',
                  name: 'かさ（L・dL・mL）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s2.a07',
              name: '時こくと時間',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e2.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.e2.s2.a07.main',
                  name: '時こくと時間',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s2.a08',
              name: 'かけ算九九（2・3・4・5のだん）',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e2.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.e2.s2.a08.main',
                  name: 'かけ算九九（2・3・4・5のだん）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s2.a09',
              name: 'かけ算九九（6・7・8・9・1のだん）',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e2.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'math.e2.s2.a09.main',
                  name: 'かけ算九九（6・7・8・9・1のだん）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s2.a10',
              name: '三角形と四角形・はこの形',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e2.s2.a09'],
              children: [
                CurriculumNode(
                  id: 'math.e2.s2.a10.main',
                  name: '三角形と四角形・はこの形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e2.s2.a11',
              name: '2年生のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e2.s2.a11.main',
                  name: '2年生のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'math.e3',
      name: '小3',
      level: CurriculumLevel.course,
      gameName: '小3の道',
      description: 'わり算・大きい数・筆算・小数・分数・円と球',
      grade: '小3',
      children: [
        CurriculumNode(
          id: 'math.e3.s1',
          name: 'わり算と大きい数',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e3.s1.a01',
              name: 'かけ算のきまり',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e3.s1.a01.main',
                  name: 'かけ算のきまり',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s1.a02',
              name: 'わり算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e3.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.e3.s1.a02.main',
                  name: 'わり算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s1.a03',
              name: '大きい数（万の位）',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e3.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.e3.s1.a03.main',
                  name: '大きい数（万の位）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s1.a04',
              name: 'わり算と大きい数のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e3.s1.a04.main',
                  name: 'わり算と大きい数のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.e3.s2',
          name: '筆算・小数・分数・図形',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e3.s2.a05',
              name: '3けた・4けたのたし算とひき算',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e3.s2.a05.main',
                  name: '3けた・4けたのたし算とひき算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s2.a06',
              name: 'かけ算の筆算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e3.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'math.e3.s2.a06.main',
                  name: 'かけ算の筆算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s2.a07',
              name: 'あまりのあるわり算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e3.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.e3.s2.a07.main',
                  name: 'あまりのあるわり算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s2.a08',
              name: '小数',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e3.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.e3.s2.a08.main',
                  name: '小数',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s2.a09',
              name: '分数',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e3.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'math.e3.s2.a09.main',
                  name: '分数',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s2.a10',
              name: '円と球・重さ・三角形',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e3.s2.a09'],
              children: [
                CurriculumNode(
                  id: 'math.e3.s2.a10.main',
                  name: '円と球・重さ・三角形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e3.s2.a11',
              name: '3年生のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e3.s2.a11.main',
                  name: '3年生のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'math.e4',
      name: '小4',
      level: CurriculumLevel.course,
      gameName: '小4の道',
      description: '億と兆・わり算の筆算・角・小数・分数・面積・がい数',
      grade: '小4',
      children: [
        CurriculumNode(
          id: 'math.e4.s1',
          name: '大きい数・わり算・角',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e4.s1.a01',
              name: '大きい数（億・兆）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e4.s1.a01.main',
                  name: '大きい数（億・兆）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s1.a02',
              name: 'わり算の筆算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e4.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.e4.s1.a02.main',
                  name: 'わり算の筆算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s1.a03',
              name: '角の大きさ',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e4.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.e4.s1.a03.main',
                  name: '角の大きさ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s1.a04',
              name: '大きい数・わり算・角のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e4.s1.a04.main',
                  name: '大きい数・わり算・角のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.e4.s2',
          name: '小数・分数・面積',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e4.s2.a05',
              name: '小数のたし算とひき算',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e4.s2.a05.main',
                  name: '小数のたし算とひき算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s2.a06',
              name: '小数のかけ算とわり算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e4.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'math.e4.s2.a06.main',
                  name: '小数のかけ算とわり算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s2.a07',
              name: '分数（仮分数・帯分数）',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e4.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.e4.s2.a07.main',
                  name: '分数（仮分数・帯分数）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s2.a08',
              name: '面積',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e4.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.e4.s2.a08.main',
                  name: '面積',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s2.a09',
              name: '垂直・平行と四角形・直方体',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e4.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'math.e4.s2.a09.main',
                  name: '垂直・平行と四角形・直方体',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s2.a10',
              name: 'がい数',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e4.s2.a09'],
              children: [
                CurriculumNode(
                  id: 'math.e4.s2.a10.main',
                  name: 'がい数',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e4.s2.a11',
              name: '4年生のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e4.s2.a11.main',
                  name: '4年生のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'math.e5',
      name: '小5',
      level: CurriculumLevel.course,
      gameName: '小5の道',
      description: '小数のかけ算わり算・倍数と約数・分数・平均・速さ・割合・面積と体積',
      grade: '小5',
      children: [
        CurriculumNode(
          id: 'math.e5.s1',
          name: '小数のかけ算わり算・倍数と約数',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e5.s1.a01',
              name: '整数と小数・体積',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e5.s1.a01.main',
                  name: '整数と小数・体積',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s1.a02',
              name: '小数のかけ算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e5.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.e5.s1.a02.main',
                  name: '小数のかけ算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s1.a03',
              name: '小数のわり算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e5.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.e5.s1.a03.main',
                  name: '小数のわり算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s1.a04',
              name: '小数と体積のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e5.s1.a04.main',
                  name: '小数と体積のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.e5.s2',
          name: '分数・平均・割合・図形',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e5.s2.a05',
              name: '倍数と約数',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e5.s2.a05.main',
                  name: '倍数と約数',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s2.a06',
              name: '分数のたし算とひき算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e5.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'math.e5.s2.a06.main',
                  name: '分数のたし算とひき算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s2.a07',
              name: '平均',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e5.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.e5.s2.a07.main',
                  name: '平均',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s2.a08',
              name: '単位量あたりの大きさ・速さ',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e5.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.e5.s2.a08.main',
                  name: '単位量あたりの大きさ・速さ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s2.a09',
              name: '割合と百分率',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e5.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'math.e5.s2.a09.main',
                  name: '割合と百分率',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s2.a10',
              name: '図形の角・面積・円周',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e5.s2.a09'],
              children: [
                CurriculumNode(
                  id: 'math.e5.s2.a10.main',
                  name: '図形の角・面積・円周',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e5.s2.a11',
              name: '5年生のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e5.s2.a11.main',
                  name: '5年生のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'math.e6',
      name: '小6',
      level: CurriculumLevel.course,
      gameName: '小6の道',
      description: '文字と式・分数のかけ算わり算・比・比例と反比例・円の面積・体積・場合の数',
      grade: '小6',
      children: [
        CurriculumNode(
          id: 'math.e6.s1',
          name: '文字と式・分数の計算',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e6.s1.a01',
              name: '文字と式',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e6.s1.a01.main',
                  name: '文字と式',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e6.s1.a02',
              name: '分数のかけ算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e6.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.e6.s1.a02.main',
                  name: '分数のかけ算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e6.s1.a03',
              name: '分数のわり算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e6.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.e6.s1.a03.main',
                  name: '分数のわり算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e6.s1.a04',
              name: '文字と式・分数のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e6.s1.a04.main',
                  name: '文字と式・分数のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.e6.s2',
          name: '比・比例・図形・データ',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.e6.s2.a05',
              name: '比',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e6.s2.a05.main',
                  name: '比',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e6.s2.a06',
              name: '比例と反比例',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e6.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'math.e6.s2.a06.main',
                  name: '比例と反比例',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e6.s2.a07',
              name: '対称な図形・拡大図と縮図・円の面積',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e6.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.e6.s2.a07.main',
                  name: '対称な図形・拡大図と縮図・円の面積',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e6.s2.a08',
              name: '立体の体積・場合の数・データ',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e6.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.e6.s2.a08.main',
                  name: '立体の体積・場合の数・データ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e6.s2.a09',
              name: '計算のきまり（総合）',
              level: CurriculumLevel.unit,
              prerequisites: ['math.e6.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'math.e6.s2.a09.main',
                  name: '計算のきまり（総合）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.e6.s2.a10',
              name: '6年生のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.e6.s2.a10.main',
                  name: '6年生のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'math.j1',
      name: '中1',
      level: CurriculumLevel.course,
      gameName: '中1の道',
      description: '正負の数・文字式・方程式・比例反比例・平面図形・空間図形・データ',
      grade: '中1',
      children: [
        CurriculumNode(
          id: 'math.j1.s1',
          name: '数と式',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.j1.s1.a01',
              name: '正負の数',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j1.s1.a01.main',
                  name: '正負の数',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j1.s1.a02',
              name: '正負の数の計算',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j1.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.j1.s1.a02.main',
                  name: '正負の数の計算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j1.s1.a03',
              name: '文字と式',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j1.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.j1.s1.a03.main',
                  name: '文字と式',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j1.s1.a04',
              name: '数と式のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j1.s1.a04.main',
                  name: '数と式のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j1.s1.a05',
              name: '一次方程式',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j1.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'math.j1.s1.a05.main',
                  name: '一次方程式',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.j1.s2',
          name: '関数・図形・データ',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.j1.s2.a06',
              name: '比例と反比例',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j1.s2.a06.main',
                  name: '比例と反比例',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j1.s2.a07',
              name: '平面図形',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j1.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.j1.s2.a07.main',
                  name: '平面図形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j1.s2.a08',
              name: '空間図形',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j1.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.j1.s2.a08.main',
                  name: '空間図形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j1.s2.a09',
              name: 'データの活用',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j1.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'math.j1.s2.a09.main',
                  name: 'データの活用',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j1.s2.a10',
              name: '中1のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j1.s2.a10.main',
                  name: '中1のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'math.j2',
      name: '中2',
      level: CurriculumLevel.course,
      gameName: '中2の道',
      description: '式の計算・連立方程式・一次関数・図形の性質と証明・確率・箱ひげ図',
      grade: '中2',
      children: [
        CurriculumNode(
          id: 'math.j2.s1',
          name: '式と方程式・一次関数',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.j2.s1.a01',
              name: '式の計算',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j2.s1.a01.main',
                  name: '式の計算',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j2.s1.a02',
              name: '連立方程式',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j2.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.j2.s1.a02.main',
                  name: '連立方程式',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j2.s1.a03',
              name: '一次関数',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j2.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.j2.s1.a03.main',
                  name: '一次関数',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j2.s1.a04',
              name: '式と関数のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j2.s1.a04.main',
                  name: '式と関数のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.j2.s2',
          name: '図形・確率・データ',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.j2.s2.a05',
              name: '平行と合同',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j2.s2.a05.main',
                  name: '平行と合同',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j2.s2.a06',
              name: '三角形と四角形',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j2.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'math.j2.s2.a06.main',
                  name: '三角形と四角形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j2.s2.a07',
              name: '確率',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j2.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.j2.s2.a07.main',
                  name: '確率',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j2.s2.a08',
              name: 'データの分布（箱ひげ図）',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j2.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.j2.s2.a08.main',
                  name: 'データの分布（箱ひげ図）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j2.s2.a09',
              name: '中2のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j2.s2.a09.main',
                  name: '中2のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'math.j3',
      name: '中3',
      level: CurriculumLevel.course,
      gameName: '中3の道',
      description: '展開と因数分解・平方根・二次方程式・関数y=ax²・相似・円・三平方・標本調査',
      grade: '中3',
      children: [
        CurriculumNode(
          id: 'math.j3.s1',
          name: '式と方程式',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.j3.s1.a01',
              name: '展開と因数分解',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j3.s1.a01.main',
                  name: '展開と因数分解',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j3.s1.a02',
              name: '平方根',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j3.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'math.j3.s1.a02.main',
                  name: '平方根',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j3.s1.a03',
              name: '二次方程式',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j3.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'math.j3.s1.a03.main',
                  name: '二次方程式',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j3.s1.a04',
              name: '式と方程式のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j3.s1.a04.main',
                  name: '式と方程式のまとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'math.j3.s2',
          name: '関数と図形',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'math.j3.s2.a05',
              name: '関数 y = ax²',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j3.s2.a05.main',
                  name: '関数 y = ax²',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j3.s2.a06',
              name: '相似な図形',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j3.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'math.j3.s2.a06.main',
                  name: '相似な図形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j3.s2.a07',
              name: '円周角',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j3.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'math.j3.s2.a07.main',
                  name: '円周角',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j3.s2.a08',
              name: '三平方の定理',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j3.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'math.j3.s2.a08.main',
                  name: '三平方の定理',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j3.s2.a09',
              name: '標本調査',
              level: CurriculumLevel.unit,
              prerequisites: ['math.j3.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'math.j3.s2.a09.main',
                  name: '標本調査',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'math.j3.s2.a10',
              name: '中3のまとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'math.j3.s2.a10.main',
                  name: '中3のまとめ',
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
