import type { Attendance, AttendanceStatus, Member } from './types';
import { partLabel, partOrder } from './parts';

export const ATTENDANCE_LABELS: Record<AttendanceStatus | 'none', string> = {
  present: '出席',
  late: '遅刻',
  absent: '欠席',
  none: '未回答'
};

export interface AttendanceCount {
  present: number;
  late: number;
  absent: number;
  none: number;
  total: number;
}

export interface AttendanceSummary extends AttendanceCount {
  byPart: (AttendanceCount & { part: string; label: string })[];
  unanswered: Member[];
}

function emptyCount(): AttendanceCount {
  return { present: 0, late: 0, absent: 0, none: 0, total: 0 };
}

/**
 * 出欠の集計（在籍中の団員が対象。退団者の回答は数えない）
 * 未回答 = 回答が無い在籍中の団員
 */
export function summarizeAttendance(members: Member[], records: Attendance[]): AttendanceSummary {
  const active = members.filter(m => m.status === 'active');
  const byMember = new Map(records.map(r => [r.memberId, r.status]));
  const total = emptyCount();
  const parts = new Map<string, AttendanceCount>();
  const unanswered: Member[] = [];

  for (const m of active) {
    const status = byMember.get(m.id);
    const key: keyof AttendanceCount = status ?? 'none';
    const p = parts.get(m.part) ?? emptyCount();
    total[key]++;
    total.total++;
    p[key]++;
    p.total++;
    parts.set(m.part, p);
    if (!status) unanswered.push(m);
  }

  const byPart = [...parts.entries()]
    .sort((a, b) => partOrder(a[0]) - partOrder(b[0]))
    .map(([part, c]) => ({ part, label: partLabel(part), ...c }));

  return { ...total, byPart, unanswered };
}
