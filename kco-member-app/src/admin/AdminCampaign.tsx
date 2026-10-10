import { useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { ErrorNote, Loading } from '../components/Layout';
import { getServices } from '../firebase';
import { DEFAULT_CAMPAIGN, isValidFormUrl, sortParts, suggestParts } from '../lib/campaign';
import { useCampaign, useStats } from '../lib/data';
import { PARTS } from '../lib/parts';
import type { Campaign, CampaignPart } from '../lib/types';

type Level = CampaignPart['level'] | 'none';

/** 団員募集キャンペーンの設定（募集ページ /join と募集カードの内容） */
export function AdminCampaign() {
  const campaign = useCampaign();
  const stats = useStats();
  const [f, setF] = useState<Campaign>(DEFAULT_CAMPAIGN);
  const [loaded, setLoaded] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  useEffect(() => {
    if (!loaded && !campaign.loading) {
      if (campaign.data) setF(campaign.data);
      setLoaded(true);
    }
  }, [campaign.loading, campaign.data, loaded]);

  if (!loaded) return <Loading />;

  const set = <K extends keyof Campaign>(k: K, v: Campaign[K]) => setF(prev => ({ ...prev, [k]: v }));
  const levelOf = (part: string): Level => f.parts.find(p => p.part === part)?.level ?? 'none';

  function setLevel(part: string, label: string, level: Level) {
    const rest = f.parts.filter(p => p.part !== part);
    set('parts', sortParts(level === 'none' ? rest : [...rest, { part, label, level }]));
  }

  function applySuggestion() {
    const byPart = stats.data?.byPart ?? [];
    const suggested = suggestParts(byPart);
    set('parts', suggested);
    setMessage({
      ok: true,
      text: suggested.length
        ? `募集設定の目標・最低人数から ${suggested.length} パートを選びました。必要に応じて調整してください。`
        : '目標・最低人数に届いていないパートはありませんでした（募集設定で目標人数を入れると提案できます）。'
    });
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    if (!f.headline.trim()) {
      setMessage({ ok: false, text: '見出しを入力してください。' });
      return;
    }
    if (!isValidFormUrl(f.formUrl.trim())) {
      setMessage({ ok: false, text: '応募フォームの URL は https:// から始まるものを入力してください。' });
      return;
    }
    setSaving(true);
    try {
      await setDoc(doc(getServices().db, 'publicCampaign', 'current'), {
        active: f.active,
        headline: f.headline.trim().slice(0, 40),
        message: f.message.slice(0, 400),
        parts: f.parts.slice(0, 16).map(p => ({ part: p.part, label: p.label.slice(0, 20), level: p.level })),
        formUrl: f.formUrl.trim(),
        hashtags: f.hashtags.slice(0, 200),
        deadlineText: f.deadlineText.trim().slice(0, 40),
        showMemberCount: f.showMemberCount,
        // 団員数は保存した時点の値を載せる（公開ページから団員の情報は読めないため）
        memberCount: Math.min(stats.data?.memberCount ?? f.memberCount, 1000),
        targetMembers: Math.min(stats.data?.targetMembers ?? f.targetMembers, 1000),
        updatedAt: serverTimestamp()
      });
      setMessage({ ok: true, text: f.active ? '保存しました。募集ページとカードに反映されています。' : '保存しました（募集は「停止中」です）。' });
    } catch {
      setMessage({ ok: false, text: '保存できませんでした。入力内容を確認してください。' });
    } finally {
      setSaving(false);
    }
  }

  return (
    <form className="stack" onSubmit={onSubmit}>
      <div className="row">
        <h2 style={{ margin: 0 }}>団員募集キャンペーン</h2>
        <span className="spacer" />
        <Link className="btn btn--sm btn--outline" to="/campaign">カードを見る</Link>
      </div>
      <p className="small muted">
        ここで入力した内容は、<strong>誰でも見られる募集ページ</strong>（<a href="/join" target="_blank" rel="noopener noreferrer">/join</a>）と、
        団員がシェアする募集カードに表示されます。個人名・連絡先・未確定の情報は書かないでください。
      </p>

      <label className="checkbox">
        <input type="checkbox" checked={f.active} onChange={e => set('active', e.target.checked)} />
        募集中にする（オフにすると募集ページは「現在募集していません」と表示）
      </label>

      <div className="field">
        <label htmlFor="c-head">見出し（40文字まで）</label>
        <input id="c-head" type="text" maxLength={40} value={f.headline} onChange={e => set('headline', e.target.value)} required />
      </div>
      <div className="field">
        <label htmlFor="c-msg">メッセージ（400文字まで・任意）</label>
        <textarea id="c-msg" maxLength={400} value={f.message} onChange={e => set('message', e.target.value)} placeholder="例：一緒に音楽をつくる仲間を募集しています。" />
        <p className="field__hint">練習会場・日時・会費などは、決まっているものだけを書いてください。</p>
      </div>
      <div className="field">
        <label htmlFor="c-form">応募フォームの URL（任意）</label>
        <input id="c-form" type="url" inputMode="url" maxLength={500} value={f.formUrl} onChange={e => set('formUrl', e.target.value)} placeholder="https://forms.gle/..." />
        <p className="field__hint">公式サイトの団員募集ページと同じ参加希望フォームのURLを貼ってください（フォームの「送信」→ リンク）。空欄なら「準備中」と表示します。募集ページには公式サイトへのリンクも表示されます。</p>
      </div>
      <div className="field">
        <label htmlFor="c-deadline">締切（任意・自由入力）</label>
        <input id="c-deadline" type="text" maxLength={40} value={f.deadlineText} onChange={e => set('deadlineText', e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="c-tags">ハッシュタグ（任意・空白区切り）</label>
        <input id="c-tags" type="text" maxLength={200} value={f.hashtags} onChange={e => set('hashtags', e.target.value)} placeholder="#オーケストラ #団員募集" />
      </div>
      <label className="checkbox">
        <input type="checkbox" checked={f.showMemberCount} onChange={e => set('showMemberCount', e.target.checked)} />
        現在の団員数と目標人数を載せる（いま：{stats.data?.memberCount ?? 0}人 ／ {stats.data?.targetMembers ?? 0}人）
      </label>

      <fieldset className="card">
        <legend className="card__title">募集するパート</legend>
        <div className="row" style={{ marginBottom: '0.75rem' }}>
          <button type="button" className="btn btn--sm btn--outline" onClick={applySuggestion}>人数から自動で選ぶ</button>
          <span className="small muted">選ばない場合は「全パート募集中」と表示します。</span>
        </div>
        <ul className="part-levels">
          {PARTS.map(p => (
            <li key={p.part}>
              <span>{p.label}</span>
              <select aria-label={`${p.label}の募集`} value={levelOf(p.part)} onChange={e => setLevel(p.part, p.label, e.target.value as Level)}>
                <option value="none">—</option>
                <option value="wanted">募集中</option>
                <option value="urgent">急募</option>
              </select>
            </li>
          ))}
        </ul>
      </fieldset>

      <ErrorNote message={campaign.error} />
      {message && <p className={`alert ${message.ok ? 'alert--ok' : 'alert--error'}`} role="status">{message.text}</p>}
      <div className="row">
        <button className="btn" type="submit" disabled={saving}>保存する</button>
      </div>
    </form>
  );
}
