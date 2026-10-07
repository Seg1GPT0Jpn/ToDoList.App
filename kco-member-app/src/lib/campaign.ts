import type { Campaign, CampaignPart, PartStat } from './types';
import { PARTS, partLabel } from './parts';

/**
 * パート別の団員数から「募集したいパート」を提案する
 *  ・最低人数に届いていない → 急募
 *  ・目標人数に届いていない → 募集中
 * （目標・最低人数は応募者管理の「募集設定」の値。未設定のパートは提案しない）
 */
export function suggestParts(byPart: PartStat[]): CampaignPart[] {
  const list: CampaignPart[] = [];
  for (const p of byPart) {
    if (p.min !== null && p.min !== undefined && p.count < p.min) {
      list.push({ part: p.part, label: partLabel(p.part), level: 'urgent' });
    } else if (p.target !== null && p.target !== undefined && p.count < p.target) {
      list.push({ part: p.part, label: partLabel(p.part), level: 'wanted' });
    }
  }
  return sortParts(list);
}

export function sortParts(list: CampaignPart[]): CampaignPart[] {
  const order = (part: string) => {
    const i = PARTS.findIndex(p => p.part === part);
    return i < 0 ? PARTS.length : i;
  };
  return [...list].sort((a, b) => (a.level === b.level ? order(a.part) - order(b.part) : a.level === 'urgent' ? -1 : 1));
}

/** ハッシュタグを「#タグ」の形にそろえる（全角＃・空白区切り・重複に対応） */
export function normalizeHashtags(text: string): string[] {
  const tags = text
    .split(/[\s,、　]+/)
    .map(t => t.replace(/^[#＃]+/, '').trim())
    .filter(Boolean)
    .map(t => '#' + t);
  return [...new Set(tags)].slice(0, 10);
}

/** LINE・SNS に添える文章 */
export function shareText(c: Campaign, joinUrl: string): string {
  const lines: string[] = [];
  lines.push(`【${c.headline}】かながわコネクトオーケストラ`);
  if (c.message) lines.push(c.message);
  const urgent = c.parts.filter(p => p.level === 'urgent').map(p => p.label);
  const wanted = c.parts.filter(p => p.level === 'wanted').map(p => p.label);
  if (urgent.length) lines.push(`急募：${urgent.join('・')}`);
  if (wanted.length) lines.push(`募集中：${wanted.join('・')}`);
  if (c.deadlineText) lines.push(`締切：${c.deadlineText}`);
  lines.push(`詳しくはこちら ${joinUrl}`);
  const tags = normalizeHashtags(c.hashtags);
  if (tags.length) lines.push(tags.join(' '));
  return lines.join('\n');
}

export function lineShareUrl(text: string): string {
  return 'https://line.me/R/share?text=' + encodeURIComponent(text);
}

export function xShareUrl(text: string): string {
  return 'https://x.com/intent/post?text=' + encodeURIComponent(text);
}

export function isValidFormUrl(url: string): boolean {
  return url === '' || /^https:\/\/[^\s]+$/.test(url);
}

export const DEFAULT_CAMPAIGN: Campaign = {
  active: false,
  headline: '団員募集',
  message: '',
  parts: [],
  formUrl: '',
  hashtags: '',
  deadlineText: '',
  showMemberCount: false,
  memberCount: 0,
  targetMembers: 0
};
