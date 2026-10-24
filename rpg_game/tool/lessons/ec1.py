from common import B, C, L, Q

S = 'ec1'
SRC = '教科書 Lesson 5〜7 の範囲にそって、例文はすべて新しく書いたもの（教科書本文は写していない）'

LESSONS = [
L(S, 'english.eng.vocab.basic', '重要表現・熟語（Lesson 5〜7）',
  ['Lesson 5〜7 に出てくる重要熟語の意味を言える', '熟語を例文の中で正しく使い分けられる', '似た形の熟語（take care of / take advantage of など）を区別できる'],
  [
    B('intro', '熟語は「かたまり」で覚える', '''
英語の熟語は、1語ずつ訳すと意味が通らないことが多い。take care of は「取る・世話・の」ではなく「〜の世話をする」。
熟語は「かたまり」と「例文」で覚えると、長文の中でもすぐ意味が取れる。ここでは Lesson 5〜7 に出てくる表現を、テーマごとにまとめる。'''),
    B('explain', 'Lesson 5：自然と生き物', '''
・take care of ～：〜の世話をする　例 She takes care of her grandmother's cat.
・take advantage of ～：〜を利用する・生かす　例 Take advantage of this chance.
・have ～ in common：〜を共通にもつ　例 We have a lot in common.
・in danger of ～：〜の危険がある　例 The bird is in danger of extinction.
・to one's surprise：驚いたことに　例 To my surprise, he won.
・increase in number：数が増える　例 Deer have increased in number.
・consequence＝結果・影響、conservation＝保護・保全、thirsty＝のどがかわいた'''),
    C('「The rare frog is in danger of extinction.」の意味は？', 'その珍しいカエルは絶滅の危険がある', ['その珍しいカエルは絶滅した', 'その珍しいカエルを絶滅から守った', 'その珍しいカエルは危険な生き物だ'],
      'in danger of ～ は「〜の危険がある」。extinction は「絶滅」。',
      hint='in danger of の of の後ろには「起こりそうな悪いこと」が来る。',
      reteach='「in danger（危険の中に）＋ of（何の？）」＝「〜という危険の中にいる」。まだ起きていない点に注意。'),
    B('explain', 'Lesson 6：スマートフォンと情報', '''
・rely on ～：〜に頼る　例 Many people rely on their phones for news.
・pay attention to ～：〜に注意を払う　例 Pay attention to the signs.
・have an effect on ～：〜に影響を与える　例 Sleep has an effect on memory.
・no longer：もはや〜ない　例 He no longer lives here.
・for instance：例えば
・to make matters worse：さらに悪いことに
・It is estimated that ～：〜と推定されている
・It's about time to ～：そろそろ〜する時だ
・distract：（注意を）そらす　例 Music distracts me from studying.'''),
    B('explain', 'Lesson 7：旅と出会い', '''
・come across ～：〜に偶然出会う・見つける　例 I came across an old photo.
・as it turned out：結局のところ、結果的に
・carry on ～：〜を続ける
・as far as I'm concerned：私に関して言えば
・have an urge to ～：〜したい衝動にかられる
・remote / out-of-the-way：遠く離れた・人里離れた
・horizon：地平線・水平線、enrich：豊かにする、vast：広大な'''),
    B('example', '例題：形の似た熟語', '''
問：（　）に入る語を選べ。
(1) We should take (　) of this good weather and go hiking.
(2) Who will take (　) of the dog while you're away?
答え：(1) advantage（〜を利用する）　(2) care（〜の世話をする）
ポイント：take 〇〇 of の 〇〇 で意味が決まる。文全体の意味（天気を「利用する」／犬の「世話」）から判断する。'''),
    C('「I came across my old diary while cleaning my room.」の came across の意味は？', '偶然見つけた', ['横切った', '捨てた', '書き直した'],
      'come across ～ は「〜に偶然出会う・見つける」。',
      hint='部屋の片づけ中に、昔の日記を…？'),
    B('mistake', 'よくある間違い', '''
・no longer を「もっと長く」と訳す → 「もはや〜ない」。
・rely on と depend on は同じ意味（〜に頼る）だが、rely の後ろに on を忘れやすい。
・have an effect on の on を to にしてしまう。'''),
    B('summary', 'まとめ', '''
・L5：take care of / take advantage of / have ～ in common / in danger of / to one's surprise
・L6：rely on / pay attention to / have an effect on / no longer / for instance / to make matters worse
・L7：come across / as it turned out / carry on / as far as I'm concerned / have an urge to
・熟語は「かたまり＋例文」で覚え、形の似たものは文の意味で区別する。'''),
  ],
  [
    Q('「We have a lot in common.」の意味は？', '私たちには共通点がたくさんある', ['私たちはたくさんの物を共有している', '私たちはよく一緒にいる', '私たちはたくさん持ちすぎている'], 'have ～ in common＝〜を共通にもつ。'),
    Q('「〜に注意を払う」を表すのは？', 'pay attention to ～', ['take advantage of ～', 'rely on ～', 'come across ～'], 'attention（注意）を pay（払う）。'),
    Q('「He no longer plays the piano.」の意味は？', '彼はもうピアノを弾かない', ['彼はもっと長くピアノを弾く', '彼は長い間ピアノを弾いている', '彼はピアノを弾くのをやめなかった'], 'no longer＝もはや〜ない。'),
    Q('「To make matters worse, it began to rain.」の意味は？', 'さらに悪いことに、雨が降りはじめた', ['事態をよくするために、雨が降った', '雨のせいで物事が悪くなった', '雨が降って問題は解決した'], 'to make matters worse は文頭で「さらに悪いことに」。'),
    Q('「as it turned out」の意味は？', '結局のところ', ['向きを変えて', '最初から', 'それが消えると'], '結果的に分かったことを言うときに使う。'),
  ],
  kw=['take care of', 'take advantage of', 'have ～ in common', 'in danger of', 'rely on', 'pay attention to', 'have an effect on', 'no longer', 'come across', 'as it turned out'],
  reteach='''
熟語は、中心になる名詞や前置詞のイメージから考えると覚えやすい。
・take advantage（有利な点を取る）→ 利用する
・pay attention（注意を支払う）→ 注意を払う
・come across（横切って来る）→ ばったり出会う
意味が分からないときは、まず前後の文から「良い意味か悪い意味か」を決めると、選択肢をしぼれる。''',
  source=SRC),

L(S, 'english.eng.grammar.tense', '時制：過去完了と現在完了',
  ['過去完了 had＋過去分詞が使われる理由（基準になる過去の時点）を説明できる', '現在完了と過去完了、過去形を使い分けられる', '過去完了の3つの用法（完了・経験・継続）と大過去を見分けられる'],
  [
    B('intro', '「基準の時点」を見つける', '''
完了形は「ある時点までのつながり」を表す。現在完了は「今」まで、過去完了は「過去のある時点」まで。
過去完了を見たら、まず「どの過去の時点が基準になっているか」を探すのがコツ。'''),
    B('explain', '現在完了と過去形', '''
・現在完了 have＋過去分詞：過去のことが今とつながっている（完了・経験・継続）。
 I have lost my key.（なくして、今も見つかっていない）
・過去形：過去の一時点のこと。今とのつながりは言っていない。
 I lost my key yesterday.（昨日なくした。今どうかは不明）
・yesterday, last week, ～ago, When ～? など過去の時点をはっきり示す語があると、現在完了は使えない。'''),
    B('explain', '過去完了 had＋過去分詞', '''
過去のある時点（基準）より前のこと、または基準の時点までのつながりを表す。
・完了：When I arrived, the train had already left.（着いたときには、電車はもう出ていた）
・経験：I had never seen snow before I visited Hokkaido.
・継続：She had lived there for ten years when the town changed.
・大過去：過去の2つの出来事の順番をはっきりさせる。I lost the pen that my father had given me.（もらったのが先）
・期限：By 2020, the number had increased to 60%.（2020年という過去の時点までに増えていた）'''),
    C('「When we got to the theater, the movie (　) already started.」の（　）に入るのは？', 'had', ['has', 'have', 'was'],
      '基準は「劇場に着いた」という過去の時点。それより前に始まっていたので過去完了 had started。',
      hint='基準になる過去の時点（got to）より前の出来事。',
      reteach='時間の線を書いてみよう。「映画が始まる」→「私たちが着く」の順。後ろの出来事（過去）を基準に、前の出来事を had＋過去分詞で表す。'),
    B('example', '例題：なぜ過去完了？', '''
問：「By last year, the rate had increased to 50%.」で過去完了が使われているのはなぜか。
答え：「去年」という過去の時点までに起きた変化（増加）を表しているから。基準の時点が「今」ではなく「去年」なので、現在完了ではなく過去完了になる。
同じように「I decided to go there after I had read the books.」では、「行くと決めた」時点より前に本を読んでいたことを表す。'''),
    B('point', '見分け方の手順', '''
①文の中の「基準の時点」を探す（when ～, by ～, before ～, 過去形の動詞）。
②基準が「今」→ 現在完了、「過去のある時」→ 過去完了。
③過去の時点そのもの（yesterday など）を言うだけなら過去形。
④before / after で順番が明らかなときは、過去完了の代わりに過去形を使うこともある。'''),
    C('「I have visited Kyoto last year.」の誤りを直すと？', 'I visited Kyoto last year.', ['I had visited Kyoto last year.', 'I have visit Kyoto last year.', 'I visit Kyoto last year.'],
      'last year（過去の一時点）があるので現在完了は使えない。過去形にする。',
      hint='last year は「今」とつながる表現？'),
    B('mistake', 'よくある間違い', '''
・過去完了を「すごく昔のこと」と思う → 時間の長さではなく「基準の過去より前」かどうか。
・現在完了に yesterday, ～ago をつける。
・By 2018 のような「過去の時点までに」を現在完了で書く。'''),
    B('summary', 'まとめ', '''
・現在完了：今が基準。過去形：過去の一時点（今とのつながりは言わない）。
・過去完了 had＋過去分詞：過去の基準の時点より前／その時点まで（完了・経験・継続・大過去）。
・まず「基準の時点」を探す。'''),
  ],
  [
    Q('「She (　) the book before she saw the movie.」に最も適するのは？', 'had read', ['has read', 'reads', 'have read'], '映画を見た（過去）より前に読んでいた。'),
    Q('現在完了と一緒に使えない語句は？', 'two days ago', ['already', 'since 2020', 'for three years'], '〜ago は過去の一時点。'),
    Q('「By the time he came back, his family had moved.」の意味は？', '彼が戻ったときには、家族は引っ越してしまっていた', ['彼が戻ってから、家族は引っ越した', '彼が戻るまで、家族は引っ越さなかった', '彼は家族と一緒に引っ越した'], '戻った時点より前に引っ越しが完了していた。'),
    Q('「I had never seen the sea until I was ten.」の過去完了の用法は？', '経験', ['完了', '継続', '受け身'], '10歳の時点までに一度も見たことがなかった（経験）。'),
    Q('過去完了が使われるときに必ず必要なのは？', '基準になる過去の時点', ['未来の時点', '現在の時点だけ', '受動態'], 'それより前のことを表すので、基準の過去が文や文脈にある。'),
  ],
  kw=['現在完了', '過去完了', 'had＋過去分詞', '基準の時点', '大過去', '完了・経験・継続'],
  reteach='''
完了形は「矢印の先の時点」が大事。現在完了は矢印の先が「今」、過去完了は矢印の先が「過去のある時点」。
「〜した（その時点では）もう…してしまっていた」と日本語で言いたくなったら過去完了、と覚えるとよい。''',
  source=SRC),

L(S, 'english.eng.grammar.conj', '接続詞と節（not only A but also B・as・once・even if）',
  ['相関的な接続詞 not only A but also B を正しく訳し、使える', 'as・once・even if など、意味の多い接続詞を文脈で訳し分けられる', '主節と従属節の関係をつかんで文を読める'],
  [
    B('intro', '接続詞は「文と文の関係」を示す', '''
接続詞は、2つの文（節）がどんな関係か――理由・時・条件・譲歩・追加――を示す道しるべ。長文では、接続詞を見るだけで、次にどんな内容が来るか予想できる。'''),
    B('explain', 'not only A but also B', '''
「AだけでなくBも」。強調したいのはB。
・Not only students but also teachers enjoyed the event.（生徒だけでなく先生も楽しんだ）
・主語になるとき、動詞はBに合わせる：Not only you but also he is wrong.
・B as well as A も同じ意味（Bを強調）：He as well as you is wrong.'''),
    B('explain', 'as・once・even if', '''
・as の主な意味：〜するとき／〜するにつれて／〜なので／〜のように
 As the days get longer, people feel spring coming.（日が長くなるにつれて）
 As it was raining, we stayed home.（雨だったので）
 Do as I say.（私の言うように）
・once：「いったん〜すると」　Once you start, you can't stop.
・even if：「たとえ〜でも」（仮定）　Even if it rains, we will go.
 even though：「〜だけれども」（事実）　Even though it was raining, we went.'''),
    C('「As he grew older, he became wiser.」の As の意味は？', '〜するにつれて', ['〜なので', '〜のように', '〜だけれども'],
      '「年をとる」と「賢くなる」が一緒に変化しているので「〜につれて」。',
      hint='比較級（older, wiser）が2つあるとき、as はどの意味になりやすい？',
      reteach='as は「＝（同時に・同じように）」がもとのイメージ。2つの変化が同時に進むなら「〜につれて」、理由なら「〜なので」と、文の中身で決める。'),
    B('example', '例題：訳し分け', '''
問：次の文の意味を答えよ。
(1) Once you learn to ride a bike, you never forget.
(2) Even if all the trees disappear, the forest will come back.
答え：(1) いったん自転車に乗れるようになると、決して忘れない。(2) たとえ木がすべてなくなっても、森はもどってくるだろう。
ポイント：once は文頭で「いったん〜すると」（副詞の「一度・かつて」と区別）。even if は「たとえ（そうなったとしても）」という仮定。'''),
    C('「Not only Ken but also his sisters (　) good at swimming.」の（　）に入るのは？', 'are', ['is', 'am', 'be'],
      'not only A but also B が主語のとき、動詞はBに合わせる。his sisters は複数なので are。',
      hint='動詞は A と B のどちらに合わせる？'),
    B('mistake', 'よくある間違い', '''
・not only A but also B で、動詞をAに合わせる。
・even if と even though の混同（仮定か事実か）。
・as をいつも「〜として」と訳す（前置詞の as と接続詞の as の区別）。'''),
    B('summary', 'まとめ', '''
・not only A but also B＝B as well as A（Bを強調、動詞はBに合わせる）。
・as：時・につれて・理由・様態。once：いったん〜すると。even if：たとえ〜でも（仮定）。even though：〜だけれども（事実）。
・接続詞は文と文の関係を示す道しるべ。'''),
  ],
  [
    Q('「Even if you are tired, you should finish your homework.」の意味は？', 'たとえ疲れていても、宿題を終えるべきだ', ['疲れているので、宿題を終えるべきだ', '疲れていたら、宿題はしなくてよい', '疲れているが、宿題は終わった'], 'even if＝たとえ〜でも。'),
    Q('「B as well as A」と同じ意味を表すのは？', 'not only A but also B', ['either A or B', 'neither A nor B', 'both A and B'], 'どちらも「AだけでなくBも」。'),
    Q('「As it was late, we took a taxi.」の As の意味は？', '〜なので', ['〜につれて', '〜のように', '〜として'], '遅かったので（理由）。'),
    Q('「Once you open the box, you cannot close it again.」の Once の意味は？', 'いったん〜すると', ['かつて', '1回だけ', '〜するとすぐに必ず'], '接続詞の once。'),
    Q('事実を表し「〜だけれども」を意味するのは？', 'even though', ['even if', 'as if', 'as long as'], 'even if は仮定。'),
  ],
  kw=['not only A but also B', 'B as well as A', 'as', 'once', 'even if', 'even though', '従属節'],
  reteach='''
接続詞は「交通標識」。as は「同時に・同じように」の標識で、場面によって「につれて・ので・ように」に変わる。even if は「もしそうなっても大丈夫」という仮の話、even though は「実際そうだけど」という本当の話。
not only A but also B は「Aは当然、Bまでも！」とBに驚きのアクセントがあると考える。''',
  source=SRC),

L(S, 'english.eng.grammar.pronoun', '代名詞・形式主語 it と使役の構文',
  ['再帰代名詞（oneself）を使った表現を訳せる', '形式主語 it（It is ～ that…, It is estimated that…）を読める', 'make / let / have＋O＋原形不定詞の意味を区別できる'],
  [
    B('intro', '「代わり」と「させる」', '''
代名詞は名詞の代わりをする語。とくに再帰代名詞（myself, ourselves など）と、文の頭で「仮の主語」になる it は、長文でよく出る。
あわせて、「人に〜させる」を表す使役の構文も、Lesson で使われている表現として確認する。'''),
    B('explain', '再帰代名詞', '''
主語と目的語が同じ人のとき、目的語に -self / -selves を使う。
・enjoy oneself：楽しむ　We enjoyed ourselves at the party.
・amuse oneself：楽しむ・気をまぎらす　The kids amused themselves with games.
・help oneself to ～：〜を自由に取って食べる
・by oneself：ひとりで、for oneself：自分のために・自分で
・強調：I did it myself.（自分で）'''),
    B('explain', '形式主語 it', '''
長い主語を後ろに回し、文頭に仮の主語 it を置く。
・It is important to sleep well.（よく眠ることは大切だ）
・It is estimated that 30% of people use the app.（〜と推定されている）
・It seems that ～：〜のようだ　It seemed that every day was new.
it 自体は「それ」と訳さない。後ろの to ～ / that ～ が本当の主語。'''),
    C('「It is said that the castle was built 400 years ago.」の意味は？', 'その城は400年前に建てられたと言われている', ['それは400年前に建てられた城だと言った', 'その城が建てられたことは言われていない', 'それは400年前に言われた城だ'],
      'It is said that ～＝〜と言われている。it は that 以下を指す形式主語なので「それは」と訳さない。',
      hint='it を「それ」と訳さず、that の後ろを主語として読む。',
      reteach='「It is ＋過去分詞（said / estimated / believed）＋ that ～」は「〜と言われて／推定されて／信じられている」というかたまり。'),
    B('explain', '使役の構文：make / let / have＋O＋原形', '''
・make＋O＋原形：（強制的に）Oに〜させる　The teacher made us rewrite the report.
・let＋O＋原形：（許可して）Oに〜させてやる　My parents let me stay up late.
・have＋O＋原形：（頼んで・役目として）Oに〜してもらう　I had the mechanic check my bike.
・get＋O＋to不定詞：（説得して）Oに〜させる　I got him to help me.
受け身にすると make の原形は to不定詞になる：We were made to rewrite it.'''),
    B('example', '例題：使役の訳し分け', '''
問：意味のちがいを説明せよ。
(1) He made his son clean the room.　(2) He let his son use the car.
答え：(1) 息子に部屋をそうじさせた（息子がいやでもさせた・強制）。(2) 息子に車を使わせてやった（息子がしたいことを許した・許可）。
ポイント：Smartphones have made us do many things differently. のように、主語が「物」でも make＋O＋原形は使える（スマホが私たちに多くのことをちがうやり方でさせるようにした）。'''),
    C('「My mother let me go to the concert.」の意味は？', '母は私がコンサートに行くのを許してくれた', ['母は私を無理やりコンサートに行かせた', '母は私をコンサートに連れて行かなかった', '母はコンサートに行かせてもらった'],
      'let＋O＋原形は「（許可して）〜させてやる」。',
      hint='make は強制、let は…？'),
    B('mistake', 'よくある間違い', '''
・make / let / have の後ろに to をつける（原形不定詞なので to は不要。ただし get は to が必要）。
・形式主語の it を「それ」と訳す。
・再帰代名詞を使う動詞で目的語を忘れる（We enjoyed. ではなく We enjoyed ourselves.）。'''),
    B('summary', 'まとめ', '''
・再帰代名詞：enjoy / amuse oneself、by oneself、for oneself。
・形式主語 it：It is ～ to… / It is said（estimated）that… / It seems that…。
・使役：make（強制）・let（許可）・have（依頼）＋O＋原形、get＋O＋to不定詞。'''),
  ],
  [
    Q('「The movie made me cry.」の意味は？', 'その映画を見て私は泣いてしまった', ['その映画は私を泣かせないようにした', '私は泣いて映画を作った', '私はその映画で泣く役をした'], 'make＋O＋原形。物が主語のときは「〜のせいで…した」と訳すと自然。'),
    Q('「Please help yourself to the cookies.」の意味は？', 'クッキーを自由に取って食べてください', ['クッキー作りを手伝ってください', 'クッキーを自分で作ってください', 'クッキーを持って帰ってください'], 'help oneself to ～＝〜を自由に取って食べる。'),
    Q('「I (　) my hair cut yesterday.」に入る、「切ってもらった」を表す動詞は？', 'had', ['made', 'let', 'got to'], 'have＋O＋過去分詞で「Oを〜してもらう」。'),
    Q('「It is estimated that ～」の意味は？', '〜と推定されている', ['それは〜と見積もった', '〜は確実である', '〜は禁止されている'], '形式主語 it と that 節。'),
    Q('使役動詞の後ろに to不定詞をとるものは？', 'get', ['make', 'let', 'have'], 'get＋O＋to不定詞。make / let / have は原形。'),
  ],
  kw=['再帰代名詞', 'enjoy oneself', 'amuse oneself', '形式主語 it', 'It is said that', 'It is estimated that', 'make＋O＋原形', 'let＋O＋原形', 'have＋O＋原形', 'get＋O＋to不定詞'],
  reteach='''
使役は「させ方の強さ」で並べると覚えやすい：make（むりやり）＞ get（説得して）＞ have（頼んで・仕事として）＞ let（したいならどうぞ）。
形式主語 it は「ここに長い主語が入りますよ」という予約席。席に座る本当の主語は、後ろの to ～ や that ～。''',
  source=SRC),

L(S, 'english.eng.reading.passage', '長文読解の進め方（内容一致・細部の読み取り）',
  ['段落ごとの要点（トピック・センテンス）をつかめる', 'ディスコースマーカー（however, for instance など）で文章の流れを読める', '内容一致問題で、本文の根拠を示して選択肢を判断できる'],
  [
    B('intro', '長文は「全部を訳す」のではなく「流れをつかむ」', '''
定期テストの長文問題では、教科書本文の内容一致や、細部の読み取りが問われる。すべてを日本語に訳そうとすると時間が足りない。
大切なのは、①段落ごとの言いたいことをつかむ、②話の流れを示す言葉に印をつける、③設問の根拠を本文で探す、の3つ。'''),
    B('explain', 'トピック・センテンスと段落', '''
英語の段落は、多くの場合「最初の文（トピック・センテンス）で言いたいことを言い、そのあとに具体例や理由が続く」形になっている。
読むときは、各段落の1文目に線を引き、段落の内容を日本語で一言メモしておくと、全体の流れが見える。
Lesson 5（生き物と自然のつながり）、Lesson 6（スマートフォンと私たちの生活）、Lesson 7（アラスカでの体験）でも、まず段落ごとの話題を整理しておこう。'''),
    B('explain', 'ディスコースマーカー', '''
話の流れを示す言葉に印をつける。
・逆接：however, but, though（このあとに筆者の本当の主張が来やすい）
・例示：for instance, for example, such as
・追加：also, in addition, moreover, not only ～ but also
・結果：so, therefore, as a result
・時の流れ：first, then, later, finally, as the days get longer
・さらに悪いことに：to make matters worse
・結論：in short, in conclusion'''),
    C('長文で、筆者の主張が来やすいのはどの語のあと？', 'however', ['for instance', 'first', 'also'],
      '逆接のあとは、それまでの一般論を否定して、筆者が本当に言いたいことが来ることが多い。',
      hint='「しかし」のあとには何が来やすい？',
      reteach='「みんなは〜と思っている。しかし（however）、実は…」という形が多い。「しかし」の後ろが主役。'),
    B('example', '例題：内容一致の解き方', '''
手順：
①設問の選択肢を先に読み、キーワード（固有名詞・数字・特徴的な語）に印をつける。
②本文でそのキーワードが出てくる場所を探す。
③その前後を丁寧に読み、選択肢と比べる。
よくあるひっかけ：
・本文の語句をそのまま使っているが、主語や時制が入れかわっている。
・always / never / all など、本文より言い過ぎている。
・本文に書かれていないこと（常識的には正しいこと）を言っている。
例：本文が「アラスカにも、はっきりした季節の変化がある」なら、選択肢「アラスカはいつも冬だ」は本文と反対なので×。'''),
    C('内容一致問題で、本文に always と書かれていないのに選択肢に always があるとき、まず疑うべきことは？', '本文より言い過ぎている（誤りの可能性が高い）', ['必ず正解', '本文の要約なので正しい', '関係ない'],
      '「いつも」「すべて」「決して」は、本文より範囲を広げた「言い過ぎ」のひっかけになりやすい。',
      hint='本文の程度と選択肢の程度を比べてみよう。'),
    B('mistake', 'よくある間違い', '''
・自分の常識や知識で選択肢を選ぶ（本文に根拠があるかで判断する）。
・本文と同じ単語がある選択肢をすぐ正解にする。
・1文ずつ訳すのに時間を使い、段落の要点をつかんでいない。'''),
    B('summary', 'まとめ', '''
・段落の1文目（トピック・センテンス）で要点をつかみ、一言メモ。
・ディスコースマーカー（however / for instance / as a result など）に印。
・内容一致は「選択肢のキーワード → 本文の場所 → 前後を比べる」。言い過ぎ・入れかえ・書かれていないことに注意。'''),
  ],
  [
    Q('英語の段落で、要点が最も書かれやすい場所は？', '段落の最初の文', ['段落の真ん中の文', '具体例の部分', '固有名詞が出てくる文'], 'トピック・センテンスはふつう段落の最初に来る。'),
    Q('「for instance」のあとに来るのは？', '具体例', ['反対の意見', '結論', '時間の流れ'], 'for instance＝例えば。'),
    Q('内容一致問題で正しい判断の根拠になるのは？', '本文に書かれている内容', ['一般的な常識', '自分の経験', '選択肢の長さ'], '本文に根拠があるかどうかで判断する。'),
    Q('「as a result」が示す文と文の関係は？', '結果', ['逆接', '例示', '追加'], '「その結果」。'),
    Q('選択肢が本文と同じ単語を使っているときに気をつけることは？', '主語や時制などが入れかわっていないか確かめる', ['必ず正解なので選ぶ', '必ずまちがいなので選ばない', '単語の数を数える'], '同じ単語を使ったひっかけが多い。'),
  ],
  kw=['トピック・センテンス', 'ディスコースマーカー', 'however', 'for instance', 'as a result', '内容一致', '言い過ぎの選択肢'],
  reteach='''
長文は「地図を作ってから歩く」。最初に各段落の1文目だけを読んで、どんな順番で話が進むか（地図）を作る。そのあと設問のキーワードを持って、地図のどこに答えがありそうか見当をつけてから、その場所を細かく読む。
全部を最初から丁寧に訳すより、ずっと速く正確になる。''',
  source=SRC),
]
