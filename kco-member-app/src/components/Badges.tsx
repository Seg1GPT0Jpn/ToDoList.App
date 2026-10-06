import { ATTENDANCE_LABELS } from '../lib/attendance';
import type { AnnouncementCategory, AttendanceStatus } from '../lib/types';

export function AttendanceBadge({ status }: { status: AttendanceStatus | null | undefined }) {
  const key = status ?? 'none';
  return <span className={`badge badge--${key}`}>{ATTENDANCE_LABELS[key]}</span>;
}

export const CATEGORY_LABELS: Record<AnnouncementCategory, string> = {
  general: 'お知らせ',
  practice: '練習連絡',
  concert: '演奏会',
  score: '楽譜',
  venue: '会場',
  submission: '提出物'
};

export function CategoryBadge({ category }: { category: AnnouncementCategory }) {
  return <span className="badge">{CATEGORY_LABELS[category] ?? 'お知らせ'}</span>;
}
