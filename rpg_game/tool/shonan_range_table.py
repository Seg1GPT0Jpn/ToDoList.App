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
    title = '1年' + ws.title
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
    out.append((ws.title, title, plan))
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
        L.append(f"        subjects[{dq(sid)}] = SubjectExamPlan(subjectId: {dq(sid)}, rangeText: {dq(sp['note'])}, {date}status: RangeStatus.{'entered' if filled else 'empty'}, materials: const [{mats}]);")
    L.append("        break;")
L += ["    }", "    final title = sheets.firstWhere((s) => s.$1 == sheet, orElse: () => (sheet, sheet)).$2;",
      "    return SchoolExamPlan(id: id, title: title, createdAt: now, subjects: subjects);", "  }", "}", ""]
open(OUT,'w').write('\n'.join(L))
for sheet,title,plan in out: print(sheet,title,{k:len(v['materials']) for k,v in plan.items()})
