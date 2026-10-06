import { describe, expect, it } from 'vitest';
import { endOfDayJst, formatDateJa, formatTimeRange, orTbd, splitByDate, todayJst } from './dates';

describe('dates', () => {
  it('日本時間の今日', () => {
    // 2026-12-04 15:30 UTC = 2026-12-05 00:30 JST
    expect(todayJst(new Date(Date.UTC(2026, 11, 4, 15, 30)))).toBe('2026-12-05');
  });

  it('日付の表示。空欄は「未定」で、架空の日付を出さない', () => {
    expect(formatDateJa('2026-12-05')).toBe('2026年12月5日（土）');
    expect(formatDateJa('2026-12-05', false)).toBe('12月5日（土）');
    expect(formatDateJa('')).toBe('未定');
    expect(formatDateJa('12月5日')).toBe('未定');
  });

  it('時間・会場の表示', () => {
    expect(formatTimeRange('13:00', '16:00')).toBe('13:00〜16:00');
    expect(formatTimeRange('', '')).toBe('時間未定');
    expect(orTbd('')).toBe('未定');
    expect(orTbd('  ')).toBe('未定');
    expect(orTbd('〇〇公会堂')).toBe('〇〇公会堂');
  });

  it('締切はその日の23:59:59（日本時間）', () => {
    expect(endOfDayJst('2026-12-01')?.toISOString()).toBe('2026-12-01T14:59:59.000Z');
    expect(endOfDayJst('')).toBeNull();
  });

  it('予定を「これから」「未定」「過去」に分ける', () => {
    const items = [{ date: '2026-12-20' }, { date: '' }, { date: '2026-11-01' }, { date: '2026-12-05' }];
    const r = splitByDate(items, '2026-12-05');
    expect(r.upcoming.map(i => i.date)).toEqual(['2026-12-05', '2026-12-20']);
    expect(r.undecided.length).toBe(1);
    expect(r.past.map(i => i.date)).toEqual(['2026-11-01']);
  });
});
