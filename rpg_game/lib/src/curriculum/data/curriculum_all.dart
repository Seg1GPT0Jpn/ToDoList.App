// このファイルは tool/curriculum/build.py が生成しています。手で直さず src/*.txt を直してください。

import '../curriculum.dart';
import 'curriculum_english.dart';
import 'curriculum_math.dart';
import 'curriculum_japanese.dart';
import 'curriculum_science.dart';
import 'curriculum_social.dart';

/// すべての教科の学習体系（画面に出す順）
const allCurricula = <CurriculumNode>[
  englishCurriculum,
  mathCurriculum,
  japaneseCurriculum,
  scienceCurriculum,
  socialCurriculum,
];
