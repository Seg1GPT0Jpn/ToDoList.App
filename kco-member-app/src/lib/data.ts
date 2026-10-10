import { useEffect, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  limit,
  orderBy,
  query,
  where,
  type DocumentData,
  type Query
} from 'firebase/firestore';
import { getServices } from '../firebase';
import type {
  AdminStats,
  Announcement,
  Attendance,
  Campaign,
  Concert,
  Member,
  NotificationRequest,
  Proposal,
  Rehearsal,
  Score,
  Stats,
  Survey,
  SurveyQuestion,
  SurveyResponse,
  SurveyResults
} from './types';

/*
 * Firestore の読み込み（リアルタイム更新）。
 * 団員向けの一覧は「公開中（published == true）」で絞り込みます（ルール側でも同じ条件を強制）。
 */

export interface Loadable<T> {
  data: T;
  loading: boolean;
  error: string | null;
}

function errorMessage(e: unknown): string {
  const code = (e as { code?: string })?.code;
  if (code === 'permission-denied') return '閲覧する権限がありません。';
  if (code === 'unavailable') return '通信できません。電波の良い場所で再度お試しください。';
  return '読み込みに失敗しました。時間をおいて再度お試しください。';
}

function useQueryData<T>(build: () => Query<DocumentData> | null, map: (id: string, d: DocumentData) => T, deps: unknown[]): Loadable<T[]> {
  const [state, setState] = useState<Loadable<T[]>>({ data: [], loading: true, error: null });

  useEffect(() => {
    const q = build();
    if (!q) {
      setState({ data: [], loading: false, error: null });
      return;
    }
    setState(s => ({ ...s, loading: true }));
    return onSnapshot(
      q,
      snap => setState({ data: snap.docs.map(d => map(d.id, d.data())), loading: false, error: null }),
      e => setState({ data: [], loading: false, error: errorMessage(e) })
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  return state;
}

function useDocData<T>(path: string[] | null, map: (id: string, d: DocumentData) => T, deps: unknown[]): Loadable<T | null> {
  const [state, setState] = useState<Loadable<T | null>>({ data: null, loading: true, error: null });

  useEffect(() => {
    if (!path) {
      setState({ data: null, loading: false, error: null });
      return;
    }
    const { db } = getServices();
    const [first, ...rest] = path;
    return onSnapshot(
      doc(db, first, ...rest),
      snap => setState({ data: snap.exists() ? map(snap.id, snap.data()) : null, loading: false, error: null }),
      e => setState({ data: null, loading: false, error: errorMessage(e) })
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  return state;
}

// ---------- 変換 ----------

const s = (v: unknown) => (typeof v === 'string' ? v : '');

export function toMember(id: string, d: DocumentData): Member {
  return {
    id,
    displayName: s(d.displayName) || '（名前未設定）',
    instrument: s(d.instrument),
    instrumentLabel: s(d.instrumentLabel) || s(d.instrument),
    part: s(d.part),
    section: s(d.section),
    status: d.status === 'paused' || d.status === 'inactive' ? d.status : 'active',
    bio: s(d.bio),
    roleLabel: s(d.roleLabel)
  };
}

export function toRehearsal(id: string, d: DocumentData): Rehearsal {
  return {
    id,
    title: s(d.title),
    date: s(d.date),
    startTime: s(d.startTime),
    endTime: s(d.endTime),
    venue: s(d.venue),
    content: s(d.content),
    notes: s(d.notes),
    target: s(d.target),
    scoreNote: s(d.scoreNote),
    attendanceDeadline: d.attendanceDeadline ?? null,
    published: d.published === true
  };
}

export function toAnnouncement(id: string, d: DocumentData): Announcement {
  return {
    id,
    title: s(d.title),
    body: s(d.body),
    important: d.important === true,
    category: d.category ?? 'general',
    audience: d.audience ?? { type: 'all', values: [] },
    published: d.published === true,
    publishedAt: d.publishedAt ?? null,
    forApplicants: d.forApplicants === true
  };
}

export function toConcert(id: string, d: DocumentData): Concert {
  return {
    id,
    title: s(d.title),
    date: s(d.date),
    venue: s(d.venue),
    openTime: s(d.openTime),
    startTime: s(d.startTime),
    program: Array.isArray(d.program) ? d.program : [],
    performers: s(d.performers),
    notes: s(d.notes),
    daySchedule: s(d.daySchedule),
    order: typeof d.order === 'number' ? d.order : 0,
    published: d.published === true
  };
}

// ---------- フック ----------

export function useStats() {
  return useDocData<Stats>(['stats', 'summary'], (_id, d) => ({
    memberCount: d.memberCount ?? 0,
    pausedCount: d.pausedCount ?? 0,
    applicantCount: d.applicantCount ?? 0,
    targetMembers: d.targetMembers ?? 80,
    decisionMembers: d.decisionMembers,
    minimumMembers: d.minimumMembers,
    byPart: Array.isArray(d.byPart) ? d.byPart : [],
    updatedAt: d.updatedAt
  }), []);
}

export function useAdminStats(enabled: boolean) {
  return useDocData<AdminStats>(enabled ? ['adminStats', 'summary'] : null, (_id, d) => ({
    applicantCount: d.applicantCount ?? 0,
    activeApplicantCount: d.activeApplicantCount ?? 0,
    memberCount: d.memberCount ?? 0,
    statusCounts: d.statusCounts ?? {},
    updatedAt: d.updatedAt
  }), [enabled]);
}

export function useMembers() {
  return useQueryData(() => collection(getServices().db, 'members'), toMember, []);
}

export function useMember(memberId: string | null) {
  return useDocData(memberId ? ['members', memberId] : null, toMember, [memberId]);
}

/** 自分のプロフィール（団員は members、参加希望者は applicants） */
export function useMyProfile(memberId: string | null, isApplicant: boolean) {
  return useDocData(memberId ? [isApplicant ? 'applicants' : 'members', memberId] : null, toMember, [memberId, isApplicant]);
}

/** 参加希望者の一覧（運営のみ。出欠の確認用） */
export function useApplicants(enabled: boolean) {
  return useQueryData(() => (enabled ? collection(getServices().db, 'applicants') : null), toMember, [enabled]);
}

/** staff/admin は下書きも含めて取得、団員は公開中のみ */
export function useRehearsals(includeDrafts = false) {
  return useQueryData(() => {
    const ref = collection(getServices().db, 'rehearsals');
    return includeDrafts ? query(ref, orderBy('date')) : query(ref, where('published', '==', true), orderBy('date'));
  }, toRehearsal, [includeDrafts]);
}

export function useRehearsal(id: string | undefined) {
  return useDocData(id ? ['rehearsals', id] : null, toRehearsal, [id]);
}

export function useMyAttendance(rehearsalId: string | undefined, memberId: string | null) {
  return useDocData<Attendance>(rehearsalId && memberId ? ['rehearsals', rehearsalId, 'attendance', memberId] : null,
    (id, d) => ({ memberId: id, status: d.status, comment: s(d.comment) }), [rehearsalId, memberId]);
}

export function useAllAttendance(rehearsalId: string | undefined, enabled: boolean) {
  return useQueryData(() => (rehearsalId && enabled ? collection(getServices().db, 'rehearsals', rehearsalId, 'attendance') : null),
    (id, d): Attendance => ({ memberId: id, status: d.status, comment: s(d.comment) }), [rehearsalId, enabled]);
}

/** includeDrafts：運営は下書きも／applicantOnly：参加希望者は「参加希望者にも表示」のものだけ */
export function useAnnouncements(includeDrafts = false, applicantOnly = false) {
  return useQueryData(() => {
    const ref = collection(getServices().db, 'announcements');
    if (includeDrafts) return query(ref, orderBy('updatedAt', 'desc'));
    if (applicantOnly) return query(ref, where('published', '==', true), where('forApplicants', '==', true), orderBy('publishedAt', 'desc'));
    return query(ref, where('published', '==', true), orderBy('publishedAt', 'desc'));
  }, toAnnouncement, [includeDrafts, applicantOnly]);
}

export function useConcerts(includeDrafts = false) {
  return useQueryData(() => {
    const ref = collection(getServices().db, 'concerts');
    return includeDrafts ? query(ref, orderBy('order')) : query(ref, where('published', '==', true), orderBy('order'));
  }, toConcert, [includeDrafts]);
}

// ---------- アンケート ----------

function toQuestion(q: unknown, i: number): SurveyQuestion {
  const o = (q ?? {}) as Record<string, unknown>;
  const type = o.type === 'multi' || o.type === 'text' ? o.type : 'single';
  return {
    id: s(o.id) || `q${i + 1}`,
    type,
    label: s(o.label),
    options: Array.isArray(o.options) ? o.options.filter((x): x is string => typeof x === 'string') : [],
    required: o.required === true
  };
}

export function toSurvey(id: string, d: DocumentData): Survey {
  const r = d.results as SurveyResults | null | undefined;
  return {
    id,
    title: s(d.title),
    description: s(d.description),
    questions: Array.isArray(d.questions) ? d.questions.map(toQuestion) : [],
    anonymous: d.anonymous === true,
    deadline: d.deadline ?? null,
    published: d.published === true,
    closed: d.closed === true,
    results: r && typeof r === 'object' && typeof r.respondents === 'number' ? r : null,
    resultsPublished: d.resultsPublished === true,
    createdAt: d.createdAt ?? null
  };
}

export function useSurveys(includeDrafts = false, enabled = true) {
  return useQueryData(() => {
    if (!enabled) return null;
    const ref = collection(getServices().db, 'surveys');
    return includeDrafts
      ? query(ref, orderBy('createdAt', 'desc'))
      : query(ref, where('published', '==', true), orderBy('createdAt', 'desc'));
  }, toSurvey, [includeDrafts, enabled]);
}

export function useSurvey(id: string | undefined) {
  return useDocData(id ? ['surveys', id] : null, toSurvey, [id]);
}

function toResponse(id: string, d: DocumentData): SurveyResponse {
  return { memberId: id, answers: d.answers && typeof d.answers === 'object' ? d.answers : {} };
}

export function useMyResponse(surveyId: string | undefined, memberId: string | null) {
  return useDocData(surveyId && memberId ? ['surveys', surveyId, 'responses', memberId] : null, toResponse, [surveyId, memberId]);
}

export function useAllResponses(surveyId: string | undefined, enabled: boolean) {
  return useQueryData(() => (surveyId && enabled ? collection(getServices().db, 'surveys', surveyId, 'responses') : null),
    toResponse, [surveyId, enabled]);
}

// ---------- 提案 ----------

export function toProposal(id: string, d: DocumentData): Proposal {
  return {
    id,
    title: s(d.title),
    body: s(d.body),
    category: d.category ?? 'other',
    visibility: d.visibility === 'staff' ? 'staff' : 'members',
    authorId: s(d.authorId),
    authorName: s(d.authorName),
    status: d.status ?? 'open',
    staffReply: s(d.staffReply),
    supportCount: typeof d.supportCount === 'number' ? d.supportCount : 0,
    createdAt: d.createdAt ?? null
  };
}

/**
 * 提案の一覧。団員は「みんなに公開」と「自分の提案」を別々に読んでまとめる
 * （ルールで読めるものだけを問い合わせる必要があるため）
 */
export function useProposals(memberId: string | null, isStaff: boolean): Loadable<Proposal[]> {
  const ref = () => collection(getServices().db, 'proposals');
  const all = useQueryData(() => (isStaff ? query(ref(), orderBy('createdAt', 'desc')) : null), toProposal, [isStaff]);
  const shared = useQueryData(() => (isStaff ? null : query(ref(), where('visibility', '==', 'members'), orderBy('createdAt', 'desc'))), toProposal, [isStaff]);
  const mine = useQueryData(() => (isStaff || !memberId ? null : query(ref(), where('authorId', '==', memberId))), toProposal, [isStaff, memberId]);

  if (isStaff) return all;
  const map = new Map<string, Proposal>();
  [...shared.data, ...mine.data].forEach(p => map.set(p.id, p));
  const data = [...map.values()].sort((a, b) => (b.createdAt?.toMillis() ?? Infinity) - (a.createdAt?.toMillis() ?? Infinity));
  return { data, loading: shared.loading || mine.loading, error: shared.error || mine.error };
}

export function useMySupport(proposalId: string, memberId: string | null) {
  return useDocData(memberId ? ['proposals', proposalId, 'supports', memberId] : null, id => id, [proposalId, memberId]);
}

// ---------- 楽譜 ----------

export function toScore(id: string, d: DocumentData): Score {
  return {
    id,
    title: s(d.title),
    composer: s(d.composer),
    note: s(d.note),
    parts: Array.isArray(d.parts) ? d.parts.filter((x: unknown): x is string => typeof x === 'string') : [],
    kind: d.kind === 'file' ? 'file' : 'link',
    url: s(d.url),
    storagePath: s(d.storagePath),
    fileName: s(d.fileName),
    published: d.published === true,
    createdAt: d.createdAt ?? null
  };
}

/**
 * 楽譜の一覧。団員は「全員向け」と「自分のパート向け」を別々に読んでまとめる
 */
export function useScores(myPart: string, isStaff: boolean): Loadable<Score[]> {
  const ref = () => collection(getServices().db, 'scores');
  const all = useQueryData(() => (isStaff ? query(ref(), orderBy('createdAt', 'desc')) : null), toScore, [isStaff]);
  const forAll = useQueryData(() => (isStaff ? null : query(ref(), where('published', '==', true), where('parts', 'array-contains', 'all'))), toScore, [isStaff]);
  const forPart = useQueryData(() => (isStaff || !myPart ? null : query(ref(), where('published', '==', true), where('parts', 'array-contains', myPart))), toScore, [isStaff, myPart]);

  if (isStaff) return all;
  const map = new Map<string, Score>();
  [...forAll.data, ...forPart.data].forEach(x => map.set(x.id, x));
  const data = [...map.values()].sort((a, b) => (b.createdAt?.toMillis() ?? 0) - (a.createdAt?.toMillis() ?? 0));
  return { data, loading: forAll.loading || forPart.loading, error: forAll.error || forPart.error };
}

// ---------- 通知 ----------

export function useNotifications(enabled: boolean) {
  return useQueryData(() => (enabled ? query(collection(getServices().db, 'notifications'), orderBy('createdAt', 'desc'), limit(30)) : null),
    (id, d): NotificationRequest => ({
      id,
      title: s(d.title),
      body: s(d.body),
      url: s(d.url),
      audience: d.audience ?? { type: 'all', values: [] },
      status: d.status ?? 'pending',
      source: s(d.source),
      sentCount: typeof d.sentCount === 'number' ? d.sentCount : null,
      failedCount: typeof d.failedCount === 'number' ? d.failedCount : null,
      error: s(d.error),
      createdAt: d.createdAt ?? null,
      sentAt: d.sentAt ?? null
    }), [enabled]);
}

export function useAppConfig() {
  return useDocData(['appConfig', 'public'], (_id, d) => ({
    vapidKey: s(d.vapidKey),
    // 正式加入確認フォームの URL（スプレッドシートの「加入確認設定」から同期）
    joinFormUrl: /^https:\/\/\S+$/.test(s(d.joinFormUrl)) ? s(d.joinFormUrl) : ''
  }), []);
}

// ---------- 団員募集キャンペーン ----------

export function toCampaign(d: DocumentData): Campaign {
  return {
    active: d.active === true,
    headline: s(d.headline) || '団員募集',
    message: s(d.message),
    parts: Array.isArray(d.parts) ? d.parts.filter((p: unknown) => p && typeof p === 'object') : [],
    formUrl: s(d.formUrl),
    hashtags: s(d.hashtags),
    deadlineText: s(d.deadlineText),
    showMemberCount: d.showMemberCount === true,
    memberCount: typeof d.memberCount === 'number' ? d.memberCount : 0,
    targetMembers: typeof d.targetMembers === 'number' ? d.targetMembers : 0
  };
}

export function useCampaign() {
  return useDocData(['publicCampaign', 'current'], (_id, d) => toCampaign(d), []);
}
