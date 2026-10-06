import { describe, expect, it } from 'vitest';
import { summarizeAttendance } from './attendance';
import type { Member } from './types';

const m = (id: string, part: string, status: Member['status'] = 'active'): Member => ({
  id, part, status, displayName: id, instrument: part, instrumentLabel: part, section: 'strings', bio: ''
});

describe('summarizeAttendance', () => {
  const members = [m('a', 'Va'), m('b', 'Va'), m('c', 'Vc'), m('d', 'Fl'), m('x', 'Ob', 'inactive'), m('p', 'Hr', 'paused')];

  it('出席・遅刻・欠席・未回答を数える（在籍中のみ）', () => {
    const s = summarizeAttendance(members, [
      { memberId: 'a', status: 'present', comment: '' },
      { memberId: 'c', status: 'late', comment: '' },
      { memberId: 'd', status: 'absent', comment: '' },
      { memberId: 'x', status: 'present', comment: '' }
    ]);
    expect([s.present, s.late, s.absent, s.none, s.total]).toEqual([1, 1, 1, 1, 4]);
    expect(s.unanswered.map(u => u.id)).toEqual(['b']);
  });

  it('パート別はオーケストラの並び順', () => {
    const s = summarizeAttendance(members, []);
    expect(s.byPart.map(p => p.part)).toEqual(['Fl', 'Va', 'Vc']);
    expect(s.byPart.find(p => p.part === 'Va')?.none).toBe(2);
  });

  it('80人規模でも正しく数える', () => {
    const many = Array.from({ length: 80 }, (_, i) => m('m' + i, ['Vn', 'Va', 'Vc', 'Cb', 'Fl'][i % 5]));
    const recs = many.slice(0, 50).map(x => ({ memberId: x.id, status: 'present' as const, comment: '' }));
    const s = summarizeAttendance(many, recs);
    expect([s.present, s.none, s.total]).toEqual([50, 30, 80]);
  });
});
