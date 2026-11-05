// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';

const eikenCurriculum = CurriculumNode(
  id: 'eiken',
  name: '英検',
  level: CurriculumLevel.subject,
  gameName: '英検の世界',
  curriculumReference: '実用英語技能検定（英検）の各級の語彙',
  source: '公益財団法人 日本英語検定協会「各級の目安」',
  sourceUrl: 'https://www.eiken.or.jp/eiken/exam/about/',
  children: [
    CurriculumNode(
      id: 'eiken.p2',
      name: '準2級',
      level: CurriculumLevel.course,
      gameName: '準2級の道',
      description: '英検準2級レベルの単語（約1,500語）',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'eiken.p2.vocab',
          name: '単語',
          level: CurriculumLevel.field,
          curriculumReference: '準2級の語彙',
          children: [
            CurriculumNode(
              id: 'eiken.p2.vocab.words',
              name: '単語帳',
              level: CurriculumLevel.unit,
              description: '準2級の単語',
              children: [
                CurriculumNode(
                  id: 'eiken.p2.vocab.words.a',
                  name: 'A〜M の単語',
                  level: CurriculumLevel.subUnit,
                  keywords: ['a'],
                ),
                CurriculumNode(
                  id: 'eiken.p2.vocab.words.n',
                  name: 'N〜Z の単語',
                  level: CurriculumLevel.subUnit,
                  keywords: ['n'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'eiken.g2',
      name: '2級',
      level: CurriculumLevel.course,
      gameName: '2級の道',
      description: '英検2級レベルの単語（約2,000語）',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'eiken.g2.vocab',
          name: '単語',
          level: CurriculumLevel.field,
          curriculumReference: '2級の語彙',
          children: [
            CurriculumNode(
              id: 'eiken.g2.vocab.words',
              name: '単語帳',
              level: CurriculumLevel.unit,
              description: '2級の単語',
              children: [
                CurriculumNode(
                  id: 'eiken.g2.vocab.words.a',
                  name: 'A〜M の単語',
                  level: CurriculumLevel.subUnit,
                  keywords: ['a'],
                ),
                CurriculumNode(
                  id: 'eiken.g2.vocab.words.n',
                  name: 'N〜Z の単語',
                  level: CurriculumLevel.subUnit,
                  keywords: ['n'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'eiken.p1',
      name: '準1級',
      level: CurriculumLevel.course,
      gameName: '準1級の道',
      description: '英検準1級レベルの単語（約2,500語）',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'eiken.p1.vocab',
          name: '単語',
          level: CurriculumLevel.field,
          curriculumReference: '準1級の語彙',
          children: [
            CurriculumNode(
              id: 'eiken.p1.vocab.words',
              name: '単語帳',
              level: CurriculumLevel.unit,
              description: '準1級の単語',
              children: [
                CurriculumNode(
                  id: 'eiken.p1.vocab.words.a',
                  name: 'A〜M の単語',
                  level: CurriculumLevel.subUnit,
                  keywords: ['a'],
                ),
                CurriculumNode(
                  id: 'eiken.p1.vocab.words.n',
                  name: 'N〜Z の単語',
                  level: CurriculumLevel.subUnit,
                  keywords: ['n'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    CurriculumNode(
      id: 'eiken.g1',
      name: '1級',
      level: CurriculumLevel.course,
      gameName: '1級の道',
      description: '英検1級レベルの単語（約3,000語）',
      grade: '1-3',
      children: [
        CurriculumNode(
          id: 'eiken.g1.vocab',
          name: '単語',
          level: CurriculumLevel.field,
          curriculumReference: '1級の語彙',
          children: [
            CurriculumNode(
              id: 'eiken.g1.vocab.words',
              name: '単語帳',
              level: CurriculumLevel.unit,
              description: '1級の単語',
              children: [
                CurriculumNode(
                  id: 'eiken.g1.vocab.words.a',
                  name: 'A〜M の単語',
                  level: CurriculumLevel.subUnit,
                  keywords: ['a'],
                ),
                CurriculumNode(
                  id: 'eiken.g1.vocab.words.n',
                  name: 'N〜Z の単語',
                  level: CurriculumLevel.subUnit,
                  keywords: ['n'],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
