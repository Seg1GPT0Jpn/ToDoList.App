import { describe, expect, it } from 'vitest';
import { checkScoreFile, isHttpsUrl, safeFileName, scorePartsLabel } from './scores';

describe('scores', () => {
  it('対象パートの表示', () => {
    expect(scorePartsLabel(['all'])).toBe('全員');
    expect(scorePartsLabel([])).toBe('全員');
    expect(scorePartsLabel(['Va', 'Vc'])).toBe('ヴィオラ・チェロ');
  });
  it('ファイル名を安全にする', () => {
    expect(safeFileName('../a/b?.pdf')).toBe('.._a_b_.pdf');
    expect(safeFileName('   ')).toBe('score.pdf');
    expect(safeFileName('第1楽章 Vn1.pdf')).toBe('第1楽章 Vn1.pdf');
  });
  it('ファイルの確認', () => {
    expect(checkScoreFile({ size: 10, type: 'application/pdf' })).toBeNull();
    expect(checkScoreFile({ size: 10, type: 'text/html' })).not.toBeNull();
    expect(checkScoreFile({ size: 31 * 1024 * 1024, type: 'application/pdf' })).not.toBeNull();
  });
  it('リンクは https のみ', () => {
    expect(isHttpsUrl('https://drive.google.com/file/d/x')).toBe(true);
    expect(isHttpsUrl('http://x')).toBe(false);
    expect(isHttpsUrl('javascript:alert(1)')).toBe(false);
  });
});
