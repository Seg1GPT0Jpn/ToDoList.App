"""ECⅠ（後期中間）：Lesson 5〜7 で使われる文法（時制・接続詞・代名詞）の委員会セットを作る。

  cd rpg_game/tool/shonan_questions && python3 ec1_grammar_gen.py

例文はすべてここで新しく書いたもの（教科書本文は写していない）。
"""
import json
import os
import random

QDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'questions', 'english')
K, T = 'knowledge', 'thinking'
PERF = 'english.eng.grammar.tense.perfect'
SIMPLE = 'english.eng.grammar.tense.simple'
COORD = 'english.eng.grammar.conj.coordinate'
SUB = 'english.eng.grammar.conj.subordinate'
PRON = 'english.eng.grammar.pronoun.pronoun'


def items():
    it = []
    a = lambda *x: it.append(x)
    # 時制（過去完了・現在完了）
    a(PERF, T, 'When I got to the station, the train ( ) already left.', 'had', ['has', 'have', 'was'], '「駅に着いた」という過去の時点より前に出発していたので過去完了 had left。')
    a(PERF, T, 'She ( ) in Osaka for five years before she moved to Tokyo.', 'had lived', ['has lived', 'lives', 'is living'], '東京に引っ越した（過去）時点までの継続なので過去完了。')
    a(PERF, T, 'I ( ) never seen such a beautiful sunset until I visited the island.', 'had', ['have', 'was', 'did'], '島を訪れた（過去）時点までの経験なので過去完了 had seen。')
    a(PERF, T, 'By last year, the number of visitors ( ) to two million.', 'had increased', ['has increased', 'increases', 'will increase'], '「去年までに」という過去の時点までの変化なので過去完了。')
    a(PERF, T, 'I ( ) my homework yet, so I can’t go out now.', 'haven’t finished', ['hadn’t finished', 'didn’t finish', 'don’t finish'], '「今」の時点でまだ終わっていない（現在完了）。')
    a(PERF, T, 'I lost the watch that my grandfather ( ) me.', 'had given', ['has given', 'gives', 'is giving'], 'もらった（先）→なくした（後）。先の出来事を過去完了で表す（大過去）。')
    a(SIMPLE, T, 'I ( ) Kyoto two years ago.', 'visited', ['have visited', 'had visited', 'have been visiting'], '〜ago は過去の一時点を表すので過去形。現在完了は使えない。')
    a(SIMPLE, T, 'When ( ) you buy that bike?', 'did', ['have', 'had', 'do'], 'When で過去の時点をたずねるときは過去形（When have you ～? とは言わない）。')
    a(PERF, K, '過去完了 had＋過去分詞 を使うのに必要なものは？', '基準になる過去の時点', ['未来の時点', '受動態', '助動詞'], 'その時点より前、またはその時点までのことを表す。')
    a(PERF, T, '「The concert had already started when we arrived.」の意味は？', '私たちが着いたときには、コンサートはもう始まっていた', ['私たちが着いてから、コンサートが始まった', '私たちが着く前に、コンサートは終わった', 'コンサートが始まったので、私たちは着いた'], '着いた時点で「始まる」は完了していた。')
    # 接続詞
    a(COORD, T, 'Not only Mika but also her brothers ( ) interested in birds.', 'are', ['is', 'am', 'be'], 'not only A but also B では、動詞は B（her brothers：複数）に合わせる。')
    a(COORD, T, '「He speaks not only English but also Chinese.」の意味は？', '彼は英語だけでなく中国語も話す', ['彼は英語ではなく中国語を話す', '彼は英語も中国語も話さない', '彼は英語より中国語を多く話す'], 'not only A but also B＝AだけでなくBも。')
    a(COORD, K, '「not only A but also B」とほぼ同じ意味を表すのは？', 'B as well as A', ['either A or B', 'neither A nor B', 'A rather than B'], 'どちらもBに重点がある。')
    a(SUB, T, '「As we went up the mountain, the air became colder.」の As の意味は？', '〜するにつれて', ['〜なので', '〜のように', '〜として'], '登ることと寒くなることが同時に進んでいる。')
    a(SUB, T, '「As it was raining, the game was put off.」の As の意味は？', '〜なので', ['〜するにつれて', '〜のように', '〜だけれども'], '雨が降っていたので（理由）延期された。')
    a(SUB, T, '「Once you get used to it, it will be easy.」の意味は？', 'いったん慣れてしまえば、簡単になるだろう', ['一度だけ慣れれば、簡単だった', 'かつて慣れたので、簡単だ', '慣れるとすぐに難しくなる'], '接続詞 once＝いったん〜すると。')
    a(SUB, T, '「Even if you fail, you will learn something.」の意味は？', 'たとえ失敗しても、何かを学ぶだろう', ['失敗したので、何かを学んだ', '失敗しなければ、何も学ばない', '失敗するまで、学び続ける'], 'even if＝たとえ〜でも（仮定）。')
    a(SUB, K, '「〜だけれども（実際にそうである）」という事実を表すのは？', 'even though', ['even if', 'as if', 'unless'], 'even if は仮定、even though は事実。')
    a(SUB, T, '( ) far as I know, she has never been late.', 'As', ['So', 'Even', 'Once'], 'as far as I know＝私の知る限り。')
    # 代名詞・形式主語
    a(PRON, T, 'We enjoyed ( ) very much at the festival.', 'ourselves', ['us', 'our', 'we'], 'enjoy oneself＝楽しむ。主語 We に合わせて ourselves。')
    a(PRON, T, '「Please help yourself to the cake.」の意味は？', 'ケーキを自由に取って食べてください', ['ケーキ作りを手伝ってください', 'ケーキを自分で作ってください', 'ケーキを持ち帰ってください'], 'help oneself to ～＝〜を自由に取って食べる。')
    a(PRON, T, 'The children amused ( ) by playing cards.', 'themselves', ['them', 'their', 'they'], 'amuse oneself＝楽しむ・気をまぎらす。')
    a(PRON, T, '「It is said that the tree is 500 years old.」の It は？', 'that 以下を指す形式主語', ['前に出た木を指す代名詞', '天気を表す it', '時間を表す it'], 'It is said that ～＝〜と言われている。it は「それ」と訳さない。')
    a(PRON, T, '「It is important to get enough sleep.」の本当の主語は？', 'to get enough sleep', ['It', 'important', 'enough sleep だけ'], 'It は形式主語で、to 不定詞が本当の主語。')
    a(PRON, T, '「It seems that she knows the answer.」の意味は？', '彼女は答えを知っているようだ', ['それは彼女が答えを知っていると見える', '彼女は答えを知らないようだ', '彼女は答えを見つけた'], 'It seems that ～＝〜のようだ。')
    a(PRON, T, 'I made the decision by ( ).', 'myself', ['me', 'my', 'mine'], 'by oneself＝ひとりで、自分で。')
    return it


def main():
    rng = random.Random(31)
    sid = 'english_shonan_104_ec1_grammar_01'
    qs = []
    seen = set()
    for unit, cat, prompt, ans, wrong, exp in items():
        assert prompt not in seen, prompt
        seen.add(prompt)
        ch = [ans, *wrong]
        assert len(set(ch)) == 4, prompt
        rng.shuffle(ch)
        qs.append({'id': f'{sid}_{len(qs) + 1:03d}', 'unit': unit, 'unitLocked': True, 'category': 'usage' if cat == T else cat,
                   'prompt': prompt, 'choices': ch, 'answerIndex': ch.index(ans), 'explanation': exp,
                   'targetGrade': '1', 'phase': 'teikiTest', 'tags': ['shonan-hs-104', 'kouki-chukan', 'ec1', 'grammar']})
    with open(os.path.join(QDIR, sid + '.json'), 'w', encoding='utf-8') as f:
        json.dump({'setId': sid, 'worldId': 'english', 'origin': 'original', 'version': 1, 'questions': qs}, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(sid, len(qs))


if __name__ == '__main__':
    main()
