// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const socialCurriculum =
CurriculumNode(
  id: 'social',
  name: '社会',
  level: CurriculumLevel.subject,
  gameName: '時空の回廊',
  curriculumReference: '小学校 社会・中学校 社会',
  source: '文部科学省 小学校・中学校学習指導要領（平成29年告示）',
  sourceUrl: 'https://www.mext.go.jp/a_menu/shotou/new-cs/1384661.htm',
  children: [
    CurriculumNode(
      id: 'social.e3',
      name: '小3',
      level: CurriculumLevel.course,
      gameName: '小3の道',
      description: 'わたしたちのまち・地図記号・店ではたらく人・工場・火事や事故・昔のくらし',
      grade: '小3',
      children: [
        CurriculumNode(
          id: 'social.e3.s1',
          name: 'わたしたちのまち',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.e3.s1.a01',
              name: '地図と方位',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e3.s1.a01.main',
                  name: '地図と方位',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e3.s1.a02',
              name: '店ではたらく人びと',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e3.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'social.e3.s1.a02.main',
                  name: '店ではたらく人びと',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e3.s1.a03',
              name: '工場と農家の仕事',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e3.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'social.e3.s1.a03.main',
                  name: '工場と農家の仕事',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e3.s1.a04',
              name: 'わたしたちのまちの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e3.s1.a04.main',
                  name: 'わたしたちのまちの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'social.e3.s2',
          name: 'まちのくらしと人びと',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.e3.s2.a05',
              name: '火事からくらしを守る',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e3.s2.a05.main',
                  name: '火事からくらしを守る',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e3.s2.a06',
              name: '事故や事件からくらしを守る',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e3.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'social.e3.s2.a06.main',
                  name: '事故や事件からくらしを守る',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e3.s2.a07',
              name: '昔のくらしと道具',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e3.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'social.e3.s2.a07.main',
                  name: '昔のくらしと道具',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e3.s2.a08',
              name: '3年生の社会の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e3.s2.a08.main',
                  name: '3年生の社会の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'social.e4',
      name: '小4',
      level: CurriculumLevel.course,
      gameName: '小4の道',
      description: '都道府県・水とごみ・自然災害・地いきの伝統と先人',
      grade: '小4',
      children: [
        CurriculumNode(
          id: 'social.e4.s1',
          name: '都道府県とくらし',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.e4.s1.a01',
              name: '47都道府県',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e4.s1.a01.main',
                  name: '47都道府県',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e4.s1.a02',
              name: '水とくらし',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e4.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'social.e4.s1.a02.main',
                  name: '水とくらし',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e4.s1.a03',
              name: 'ごみとくらし',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e4.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'social.e4.s1.a03.main',
                  name: 'ごみとくらし',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e4.s1.a04',
              name: '都道府県とくらしの まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e4.s1.a04.main',
                  name: '都道府県とくらしの まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'social.e4.s2',
          name: '災害と地いきの伝統',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.e4.s2.a05',
              name: '自然災害からくらしを守る',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e4.s2.a05.main',
                  name: '自然災害からくらしを守る',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e4.s2.a06',
              name: '地いきの伝統と文化',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e4.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'social.e4.s2.a06.main',
                  name: '地いきの伝統と文化',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e4.s2.a07',
              name: '地いきの発展につくした人びと',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e4.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'social.e4.s2.a07.main',
                  name: '地いきの発展につくした人びと',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e4.s2.a08',
              name: '4年生の社会の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e4.s2.a08.main',
                  name: '4年生の社会の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'social.e5',
      name: '小5',
      level: CurriculumLevel.course,
      gameName: '小5の道',
      description: '日本の国土・気候・農業・水産業・工業・情報・環境',
      grade: '小5',
      children: [
        CurriculumNode(
          id: 'social.e5.s1',
          name: '日本の国土と食料',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.e5.s1.a01',
              name: '日本の国土と気候',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e5.s1.a01.main',
                  name: '日本の国土と気候',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e5.s1.a02',
              name: '米づくりと農業',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e5.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'social.e5.s1.a02.main',
                  name: '米づくりと農業',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e5.s1.a03',
              name: '水産業と食料自給',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e5.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'social.e5.s1.a03.main',
                  name: '水産業と食料自給',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e5.s1.a04',
              name: '国土と食料の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e5.s1.a04.main',
                  name: '国土と食料の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'social.e5.s2',
          name: '工業・情報・環境',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.e5.s2.a05',
              name: '日本の工業',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e5.s2.a05.main',
                  name: '日本の工業',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e5.s2.a06',
              name: '情報とくらし',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e5.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'social.e5.s2.a06.main',
                  name: '情報とくらし',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e5.s2.a07',
              name: '国土の環境を守る',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e5.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'social.e5.s2.a07.main',
                  name: '国土の環境を守る',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e5.s2.a08',
              name: '5年生の社会の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e5.s2.a08.main',
                  name: '5年生の社会の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'social.e6',
      name: '小6',
      level: CurriculumLevel.course,
      gameName: '小6の道',
      description: '政治のしくみ・日本国憲法・日本の歴史・世界の中の日本',
      grade: '小6',
      children: [
        CurriculumNode(
          id: 'social.e6.s1',
          name: 'わたしたちの生活と政治',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.e6.s1.a01',
              name: '日本国憲法',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e6.s1.a01.main',
                  name: '日本国憲法',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e6.s1.a02',
              name: '国の政治のしくみ',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e6.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'social.e6.s1.a02.main',
                  name: '国の政治のしくみ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e6.s1.a03',
              name: 'くらしをささえる政治',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e6.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'social.e6.s1.a03.main',
                  name: 'くらしをささえる政治',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e6.s1.a04',
              name: '政治の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e6.s1.a04.main',
                  name: '政治の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'social.e6.s2',
          name: '日本の歴史と世界',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.e6.s2.a05',
              name: 'むかしの日本（縄文〜平安）',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e6.s2.a05.main',
                  name: 'むかしの日本（縄文〜平安）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e6.s2.a06',
              name: '武士の時代（鎌倉〜江戸）',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e6.s2.a05'],
              children: [
                CurriculumNode(
                  id: 'social.e6.s2.a06.main',
                  name: '武士の時代（鎌倉〜江戸）',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e6.s2.a07',
              name: '明治から今の日本と世界',
              level: CurriculumLevel.unit,
              prerequisites: ['social.e6.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'social.e6.s2.a07.main',
                  name: '明治から今の日本と世界',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.e6.s2.a08',
              name: '小学校社会の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.e6.s2.a08.main',
                  name: '小学校社会の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'social.geo',
      name: '地理',
      level: CurriculumLevel.course,
      gameName: '地理の道',
      description: '世界の姿・世界の地域・日本の姿・日本の諸地域',
      grade: '中1-2',
      children: [
        CurriculumNode(
          id: 'social.geo.s1',
          name: '世界の姿と世界の地域',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.geo.s1.a01',
              name: '世界の姿',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.geo.s1.a01.main',
                  name: '世界の姿',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.geo.s1.a02',
              name: '世界の人々の生活と環境',
              level: CurriculumLevel.unit,
              prerequisites: ['social.geo.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'social.geo.s1.a02.main',
                  name: '世界の人々の生活と環境',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.geo.s1.a03',
              name: 'アジア・ヨーロッパ',
              level: CurriculumLevel.unit,
              prerequisites: ['social.geo.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'social.geo.s1.a03.main',
                  name: 'アジア・ヨーロッパ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.geo.s1.a04',
              name: 'アフリカ・アメリカ・オセアニア',
              level: CurriculumLevel.unit,
              prerequisites: ['social.geo.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'social.geo.s1.a04.main',
                  name: 'アフリカ・アメリカ・オセアニア',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.geo.s1.a05',
              name: '世界の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.geo.s1.a05.main',
                  name: '世界の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'social.geo.s2',
          name: '日本の姿と諸地域',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.geo.s2.a06',
              name: '日本の姿と自然環境',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.geo.s2.a06.main',
                  name: '日本の姿と自然環境',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.geo.s2.a07',
              name: '九州・中国四国・近畿',
              level: CurriculumLevel.unit,
              prerequisites: ['social.geo.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'social.geo.s2.a07.main',
                  name: '九州・中国四国・近畿',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.geo.s2.a08',
              name: '中部・関東・東北・北海道',
              level: CurriculumLevel.unit,
              prerequisites: ['social.geo.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'social.geo.s2.a08.main',
                  name: '中部・関東・東北・北海道',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.geo.s2.a09',
              name: '地域調査と 地形図',
              level: CurriculumLevel.unit,
              prerequisites: ['social.geo.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'social.geo.s2.a09.main',
                  name: '地域調査と 地形図',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.geo.s2.a10',
              name: '地理の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.geo.s2.a10.main',
                  name: '地理の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'social.hist',
      name: '歴史',
      level: CurriculumLevel.course,
      gameName: '歴史の道',
      description: '古代・中世・近世・近代・現代の日本と世界',
      grade: '中1-3',
      children: [
        CurriculumNode(
          id: 'social.hist.s1',
          name: '古代〜近世',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.hist.s1.a01',
              name: '古代文明と日本の始まり',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.hist.s1.a01.main',
                  name: '古代文明と日本の始まり',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.hist.s1.a02',
              name: '飛鳥・奈良・平安',
              level: CurriculumLevel.unit,
              prerequisites: ['social.hist.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'social.hist.s1.a02.main',
                  name: '飛鳥・奈良・平安',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.hist.s1.a03',
              name: '鎌倉・室町',
              level: CurriculumLevel.unit,
              prerequisites: ['social.hist.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'social.hist.s1.a03.main',
                  name: '鎌倉・室町',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.hist.s1.a04',
              name: '安土桃山・江戸',
              level: CurriculumLevel.unit,
              prerequisites: ['social.hist.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'social.hist.s1.a04.main',
                  name: '安土桃山・江戸',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.hist.s1.a05',
              name: '古代〜近世の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.hist.s1.a05.main',
                  name: '古代〜近世の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'social.hist.s2',
          name: '近代〜現代',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.hist.s2.a06',
              name: '欧米の近代化と開国',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.hist.s2.a06.main',
                  name: '欧米の近代化と開国',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.hist.s2.a07',
              name: '明治維新と近代国家',
              level: CurriculumLevel.unit,
              prerequisites: ['social.hist.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'social.hist.s2.a07.main',
                  name: '明治維新と近代国家',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.hist.s2.a08',
              name: '二度の世界大戦',
              level: CurriculumLevel.unit,
              prerequisites: ['social.hist.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'social.hist.s2.a08.main',
                  name: '二度の世界大戦',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.hist.s2.a09',
              name: '戦後の日本と現代',
              level: CurriculumLevel.unit,
              prerequisites: ['social.hist.s2.a08'],
              children: [
                CurriculumNode(
                  id: 'social.hist.s2.a09.main',
                  name: '戦後の日本と現代',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.hist.s2.a10',
              name: '歴史の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.hist.s2.a10.main',
                  name: '歴史の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'social.civ',
      name: '公民',
      level: CurriculumLevel.course,
      gameName: '公民の道',
      description: '現代社会・日本国憲法・政治・経済・国際社会',
      grade: '中3',
      children: [
        CurriculumNode(
          id: 'social.civ.s1',
          name: '現代社会と憲法・政治',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.civ.s1.a01',
              name: '現代社会とわたしたち',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.civ.s1.a01.main',
                  name: '現代社会とわたしたち',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.civ.s1.a02',
              name: '人権と日本国憲法',
              level: CurriculumLevel.unit,
              prerequisites: ['social.civ.s1.a01'],
              children: [
                CurriculumNode(
                  id: 'social.civ.s1.a02.main',
                  name: '人権と日本国憲法',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.civ.s1.a03',
              name: '民主政治と選挙',
              level: CurriculumLevel.unit,
              prerequisites: ['social.civ.s1.a02'],
              children: [
                CurriculumNode(
                  id: 'social.civ.s1.a03.main',
                  name: '民主政治と選挙',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.civ.s1.a04',
              name: '国会・内閣・裁判所・地方自治',
              level: CurriculumLevel.unit,
              prerequisites: ['social.civ.s1.a03'],
              children: [
                CurriculumNode(
                  id: 'social.civ.s1.a04.main',
                  name: '国会・内閣・裁判所・地方自治',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.civ.s1.a05',
              name: '憲法と政治の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.civ.s1.a05.main',
                  name: '憲法と政治の まとめ',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
          ],
        ),
        CurriculumNode(
          id: 'social.civ.s2',
          name: '経済と国際社会',
          level: CurriculumLevel.field,
          children: [
            CurriculumNode(
              id: 'social.civ.s2.a06',
              name: '消費生活と市場経済',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.civ.s2.a06.main',
                  name: '消費生活と市場経済',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.civ.s2.a07',
              name: '金融と財政',
              level: CurriculumLevel.unit,
              prerequisites: ['social.civ.s2.a06'],
              children: [
                CurriculumNode(
                  id: 'social.civ.s2.a07.main',
                  name: '金融と財政',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.civ.s2.a08',
              name: '国際社会と地球規模の課題',
              level: CurriculumLevel.unit,
              prerequisites: ['social.civ.s2.a07'],
              children: [
                CurriculumNode(
                  id: 'social.civ.s2.a08.main',
                  name: '国際社会と地球規模の課題',
                  level: CurriculumLevel.subUnit,
                ),
              ],
            ),
            CurriculumNode(
              id: 'social.civ.s2.a09',
              name: '経済と国際社会の まとめ',
              level: CurriculumLevel.unit,
              children: [
                CurriculumNode(
                  id: 'social.civ.s2.a09.main',
                  name: '経済と国際社会の まとめ',
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
