// 湘南高校2026年度（104回生）1年の試験範囲表から tool/shonan_range_table.py で自動生成（手で直さない）。
// 生成元：委員会が作成した範囲表（Excel）。範囲が空欄の科目は未入力のまま。
import 'school_exam.dart';

class ShonanRangeTable {
  const ShonanRangeTable._();

  /// 範囲表に載っている試験（シート名, 試験名）
  static const sheets = [
    ('前期期末試験', '1年前期期末試験'),
    ('後期中間試験', '1年後期中間試験'),
    ('後期期末試験', '1年後期期末試験'),
  ];

  /// 範囲表のシートから試験計画を作る
  static SchoolExamPlan plan(String sheet,
      {required String id, required DateTime now}) {
    final subjects = <String, SubjectExamPlan>{};
    switch (sheet) {
      case '前期期末試験':
        subjects['gendai_kokugo'] = SubjectExamPlan(
            subjectId: 'gendai_kokugo',
            rangeText: '',
            examDate: DateTime.parse('2026-08-25'),
            existingSetIds: const [
              'japanese_gendai_01',
              'japanese_gendai_02',
              'japanese_kanji_01',
              'japanese_gendai_04',
              'japanese_bungakushi_01'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: 'その他',
                  name: '漢字',
                  range: 'P.12-15,66-113(第3,4章)',
                  note: ''),
              StudyMaterial(
                  kind: 'その他',
                  name: 'キーワード',
                  range: 'P.50-89（21-40）',
                  note: ''),
              StudyMaterial(
                  kind: 'ワーク',
                  name: '開発講座',
                  range: '第3,4問 P.54-80',
                  note: '第5,6問は夏休み課題'),
              StudyMaterial(
                  kind: '配布資料',
                  name: '便覧',
                  range: 'P.228,229,314,315,326,327,334,335',
                  note: '近現代の文学② （ノートP.24）')
            ]);
        subjects['gengo_bunka'] = SubjectExamPlan(
            subjectId: 'gengo_bunka',
            rangeText: '',
            examDate: DateTime.parse('2026-08-27'),
            existingSetIds: const ['japanese_kobun_01', 'japanese_kobun_02'],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: 'その他', name: '古文単語', range: 'P.74-156', note: ''),
              StudyMaterial(
                  kind: 'ワーク', name: 'うさぎ', range: '11~13', note: 'ノート提出'),
              StudyMaterial(
                  kind: '配布資料',
                  name: '便覧',
                  range: 'P.80-83',
                  note: 'ノートはP.13-15'),
              StudyMaterial(
                  kind: 'ワーク', name: 'Z会ワーク', range: '10~13', note: '提出')
            ]);
        subjects['math1'] = SubjectExamPlan(
            subjectId: 'math1',
            rangeText: '2次関数',
            examDate: DateTime.parse('2026-08-28'),
            existingSetIds: const [
              'math_m1_10',
              'math_m1_11',
              'math_m1_12',
              'math_m1_13',
              'math_m1_14',
              'math_m1_15',
              'math_quadratic_app_01'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書', name: '教科書', range: '数Ⅰ P.74-131', note: '2次関数'),
              StudyMaterial(
                  kind: 'ワーク', name: 'サクシード', range: 'P.38-65', note: '提出'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: '青チャート',
                  range: 'P.114-226(例題63-132)',
                  note: '')
            ]);
        subjects['math_a'] = SubjectExamPlan(
            subjectId: 'math_a',
            rangeText: '確率',
            examDate: DateTime.parse('2026-08-26'),
            existingSetIds: const [
              'math_ma_01',
              'math_ma_02',
              'math_ma_03',
              'math_ma_04',
              'math_ma_05',
              'math_ma_06'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書', name: '教科書', range: '数A P.42-77', note: '確率'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: 'サクシード',
                  range: 'P.128-143,144,145',
                  note: '提出'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: '青チャート',
                  range: 'P.404-458(例題36-71)',
                  note: '')
            ]);
        subjects['ec1'] = SubjectExamPlan(
            subjectId: 'ec1',
            rangeText: 'Lesson3,4',
            examDate: DateTime.parse('2026-08-27'),
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書',
                  name: '教科書',
                  range: 'P.40-49,56-65',
                  note: 'Lesson3,4'),
              StudyMaterial(
                  kind: 'その他',
                  name: 'LEAP',
                  range: '501-1100',
                  note: '20-30点程度出題'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: '教科書ワーク',
                  range: 'P.30-34,46-50,40-41,56-57',
                  note: 'Listening,Writing,Expend Your Perspectiveなし')
            ]);
        subjects['ronhyo1'] = SubjectExamPlan(
            subjectId: 'ronhyo1',
            rangeText: '',
            examDate: DateTime.parse('2026-08-25'),
            existingSetIds: const ['english_stage_01', 'english_stage_02'],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: 'ワーク',
                  name: 'チャート',
                  range: 'P.77-115',
                  note: '時制、完了形、助動詞'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: 'be EG 46',
                  range: 'P.20-31',
                  note: 'L6~10'),
              StudyMaterial(
                  kind: 'ワーク', name: 'beワーク', range: 'P.14-25', note: '提出'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: 'Scramble',
                  range: 'P.52-57,66-75,346-363',
                  note: '')
            ]);
        subjects['chemistry_basic'] = SubjectExamPlan(
            subjectId: 'chemistry_basic',
            rangeText: '',
            examDate: DateTime.parse('2026-08-29'),
            existingSetIds: const [
              'science_chemistry_02',
              'science_chemistry_03',
              'science_chemistry_04'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '授業プリント', name: 'プリント', range: 'P.14~42', note: ''),
              StudyMaterial(
                  kind: '教科書', name: '教科書', range: 'P.42~83,88,89', note: ''),
              StudyMaterial(
                  kind: 'ワーク',
                  name: 'セミナー',
                  range: 'P.166⃣~9⃣,17F~G,18~37,130~133',
                  note: '')
            ]);
        subjects['biology_basic'] = SubjectExamPlan(
            subjectId: 'biology_basic',
            rangeText: '',
            examDate: DateTime.parse('2026-08-26'),
            existingSetIds: const ['science_biology_03'],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書', name: '教科書', range: 'P.56~97', note: ''),
              StudyMaterial(
                  kind: 'ワーク', name: 'セミナー', range: 'P.22~49,427', note: '')
            ]);
        subjects['geography_general'] = SubjectExamPlan(
            subjectId: 'geography_general',
            rangeText: '',
            examDate: DateTime.parse('2026-08-25'),
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書', name: '教科書', range: 'P.46~55', note: ''),
              StudyMaterial(
                  kind: '配布資料',
                  name: '資料集',
                  range: 'P.16~21,241️⃣,2️⃣,26,28~39',
                  note: ''),
              StudyMaterial(
                  kind: 'ワーク',
                  name: '問題集',
                  range: 'P.20~27(20~222️⃣,3️⃣ｱｲｳｶｸ,25,26問7を除)',
                  note: ''),
              StudyMaterial(
                  kind: '授業プリント', name: 'プリント', range: 'いわちりプリント5~13', note: '')
            ]);
        subjects['public_economy'] = SubjectExamPlan(
            subjectId: 'public_economy',
            rangeText: '',
            examDate: DateTime.parse('2026-08-29'),
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書', name: '教科書', range: 'P.170~204', note: ''),
              StudyMaterial(
                  kind: '配布資料',
                  name: '資料集',
                  range: 'P.198~225,244~248',
                  note: ''),
              StudyMaterial(
                  kind: '授業プリント', name: 'プリント', range: '冊子No.2すべて', note: '')
            ]);
        subjects['information1'] = SubjectExamPlan(
            subjectId: 'information1',
            rangeText: '',
            examDate: DateTime.parse('2026-08-28'),
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書',
                  name: '教科書',
                  range: 'P.42~49,54,55,69,70,176,189',
                  note: ''),
              StudyMaterial(
                  kind: 'その他',
                  name: '授業ノート',
                  range: '16,17,18-1,19,22',
                  note: '提出')
            ]);
        break;
      case '後期中間試験':
        subjects['gendai_kokugo'] = SubjectExamPlan(
            subjectId: 'gendai_kokugo',
            rangeText: '',
            existingSetIds: const [
              'japanese_gendai_01',
              'japanese_gendai_02',
              'japanese_kanji_01',
              'japanese_gendai_03',
              'japanese_gendai_04',
              'japanese_bungakushi_01'
            ],
            committeeSetIds: const [
              'japanese_shonan_104_gendai_kokugo_01',
              'japanese_shonan_104_gendai_kokugo_02',
              'japanese_shonan_104_gendai_kokugo_03'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: 'その他',
                  name: '漢字',
                  range: 'P.114-157（第5,6章）、P.206-209（四字熟語①②）',
                  note: ''),
              StudyMaterial(
                  kind: 'その他',
                  name: 'キーワード',
                  range: 'P.90-149(41-70)',
                  note: ''),
              StudyMaterial(
                  kind: 'ワーク',
                  name: '開発講座',
                  range: 'P.110-142(第7,8問)',
                  note: ''),
              StudyMaterial(
                  kind: '配布資料',
                  name: '便覧',
                  range: '近現代の文学③、④　P.230,231,314,315,326,327, 334,335',
                  note: 'ノートP.26-27 提出')
            ]);
        subjects['gengo_bunka'] = SubjectExamPlan(
            subjectId: 'gengo_bunka',
            rangeText: '',
            existingSetIds: const [
              'japanese_kobun_01',
              'japanese_kobun_02',
              'japanese_kanbun_01',
              'japanese_kanbun_02'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: 'その他',
                  name: '古文単語',
                  range: 'P.183-258(151-254)',
                  note: ''),
              StudyMaterial(
                  kind: 'ワーク', name: 'うさぎ', range: '14-17', note: 'ノート提出'),
              StudyMaterial(
                  kind: '配布資料',
                  name: '便覧',
                  range: 'P.84-87',
                  note: 'ノートはP.16-17'),
              StudyMaterial(
                  kind: 'ワーク', name: '力をつける漢文', range: '1~6', note: ''),
              StudyMaterial(
                  kind: 'その他', name: 'これ漢ノート', range: 'P.2-12', note: 'ノート提出'),
              StudyMaterial(
                  kind: 'ワーク', name: 'Z会ワーク', range: '14-17', note: '提出')
            ]);
        subjects['math1'] = SubjectExamPlan(
            subjectId: 'math1',
            rangeText: '数Ⅰ：データの分析　数Ⅱ：式と証明、複素数',
            existingSetIds: const [
              'math_m1_16',
              'math_m1_17',
              'math_m1_18',
              'math_m1_stat_01',
              'math_m2_01',
              'math_m2_02',
              'math_m2_03',
              'math_m2_04',
              'math_m2_05',
              'math_m2_06'
            ],
            committeeSetIds: const [
              'math_shonan_104_m1_data_01',
              'math_shonan_104_m1_data_02',
              'math_shonan_104_m1_data_03',
              'math_shonan_104_m1_data_04',
              'math_shonan_104_m1_proof_01',
              'math_shonan_104_m1_proof_02',
              'math_shonan_104_m1_proof_03',
              'math_shonan_104_m1_complex_01',
              'math_shonan_104_m1_complex_02',
              'math_shonan_104_m1_complex_03',
              'math_shonan_104_m1_complex_04'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書',
                  name: '教科書',
                  range: '数Ⅰ P.176~211　数Ⅱ P.11~37,42~68',
                  note: '数Ⅰ：データの分析　数Ⅱ：式と証明、複素数'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: 'サクシード',
                  range: '数Ⅰ P.84~97　数Ⅱ P.6~21,24~39',
                  note: '提出'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: '青チャート',
                  range: '数Ⅰ 174~194　数Ⅱ 1~70',
                  note: '（左記の数字は問題番号）')
            ]);
        subjects['math_a'] = SubjectExamPlan(
            subjectId: 'math_a',
            rangeText: '数学と人間活動',
            existingSetIds: const ['math_ma_10', 'math_ma_11', 'math_ma_12'],
            committeeSetIds: const [
              'math_shonan_104_ma_integer_01',
              'math_shonan_104_ma_integer_02',
              'math_shonan_104_ma_integer_03',
              'math_shonan_104_ma_integer_04',
              'math_shonan_104_ma_integer_05'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書',
                  name: '教科書',
                  range: 'P.132~185(166~183除)',
                  note: '数学と人間活動'),
              StudyMaterial(
                  kind: 'ワーク',
                  name: 'サクシード',
                  range: 'P.174~195,198,199',
                  note: ''),
              StudyMaterial(
                  kind: 'ワーク', name: '青チャート', range: '112~158?', note: '')
            ]);
        subjects['ec1'] = SubjectExamPlan(
            subjectId: 'ec1',
            rangeText: 'Lesson5~7',
            committeeSetIds: const [
              'english_shonan_104_ec1_01',
              'english_shonan_104_ec1_02',
              'english_shonan_104_ec1_03'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書',
                  name: '教科書',
                  range: 'P.74~83,90~99,108~117',
                  note: 'Lesson5~7'),
              StudyMaterial(
                  kind: 'その他', name: 'LEAP', range: '1101-2100', note: '')
            ]);
        subjects['ronhyo1'] = SubjectExamPlan(
            subjectId: 'ronhyo1',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['chemistry_basic'] = SubjectExamPlan(
            subjectId: 'chemistry_basic',
            rangeText: '',
            existingSetIds: const [
              'science_chemistry_05',
              'science_chemistry_06'
            ],
            committeeSetIds: const [
              'science_shonan_104_chem_mole_01',
              'science_shonan_104_chem_mole_02',
              'science_shonan_104_chem_mole_03',
              'science_shonan_104_chem_mole_04',
              'science_shonan_104_chem_mole_05',
              'science_shonan_104_chem_mole_06',
              'science_shonan_104_chem_solution_01',
              'science_shonan_104_chem_solution_02',
              'science_shonan_104_chem_solution_03',
              'science_shonan_104_chem_solution_04',
              'science_shonan_104_chem_reaction_01',
              'science_shonan_104_chem_reaction_02',
              'science_shonan_104_chem_reaction_03',
              'science_shonan_104_chem_reaction_04',
              'science_shonan_104_chem_reaction_05'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '授業プリント', name: 'プリント', range: 'P.42~72', note: ''),
              StudyMaterial(
                  kind: '教科書', name: '教科書', range: 'P.82~119', note: '')
            ]);
        subjects['biology_basic'] = SubjectExamPlan(
            subjectId: 'biology_basic',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['geography_general'] = SubjectExamPlan(
            subjectId: 'geography_general',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['public_economy'] = SubjectExamPlan(
            subjectId: 'public_economy',
            rangeText: '',
            existingSetIds: const [
              'social_pol_10',
              'social_pol_11',
              'social_pol_12',
              'social_pol_13',
              'social_pol_14',
              'social_pol_15'
            ],
            committeeSetIds: const [
              'social_shonan_104_public_economy_01',
              'social_shonan_104_public_economy_02',
              'social_shonan_104_public_economy_03',
              'social_shonan_104_public_economy_04',
              'social_shonan_104_public_economy_05',
              'social_shonan_104_public_economy_06',
              'social_shonan_104_public_economy_07',
              'social_shonan_104_public_economy_08',
              'social_shonan_104_public_economy_09',
              'social_shonan_104_public_economy_10',
              'social_shonan_104_public_economy_11',
              'social_shonan_104_public_economy_12',
              'social_shonan_104_public_economy_13',
              'social_shonan_104_public_economy_14'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: '教科書', name: '教科書', range: 'P.203~289', note: ''),
              StudyMaterial(
                  kind: '配布資料', name: '資料集', range: 'P.250~332', note: ''),
              StudyMaterial(
                  kind: '授業プリント', name: 'プリント', range: '冊子No.3すべて', note: '')
            ]);
        subjects['information1'] = SubjectExamPlan(
            subjectId: 'information1',
            rangeText: '',
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(kind: 'その他', name: '授業ノート', range: '25~', note: '')
            ]);
        break;
      case '後期期末試験':
        subjects['gendai_kokugo'] = SubjectExamPlan(
            subjectId: 'gendai_kokugo',
            rangeText: '',
            existingSetIds: const [
              'japanese_gendai_01',
              'japanese_gendai_02',
              'japanese_kanji_01',
              'japanese_gendai_03',
              'japanese_gendai_04',
              'japanese_bungakushi_01'
            ],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: 'その他',
                  name: '漢字',
                  range: 'P.158-197（第7,8章）　四字熟語P.210-213',
                  note: ''),
              StudyMaterial(
                  kind: 'その他',
                  name: 'キーワード',
                  range: 'P.150-209(71-100)',
                  note: ''),
              StudyMaterial(
                  kind: 'ワーク',
                  name: '開発講座',
                  range: 'P.143-173（第9問、補問）',
                  note: ''),
              StudyMaterial(
                  kind: '配布資料',
                  name: '便覧',
                  range: '近現代の文学⑤、⑥　P.232,233,234-237,314,315,326,327,334,335',
                  note: 'ノートP.28-29 提出')
            ]);
        subjects['gengo_bunka'] = SubjectExamPlan(
            subjectId: 'gengo_bunka',
            rangeText: '',
            existingSetIds: const ['japanese_kobun_01', 'japanese_kobun_02'],
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: 'その他',
                  name: '古文単語',
                  range: 'P.250-292,158-162',
                  note: '')
            ]);
        subjects['math1'] = SubjectExamPlan(
            subjectId: 'math1',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['math_a'] = SubjectExamPlan(
            subjectId: 'math_a',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['ec1'] = SubjectExamPlan(
            subjectId: 'ec1',
            rangeText: '',
            status: RangeStatus.entered,
            materials: const [
              StudyMaterial(
                  kind: 'その他',
                  name: 'LEAP',
                  range: '1~1500,2101~2300',
                  note: '')
            ]);
        subjects['ronhyo1'] = SubjectExamPlan(
            subjectId: 'ronhyo1',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['chemistry_basic'] = SubjectExamPlan(
            subjectId: 'chemistry_basic',
            rangeText: '',
            existingSetIds: const [
              'science_chemistry_05',
              'science_chemistry_06',
              'science_chemistry_07'
            ],
            committeeSetIds: const [
              'science_shonan_104_chem_mole_01',
              'science_shonan_104_chem_mole_02',
              'science_shonan_104_chem_mole_03',
              'science_shonan_104_chem_mole_04',
              'science_shonan_104_chem_mole_05',
              'science_shonan_104_chem_mole_06',
              'science_shonan_104_chem_solution_01',
              'science_shonan_104_chem_solution_02',
              'science_shonan_104_chem_solution_03',
              'science_shonan_104_chem_solution_04',
              'science_shonan_104_chem_reaction_01',
              'science_shonan_104_chem_reaction_02',
              'science_shonan_104_chem_reaction_03',
              'science_shonan_104_chem_reaction_04',
              'science_shonan_104_chem_reaction_05',
              'science_shonan_104_chem_laws_01',
              'science_shonan_104_chem_acid_01',
              'science_shonan_104_chem_acid_02',
              'science_shonan_104_chem_acid_03',
              'science_shonan_104_chem_neutral_01',
              'science_shonan_104_chem_neutral_02'
            ],
            status: RangeStatus.empty,
            materials: const []);
        subjects['biology_basic'] = SubjectExamPlan(
            subjectId: 'biology_basic',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['geography_general'] = SubjectExamPlan(
            subjectId: 'geography_general',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['public_economy'] = SubjectExamPlan(
            subjectId: 'public_economy',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        subjects['information1'] = SubjectExamPlan(
            subjectId: 'information1',
            rangeText: '',
            status: RangeStatus.empty,
            materials: const []);
        break;
    }
    final title = sheets
        .firstWhere((s) => s.$1 == sheet, orElse: () => (sheet, sheet))
        .$2;
    return SchoolExamPlan(
        id: id, title: title, createdAt: now, subjects: subjects);
  }
}
