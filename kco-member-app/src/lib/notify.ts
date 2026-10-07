import { addDoc, collection, serverTimestamp } from 'firebase/firestore';
import { getServices } from '../firebase';
import type { Audience } from './types';

export type NotificationSource = 'manual' | 'announcement' | 'survey' | 'score';

export const NOTIFY_LINKS: { path: string; label: string }[] = [
  { path: '/', label: 'ホーム' },
  { path: '/schedule', label: '予定' },
  { path: '/news', label: 'お知らせ' },
  { path: '/together', label: 'みんなで（アンケート・提案）' },
  { path: '/scores', label: '楽譜' },
  { path: '/concert', label: '演奏会' }
];

/** 通知を予約する（実際の送信は Apps Script が数分ごとに行う） */
export async function queueNotification(n: { title: string; body: string; url: string; audience: Audience; source: NotificationSource }) {
  const { auth, db } = getServices();
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error('signed-out');
  await addDoc(collection(db, 'notifications'), {
    title: n.title.trim().slice(0, 60) || 'お知らせ',
    body: n.body.replace(/\s+/g, ' ').trim().slice(0, 200),
    url: /^\/[A-Za-z0-9/_#?=&-]*$/.test(n.url) ? n.url.slice(0, 200) : '/',
    audience: { type: n.audience.type, values: n.audience.type === 'all' ? [] : n.audience.values.slice(0, 20) },
    status: 'pending',
    source: n.source,
    createdAt: serverTimestamp(),
    createdBy: uid
  });
}
