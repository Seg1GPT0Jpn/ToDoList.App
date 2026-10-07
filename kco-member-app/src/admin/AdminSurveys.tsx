import { useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { Timestamp, addDoc, collection, deleteDoc, doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { Empty, ErrorNote, Loading } from '../components/Layout';
import { SurveyResultsView } from '../components/SurveyResultsView';
import { getServices } from '../firebase';
import { useAllResponses, useMembers, useSurvey, useSurveys } from '../lib/data';
import { queueNotification } from '../lib/notify';
import { endOfDayJst, formatDeadline, toDateInput } from '../lib/dates';
import { aggregate, isSurveyOpen, newQuestionId, textAnswers } from '../lib/survey';
import type { Survey, SurveyQuestion } from '../lib/types';

export function AdminSurveys() {
  const surveys = useSurveys(true);
  if (surveys.loading) return <Loading />;
  return (
    <div className="stack">
      <div className="row">
        <h2 style={{ margin: 0 }}>アンケート</h2>
        <span className="spacer" />
        <Link className="btn btn--sm" to="/admin/surveys/new">＋ アンケートを作成</Link>
      </div>
      <p className="small muted">団員の意見を集めて、みんなでオーケストラをつくるための機能です。</p>
      <ErrorNote message={surveys.error} />
      {surveys.data.length === 0 ? (
        <Empty>アンケートはまだありません。</Empty>
      ) : (
        <ul className="list">
          {surveys.data.map(s => (
            <li key={s.id}>
              <Link className="list__item" to={`/admin/surveys/${s.id}`}>
                <span className="list__body">
                  <span className="row" style={{ gap: '0.35rem' }}>
                    {!s.published ? <span className="badge badge--draft">下書き</span> : isSurveyOpen(s) ? <span className="badge badge--ok">受付中</span> : <span className="badge">締切</span>}
                    {s.anonymous && <span className="badge">匿名</span>}
                    {s.resultsPublished && <span className="badge badge--gold">結果公開中</span>}
                  </span>
                  <span className="list__title">{s.title}</span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

interface FormState {
  title: string;
  description: string;
  questions: SurveyQuestion[];
  anonymous: boolean;
  deadline: string;
  published: boolean;
  closed: boolean;
}

const blankQuestion = (id: string): SurveyQuestion => ({ id, type: 'single', label: '', options: ['', ''], required: false });

export function AdminSurveyEdit() {
  const { id } = useParams();
  const isNew = id === 'new';
  const survey = useSurvey(isNew ? undefined : id);
  if (!isNew && survey.loading) return <Loading />;
  if (!isNew && !survey.data) return <p className="alert alert--error">アンケートが見つかりません。</p>;
  return (
    <div className="stack">
      <p className="small"><Link to="/admin/surveys">← アンケート一覧</Link></p>
      <SurveyForm key={id} original={isNew ? null : survey.data} />
      {!isNew && survey.data && <SurveyResultsAdmin survey={survey.data} />}
    </div>
  );
}

function SurveyForm({ original }: { original: Survey | null }) {
  const navigate = useNavigate();
  const { isAdmin } = useAuth();
  const [f, setF] = useState<FormState>(original ? {
    title: original.title,
    description: original.description,
    questions: original.questions,
    anonymous: original.anonymous,
    deadline: original.deadline ? toDateInput(original.deadline.toDate()) : '',
    published: original.published,
    closed: original.closed
  } : {
    title: '',
    description: '',
    questions: [blankQuestion('q1')],
    anonymous: false,
    deadline: '',
    published: false,
    closed: false
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [notify, setNotify] = useState(false);

  const set = <K extends keyof FormState>(k: K, v: FormState[K]) => setF(prev => ({ ...prev, [k]: v }));
  const setQ = (i: number, patch: Partial<SurveyQuestion>) =>
    set('questions', f.questions.map((q, j) => (j === i ? { ...q, ...patch } : q)));
  const move = (i: number, d: -1 | 1) => {
    const list = [...f.questions];
    const j = i + d;
    if (j < 0 || j >= list.length) return;
    [list[i], list[j]] = [list[j], list[i]];
    set('questions', list);
  };

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSaved(false);
    if (!f.title.trim()) return setError('タイトルを入力してください。');
    const questions = f.questions.map(q => ({
      id: q.id,
      type: q.type,
      label: q.label.trim().slice(0, 200),
      options: q.type === 'text' ? [] : q.options.map(o => o.trim().slice(0, 100)).filter(Boolean).slice(0, 20),
      required: q.required
    }));
    if (!questions.length) return setError('質問を1つ以上追加してください。');
    if (questions.some(q => !q.label)) return setError('質問文が空の質問があります。');
    if (questions.some(q => q.type !== 'text' && q.options.length < 2)) return setError('選択式の質問には選択肢を2つ以上入れてください。');

    const deadline = endOfDayJst(f.deadline);
    const data = {
      title: f.title.trim().slice(0, 120),
      description: f.description.slice(0, 3000),
      questions,
      anonymous: f.anonymous,
      deadline: deadline ? Timestamp.fromDate(deadline) : null,
      published: f.published,
      closed: f.closed,
      updatedAt: serverTimestamp()
    };
    setSaving(true);
    try {
      const { db } = getServices();
      const sendNotice = (id: string) => notify && f.published && !f.closed
        ? queueNotification({ title: `アンケート：${data.title}`, body: 'ご協力をお願いします。', url: `/surveys/${id}`, audience: { type: 'all', values: [] }, source: 'survey' }).catch(() => undefined)
        : Promise.resolve();
      if (original) {
        await setDoc(doc(db, 'surveys', original.id), data, { merge: true });
        await sendNotice(original.id);
        setNotify(false);
        setSaved(true);
      } else {
        const ref = await addDoc(collection(db, 'surveys'), { ...data, results: null, resultsPublished: false, createdAt: serverTimestamp() });
        await sendNotice(ref.id);
        navigate(`/admin/surveys/${ref.id}`, { replace: true });
      }
    } catch {
      setError('保存できませんでした。入力内容を確認してください。');
    } finally {
      setSaving(false);
    }
  }

  async function onDelete() {
    if (!original || !window.confirm('このアンケートを削除しますか？（回答は残りますが、画面から見られなくなります）')) return;
    try {
      await deleteDoc(doc(getServices().db, 'surveys', original.id));
      navigate('/admin/surveys', { replace: true });
    } catch {
      setError('削除できませんでした（削除は管理者のみ可能です）。');
    }
  }

  return (
    <form className="card stack" onSubmit={onSubmit}>
      <h2 className="card__title">{original ? 'アンケートを編集' : 'アンケートを作成'}</h2>
      {original?.published && (
        <p className="alert alert--info small">公開後に選択肢の順番を入れ替えたり削除したりすると、すでに集まった回答の集計がずれます。追加は末尾にしてください。</p>
      )}
      <div className="field">
        <label htmlFor="s-title">タイトル</label>
        <input id="s-title" type="text" maxLength={120} value={f.title} onChange={e => set('title', e.target.value)} required />
      </div>
      <div className="field">
        <label htmlFor="s-desc">説明（任意）</label>
        <textarea id="s-desc" maxLength={3000} value={f.description} onChange={e => set('description', e.target.value)} />
      </div>

      {f.questions.map((q, i) => (
        <fieldset key={q.id} className="question-edit">
          <legend>質問 {i + 1}</legend>
          <div className="field">
            <label htmlFor={`${q.id}-label`}>質問文</label>
            <input id={`${q.id}-label`} type="text" maxLength={200} value={q.label} onChange={e => setQ(i, { label: e.target.value })} />
          </div>
          <div className="row">
            <select aria-label="回答の形式" value={q.type} onChange={e => setQ(i, { type: e.target.value as SurveyQuestion['type'], options: e.target.value === 'text' ? [] : q.options.length ? q.options : ['', ''] })}>
              <option value="single">1つ選ぶ</option>
              <option value="multi">いくつでも選ぶ</option>
              <option value="text">自由に書く</option>
            </select>
            <label className="checkbox small"><input type="checkbox" checked={q.required} onChange={e => setQ(i, { required: e.target.checked })} />必須</label>
            <span className="spacer" />
            <button type="button" className="btn btn--sm btn--outline" aria-label="上へ" onClick={() => move(i, -1)} disabled={i === 0}>↑</button>
            <button type="button" className="btn btn--sm btn--outline" aria-label="下へ" onClick={() => move(i, 1)} disabled={i === f.questions.length - 1}>↓</button>
            <button type="button" className="btn btn--sm btn--danger" onClick={() => set('questions', f.questions.filter((_, j) => j !== i))} disabled={f.questions.length === 1}>削除</button>
          </div>
          {q.type !== 'text' && (
            <div className="stack" style={{ marginTop: '0.5rem', gap: '0.4rem' }}>
              {q.options.map((o, oi) => (
                <div key={oi} className="row">
                  <input type="text" aria-label={`選択肢 ${oi + 1}`} maxLength={100} value={o} placeholder={`選択肢 ${oi + 1}`} style={{ flex: 1 }}
                    onChange={e => setQ(i, { options: q.options.map((x, k) => (k === oi ? e.target.value : x)) })} />
                  <button type="button" className="btn btn--sm btn--outline" aria-label={`選択肢 ${oi + 1} を削除`} onClick={() => setQ(i, { options: q.options.filter((_, k) => k !== oi) })} disabled={q.options.length <= 2}>×</button>
                </div>
              ))}
              {q.options.length < 20 && (
                <button type="button" className="btn btn--sm btn--outline" onClick={() => setQ(i, { options: [...q.options, ''] })}>＋ 選択肢を追加</button>
              )}
            </div>
          )}
        </fieldset>
      ))}
      {f.questions.length < 20 && (
        <button type="button" className="btn btn--outline btn--sm" onClick={() => set('questions', [...f.questions, blankQuestion(newQuestionId(f.questions))])}>＋ 質問を追加</button>
      )}

      <div className="field">
        <label htmlFor="s-deadline">締切日（任意・その日の23:59まで）</label>
        <input id="s-deadline" type="date" value={f.deadline} onChange={e => set('deadline', e.target.value)} />
      </div>
      <label className="checkbox">
        <input type="checkbox" checked={f.anonymous} onChange={e => set('anonymous', e.target.checked)} disabled={!!original?.published && original.anonymous} />
        匿名アンケート（運営の画面にも回答者の名前を出さない）
      </label>
      <label className="checkbox">
        <input type="checkbox" checked={f.published} onChange={e => set('published', e.target.checked)} />
        団員に公開する
      </label>
      <label className="checkbox">
        <input type="checkbox" checked={f.closed} onChange={e => set('closed', e.target.checked)} />
        回答の受付を終了する
      </label>
      {f.published && !f.closed && (
        <label className="checkbox">
          <input type="checkbox" checked={notify} onChange={e => setNotify(e.target.checked)} />
          保存したら団員全員にプッシュ通知を送る
        </label>
      )}
      <div className="row">
        <button className="btn" type="submit" disabled={saving}>保存する</button>
        {original && isAdmin && <button className="btn btn--danger btn--sm" type="button" onClick={onDelete}>削除</button>}
      </div>
      {saved && <p className="alert alert--ok" role="status">保存しました。</p>}
      {error && <p className="alert alert--error" role="alert">{error}</p>}
    </form>
  );
}

/** 集計（運営のみ）。匿名アンケートでは名前を出さない */
function SurveyResultsAdmin({ survey }: { survey: Survey }) {
  const responses = useAllResponses(survey.id, true);
  const members = useMembers();
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  if (responses.loading) return <Loading />;

  const results = aggregate(survey.questions, responses.data);
  const nameOf = (id: string) => members.data.find(m => m.id === id)?.displayName ?? '（不明）';
  const activeCount = members.data.filter(m => m.status === 'active').length;

  async function publishResults(publish: boolean) {
    setMessage(null);
    try {
      await updateDoc(doc(getServices().db, 'surveys', survey.id), {
        results: publish ? results : survey.results,
        resultsPublished: publish,
        updatedAt: serverTimestamp()
      });
      setMessage({ ok: true, text: publish ? 'いまの集計結果を団員に公開しました（自由記述は公開されません）。' : '結果の公開をやめました。' });
    } catch {
      setMessage({ ok: false, text: '更新できませんでした。' });
    }
  }

  return (
    <section className="card stack">
      <h2 className="card__title">集計</h2>
      <ErrorNote message={responses.error} />
      <p className="small">回答 {responses.data.length} 人{activeCount ? ` ／ 在籍 ${activeCount} 人` : ''}</p>
      <SurveyResultsView questions={survey.questions} results={results} />
      {survey.questions.filter(q => q.type === 'text').map(q => {
        const list = textAnswers(q, responses.data);
        return (
          <div key={q.id}>
            <p className="list__title">{q.label}（自由記述）</p>
            {list.length ? <ul className="small">{list.map((t, i) => <li key={i} className="pre">{t}</li>)}</ul> : <p className="small muted">回答なし</p>}
          </div>
        );
      })}

      {!survey.anonymous && responses.data.length > 0 && (
        <details>
          <summary className="small">回答した人・まだの人</summary>
          <p className="small">回答済み：{responses.data.map(r => nameOf(r.memberId)).join('、')}</p>
          <p className="small">未回答：{members.data.filter(m => m.status === 'active' && !responses.data.some(r => r.memberId === m.id)).map(m => m.displayName).join('、') || 'なし'}</p>
        </details>
      )}

      <div className="row">
        <button type="button" className="btn btn--sm" onClick={() => publishResults(true)}>{survey.resultsPublished ? '最新の集計で更新して公開' : '集計結果を団員に公開'}</button>
        {survey.resultsPublished && <button type="button" className="btn btn--sm btn--outline" onClick={() => publishResults(false)}>公開をやめる</button>}
      </div>
      {survey.resultsPublished && survey.results && <p className="small muted">公開中の結果：回答者 {survey.results.respondents} 人時点</p>}
      {message && <p className={`alert ${message.ok ? 'alert--ok' : 'alert--error'}`} role="status">{message.text}</p>}
      <p className="small muted">締切：{formatDeadline(survey.deadline?.toDate() ?? null)}</p>
    </section>
  );
}
