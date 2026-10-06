import { describe, expect, it } from 'vitest';
import { audienceLabel, isForMe, partLabel } from './parts';

describe('parts', () => {
  it('表示名', () => {
    expect(partLabel('Tuba')).toBe('テューバ');
    expect(partLabel('')).toBe('未設定');
  });

  it('お知らせの対象', () => {
    expect(audienceLabel({ type: 'all', values: [] })).toBe('全員');
    expect(audienceLabel({ type: 'section', values: ['strings'] })).toBe('弦楽器向け');
    expect(audienceLabel({ type: 'part', values: ['Va', 'Vc'] })).toBe('ヴィオラ・チェロ向け');
    expect(isForMe({ type: 'section', values: ['strings'] }, 'Va')).toBe(true);
    expect(isForMe({ type: 'section', values: ['strings'] }, 'Fl')).toBe(false);
    expect(isForMe({ type: 'part', values: ['Vn'] }, 'Vn')).toBe(true);
    expect(isForMe({ type: 'all', values: [] }, 'Fl')).toBe(true);
  });
});
