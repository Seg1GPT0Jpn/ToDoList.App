// 単元名の整え（つづりクエストの単元コード → 日本語の単元名、同じ内容の単元をまとめる）
// unit-names.js / unit-groups.js は通常の <script> で読み込まれ、UNIT_NAMES / UNIT_GROUP / KANAGAWA_ALIAS をグローバルに置く

const G = /** @type {any} */ (globalThis);

function unitName(code) {
  if (!G.UNIT_NAMES) return '';
  return G.UNIT_NAMES[code] || G.UNIT_NAMES[code.split('.').slice(0, 4).join('.')] || '';
}

// 細かい単元名を教科書の単元の大きさにまとめる（不定詞（3用法）→ 不定詞、2次関数：グラフ → 二次関数）
const UNIT_ALIAS = {
  未来: '未来表現', '2次関数': '二次関数', 論理: '集合と命題', 微分積分: '微分法・積分法', '指数・対数': '指数関数・対数関数',
  微分法: '微分法とその応用', 積分法: '積分法とその応用', 統計: '統計的な推測', 平面上の曲線: '平面上の曲線と複素数平面',
  '式：複素数': '複素数と方程式', '式：二項定理・等式不等式の証明': '式と証明',
};
function bigUnit(name, code) {
  if (UNIT_ALIAS[name]) return UNIT_ALIAS[name];
  let u = name;
  const m = /^([^：]+)：(.+)$/.exec(u);
  if (m) u = code.startsWith('english.') ? m[2] : m[1];
  u = u.replace(/（[^（）]*）$/, '').trim() || name;
  return UNIT_ALIAS[u] || u;
}

/** 取り込みデータの問題に、表示用の単元名（unit / subunit）をつける。何度呼んでも同じ結果になる */
export function applyUnitNames(q) {
  if (q.ucode) {
    const name = unitName(q.ucode);
    if (name) {
      const grp = G.UNIT_GROUP && (G.UNIT_GROUP[q.ucode] || G.UNIT_GROUP[q.ucode.split('.').slice(0, 4).join('.')]);
      q.unit = grp || bigUnit(name, q.ucode);
      q.subunit = name !== q.unit ? name : '';
    }
  } else if (q.src === '予想問題' && !q.subunit) {
    // 予想問題は大問ごとではなく、科目ごとの1単元にまとめる（大問名は小単元として残す）
    q.subunit = q.unit;
    q.unit = q.set;
  } else if (q.src === 'かながわ' && G.KANAGAWA_ALIAS && G.KANAGAWA_ALIAS[q.unit] && !q.subunit) {
    q.subunit = q.unit;
    q.unit = G.KANAGAWA_ALIAS[q.unit];
  }
  return q;
}
