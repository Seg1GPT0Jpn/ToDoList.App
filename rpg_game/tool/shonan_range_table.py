# 湘南高校104回生の試験範囲表（Excel）から lib/src/study/shonan_range_table.dart を作る。
#   python3 tool/shonan_range_table.py <範囲表.xlsx>
# 範囲表が更新されたら実行し、生成された Dart を確認してからコミットする。
import openpyxl, datetime, json, sys, os
if len(sys.argv) != 2:
    sys.exit('usage: shonan_range_table.py <range.xlsx>')
wb = openpyxl.load_workbook(sys.argv[1], data_only=True)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'lib', 'src', 'study', 'shonan_range_table.dart')
SUBJ = {'現代の国語':'gendai_kokugo','言語文化':'gengo_bunka','数学Ⅰ':'math1','数学A':'math_a','ECⅠ':'ec1','論表Ⅰ':'ronhyo1',
        '化学基礎':'chemistry_basic','生物基礎':'biology_basic','地理総合':'geography_general','公共':'public_economy','情報Ⅰ':'information1'}
# 範囲表の試験・科目に最初から登録しておく委員会の新作問題セット
def _sets(prefix, n):
    return [f'{prefix}_{i:02d}' for i in range(1, n + 1)]


COMMITTEE = {
    ('後期中間試験', 'public_economy'): _sets('social_shonan_104_public_economy', 14),
    ('後期中間試験', 'gendai_kokugo'): _sets('japanese_shonan_104_gendai_kokugo', 3),
    ('後期中間試験', 'biology_basic'): _sets('science_shonan_104_bio_body', 2) + _sets('science_shonan_104_bio_hormone', 1) + _sets('science_shonan_104_bio_immune', 2) + _sets('science_shonan_104_bio_veg', 2),
    ('後期中間試験', 'gengo_bunka'): _sets('japanese_shonan_104_gengo_bunka_kundoku', 2) + _sets('japanese_shonan_104_gengo_bunka_koji', 2) + _sets('japanese_shonan_104_gengo_bunka_history', 1),
    # 後期期末の化学基礎は範囲が未定なので、第2章（物質の変化）の新作をすべて入れて、単元ごとに対策できるようにする
    ('後期期末試験', 'chemistry_basic'): _sets('science_shonan_104_chem_mole', 6) + _sets('science_shonan_104_chem_solution', 4) + _sets('science_shonan_104_chem_reaction', 5) + _sets('science_shonan_104_chem_laws', 1) + _sets('science_shonan_104_chem_acid', 3) + _sets('science_shonan_104_chem_neutral', 2),
    ('後期中間試験', 'math1'): _sets('math_shonan_104_m1_data', 4) + _sets('math_shonan_104_m1_proof', 3) + _sets('math_shonan_104_m1_complex', 4),
    ('後期中間試験', 'math_a'): _sets('math_shonan_104_ma_integer', 5),
    ('後期中間試験', 'ec1'): _sets('english_shonan_104_ec1', 3),
    ('後期中間試験', 'chemistry_basic'): _sets('science_shonan_104_chem_mole', 6) + _sets('science_shonan_104_chem_solution', 4) + _sets('science_shonan_104_chem_reaction', 5),
}
# 範囲表の試験・科目に最初から登録しておく、アプリに入っている問題セット。
# 範囲（教材名・単元名・ページ）から内容が読みとれるものだけ。LEAP など市販教材の中身は入れない。
_KANJI = ['japanese_gendai_01', 'japanese_gendai_02', 'japanese_kanji_01']
_KOGO = ['japanese_kobun_01', 'japanese_kobun_02']
EXISTING = {
    ('前期期末試験', 'gendai_kokugo'): _KANJI + ['japanese_gendai_04', 'japanese_bungakushi_01'],
    ('前期期末試験', 'gengo_bunka'): _KOGO,
    ('前期期末試験', 'math1'): [f'math_m1_{i}' for i in range(10, 16)] + ['math_quadratic_app_01'],
    ('前期期末試験', 'math_a'): [f'math_ma_{i:02d}' for i in range(1, 7)],
    ('前期期末試験', 'ronhyo1'): ['english_stage_01', 'english_stage_02'],
    ('前期期末試験', 'chemistry_basic'): ['science_chemistry_02', 'science_chemistry_03', 'science_chemistry_04'],
    ('前期期末試験', 'biology_basic'): ['science_biology_03'],
    ('後期中間試験', 'gendai_kokugo'): _KANJI + ['japanese_gendai_03', 'japanese_gendai_04', 'japanese_bungakushi_01'],
    ('後期中間試験', 'gengo_bunka'): _KOGO + ['japanese_kanbun_01', 'japanese_kanbun_02'],
    ('後期中間試験', 'math1'): ['math_m1_16', 'math_m1_17', 'math_m1_18', 'math_m1_stat_01'] + [f'math_m2_{i:02d}' for i in range(1, 7)],
    ('後期中間試験', 'math_a'): ['math_ma_10', 'math_ma_11', 'math_ma_12'],
    ('後期中間試験', 'chemistry_basic'): ['science_chemistry_05', 'science_chemistry_06'],
    ('後期中間試験', 'biology_basic'): ['science_biology_04', 'science_biology_05', 'science_biology_06', 'science_biology_07'],
    ('後期中間試験', 'public_economy'): [f'social_pol_{i}' for i in range(10, 16)],
    ('後期期末試験', 'chemistry_basic'): ['science_chemistry_05', 'science_chemistry_06', 'science_chemistry_07'],
    ('後期期末試験', 'gendai_kokugo'): _KANJI + ['japanese_gendai_03', 'japanese_gendai_04', 'japanese_bungakushi_01'],
    ('後期期末試験', 'gengo_bunka'): _KOGO,
}
def kind(name):
    if name == '教科書': return '教科書'
    if 'プリント' in name: return '授業プリント'
    if any(k in name for k in ['便覧','資料集','図説']): return '配布資料'
    if any(k in name for k in ['ワーク','サクシード','セミナー','問題集','チャート','Scramble','EG','うさぎ','開発講座','漢文']): return 'ワーク'
    return 'その他'
def s(v): return '' if v is None else str(v).strip().replace('　',' ')
def norm(t):
    import re
    return re.sub(r'\s{2,}', '　', t)
out = []
for ws in wb:
    sheet = ws.title.replace('（仮）', '')  # 「（仮）」は付けない
    title = '1年' + sheet
    plan = {}
    cur = None
    for r in ws.iter_rows(min_row=3, values_only=True):
        if r[1]: cur = SUBJ.get(s(r[1]))
        if cur is None: continue
        sp = plan.setdefault(cur, {'materials': [], 'note': '', 'date': None})
        mat, rng, dt, note = s(r[2]), norm(s(r[3])), r[4], norm(s(r[6]))
        if isinstance(dt, (int, float)) and dt > 40000:
            sp['date'] = (datetime.date(1899,12,30)+datetime.timedelta(days=int(dt))).isoformat()
        if mat == '教科書' and note: sp['note'] = note
        if mat and (rng or note):
            sp['materials'].append({'kind': kind(mat), 'name': mat, 'range': rng, 'note': note})
    out.append((sheet, title, plan))
def dq(t): return "'" + t.replace('\\','\\\\').replace('$','\\$').replace("'", "\\'") + "'"
L = ["// 湘南高校2026年度（104回生）1年の試験範囲表から tool/shonan_range_table.py で自動生成（手で直さない）。",
     "// 生成元：委員会が作成した範囲表（Excel）。範囲が空欄の科目は未入力のまま。",
     "import 'school_exam.dart';", "",
     "class ShonanRangeTable {", "  const ShonanRangeTable._();", "",
     "  /// 範囲表に載っている試験（シート名, 試験名）", "  static const sheets = [",]
for sheet, title, _ in out: L.append(f"    ({dq(sheet)}, {dq(title)}),")
L += ["  ];", "", "  /// 範囲表のシートから試験計画を作る", "  static SchoolExamPlan plan(String sheet, {required String id, required DateTime now}) {",
      "    final subjects = <String, SubjectExamPlan>{};", "    switch (sheet) {"]
for sheet, title, plan in out:
    L.append(f"      case {dq(sheet)}:")
    for sid, sp in plan.items():
        mats = ', '.join("StudyMaterial(kind: %s, name: %s, range: %s, note: %s)" % (dq(m['kind']), dq(m['name']), dq(m['range']), dq(m['note'])) for m in sp['materials'])
        filled = bool(sp['materials'])
        date = f"examDate: DateTime.parse('{sp['date']}'), " if sp['date'] else ''
        sets = COMMITTEE.get((sheet, sid), [])
        es = f"existingSetIds: const [{', '.join(dq(x) for x in EXISTING.get((sheet, sid), []))}], " if EXISTING.get((sheet, sid)) else ''
        cs = f"committeeSetIds: const [{', '.join(dq(x) for x in sets)}], " if sets else ''
        L.append(f"        subjects[{dq(sid)}] = SubjectExamPlan(subjectId: {dq(sid)}, rangeText: {dq(sp['note'])}, {date}{es}{cs}status: RangeStatus.{'entered' if filled else 'empty'}, materials: const [{mats}]);")
    L.append("        break;")
L += ["    }", "    final title = sheets.firstWhere((s) => s.$1 == sheet, orElse: () => (sheet, sheet)).$2;",
      "    return SchoolExamPlan(id: id, title: title, createdAt: now, subjects: subjects);", "  }", "}", ""]
open(OUT,'w').write('\n'.join(L))
for sheet,title,plan in out: print(sheet,title,{k:len(v['materials']) for k,v in plan.items()})
