import { partLabel } from './parts';

export const MAX_SCORE_BYTES = 30 * 1024 * 1024;
export const SCORE_ACCEPT = 'application/pdf,image/png,image/jpeg';

/** 楽譜の対象パートの表示（例：「全員」「ヴィオラ・チェロ」） */
export function scorePartsLabel(parts: string[]): string {
  if (!parts.length || parts.includes('all')) return '全員';
  return parts.map(partLabel).join('・');
}

/** 保存用のファイル名（パス区切りや制御文字を取り除く） */
export function safeFileName(name: string): string {
  const cleaned = name.replace(/[\\/\u0000-\u001f\u007f#?[\]*]/g, '_').replace(/\s+/g, ' ').trim();
  const trimmed = cleaned.slice(-120);
  return trimmed || 'score.pdf';
}

export function checkScoreFile(file: { size: number; type: string }): string | null {
  if (file.size > MAX_SCORE_BYTES) return 'ファイルが大きすぎます（30MB まで）。';
  if (!/^(application\/pdf|image\/(png|jpeg))$/.test(file.type)) return 'PDF・PNG・JPEG のファイルを選んでください。';
  return null;
}

export function isHttpsUrl(url: string): boolean {
  return /^https:\/\/[^\s]{1,1000}$/.test(url);
}
