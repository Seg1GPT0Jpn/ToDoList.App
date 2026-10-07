import type { SurveyQuestion, SurveyResults } from '../lib/types';

/** 選択式の集計を横棒で表示する */
export function SurveyResultsView({ questions, results }: { questions: SurveyQuestion[]; results: SurveyResults }) {
  return (
    <div className="stack">
      <p className="small muted">回答者 {results.respondents} 人</p>
      {questions.filter(q => q.type !== 'text').map(q => {
        const counts = results.counts[q.id] ?? [];
        const max = Math.max(1, ...counts);
        return (
          <div key={q.id}>
            <p className="list__title">{q.label}{q.type === 'multi' && <span className="small muted">（複数選択）</span>}</p>
            <ul className="result-bars">
              {q.options.map((o, i) => (
                <li key={i}>
                  <span className="result-bars__label">{o}</span>
                  <span className="result-bars__track" aria-hidden="true">
                    <span className="result-bars__bar" style={{ width: `${((counts[i] ?? 0) / max) * 100}%` }} />
                  </span>
                  <span className="result-bars__count">{counts[i] ?? 0}</span>
                </li>
              ))}
            </ul>
          </div>
        );
      })}
    </div>
  );
}
