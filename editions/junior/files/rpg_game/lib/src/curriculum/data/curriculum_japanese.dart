// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const japaneseCurriculum = CurriculumNode(
  id: 'japanese',
  name: '国語',
  level: CurriculumLevel.subject,
  gameName: '言の葉の国',
  curriculumReference: '小学校 国語・中学校 国語',
  source: '文部科学省 小学校・中学校学習指導要領（平成29年告示）',
  sourceUrl: 'https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm',
  children: [
    CurriculumNode(
      id: 'japanese.e1',
      name: '小1',
      level: CurriculumLevel.course,
      gameName: '小1の道',
      description: 'ひらがな・カタカナ・かん字・文のきまり・おはなし',
      grade: '小1',
      children: [
        CurriculumNode(
          id: 'japanese.e1.s1',
          name: 'ひらがなと かん字',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e1.s1.a01',
              name: 'ひらがな',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e1.s1.a01.main',
                  name: 'ひらがな',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e1.s1.a02',
              name: 'カタカナ',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e1.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.e1.s1.a02.main',
                  name: 'カタカナ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e1.s1.a03',
              name: 'かん字の よみ（1年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e1.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.e1.s1.a03.main',
                  name: 'かん字の よみ（1年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e1.s1.a04',
              name: 'ひらがなと かん字の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e1.s1.a04.main',
                  name: 'ひらがなと かん字の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.e1.s2',
          name: 'ことばと おはなし',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e1.s2.a05',
              name: 'かん字の かき（1年）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e1.s2.a05.main',
                  name: 'かん字の かき（1年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e1.s2.a06',
              name: 'は・を・へと 文の きまり',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e1.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.e1.s2.a06.main',
                  name: 'は・を・へと 文の きまり',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e1.s2.a07',
              name: 'おはなしを よむ',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e1.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.e1.s2.a07.main',
                  name: 'おはなしを よむ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e1.s2.a08',
              name: '1年生の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e1.s2.a08.main',
                  name: '1年生の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'japanese.e2',
      name: '小2',
      level: CurriculumLevel.course,
      gameName: '小2の道',
      description: 'かん字・なかまのことば・主語と述語・せつめい文・物語',
      grade: '小2',
      children: [
        CurriculumNode(
          id: 'japanese.e2.s1',
          name: '漢字と ことば',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e2.s1.a01',
              name: '漢字の 読み（2年）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e2.s1.a01.main',
                  name: '漢字の 読み（2年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e2.s1.a02',
              name: '漢字の 書き（2年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e2.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.e2.s1.a02.main',
                  name: '漢字の 書き（2年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e2.s1.a03',
              name: 'なかまの ことば・反対の ことば',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e2.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.e2.s1.a03.main',
                  name: 'なかまの ことば・反対の ことば',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e2.s1.a04',
              name: '漢字と ことばの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e2.s1.a04.main',
                  name: '漢字と ことばの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.e2.s2',
          name: '文を 読む',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e2.s2.a05',
              name: '主語と 述語・かたかなの ことば',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e2.s2.a05.main',
                  name: '主語と 述語・かたかなの ことば',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e2.s2.a06',
              name: 'せつめい文を 読む',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e2.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.e2.s2.a06.main',
                  name: 'せつめい文を 読む',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e2.s2.a07',
              name: '物語を 読む',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e2.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.e2.s2.a07.main',
                  name: '物語を 読む',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e2.s2.a08',
              name: '2年生の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e2.s2.a08.main',
                  name: '2年生の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'japanese.e3',
      name: '小3',
      level: CurriculumLevel.course,
      gameName: '小3の道',
      description: '漢字・国語辞典・こそあど・ことわざ・ローマ字・読解',
      grade: '小3',
      children: [
        CurriculumNode(
          id: 'japanese.e3.s1',
          name: '漢字と 辞典',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e3.s1.a01',
              name: '漢字の読み（3年）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e3.s1.a01.main',
                  name: '漢字の読み（3年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e3.s1.a02',
              name: '漢字の書き（3年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e3.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.e3.s1.a02.main',
                  name: '漢字の書き（3年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e3.s1.a03',
              name: '国語辞典と こそあど言葉',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e3.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.e3.s1.a03.main',
                  name: '国語辞典と こそあど言葉',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e3.s1.a04',
              name: '漢字と辞典の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e3.s1.a04.main',
                  name: '漢字と辞典の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.e3.s2',
          name: 'ことわざ・ローマ字・読解',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e3.s2.a05',
              name: 'ことわざ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e3.s2.a05.main',
                  name: 'ことわざ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e3.s2.a06',
              name: 'ローマ字',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e3.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.e3.s2.a06.main',
                  name: 'ローマ字',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e3.s2.a07',
              name: '説明文を読む（3年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e3.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.e3.s2.a07.main',
                  name: '説明文を読む（3年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e3.s2.a08',
              name: '3年生の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e3.s2.a08.main',
                  name: '3年生の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'japanese.e4',
      name: '小4',
      level: CurriculumLevel.course,
      gameName: '小4の道',
      description: '漢字・部首・つなぎ言葉・慣用句・故事成語・読解',
      grade: '小4',
      children: [
        CurriculumNode(
          id: 'japanese.e4.s1',
          name: '漢字と 部首',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e4.s1.a01',
              name: '漢字の読み（4年）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e4.s1.a01.main',
                  name: '漢字の読み（4年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e4.s1.a02',
              name: '漢字の書き（4年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e4.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.e4.s1.a02.main',
                  name: '漢字の書き（4年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e4.s1.a03',
              name: '部首',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e4.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.e4.s1.a03.main',
                  name: '部首',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e4.s1.a04',
              name: '漢字と部首の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e4.s1.a04.main',
                  name: '漢字と部首の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.e4.s2',
          name: '言葉のきまりと 読解',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e4.s2.a05',
              name: 'つなぎ言葉と 修飾語',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e4.s2.a05.main',
                  name: 'つなぎ言葉と 修飾語',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e4.s2.a06',
              name: '慣用句と 故事成語',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e4.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.e4.s2.a06.main',
                  name: '慣用句と 故事成語',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e4.s2.a07',
              name: '説明文を読む（4年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e4.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.e4.s2.a07.main',
                  name: '説明文を読む（4年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e4.s2.a08',
              name: '4年生の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e4.s2.a08.main',
                  name: '4年生の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'japanese.e5',
      name: '小5',
      level: CurriculumLevel.course,
      gameName: '小5の道',
      description: '漢字・敬語・和語漢語外来語・熟語・古文・読解',
      grade: '小5',
      children: [
        CurriculumNode(
          id: 'japanese.e5.s1',
          name: '漢字と 敬語',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e5.s1.a01',
              name: '漢字の読み（5年）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e5.s1.a01.main',
                  name: '漢字の読み（5年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e5.s1.a02',
              name: '漢字の書き（5年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e5.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.e5.s1.a02.main',
                  name: '漢字の書き（5年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e5.s1.a03',
              name: '敬語',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e5.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.e5.s1.a03.main',
                  name: '敬語',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e5.s1.a04',
              name: '漢字と敬語の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e5.s1.a04.main',
                  name: '漢字と敬語の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.e5.s2',
          name: '言葉の由来と 古典',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e5.s2.a05',
              name: '和語・漢語・外来語と 熟語の組み立て',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e5.s2.a05.main',
                  name: '和語・漢語・外来語と 熟語の組み立て',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e5.s2.a06',
              name: '古文に親しむ',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e5.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.e5.s2.a06.main',
                  name: '古文に親しむ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e5.s2.a07',
              name: '説明文を読む（5年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e5.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.e5.s2.a07.main',
                  name: '説明文を読む（5年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e5.s2.a08',
              name: '5年生の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e5.s2.a08.main',
                  name: '5年生の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'japanese.e6',
      name: '小6',
      level: CurriculumLevel.course,
      gameName: '小6の道',
      description: '漢字・同音異義語・文の組み立て・古典・読解',
      grade: '小6',
      children: [
        CurriculumNode(
          id: 'japanese.e6.s1',
          name: '漢字と 熟語',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e6.s1.a01',
              name: '漢字の読み（6年）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e6.s1.a01.main',
                  name: '漢字の読み（6年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e6.s1.a02',
              name: '漢字の書き（6年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e6.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.e6.s1.a02.main',
                  name: '漢字の書き（6年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e6.s1.a03',
              name: '同音異義語・同訓異字',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e6.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.e6.s1.a03.main',
                  name: '同音異義語・同訓異字',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e6.s1.a04',
              name: '漢字と熟語の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e6.s1.a04.main',
                  name: '漢字と熟語の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.e6.s2',
          name: '文の組み立てと 古典',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.e6.s2.a05',
              name: '文の組み立て',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e6.s2.a05.main',
                  name: '文の組み立て',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e6.s2.a06',
              name: '古典・短歌と俳句',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e6.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.e6.s2.a06.main',
                  name: '古典・短歌と俳句',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e6.s2.a07',
              name: '物語を読む（6年）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.e6.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.e6.s2.a07.main',
                  name: '物語を読む（6年）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.e6.s2.a08',
              name: '小学校国語の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.e6.s2.a08.main',
                  name: '小学校国語の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'japanese.j1',
      name: '中1',
      level: CurriculumLevel.course,
      gameName: '中1の道',
      description: '漢字・文法（文節と品詞）・古文の基礎・故事成語・説明的文章',
      grade: '中1',
      children: [
        CurriculumNode(
          id: 'japanese.j1.s1',
          name: '漢字と 文法',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.j1.s1.a01',
              name: '漢字の読み（中1）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j1.s1.a01.main',
                  name: '漢字の読み（中1）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j1.s1.a02',
              name: '漢字の書き（中1）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j1.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.j1.s1.a02.main',
                  name: '漢字の書き（中1）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j1.s1.a03',
              name: '文法：文節・単語・品詞',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j1.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.j1.s1.a03.main',
                  name: '文法：文節・単語・品詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j1.s1.a04',
              name: '漢字と文法の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j1.s1.a04.main',
                  name: '漢字と文法の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.j1.s2',
          name: '古典と 説明的文章',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.j1.s2.a05',
              name: '古文の基礎：竹取物語',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j1.s2.a05.main',
                  name: '古文の基礎：竹取物語',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j1.s2.a06',
              name: '故事成語と 漢文の読み方',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j1.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.j1.s2.a06.main',
                  name: '故事成語と 漢文の読み方',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j1.s2.a07',
              name: '説明的文章を読む（中1）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j1.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.j1.s2.a07.main',
                  name: '説明的文章を読む（中1）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j1.s2.a08',
              name: '中1の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j1.s2.a08.main',
                  name: '中1の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'japanese.j2',
      name: '中2',
      level: CurriculumLevel.course,
      gameName: '中2の道',
      description: '漢字・用言の活用・枕草子・徒然草・平家物語・漢詩',
      grade: '中2',
      children: [
        CurriculumNode(
          id: 'japanese.j2.s1',
          name: '漢字と 用言の活用',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.j2.s1.a01',
              name: '漢字の読み（中2）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j2.s1.a01.main',
                  name: '漢字の読み（中2）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j2.s1.a02',
              name: '漢字の書き（中2）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j2.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.j2.s1.a02.main',
                  name: '漢字の書き（中2）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j2.s1.a03',
              name: '文法：用言の活用',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j2.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.j2.s1.a03.main',
                  name: '文法：用言の活用',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j2.s1.a04',
              name: '漢字と活用の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j2.s1.a04.main',
                  name: '漢字と活用の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.j2.s2',
          name: '古典と 文学的文章',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.j2.s2.a05',
              name: '枕草子・徒然草・平家物語',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j2.s2.a05.main',
                  name: '枕草子・徒然草・平家物語',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j2.s2.a06',
              name: '漢詩',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j2.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.j2.s2.a06.main',
                  name: '漢詩',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j2.s2.a07',
              name: '文学的文章を読む（中2）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j2.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.j2.s2.a07.main',
                  name: '文学的文章を読む（中2）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j2.s2.a08',
              name: '中2の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j2.s2.a08.main',
                  name: '中2の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'japanese.j3',
      name: '中3',
      level: CurriculumLevel.course,
      gameName: '中3の道',
      description: '漢字・助詞と助動詞・敬語・おくのほそ道・和歌・論語',
      grade: '中3',
      children: [
        CurriculumNode(
          id: 'japanese.j3.s1',
          name: '漢字と 文法・敬語',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.j3.s1.a01',
              name: '漢字の読み（中3）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j3.s1.a01.main',
                  name: '漢字の読み（中3）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j3.s1.a02',
              name: '漢字の書き（中3）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j3.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'japanese.j3.s1.a02.main',
                  name: '漢字の書き（中3）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j3.s1.a03',
              name: '文法：助詞・助動詞と敬語',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j3.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'japanese.j3.s1.a03.main',
                  name: '文法：助詞・助動詞と敬語',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j3.s1.a04',
              name: '文法と敬語の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j3.s1.a04.main',
                  name: '文法と敬語の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'japanese.j3.s2',
          name: '古典と 論理的な文章',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'japanese.j3.s2.a05',
              name: 'おくのほそ道と和歌',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j3.s2.a05.main',
                  name: 'おくのほそ道と和歌',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j3.s2.a06',
              name: '論語',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j3.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'japanese.j3.s2.a06.main',
                  name: '論語',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j3.s2.a07',
              name: '論理的な文章を読む（中3）',
              level: CurriculumLevel.unit,
              prerequisites: ['japanese.j3.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'japanese.j3.s2.a07.main',
                  name: '論理的な文章を読む（中3）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'japanese.j3.s2.a08',
              name: '中学国語の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'japanese.j3.s2.a08.main',
                  name: '中学国語の まとめ',
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
