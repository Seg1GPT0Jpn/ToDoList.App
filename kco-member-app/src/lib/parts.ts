/** パート（表示順・表示名・セクション）。楽器コードは応募者管理（スプレッドシート）と同じ */

export interface PartInfo {
  part: string;
  label: string;
  section: 'woodwind' | 'brass' | 'percussion' | 'strings' | 'other';
}

export const PARTS: PartInfo[] = [
  { part: 'Fl', label: 'フルート', section: 'woodwind' },
  { part: 'Ob', label: 'オーボエ', section: 'woodwind' },
  { part: 'Cl', label: 'クラリネット', section: 'woodwind' },
  { part: 'Fg', label: 'ファゴット', section: 'woodwind' },
  { part: 'Hr', label: 'ホルン', section: 'brass' },
  { part: 'Tp', label: 'トランペット', section: 'brass' },
  { part: 'Tb', label: 'トロンボーン', section: 'brass' },
  { part: 'Tuba', label: 'テューバ', section: 'brass' },
  { part: 'Perc', label: '打楽器', section: 'percussion' },
  { part: 'Vn', label: 'ヴァイオリン', section: 'strings' },
  { part: 'Va', label: 'ヴィオラ', section: 'strings' },
  { part: 'Vc', label: 'チェロ', section: 'strings' },
  { part: 'Cb', label: 'コントラバス', section: 'strings' },
  { part: 'Hp', label: 'ハープ', section: 'other' },
  { part: 'Pf', label: 'ピアノ・鍵盤', section: 'other' }
];

export const SECTIONS: { id: PartInfo['section']; label: string }[] = [
  { id: 'woodwind', label: '木管楽器' },
  { id: 'brass', label: '金管楽器' },
  { id: 'percussion', label: '打楽器' },
  { id: 'strings', label: '弦楽器' },
  { id: 'other', label: 'その他' }
];

export function partLabel(part: string): string {
  return PARTS.find(p => p.part === part)?.label ?? (part || '未設定');
}

export function partOrder(part: string): number {
  const i = PARTS.findIndex(p => p.part === part);
  return i < 0 ? PARTS.length : i;
}

export function sectionOf(part: string): PartInfo['section'] {
  return PARTS.find(p => p.part === part)?.section ?? 'other';
}

export function sectionLabel(section: string): string {
  return SECTIONS.find(s => s.id === section)?.label ?? section;
}

/** お知らせの対象表示（例：「弦楽器向け」「Va・Vc 向け」「全員」） */
export function audienceLabel(audience: { type: string; values: string[] }): string {
  if (!audience || audience.type === 'all' || !audience.values?.length) return '全員';
  if (audience.type === 'section') return audience.values.map(sectionLabel).join('・') + '向け';
  return audience.values.map(partLabel).join('・') + '向け';
}

/** そのお知らせが自分向けか（表示の絞り込み用。閲覧権限ではない） */
export function isForMe(audience: { type: string; values: string[] }, myPart: string | null): boolean {
  if (!audience || audience.type === 'all' || !audience.values?.length) return true;
  if (!myPart) return true;
  if (audience.type === 'section') return audience.values.includes(sectionOf(myPart));
  return audience.values.includes(myPart);
}
