import type { Survey, SurveyAnswers, SurveyQuestion, SurveyResponse, SurveyResults } from './types';

/** 回答受付中か（締切は端末の時計で目安表示。最終的な判定は Firestore ルール） */
export function isSurveyOpen(s: Pick<Survey, 'published' | 'closed' | 'deadline'>, now: Date = new Date()): boolean {
  if (!s.published || s.closed) return false;
  if (s.deadline && s.deadline.toMillis() < now.getTime()) return false;
  return true;
}

/** 未回答の必須質問（質問文の一覧）。空なら送信できる */
export function missingRequired(questions: SurveyQuestion[], answers: SurveyAnswers): string[] {
  return questions
    .filter(q => q.required)
    .filter(q => {
      const a = answers[q.id];
      if (q.type === 'text') return typeof a !== 'string' || !a.trim();
      if (q.type === 'multi') return !Array.isArray(a) || a.length === 0;
      return typeof a !== 'number';
    })
    .map(q => q.label || '（無題の質問）');
}

/** 保存する形に整える（範囲外の選択肢・長すぎる文章・存在しない質問を取り除く） */
export function cleanAnswers(questions: SurveyQuestion[], answers: SurveyAnswers): SurveyAnswers {
  const out: SurveyAnswers = {};
  for (const q of questions) {
    const a = answers[q.id];
    if (q.type === 'text') {
      if (typeof a === 'string' && a.trim()) out[q.id] = a.slice(0, 1000);
    } else if (q.type === 'multi') {
      if (Array.isArray(a)) {
        const v = [...new Set(a)].filter(i => Number.isInteger(i) && i >= 0 && i < q.options.length).sort((x, y) => x - y);
        if (v.length) out[q.id] = v;
      }
    } else if (typeof a === 'number' && Number.isInteger(a) && a >= 0 && a < q.options.length) {
      out[q.id] = a;
    }
  }
  return out;
}

/** 選択式の質問を集計する（自由記述は数えない） */
export function aggregate(questions: SurveyQuestion[], responses: SurveyResponse[]): SurveyResults {
  const counts: Record<string, number[]> = {};
  for (const q of questions) {
    if (q.type === 'text') continue;
    counts[q.id] = q.options.map(() => 0);
  }
  for (const r of responses) {
    for (const q of questions) {
      const a = r.answers[q.id];
      const list = counts[q.id];
      if (!list) continue;
      const picks = q.type === 'multi' ? (Array.isArray(a) ? a : []) : typeof a === 'number' ? [a] : [];
      for (const i of new Set(picks)) {
        if (Number.isInteger(i) && i >= 0 && i < list.length) list[i]++;
      }
    }
  }
  return { respondents: responses.length, counts };
}

/** 自由記述の回答（名前は付けない。回答順から人が推測できないよう五十音順で返す） */
export function textAnswers(question: SurveyQuestion, responses: SurveyResponse[]): string[] {
  const list = responses
    .map(r => r.answers[question.id])
    .filter((a): a is string => typeof a === 'string' && a.trim() !== '');
  return list.sort((a, b) => a.localeCompare(b, 'ja'));
}

export function newQuestionId(existing: SurveyQuestion[]): string {
  let n = existing.length + 1;
  const ids = new Set(existing.map(q => q.id));
  while (ids.has(`q${n}`)) n++;
  return `q${n}`;
}
