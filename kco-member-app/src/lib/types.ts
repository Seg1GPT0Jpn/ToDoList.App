import type { Timestamp } from 'firebase/firestore';

/** memberAccess/{メールアドレス}：ログイン許可・権限（スプレッドシートからの同期だけが書き込む） */
export type AccessStatus = 'active' | 'paused' | 'inactive';
export type Role = 'member' | 'staff' | 'admin';

export interface MemberAccess {
  email: string;
  status: AccessStatus;
  role: Role;
  memberId: string | null;
}

/** members/{団員ID}：団員同士で見える情報だけ（個人情報は置かない） */
export interface Member {
  id: string;
  displayName: string;
  instrument: string;
  instrumentLabel: string;
  part: string;
  section: string;
  status: AccessStatus;
  bio: string;
  roleLabel?: string;
}

export interface PartStat {
  part: string;
  label: string;
  count: number;
  target: number | null;
  min: number | null;
}

export interface Stats {
  memberCount: number;
  targetMembers: number;
  decisionMembers?: number;
  minimumMembers?: number;
  byPart: PartStat[];
  updatedAt?: Timestamp;
}

export interface AdminStats {
  applicantCount: number;
  activeApplicantCount: number;
  memberCount: number;
  statusCounts: Record<string, number>;
  updatedAt?: Timestamp;
}

export interface Rehearsal {
  id: string;
  title: string;
  /** YYYY-MM-DD（空欄 = 未定） */
  date: string;
  startTime: string;
  endTime: string;
  venue: string;
  content: string;
  notes: string;
  target: string;
  scoreNote: string;
  attendanceDeadline: Timestamp | null;
  published: boolean;
}

export type AttendanceStatus = 'present' | 'absent' | 'late';

export interface Attendance {
  memberId: string;
  status: AttendanceStatus;
  comment: string;
}

export type AnnouncementCategory = 'general' | 'practice' | 'concert' | 'score' | 'venue' | 'submission';

export interface Audience {
  type: 'all' | 'section' | 'part';
  values: string[];
}

export interface Announcement {
  id: string;
  title: string;
  body: string;
  important: boolean;
  category: AnnouncementCategory;
  audience: Audience;
  published: boolean;
  publishedAt: Timestamp | null;
}

export interface ProgramItem {
  label: string;
  composer: string;
  work: string;
}

export interface Concert {
  id: string;
  title: string;
  date: string;
  venue: string;
  openTime: string;
  startTime: string;
  program: ProgramItem[];
  performers: string;
  notes: string;
  daySchedule: string;
  order: number;
  published: boolean;
}
