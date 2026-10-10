import type { Timestamp } from 'firebase/firestore';

/** memberAccess/{メールアドレス}：ログイン許可・権限（スプレッドシートからの同期だけが書き込む） */
export type AccessStatus = 'active' | 'paused' | 'inactive';
export type Role = 'member' | 'staff' | 'admin';

export interface MemberAccess {
  email: string;
  status: AccessStatus;
  role: Role;
  memberId: string | null;
  /** パートコード（楽譜の閲覧範囲。同期が書き込む） */
  part: string;
  /** member = 正式参加の団員・運営／applicant = 応募しただけの参加希望者 */
  stage: 'member' | 'applicant';
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
  /** 団員数（在籍中＋活動休止中） */
  memberCount: number;
  pausedCount: number;
  /** アプリに登録されている参加希望者の数 */
  applicantCount: number;
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
  /** 参加希望者にも表示する */
  forApplicants: boolean;
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

// ---------- アンケート ----------

export type QuestionType = 'single' | 'multi' | 'text';

export interface SurveyQuestion {
  id: string;
  type: QuestionType;
  label: string;
  options: string[];
  required: boolean;
}

/** 選択式の集計結果（質問ID → 選択肢ごとの人数）。自由記述は含めない */
export interface SurveyResults {
  respondents: number;
  counts: Record<string, number[]>;
}

export interface Survey {
  id: string;
  title: string;
  description: string;
  questions: SurveyQuestion[];
  anonymous: boolean;
  deadline: Timestamp | null;
  published: boolean;
  closed: boolean;
  results: SurveyResults | null;
  resultsPublished: boolean;
  createdAt: Timestamp | null;
}

/** 回答：質問ID → 選んだ選択肢の番号（single/multi）または文章（text） */
export type SurveyAnswers = Record<string, number | number[] | string>;

export interface SurveyResponse {
  memberId: string;
  answers: SurveyAnswers;
}

// ---------- 提案 ----------

export type ProposalCategory = 'idea' | 'music' | 'practice' | 'event' | 'other';
export type ProposalStatus = 'open' | 'considering' | 'adopted' | 'done' | 'declined';
export type ProposalVisibility = 'members' | 'staff';

export interface Proposal {
  id: string;
  title: string;
  body: string;
  category: ProposalCategory;
  visibility: ProposalVisibility;
  authorId: string;
  authorName: string;
  status: ProposalStatus;
  staffReply: string;
  supportCount: number;
  createdAt: Timestamp | null;
}

// ---------- 楽譜 ----------

export interface Score {
  id: string;
  title: string;
  composer: string;
  note: string;
  /** パートコード（'all' = 全員） */
  parts: string[];
  kind: 'file' | 'link';
  url: string;
  storagePath: string;
  fileName: string;
  published: boolean;
  createdAt: Timestamp | null;
}

// ---------- 通知 ----------

export interface NotificationRequest {
  id: string;
  title: string;
  body: string;
  url: string;
  audience: Audience;
  status: 'pending' | 'sending' | 'sent' | 'failed';
  source: string;
  sentCount: number | null;
  failedCount: number | null;
  error: string;
  createdAt: Timestamp | null;
  sentAt: Timestamp | null;
}

// ---------- 団員募集キャンペーン（一般公開） ----------

export interface CampaignPart {
  part: string;
  label: string;
  /** urgent = 急募 / wanted = 募集中 */
  level: 'urgent' | 'wanted';
}

export interface Campaign {
  active: boolean;
  headline: string;
  message: string;
  parts: CampaignPart[];
  formUrl: string;
  hashtags: string;
  deadlineText: string;
  showMemberCount: boolean;
  memberCount: number;
  targetMembers: number;
}
