import { useEffect, useState, type FormEvent } from 'react';
import { Link, useParams } from 'react-router-dom';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { Empty, ErrorNote, Loading, PageTitle } from '../components/Layout';
import { SurveyResultsView } from '../components/SurveyResultsView';
import { getServices } from '../firebase';
import { useMyResponse, useSurvey, useSurveys } from '../lib/data';
import { formatDeadline } from '../lib/dates';
import { cleanAnswers, isSurveyOpen, missingRequired } from '../lib/survey';
import type { Survey, SurveyAnswers } from '../lib/types';

function SurveyStateBadge({ survey, answered }: { survey: Survey; answered: boolean }) {
  return (
    <span className="row" style={{ gap: '0.35rem' }}>
      {isSurveyOpen(survey) ? <span className="badge badge--ok">受付中</span> : <span className="badge">締切</span>}
      {answered ? <span className="badge badge--navy">回答済み</span> : isSurveyOpen(survey) && <span className="badge badge--important">未回答</span>}
      {survey.anonymous && <span className="badge">匿名</span>}
      {survey.resultsPublished && <span className="badge badge--gold">結果公開</span>}
    </span>
  );
}

export function SurveyListItem({ survey }: { survey: Survey }) {
  const { access } = useAuth();
  const mine = useMyResponse(survey.id, access?.memberId ?? null);
  return (
    <li>
      <Link className="list__item" to={`/surveys/${survey.id}`}>
        <div className="list__body">
          <SurveyStateBadge survey={survey} answered={!!mine.data} />
          <p className="list__title">{survey.title}</p>
          {survey.deadline && <p className="small muted">締切：{formatDeadline(survey.deadline.toDate())}</p>}
        </div>
      </Link>
    </li>
  );
}

export function SurveyList() {
  const surveys = useSurveys();
  if (surveys.loading) return <Loading />;
  return (
    <>
      <ErrorNote message={surveys.error} />
      {surveys.data.length === 0 ? (
        <Empty>いま回答できるアンケートはありません。</Empty>
      ) : (
        <ul className="list">{surveys.data.map(s => <SurveyListItem key={s.id} survey={s} />)}</ul>
      )}
    </>
  );
}

export function SurveyPage() {
  const { id } = useParams();
  const { access, canWrite } = useAuth();
  const survey = useSurvey(id);
  const mine = useMyResponse(id, access?.memberId ?? null);
  const [answers, setAnswers] = useState<SurveyAnswers>({});
  const [editing, setEditing] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  useEffect(() => {
    if (mine.data) setAnswers(mine.data.answers);
  }, [mine.data]);

  if (survey.loading || mine.loading) return <Loading />;
  const s = survey.data;
  if (!s) return <p className="alert alert--error">アンケートが見つかりません。</p>;

  const open = isSurveyOpen(s);
  const canAnswer = open && canWrite && !!access?.memberId;
  const answered = !!mine.data;
  const showForm = canAnswer && (!answered || editing);

  const set = (qid: string, v: SurveyAnswers[string]) => setAnswers(prev => ({ ...prev, [qid]: v }));
  const toggle = (qid: string, i: number) => {
    const cur = Array.isArray(answers[qid]) ? (answers[qid] as number[]) : [];
    set(qid, cur.includes(i) ? cur.filter(x => x !== i) : [...cur, i]);
  };

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!s || !access?.memberId) return;
    const missing = missingRequired(s.questions, answers);
    if (missing.length) {
      setMessage({ ok: false, text: `必須の質問に答えてください：${missing.join('、')}` });
      return;
    }
    setSaving(true);
    setMessage(null);
    try {
      await setDoc(doc(getServices().db, 'surveys', s.id, 'responses', access.memberId), {
        answers: cleanAnswers(s.questions, answers),
        updatedAt: serverTimestamp()
      });
      setEditing(false);
      setMessage({ ok: true, text: '回答を送信しました。ありがとうございます！' });
    } catch {
      setMessage({ ok: false, text: '送信できませんでした。締切を過ぎていないか確認してください。' });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="stack">
      <p className="small"><Link to="/together">← みんなで</Link></p>
      <PageTitle en="Survey">{s.title}</PageTitle>
      <SurveyStateBadge survey={s} answered={answered} />
      {s.description && <p className="pre">{s.description}</p>}
      {s.deadline && <p className="small muted">締切：{formatDeadline(s.deadline.toDate())}</p>}
      <p className="small muted">
        {s.anonymous
          ? '匿名のアンケートです。運営の画面にも回答者の名前は表示されません。'
          : '回答は運営メンバーが確認します（他の団員には見えません）。'}
      </p>
      <ErrorNote message={survey.error || mine.error} />

      {showForm ? (
        <form className="card stack" onSubmit={onSubmit}>
          {s.questions.map((q, qi) => (
            <fieldset key={q.id} className="field">
              <legend>
                Q{qi + 1}. {q.label}
                {q.required && <span className="badge badge--important" style={{ marginLeft: '0.4rem' }}>必須</span>}
                {q.type === 'multi' && <span className="small muted">（いくつでも）</span>}
              </legend>
              {q.type === 'text' ? (
                <textarea aria-label={q.label} maxLength={1000} value={typeof answers[q.id] === 'string' ? (answers[q.id] as string) : ''} onChange={e => set(q.id, e.target.value)} />
              ) : (
                <div className="choice-list">
                  {q.options.map((o, i) => (
                    <label key={i} className="checkbox">
                      {q.type === 'multi' ? (
                        <input type="checkbox" checked={Array.isArray(answers[q.id]) && (answers[q.id] as number[]).includes(i)} onChange={() => toggle(q.id, i)} />
                      ) : (
                        <input type="radio" name={q.id} checked={answers[q.id] === i} onChange={() => set(q.id, i)} />
                      )}
                      {o}
                    </label>
                  ))}
                </div>
              )}
            </fieldset>
          ))}
          <div className="row">
            <button className="btn" type="submit" disabled={saving}>{answered ? '回答を更新する' : '回答する'}</button>
            {editing && <button className="btn btn--outline btn--sm" type="button" onClick={() => { setEditing(false); setAnswers(mine.data?.answers ?? {}); }}>キャンセル</button>}
          </div>
        </form>
      ) : (
        <div className="card">
          {answered ? (
            <>
              <p>回答済みです。ありがとうございました。</p>
              {canAnswer && <button className="btn btn--outline btn--sm" type="button" onClick={() => setEditing(true)}>回答を修正する</button>}
            </>
          ) : open ? (
            <p className="muted">{canWrite ? '団員登録が完了すると回答できます。' : '活動休止中は回答できません。'}</p>
          ) : (
            <p className="muted">このアンケートは締め切りました。</p>
          )}
        </div>
      )}
      {message && <p className={`alert ${message.ok ? 'alert--ok' : 'alert--error'}`} role="status">{message.text}</p>}

      {s.resultsPublished && s.results && (
        <section className="card">
          <h2 className="card__title">結果</h2>
          <SurveyResultsView questions={s.questions} results={s.results} />
        </section>
      )}
    </div>
  );
}
