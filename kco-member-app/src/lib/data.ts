import { useEffect, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  where,
  type DocumentData,
  type Query
} from 'firebase/firestore';
import { getServices } from '../firebase';
import type { Announcement, Attendance, Concert, Member, Rehearsal, Stats, AdminStats } from './types';

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
    publishedAt: d.publishedAt ?? null
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

export function useAnnouncements(includeDrafts = false) {
  return useQueryData(() => {
    const ref = collection(getServices().db, 'announcements');
    return includeDrafts
      ? query(ref, orderBy('updatedAt', 'desc'))
      : query(ref, where('published', '==', true), orderBy('publishedAt', 'desc'));
  }, toAnnouncement, [includeDrafts]);
}

export function useConcerts(includeDrafts = false) {
  return useQueryData(() => {
    const ref = collection(getServices().db, 'concerts');
    return includeDrafts ? query(ref, orderBy('order')) : query(ref, where('published', '==', true), orderBy('order'));
  }, toConcert, [includeDrafts]);
}
