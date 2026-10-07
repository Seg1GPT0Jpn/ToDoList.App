import { describe, expect, it } from 'vitest';
import { DEFAULT_CAMPAIGN, isValidFormUrl, lineShareUrl, normalizeHashtags, shareText, suggestParts } from './campaign';

describe('campaign', () => {
  it('目標・最低人数から募集パートを提案する（未設定は提案しない）', () => {
    expect(suggestParts([
      { part: 'Vc', label: '', count: 1, target: 10, min: 5 },
      { part: 'Fl', label: '', count: 3, target: 4, min: 2 },
      { part: 'Tuba', label: '', count: 1, target: 1, min: 1 },
      { part: 'Hp', label: '', count: 0, target: null, min: null },
      { part: 'Ob', label: '', count: 0, target: 3, min: 2 }
    ])).toEqual([
      { part: 'Ob', label: 'オーボエ', level: 'urgent' },
      { part: 'Vc', label: 'チェロ', level: 'urgent' },
      { part: 'Fl', label: 'フルート', level: 'wanted' }
    ]);
  });

  it('ハッシュタグをそろえる', () => {
    expect(normalizeHashtags('#オーケストラ ＃団員募集、神奈川 #オーケストラ')).toEqual(['#オーケストラ', '#団員募集', '#神奈川']);
    expect(normalizeHashtags('')).toEqual([]);
  });

  it('シェア用の文章（未入力の項目は出さない）', () => {
    const text = shareText({ ...DEFAULT_CAMPAIGN, parts: [{ part: 'Ob', label: 'オーボエ', level: 'urgent' }], hashtags: '団員募集' }, 'https://example.com/join');
    expect(text).toBe('【団員募集】かながわコネクトオーケストラ\n急募：オーボエ\n詳しくはこちら https://example.com/join\n#団員募集');
    expect(lineShareUrl('a b')).toBe('https://line.me/R/share?text=a%20b');
  });

  it('応募フォームのURLは https のみ', () => {
    expect(isValidFormUrl('https://forms.gle/xxxx')).toBe(true);
    expect(isValidFormUrl('')).toBe(true);
    expect(isValidFormUrl('http://example.com')).toBe(false);
    expect(isValidFormUrl('javascript:alert(1)')).toBe(false);
  });
});
