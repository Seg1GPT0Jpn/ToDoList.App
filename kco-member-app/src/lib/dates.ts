/** 日付まわり（すべて日本時間で扱う） */

const TZ = 'Asia/Tokyo';
const WEEK = ['日', '月', '火', '水', '木', '金', '土'];

/** 今日の日付（日本時間）を YYYY-MM-DD で返す */
export function todayJst(now: Date = new Date()): string {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(now);
  const get = (t: string) => parts.find(p => p.type === t)?.value ?? '';
  return `${get('year')}-${get('month')}-${get('day')}`;
}

/** '2026-12-05' → '2026年12月5日（土）'。空欄・不正な値は「未定」 */
export function formatDateJa(date: string, withYear = true): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date || '');
  if (!m) return '未定';
  const y = Number(m[1]);
  const mo = Number(m[2]);
  const d = Number(m[3]);
  const w = WEEK[new Date(Date.UTC(y, mo - 1, d)).getUTCDay()];
  return `${withYear ? `${y}年` : ''}${mo}月${d}日（${w}）`;
}

/** '13:00','16:00' → '13:00〜16:00'。片方だけなら片方。両方空なら「時間未定」 */
export function formatTimeRange(start: string, end: string): string {
  if (start && end) return `${start}〜${end}`;
  if (start) return `${start}〜`;
  if (end) return `〜${end}`;
  return '時間未定';
}

/** 空欄なら「未定」 */
export function orTbd(value: string | null | undefined): string {
  return value && value.trim() ? value : '未定';
}

/** 締切の表示（日本時間） */
export function formatDeadline(date: Date | null): string {
  if (!date) return '締切なし';
  const f = new Intl.DateTimeFormat('ja-JP', { timeZone: TZ, month: 'numeric', day: 'numeric', weekday: 'short', hour: '2-digit', minute: '2-digit' });
  return `${f.format(date)} まで`;
}

/** 入力欄の日付（YYYY-MM-DD）→ その日の 23:59:59（日本時間）の Date。空欄は null */
export function endOfDayJst(date: string): Date | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date || '');
  if (!m) return null;
  return new Date(`${m[1]}-${m[2]}-${m[3]}T23:59:59+09:00`);
}

/** Date → 入力欄用の YYYY-MM-DD（日本時間）。null は空欄 */
export function toDateInput(date: Date | null): string {
  return date ? todayJst(date) : '';
}

/** 予定を「これから」「日程未定」「終わったもの」に分ける */
export function splitByDate<T extends { date: string }>(items: T[], today: string) {
  const upcoming = items.filter(i => i.date && i.date >= today).sort((a, b) => a.date.localeCompare(b.date));
  const undecided = items.filter(i => !i.date);
  const past = items.filter(i => i.date && i.date < today).sort((a, b) => b.date.localeCompare(a.date));
  return { upcoming, undecided, past };
}
