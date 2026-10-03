// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const englishCurriculum = CurriculumNode(
  id: 'english',
  name: '英語',
  level: CurriculumLevel.subject,
  gameName: '英語の国',
  curriculumReference: '小学校 外国語活動・外国語、中学校 外国語（英語）',
  source: '文部科学省 小学校・中学校学習指導要領（平成29年告示）',
  sourceUrl: 'https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm',
  children: [
    CurriculumNode(
      id: 'english.e34',
      name: '小3・4',
      level: CurriculumLevel.course,
      gameName: '小3・4の道',
      description: 'アルファベット・あいさつ・数・色・好きなもの',
      grade: '小3-4',
      children: [
        CurriculumNode(
          id: 'english.e34.s1',
          name: 'ABCと あいさつ',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.e34.s1.a01',
              name: 'アルファベット',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e34.s1.a01.main',
                  name: 'アルファベット',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e34.s1.a02',
              name: 'あいさつと 気もち',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e34.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'english.e34.s1.a02.main',
                  name: 'あいさつと 気もち',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e34.s1.a03',
              name: '数（1〜20）',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e34.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'english.e34.s1.a03.main',
                  name: '数（1〜20）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e34.s1.a04',
              name: '色と形',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e34.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'english.e34.s1.a04.main',
                  name: '色と形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e34.s1.a05',
              name: 'ABCと あいさつの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e34.s1.a05.main',
                  name: 'ABCと あいさつの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'english.e34.s2',
          name: 'すきなもの',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.e34.s2.a06',
              name: '動物',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e34.s1.a04'],
              children: [
                CurriculumNode(
                  id: 'english.e34.s2.a06.main',
                  name: '動物',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e34.s2.a07',
              name: '食べ物とくだもの',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e34.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'english.e34.s2.a07.main',
                  name: '食べ物とくだもの',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e34.s2.a08',
              name: '曜日と天気',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e34.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'english.e34.s2.a08.main',
                  name: '曜日と天気',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e34.s2.a09',
              name: '体とからだの動き',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e34.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'english.e34.s2.a09.main',
                  name: '体とからだの動き',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e34.s2.a10',
              name: 'すきなものの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e34.s2.a10.main',
                  name: 'すきなものの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'english.e5',
      name: '小5',
      level: CurriculumLevel.course,
      gameName: '小5の道',
      description: '自己紹介・誕生日・できること・道案内・注文',
      grade: '小5',
      children: [
        CurriculumNode(
          id: 'english.e5.s1',
          name: 'わたしのこと',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.e5.s1.a01',
              name: '自己紹介',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e5.s1.a01.main',
                  name: '自己紹介',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e5.s1.a02',
              name: '月と誕生日',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e5.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'english.e5.s1.a02.main',
                  name: '月と誕生日',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e5.s1.a03',
              name: 'できること（can）',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e5.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'english.e5.s1.a03.main',
                  name: 'できること（can）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e5.s1.a04',
              name: 'わたしのことの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e5.s1.a04.main',
                  name: 'わたしのことの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'english.e5.s2',
          name: '町とくらし',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.e5.s2.a05',
              name: '時間割と教科',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e5.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'english.e5.s2.a05.main',
                  name: '時間割と教科',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e5.s2.a06',
              name: '道案内',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e5.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'english.e5.s2.a06.main',
                  name: '道案内',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e5.s2.a07',
              name: 'レストランで注文',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e5.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'english.e5.s2.a07.main',
                  name: 'レストランで注文',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e5.s2.a08',
              name: '町とくらしの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e5.s2.a08.main',
                  name: '町とくらしの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'english.e6',
      name: '小6',
      level: CurriculumLevel.course,
      gameName: '小6の道',
      description: '過去のこと・夏休み・将来の夢・町しょうかい・中学校',
      grade: '小6',
      children: [
        CurriculumNode(
          id: 'english.e6.s1',
          name: '思い出と夢',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.e6.s1.a01',
              name: '週末にしたこと（過去）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e6.s1.a01.main',
                  name: '週末にしたこと（過去）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e6.s1.a02',
              name: '夏休みの思い出',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e6.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'english.e6.s1.a02.main',
                  name: '夏休みの思い出',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e6.s1.a03',
              name: '将来の夢',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e6.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'english.e6.s1.a03.main',
                  name: '将来の夢',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e6.s1.a04',
              name: '思い出と夢の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e6.s1.a04.main',
                  name: '思い出と夢の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'english.e6.s2',
          name: '日本と世界',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.e6.s2.a05',
              name: '行ってみたい国',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e6.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'english.e6.s2.a05.main',
                  name: '行ってみたい国',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e6.s2.a06',
              name: 'わたしたちの町と日本',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e6.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'english.e6.s2.a06.main',
                  name: 'わたしたちの町と日本',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e6.s2.a07',
              name: '中学校への準備',
              level: CurriculumLevel.unit,
              prerequisites: ['english.e6.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'english.e6.s2.a07.main',
                  name: '中学校への準備',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.e6.s2.a08',
              name: '小学校英語の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.e6.s2.a08.main',
                  name: '小学校英語の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'english.j1',
      name: '中1',
      level: CurriculumLevel.course,
      gameName: '中1の道',
      description: 'be動詞・一般動詞・3単現・疑問詞・進行形・can・過去形',
      grade: '中1',
      children: [
        CurriculumNode(
          id: 'english.j1.s1',
          name: '現在の文',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.j1.s1.a01',
              name: 'be動詞',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j1.s1.a01.main',
                  name: 'be動詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j1.s1.a02',
              name: '一般動詞',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j1.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'english.j1.s1.a02.main',
                  name: '一般動詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j1.s1.a03',
              name: '3人称単数現在',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j1.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'english.j1.s1.a03.main',
                  name: '3人称単数現在',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j1.s1.a04',
              name: '名詞の複数形と代名詞',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j1.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'english.j1.s1.a04.main',
                  name: '名詞の複数形と代名詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j1.s1.a05',
              name: '現在の文の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j1.s1.a05.main',
                  name: '現在の文の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'english.j1.s2',
          name: '進行形・can・過去',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.j1.s2.a06',
              name: '疑問詞',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j1.s1.a04'],
              children: [
                CurriculumNode(
                  id: 'english.j1.s2.a06.main',
                  name: '疑問詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j1.s2.a07',
              name: '現在進行形',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j1.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'english.j1.s2.a07.main',
                  name: '現在進行形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j1.s2.a08',
              name: 'can と命令文',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j1.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'english.j1.s2.a08.main',
                  name: 'can と命令文',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j1.s2.a09',
              name: '過去形',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j1.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'english.j1.s2.a09.main',
                  name: '過去形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j1.s2.a10',
              name: '中1の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j1.s2.a10.main',
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
      id: 'english.j2',
      name: '中2',
      level: CurriculumLevel.course,
      gameName: '中2の道',
      description: '未来・助動詞・不定詞・動名詞・接続詞・比較・受け身',
      grade: '中2',
      children: [
        CurriculumNode(
          id: 'english.j2.s1',
          name: '未来・助動詞・不定詞',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.j2.s1.a01',
              name: '未来の表現',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j2.s1.a01.main',
                  name: '未来の表現',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j2.s1.a02',
              name: '助動詞',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j2.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'english.j2.s1.a02.main',
                  name: '助動詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j2.s1.a03',
              name: '不定詞',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j2.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'english.j2.s1.a03.main',
                  name: '不定詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j2.s1.a04',
              name: '動名詞',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j2.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'english.j2.s1.a04.main',
                  name: '動名詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j2.s1.a05',
              name: '未来・助動詞・不定詞の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j2.s1.a05.main',
                  name: '未来・助動詞・不定詞の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'english.j2.s2',
          name: '接続詞・比較・受け身',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.j2.s2.a06',
              name: '接続詞',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j2.s1.a04'],
              children: [
                CurriculumNode(
                  id: 'english.j2.s2.a06.main',
                  name: '接続詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j2.s2.a07',
              name: '比較',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j2.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'english.j2.s2.a07.main',
                  name: '比較',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j2.s2.a08',
              name: '受け身',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j2.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'english.j2.s2.a08.main',
                  name: '受け身',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j2.s2.a09',
              name: 'いろいろな文型',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j2.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'english.j2.s2.a09.main',
                  name: 'いろいろな文型',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j2.s2.a10',
              name: '中2の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j2.s2.a10.main',
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
      id: 'english.j3',
      name: '中3',
      level: CurriculumLevel.course,
      gameName: '中3の道',
      description: '現在完了・不定詞の発展・分詞・関係代名詞・間接疑問・仮定法',
      grade: '中3',
      children: [
        CurriculumNode(
          id: 'english.j3.s1',
          name: '現在完了と不定詞',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.j3.s1.a01',
              name: '現在完了（完了・経験）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j3.s1.a01.main',
                  name: '現在完了（完了・経験）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j3.s1.a02',
              name: '現在完了（継続）・現在完了進行形',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j3.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'english.j3.s1.a02.main',
                  name: '現在完了（継続）・現在完了進行形',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j3.s1.a03',
              name: '不定詞の発展',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j3.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'english.j3.s1.a03.main',
                  name: '不定詞の発展',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j3.s1.a04',
              name: '間接疑問',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j3.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'english.j3.s1.a04.main',
                  name: '間接疑問',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j3.s1.a05',
              name: '現在完了と不定詞の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j3.s1.a05.main',
                  name: '現在完了と不定詞の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'english.j3.s2',
          name: '後置修飾と仮定法',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.j3.s2.a06',
              name: '分詞の後置修飾',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j3.s1.a04'],
              children: [
                CurriculumNode(
                  id: 'english.j3.s2.a06.main',
                  name: '分詞の後置修飾',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j3.s2.a07',
              name: '関係代名詞',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j3.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'english.j3.s2.a07.main',
                  name: '関係代名詞',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j3.s2.a08',
              name: '仮定法',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j3.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'english.j3.s2.a08.main',
                  name: '仮定法',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j3.s2.a09',
              name: '会話表現と読み取り',
              level: CurriculumLevel.unit,
              prerequisites: ['english.j3.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'english.j3.s2.a09.main',
                  name: '会話表現と読み取り',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.j3.s2.a10',
              name: '中学英語の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.j3.s2.a10.main',
                  name: '中学英語の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'english.vocab',
      name: '中学の単語と熟語',
      level: CurriculumLevel.course,
      gameName: '単語の森',
      grade: '中1-3',
      children: [
        CurriculumNode(
          id: 'english.vocab.words',
          name: '単語と熟語',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'english.vocab.words.j1',
              name: '中1の単語',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.vocab.words.j1.meaning',
                  name: '意味',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.vocab.words.j2',
              name: '中2の単語',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.vocab.words.j2.meaning',
                  name: '意味',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.vocab.words.j3',
              name: '中3の単語',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.vocab.words.j3.meaning',
                  name: '意味',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'english.vocab.words.idiom',
              name: '中学の熟語',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'english.vocab.words.idiom.idiom',
                  name: '意味',
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
