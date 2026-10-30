"""異界の港町：小3・4（外国語活動）〜中3。"""
import random

from lib import Q

B = '(   )'


def vocab(pairs, n, seed, ja_to_en=False, cat='m'):
    """単語表 [(英語, 日本語)] から、意味の4択を n 問作る（まちがいは同じ表から）。"""
    r = random.Random(seed)
    items = pairs[:]
    r.shuffle(items)
    out = []
    for en, ja in items[:n]:
        others = [p for p in pairs if p[0] != en and p[1] != ja]
        r.shuffle(others)
        if ja_to_en:
            out.append(Q(cat, f'「{ja}」を英語で言うと？', en, [o[0] for o in others[:3]],
                         f'{ja} ＝ {en}'))
        else:
            out.append(Q(cat, f'「{en}」の意味は？', ja, [o[1] for o in others[:3]],
                         f'{en} ＝ {ja}'))
    return out


def U(p, s, a, w, e):
    """文法（語法）の問題。s に (   ) をふくむ英文。"""
    return Q('u', p, a, w, e, s=s)


def F(s, a, w, e):
    return U(f'{B} に入るのは？', s, a, w, e)


def build(W):
    e34(W.route('e34', '小3・4', 'left', grade='小3-4', desc='アルファベット・あいさつ・数・色・好きなもの'))
    e5(W.route('e5', '小5', 'down', desc='自己紹介・誕生日・できること・道案内・注文'))
    e6(W.route('e6', '小6', 'down', desc='過去のこと・夏休み・将来の夢・町しょうかい・中学校'))
    j1(W.route('j1', '中1', 'up', desc='be動詞・一般動詞・3単現・疑問詞・進行形・can・過去形'))
    j2(W.route('j2', '中2', 'up', desc='未来・助動詞・不定詞・動名詞・接続詞・比較・受け身'))
    j3(W.route('j3', '中3', 'up', desc='現在完了・不定詞の発展・分詞・関係代名詞・間接疑問・仮定法'))


# ------------------------------------------------------------------ 小3・4
def e34(R):
    S1 = 'ABCと あいさつ'
    S2 = 'すきなもの'
    letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    qs = []
    for i, c in enumerate('ADEHMRTN'):
        others = [x for x in 'abdeghmnpqrty' if x != c.lower()]
        r = random.Random(3400 + i)
        r.shuffle(others)
        qs.append(Q('k', f'「{c}」の小文字は？', c.lower(), others[:3], f'{c} の小文字は {c.lower()}。'))
    qs += [
        Q('k', 'アルファベットで「C」の次は？', 'D', ['B', 'E', 'G'], 'A B C D E…'),
        Q('k', 'アルファベットは全部で何文字？', '26文字', ['24文字', '20文字', '30文字'], 'A から Z まで26文字。'),
        Q('k', '小文字の「b」とまちがえやすい文字は？', 'd', ['a', 'k', 'o'], 'b と d は向きが反対。'),
        Q('k', 'アルファベットで「Y」の次は？', 'Z', ['X', 'W', 'A'], '最後は Z。'),
    ]
    R.area('アルファベット', S1, qs, lesson=[
        ('大文字と小文字', 'アルファベットは26文字。大文字と小文字がある。', 'A a / B b / C c'),
        ('まちがえやすい文字', 'b と d、p と q は向きに注意。', 'bed（ベッド）'),
    ])

    R.area('あいさつと 気もち', S1, [
        Q('m', '朝のあいさつ「おはよう」は英語で？', 'Good morning.', ['Good night.', 'Goodbye.', 'Thank you.'], '朝は Good morning.'),
        Q('m', '「ありがとう」は英語で？', 'Thank you.', ['Sorry.', 'Hello.', 'See you.'], 'Thank you. ＝ ありがとう'),
        Q('m', '「さようなら」は英語で？', 'Goodbye.', ['Hello.', 'Good morning.', 'Yes.'], 'Goodbye. / See you.'),
        Q('m', '「How are you?」の意味は？', '元気ですか？', ['あなたはだれ？', '何さいですか？', 'どこに行くの？'], 'How are you? ＝ 元気？'),
        Q('m', '「I\'m happy.」の意味は？', 'わたしはうれしい。', ['わたしはねむい。', 'わたしはおなかがすいた。', 'わたしはかなしい。'], 'happy ＝ うれしい・しあわせ'),
        Q('m', '「I\'m hungry.」の意味は？', 'おなかがすいた。', ['のどがかわいた。', 'つかれた。', 'さむい。'], 'hungry ＝ おなかがすいた'),
        Q('m', '「sleepy」の意味は？', 'ねむい', ['さむい', 'あつい', 'かなしい'], 'sleepy ＝ ねむい'),
        Q('m', '「sad」の意味は？', 'かなしい', ['うれしい', 'げんき', 'ねむい'], 'sad ＝ かなしい'),
        Q('m', '「Nice to meet you.」の意味は？', 'はじめまして。', ['また明日。', 'おやすみ。', 'ごめんなさい。'], '初めて会ったときのあいさつ。'),
        Q('m', '夜ねる前のあいさつは？', 'Good night.', ['Good morning.', 'Good afternoon.', 'Nice to meet you.'], 'Good night. ＝ おやすみ'),
        Q('u', '「How are you?」への答えとして合うのは？', 'I\'m fine.', ['I\'m ten.', 'I\'m Ken.', 'I like apples.'], '気分を答える。'),
        Q('m', '「Sorry.」の意味は？', 'ごめんなさい。', ['ありがとう。', 'こんにちは。', 'すごい！'], 'Sorry. ＝ ごめんなさい'),
    ])

    nums = [('one', '1'), ('two', '2'), ('three', '3'), ('four', '4'), ('five', '5'), ('six', '6'), ('seven', '7'),
            ('eight', '8'), ('nine', '9'), ('ten', '10'), ('eleven', '11'), ('twelve', '12'), ('fifteen', '15'), ('twenty', '20')]
    R.area('数（1〜20）', S1, vocab(nums, 8, 3401) + [
        Q('c', 'three + four ＝ ?', 'seven', ['six', 'eight', 'five'], '3 + 4 = 7'),
        Q('c', 'ten − two ＝ ?', 'eight', ['nine', 'six', 'twelve'], '10 − 2 = 8'),
        Q('m', '「How many apples?」の意味は？', 'りんごはいくつ？', ['りんごはすき？', 'りんごは何色？', 'りんごはどこ？'], 'How many ～? ＝ いくつ？'),
        Q('c', 'five + five ＝ ?', 'ten', ['nine', 'eleven', 'fifteen'], '5 + 5 = 10'),
    ])

    colors = [('red', '赤'), ('blue', '青'), ('yellow', '黄色'), ('green', '緑'), ('white', '白'), ('black', '黒'),
              ('pink', 'ピンク'), ('orange', 'オレンジ色'), ('purple', 'むらさき'), ('brown', '茶色')]
    shapes = [('circle', 'まる'), ('square', '四角'), ('triangle', '三角'), ('star', '星'), ('heart', 'ハート')]
    R.area('色と形', S1, vocab(colors, 7, 3402) + vocab(shapes, 3, 3403) + [
        Q('m', '「What color do you like?」の意味は？', '何色がすき？', ['何がほしい？', 'どの形がすき？', '何さい？'], 'What color ～? ＝ 何色？'),
        Q('k', 'バナナはふつう何色？ 英語で', 'yellow', ['blue', 'purple', 'black'], 'バナナは yellow（黄色）。'),
    ])

    R.area('ABCと あいさつの まとめ', S1, [
        Q('k', '「G」の小文字は？', 'g', ['j', 'q', 'y'], 'G g'),
        Q('k', '「Q」の小文字は？', 'q', ['p', 'g', 'o'], 'Q q'),
        Q('m', '「Good afternoon.」はいつのあいさつ？', 'ひるすぎ', ['朝', '夜ねる前', '別れるとき'], 'afternoon ＝ 午後'),
        Q('m', '「tired」の意味は？', 'つかれた', ['げんき', 'うれしい', 'おこった'], 'tired ＝ つかれた'),
        Q('c', 'six + six ＝ ?', 'twelve', ['eleven', 'ten', 'twenty'], '6 + 6 = 12'),
        Q('m', '「fourteen」は？', '14', ['40', '4', '41'], '-teen は 13〜19。'),
        Q('m', '「See you.」の意味は？', 'またね。', ['はじめまして。', 'ありがとう。', 'どうぞ。'], '別れるときのあいさつ。'),
        Q('m', '「gray」の意味は？', '灰色', ['金色', '水色', '銀色'], 'gray ＝ 灰色'),
        Q('m', '「rectangle」の意味は？', '長方形', ['円', 'ひし形', '星'], 'rectangle ＝ 長方形'),
        Q('u', '「Thank you.」への返事として合うのは？', 'You\'re welcome.', ['Good night.', 'I\'m fine.', 'Me, too.'], 'どういたしまして。'),
    ], boss=True)

    animals = [('dog', 'イヌ'), ('cat', 'ネコ'), ('rabbit', 'ウサギ'), ('bird', '鳥'), ('elephant', 'ゾウ'), ('lion', 'ライオン'),
               ('monkey', 'サル'), ('bear', 'クマ'), ('panda', 'パンダ'), ('fish', '魚'), ('horse', 'ウマ'), ('pig', 'ブタ')]
    R.area('動物', S2, vocab(animals, 9, 3404) + vocab(animals, 3, 3405, ja_to_en=True)[:3])

    food = [('apple', 'りんご'), ('banana', 'バナナ'), ('orange', 'オレンジ'), ('grapes', 'ぶどう'), ('strawberry', 'いちご'),
            ('melon', 'メロン'), ('peach', 'もも'), ('milk', '牛乳'), ('juice', 'ジュース'), ('pizza', 'ピザ'),
            ('ice cream', 'アイスクリーム'), ('cake', 'ケーキ'), ('rice', 'ごはん'), ('egg', 'たまご')]
    R.area('食べ物とくだもの', S2, vocab(food, 8, 3406) + [
        Q('u', '「Do you like apples?」に「はい」と答えるときは？', 'Yes, I do.', ['Yes, I am.', 'No, I don\'t.', 'Yes, you do.'], 'Do you ～? には Yes, I do. / No, I don\'t.'),
        Q('m', '「I like strawberries.」の意味は？', 'わたしはいちごがすき。', ['わたしはいちごがきらい。', 'いちごをください。', 'いちごはいくつ？'], 'I like ～. ＝ ～がすき'),
        Q('m', '「I don\'t like milk.」の意味は？', 'わたしは牛乳がすきではない。', ['わたしは牛乳がすき。', '牛乳をください。', '牛乳はある？'], 'don\'t like ＝ すきではない'),
        Q('m', '「What do you want?」の意味は？', '何がほしい？', ['何がすき？', '何色？', 'だれ？'], 'want ＝ ほしい'),
    ])

    days = [('Sunday', '日曜日'), ('Monday', '月曜日'), ('Tuesday', '火曜日'), ('Wednesday', '水曜日'), ('Thursday', '木曜日'),
            ('Friday', '金曜日'), ('Saturday', '土曜日')]
    weather = [('sunny', '晴れ'), ('rainy', '雨'), ('cloudy', 'くもり'), ('snowy', '雪')]
    R.area('曜日と天気', S2, vocab(days, 6, 3407) + vocab(weather, 3, 3408) + [
        Q('m', '「What day is it today?」の意味は？', '今日は何曜日？', ['今日は何日？', '今日の天気は？', '今何時？'], 'What day ～? ＝ 何曜日？'),
        Q('m', '「How is the weather?」の意味は？', '天気はどう？', ['元気？', '何曜日？', 'いくつ？'], 'weather ＝ 天気'),
        Q('k', '月曜日の次の曜日は？', 'Tuesday', ['Sunday', 'Thursday', 'Wednesday'], 'Monday → Tuesday'),
    ])

    body = [('head', '頭'), ('eye', '目'), ('ear', '耳'), ('nose', '鼻'), ('mouth', '口'), ('hand', '手'), ('foot', '足'), ('shoulder', 'かた')]
    R.area('体とからだの動き', S2, vocab(body, 6, 3409) + [
        Q('m', '「Stand up.」の意味は？', '立ちましょう。', ['すわりましょう。', 'ジャンプしましょう。', '手をあげましょう。'], 'stand up ＝ 立つ'),
        Q('m', '「Sit down.」の意味は？', 'すわりましょう。', ['立ちましょう。', '走りましょう。', 'まわりましょう。'], 'sit down ＝ すわる'),
        Q('m', '「jump」の意味は？', 'とぶ', ['走る', '泳ぐ', '歩く'], 'jump ＝ ジャンプする'),
        Q('m', '「Touch your nose.」の意味は？', '鼻をさわって。', ['鼻をかんで。', '口をあけて。', '耳をすませて。'], 'touch ＝ さわる'),
        Q('m', '「run」の意味は？', '走る', ['とぶ', '食べる', 'ねる'], 'run ＝ 走る'),
        Q('m', '「swim」の意味は？', '泳ぐ', ['歌う', '走る', '読む'], 'swim ＝ 泳ぐ'),
    ])

    R.area('すきなものの まとめ', S2, [
        Q('m', '「giraffe」の意味は？', 'キリン', ['ゾウ', 'カバ', 'シマウマ'], 'giraffe ＝ キリン'),
        Q('m', '「tomato」の意味は？', 'トマト', ['じゃがいも', 'にんじん', 'たまねぎ'], 'tomato ＝ トマト'),
        Q('m', '「carrot」の意味は？', 'にんじん', ['トマト', 'キャベツ', 'ピーマン'], 'carrot ＝ にんじん'),
        Q('m', '「What animal do you like?」の意味は？', '何の動物がすき？', ['動物はいる？', '動物は何びき？', '動物はどこ？'], 'What ～ do you like? ＝ 何の～がすき？'),
        Q('u', '「I like (   ).」で正しいのは？', 'dogs', ['dog is', 'a dogs', 'dogs are'], 'すきなものは複数形で言うことが多い。'),
        Q('m', '「It\'s rainy today.」の意味は？', '今日は雨です。', ['今日は晴れです。', '今日はさむいです。', '今日は日曜日です。'], 'rainy ＝ 雨の'),
        Q('k', '週末の2日は？', 'Saturday と Sunday', ['Monday と Friday', 'Friday と Saturday', 'Sunday と Monday'], '土曜と日曜。'),
        Q('m', '「knee」の意味は？', 'ひざ', ['ひじ', 'かかと', 'おなか'], 'knee ＝ ひざ（k は読まない）'),
        Q('m', '「Let\'s play soccer.」の意味は？', 'サッカーをしよう。', ['サッカーがすき。', 'サッカーを見た。', 'サッカーができる。'], 'Let\'s ～. ＝ ～しよう'),
        Q('m', '「cold」の意味は？', 'さむい・つめたい', ['あつい', 'あたたかい', 'すずしい'], 'cold ＝ さむい'),
    ], boss=True)


# ------------------------------------------------------------------ 小5
def e5(R):
    S1 = 'わたしのこと'
    S2 = '町とくらし'
    R.area('自己紹介', S1, [
        Q('m', '「My name is Aoi.」の意味は？', 'わたしの名前はあおいです。', ['あおいはどこ？', 'あおいがすき。', 'あおいは友だち。'], 'My name is ～. ＝ わたしの名前は～'),
        Q('m', '「I\'m from Japan.」の意味は？', 'わたしは日本出身です。', ['わたしは日本に行きたい。', 'わたしは日本がすき。', '日本はどこ？'], 'be from ～ ＝ ～出身'),
        Q('m', '「How do you spell your name?」の意味は？', '名前のつづりは？', ['名前は何？', '名前がすき？', '名前を言って。'], 'spell ＝ つづる'),
        Q('u', '「What\'s your name?」に答えるのは？', 'I\'m Sora.', ['I\'m fine.', 'I\'m eleven.', 'Yes, I am.'], '名前を答える。'),
        Q('m', '「How old are you?」の意味は？', '何さいですか？', ['元気ですか？', 'どこの出身？', '背の高さは？'], 'How old ～? ＝ 何さい？'),
        Q('u', '「How old are you?」に答えるのは？', 'I\'m eleven.', ['I\'m Ken.', 'I\'m happy.', 'I like eleven.'], '年れいを答える。'),
        F('I (   ) Mika.', 'am', ['is', 'are', 'be'], 'I のあとは am。'),
        F('(   ) name is Taro.', 'My', ['I', 'Me', 'Mine'], '「わたしの」は my。'),
        Q('m', '「I play the piano.」の意味は？', 'わたしはピアノをひきます。', ['わたしはピアノが見たい。', 'ピアノはどこ？', 'ピアノを買った。'], 'play the ～ ＝ （楽器）をひく'),
        Q('m', '「I\'m good at drawing.」の意味は？', 'わたしは絵をかくのが得意です。', ['わたしは絵がきらいです。', 'わたしは絵を買います。', '絵をかいて。'], 'be good at ～ ＝ ～が得意'),
        Q('m', '「My favorite sport is tennis.」の意味は？', 'わたしのいちばんすきなスポーツはテニスです。', ['テニスはむずかしい。', 'テニスをしよう。', 'テニスを見た。'], 'favorite ＝ いちばんすきな'),
        Q('m', '「brother」の意味は？', '兄・弟', ['姉・妹', '父', '祖父'], 'brother ＝ 兄弟'),
    ])

    months = [('January', '1月'), ('February', '2月'), ('March', '3月'), ('April', '4月'), ('May', '5月'), ('June', '6月'),
              ('July', '7月'), ('August', '8月'), ('September', '9月'), ('October', '10月'), ('November', '11月'), ('December', '12月')]
    R.area('月と誕生日', S1, vocab(months, 8, 5001) + [
        Q('m', '「When is your birthday?」の意味は？', '誕生日はいつ？', ['誕生日に何がほしい？', '何さい？', '誕生日おめでとう。'], 'When ～? ＝ いつ？'),
        Q('m', '「My birthday is May 5th.」の意味は？', 'わたしの誕生日は5月5日です。', ['5月5日はこどもの日。', '5さいです。', '5月がすき。'], '5th ＝ 5日（fifth）'),
        Q('m', '「first」の意味は？', '1番目（1日）', ['3番目', '最後', '2番目'], 'first, second, third…'),
        Q('m', '「What do you want for your birthday?」の意味は？', '誕生日に何がほしい？', ['誕生日はいつ？', '誕生日に何をした？', '誕生日おめでとう。'], 'want ＝ ほしい'),
    ])

    R.area('できること（can）', S1, [
        F('I (   ) swim.', 'can', ['am', 'do', 'is'], 'できることは can + 動詞。'),
        Q('m', '「I can play the recorder.」の意味は？', 'わたしはリコーダーをふくことができる。', ['リコーダーがすき。', 'リコーダーをふいた。', 'リコーダーがほしい。'], 'can ＝ ～できる'),
        Q('m', '「I can\'t ride a unicycle.」の意味は？', 'わたしは一輪車に乗れない。', ['一輪車に乗れる。', '一輪車がすき。', '一輪車を買った。'], 'can\'t ＝ ～できない'),
        Q('u', '「Can you cook?」に「はい」と答えるのは？', 'Yes, I can.', ['Yes, I do.', 'Yes, I am.', 'No, I can\'t.'], 'Can you ～? → Yes, I can.'),
        F('(   ) you skate? — Yes, I can.', 'Can', ['Are', 'Is', 'Do'], 'たずねるときは Can を文の最初に。'),
        Q('m', '「He can run fast.」の意味は？', '彼は速く走れる。', ['彼はゆっくり走る。', '彼は走りたい。', '彼は走らない。'], 'fast ＝ 速く'),
        Q('m', '「She can sing well.」の意味は？', '彼女はじょうずに歌える。', ['彼女は歌がきらい。', '彼女は歌いたい。', '彼女は歌っている。'], 'well ＝ じょうずに'),
        F('He can (   ) the guitar.', 'play', ['plays', 'playing', 'played'], 'can のあとは動詞の元の形。'),
        Q('m', '「dance」の意味は？', 'おどる', ['歌う', '泳ぐ', 'かく'], 'dance ＝ おどる'),
        Q('m', '「jump rope」の意味は？', 'なわとび', ['てつぼう', 'ボールなげ', 'かけっこ'], 'jump rope ＝ なわとび'),
        Q('m', '「Who is this?」の意味は？', 'この人はだれ？', ['これは何？', 'どこ？', 'いつ？'], 'Who ＝ だれ'),
        Q('m', '「He is my hero.」の意味は？', '彼はわたしのヒーローです。', ['彼はわたしの兄です。', '彼はわたしの先生です。', '彼はわたしをたすけた。'], 'hero ＝ あこがれの人'),
    ])

    R.area('わたしのことの まとめ', S1, [
        Q('m', '「October」は何月？', '10月', ['8月', '11月', '1月'], 'October ＝ 10月'),
        Q('m', '「third」の意味は？', '3番目（3日）', ['30', '13', '1番目'], 'third ＝ 3番目'),
        F('I (   ) ride a bike.', 'can', ['am', 'is', 'are'], 'can ＋ 動詞'),
        F('She (   ) Emma.', 'is', ['am', 'are', 'can'], 'she のあとは is。'),
        Q('u', '「Can you play kendama?」に「いいえ」と答えるのは？', 'No, I can\'t.', ['No, I don\'t.', 'No, I am not.', 'Yes, I can.'], 'Can you ～? → No, I can\'t.'),
        Q('m', '「sister」の意味は？', '姉・妹', ['兄・弟', '母', 'いとこ'], 'sister ＝ 姉妹'),
        Q('m', '「grandmother」の意味は？', 'おばあさん', ['おじいさん', 'おばさん', 'お母さん'], 'grandmother ＝ 祖母'),
        Q('m', '「I\'m good at math.」の意味は？', 'わたしは算数が得意です。', ['算数がきらい。', '算数をしよう。', '算数は何時間目？'], 'be good at ～'),
        Q('m', '「December」は何月？', '12月', ['10月', '11月', '2月'], 'December ＝ 12月'),
        Q('m', '「kind」の意味は？', 'やさしい', ['こわい', 'せが高い', 'いそがしい'], 'kind ＝ 親切な'),
    ], boss=True)

    subjects = [('Japanese', '国語'), ('math', '算数'), ('science', '理科'), ('social studies', '社会'), ('music', '音楽'),
                ('P.E.', '体育'), ('arts and crafts', '図工'), ('English', '英語'), ('home economics', '家庭科')]
    R.area('時間割と教科', S2, vocab(subjects, 8, 5002) + [
        Q('m', '「What do you have on Monday?」の意味は？', '月曜日は何の授業がある？', ['月曜日は何をする？', '月曜日はすき？', '月曜日はいつ？'], 'have ＝ （授業が）ある'),
        Q('m', '「I study math on Friday.」の意味は？', 'わたしは金曜日に算数を勉強する。', ['金曜日は算数がない。', '金曜日に算数のテストがある。', '算数がすき。'], 'on Friday ＝ 金曜日に'),
        Q('m', '「What time do you get up?」の意味は？', '何時に起きる？', ['何時にねる？', '今何時？', '何時に学校に行く？'], 'get up ＝ 起きる'),
        Q('m', '「I go to bed at nine.」の意味は？', 'わたしは9時にねます。', ['9時に起きる。', '9時に学校に行く。', '9時に食べる。'], 'go to bed ＝ ねる'),
    ])

    R.area('道案内', S2, [
        Q('m', '「Where is the station?」の意味は？', '駅はどこですか？', ['駅は何時？', '駅に行こう。', '駅はすき？'], 'Where ＝ どこ'),
        Q('m', '「Go straight.」の意味は？', 'まっすぐ行って。', ['右に曲がって。', '左に曲がって。', '止まって。'], 'straight ＝ まっすぐ'),
        Q('m', '「Turn right.」の意味は？', '右に曲がって。', ['左に曲がって。', 'まっすぐ行って。', 'もどって。'], 'right ＝ 右'),
        Q('m', '「Turn left at the corner.」の意味は？', '角を左に曲がって。', ['角を右に曲がって。', '角で止まって。', '角をまっすぐ。'], 'left ＝ 左、corner ＝ 角'),
        Q('m', '「You can see it on your right.」の意味は？', '右手に見えます。', ['左手に見えます。', '正面に見えます。', '見えません。'], 'on your right ＝ 右側に'),
        Q('m', '「hospital」の意味は？', '病院', ['郵便局', '図書館', '公園'], 'hospital ＝ 病院'),
        Q('m', '「post office」の意味は？', '郵便局', ['警察署', '消防署', '銀行'], 'post office ＝ 郵便局'),
        Q('m', '「library」の意味は？', '図書館', ['美術館', '体育館', '病院'], 'library ＝ 図書館'),
        Q('m', '「park」の意味は？', '公園', ['駐車場', '駅', '店'], 'park ＝ 公園'),
        Q('u', '「(   ) is the park?」で、場所をたずねるのは？', 'Where', ['What', 'Who', 'When'], 'Where ＝ どこ'),
        Q('m', '「next to the bank」の意味は？', '銀行のとなり', ['銀行の前', '銀行のうしろ', '銀行の中'], 'next to ＝ ～のとなり'),
        Q('m', '「in front of the school」の意味は？', '学校の前', ['学校のうしろ', '学校の中', '学校の上'], 'in front of ＝ ～の前'),
    ])

    menu = [('hamburger', 'ハンバーガー'), ('spaghetti', 'スパゲッティ'), ('salad', 'サラダ'), ('soup', 'スープ'),
            ('French fries', 'フライドポテト'), ('steak', 'ステーキ'), ('curry and rice', 'カレーライス'), ('sandwich', 'サンドイッチ')]
    R.area('レストランで注文', S2, vocab(menu, 5, 5003) + [
        Q('m', '「What would you like?」の意味は？', '何になさいますか？', ['何がすきですか？', '何さいですか？', 'いくらですか？'], '注文をたずねる、ていねいな言い方。'),
        Q('u', '「What would you like?」に答えるのは？', 'I\'d like pizza.', ['I\'m pizza.', 'I can pizza.', 'Yes, I would.'], 'I\'d like ～. ＝ ～がほしいです'),
        Q('m', '「How much is it?」の意味は？', 'いくらですか？', ['いくつですか？', '何さいですか？', 'どれですか？'], 'How much ～? ＝ いくら'),
        Q('m', '「It\'s 500 yen.」の意味は？', '500円です。', ['500個です。', '500さいです。', '500グラムです。'], 'yen ＝ 円'),
        Q('m', '「delicious」の意味は？', 'とてもおいしい', ['まずい', 'からい', 'あまい'], 'delicious ＝ おいしい'),
        Q('m', '「sweet」の意味は？', 'あまい', ['からい', 'にがい', 'すっぱい'], 'sweet ＝ あまい'),
        Q('m', '「spicy」の意味は？', 'からい', ['あまい', 'しょっぱい', 'つめたい'], 'spicy ＝ からい'),
    ])

    R.area('町とくらしの まとめ', S2, [
        Q('m', '「science」は何の教科？', '理科', ['社会', '算数', '音楽'], 'science ＝ 理科'),
        Q('m', '「Go straight for two blocks.」の意味は？', '2ブロックまっすぐ行って。', ['2つ目を右に。', '2分歩いて。', '2回曲がって。'], 'block ＝ 区画'),
        Q('m', '「fire station」の意味は？', '消防署', ['警察署', 'ガソリンスタンド', '駅'], 'fire station ＝ 消防署'),
        Q('m', '「I\'d like curry and rice.」の意味は？', 'カレーライスをください。', ['カレーライスがすき。', 'カレーライスを作った。', 'カレーライスはどこ？'], 'I\'d like ～. ＝ ～をください'),
        Q('m', '「bitter」の意味は？', 'にがい', ['あまい', 'すっぱい', 'あつい'], 'bitter ＝ にがい'),
        Q('m', '「What time is it?」の意味は？', '今何時？', ['何曜日？', '何月？', 'いつ？'], 'What time ～? ＝ 何時'),
        Q('m', '「I wash the dishes.」の意味は？', 'わたしは皿をあらいます。', ['わたしは皿を買います。', '皿がすき。', '皿をわった。'], 'wash ＝ あらう'),
        Q('m', '「behind」の意味は？', '～のうしろに', ['～の前に', '～のとなりに', '～の上に'], 'behind ＝ うしろ'),
        Q('m', '「P.E.」は何の教科？', '体育', ['図工', '家庭科', '音楽'], 'physical education ＝ 体育'),
        Q('m', '「sour」の意味は？', 'すっぱい', ['にがい', 'からい', 'あまい'], 'sour ＝ すっぱい'),
    ], boss=True)


# ------------------------------------------------------------------ 小6
def e6(R):
    S1 = '思い出と夢'
    S2 = '日本と世界'
    R.area('週末にしたこと（過去）', S1, [
        Q('m', '「I went to the zoo.」の意味は？', 'わたしは動物園に行った。', ['動物園に行きたい。', '動物園に行く。', '動物園はどこ？'], 'went ＝ go（行く）の過去形'),
        Q('m', '「I ate ice cream.」の意味は？', 'わたしはアイスクリームを食べた。', ['アイスクリームを食べたい。', 'アイスクリームがすき。', 'アイスクリームを買う。'], 'ate ＝ eat（食べる）の過去形'),
        Q('m', '「I saw fireworks.」の意味は？', 'わたしは花火を見た。', ['花火をした。', '花火がすき。', '花火を作った。'], 'saw ＝ see（見る）の過去形'),
        Q('m', '「It was fun.」の意味は？', '楽しかった。', ['楽しい。', '楽しみ。', 'つまらなかった。'], 'was ＝ is の過去形'),
        Q('k', '「go」の過去形は？', 'went', ['goed', 'gone', 'going'], 'go → went（形が大きく変わる）'),
        Q('k', '「eat」の過去形は？', 'ate', ['eated', 'eaten', 'eats'], 'eat → ate'),
        Q('k', '「see」の過去形は？', 'saw', ['seed', 'seen', 'sees'], 'see → saw'),
        Q('k', '「enjoy」の過去形は？', 'enjoyed', ['enjoied', 'enjoy', 'enjoyd'], 'ふつうは ed をつける。'),
        Q('m', '「How was your weekend?」の意味は？', '週末はどうだった？', ['週末に何をする？', '週末はいつ？', '週末はすき？'], 'How was ～? ＝ ～はどうだった？'),
        Q('m', '「I enjoyed swimming.」の意味は？', 'わたしは水泳を楽しんだ。', ['水泳を習いたい。', '水泳がきらい。', '水泳をしている。'], 'enjoy ～ing ＝ ～を楽しむ'),
        Q('m', '「last Sunday」の意味は？', 'この前の日曜日', ['次の日曜日', '毎週日曜日', '日曜日の朝'], 'last ＝ この前の'),
        Q('m', '「It was exciting.」の意味は？', 'わくわくした。', ['こわかった。', 'つかれた。', 'ねむかった。'], 'exciting ＝ わくわくする'),
    ])

    R.area('夏休みの思い出', S1, [
        Q('m', '「summer vacation」の意味は？', '夏休み', ['冬休み', '夏まつり', '夏の天気'], 'vacation ＝ 休み'),
        Q('m', '「I went camping.」の意味は？', 'わたしはキャンプに行った。', ['キャンプをしたい。', 'キャンプはどこ？', 'キャンプがすき。'], 'go camping ＝ キャンプに行く'),
        Q('m', '「I visited my grandparents.」の意味は？', 'わたしは祖父母をたずねた。', ['祖父母がきた。', '祖父母に電話した。', '祖父母がすき。'], 'visit ＝ たずねる'),
        Q('m', '「beach」の意味は？', '浜辺', ['山', '川', '森'], 'beach ＝ 浜・ビーチ'),
        Q('m', '「mountain」の意味は？', '山', ['海', '湖', '島'], 'mountain ＝ 山'),
        Q('m', '「festival」の意味は？', 'お祭り', ['花火', '旅行', 'プール'], 'festival ＝ 祭り'),
        Q('k', '「have」の過去形は？', 'had', ['haved', 'has', 'having'], 'have → had'),
        Q('k', '「play」の過去形は？', 'played', ['plaied', 'plaid', 'play'], 'play → played'),
        Q('m', '「I had a good time.」の意味は？', '楽しい時間をすごした。', ['いい時計を持っていた。', 'よい天気だった。', '時間がなかった。'], 'have a good time ＝ 楽しくすごす'),
        Q('m', '「It was beautiful.」の意味は？', 'それは美しかった。', ['それはおいしかった。', 'それはおもしろかった。', 'それは大きかった。'], 'beautiful ＝ 美しい'),
        Q('m', '「watermelon」の意味は？', 'すいか', ['メロン', 'もも', 'なし'], 'watermelon ＝ すいか'),
        Q('m', '「I went to Okinawa by plane.」の by plane の意味は？', '飛行機で', ['船で', '車で', '電車で'], 'by ～ ＝ ～（乗り物）で'),
    ])

    jobs = [('teacher', '先生'), ('doctor', '医者'), ('nurse', '看護師'), ('cook', '料理人'), ('pilot', 'パイロット'),
            ('farmer', '農家'), ('scientist', '科学者'), ('vet', '獣医'), ('florist', '花屋'), ('soccer player', 'サッカー選手'),
            ('police officer', '警察官'), ('baker', 'パン屋')]
    R.area('将来の夢', S1, vocab(jobs, 8, 6001) + [
        Q('m', '「What do you want to be?」の意味は？', '何になりたい？', ['何がほしい？', '何をしている？', '何がすき？'], 'want to be ～ ＝ ～になりたい'),
        Q('m', '「I want to be a doctor.」の意味は？', 'わたしは医者になりたい。', ['わたしは医者です。', '医者に会いたい。', '医者がすき。'], 'want to be ～'),
        F('I want to (   ) a vet.', 'be', ['is', 'am', 'being'], 'want to be ～ ＝ ～になりたい'),
        Q('m', '「I want to help sick animals.」の意味は？', '病気の動物を助けたい。', ['動物を飼いたい。', '動物がすき。', '動物園に行きたい。'], 'help ＝ 助ける'),
    ])

    R.area('思い出と夢の まとめ', S1, [
        Q('k', '「make」の過去形は？', 'made', ['maked', 'make', 'maden'], 'make → made'),
        Q('k', '「swim」の過去形は？', 'swam', ['swimed', 'swum', 'swimmed'], 'swim → swam'),
        Q('m', '「My best memory is the school trip.」の意味は？', 'いちばんの思い出は修学旅行です。', ['修学旅行に行きたい。', '修学旅行はいつ？', '修学旅行がきらい。'], 'memory ＝ 思い出'),
        Q('m', '「sports day」の意味は？', '運動会', ['修学旅行', '音楽会', '入学式'], 'sports day ＝ 運動会'),
        Q('m', '「graduation ceremony」の意味は？', '卒業式', ['入学式', '運動会', '始業式'], 'graduation ＝ 卒業'),
        Q('m', '「astronaut」の意味は？', '宇宙飛行士', ['科学者', 'パイロット', '漫画家'], 'astronaut ＝ 宇宙飛行士'),
        Q('m', '「I want to be a singer.」の意味は？', '歌手になりたい。', ['歌が聞きたい。', '歌手に会った。', '歌がすき。'], 'singer ＝ 歌手'),
        Q('m', '「It was delicious.」の意味は？', 'おいしかった。', ['おいしい。', 'あまかった。', 'つめたかった。'], 'was ＋ 形容詞'),
        Q('k', '「get」の過去形は？', 'got', ['getted', 'gotten', 'gets'], 'get → got'),
        Q('m', '「I want to travel around the world.」の意味は？', '世界中を旅したい。', ['世界がすき。', '世界に友だちがいる。', '地図を見たい。'], 'travel ＝ 旅行する'),
    ], boss=True)

    countries = [('Japan', '日本'), ('China', '中国'), ('Korea', '韓国'), ('America', 'アメリカ'), ('Australia', 'オーストラリア'),
                 ('Brazil', 'ブラジル'), ('France', 'フランス'), ('India', 'インド'), ('Italy', 'イタリア'), ('Egypt', 'エジプト'),
                 ('Canada', 'カナダ'), ('the U.K.', 'イギリス')]
    R.area('行ってみたい国', S2, vocab(countries, 8, 6002) + [
        Q('m', '「Where do you want to go?」の意味は？', 'どこに行きたい？', ['どこに住んでいる？', 'どこに行った？', 'どこの出身？'], 'want to go ＝ 行きたい'),
        Q('m', '「I want to go to Italy.」の意味は？', 'イタリアに行きたい。', ['イタリアに行った。', 'イタリアに住んでいる。', 'イタリアがきらい。'], 'want to go to ～'),
        Q('m', '「You can see the pyramids.」の意味は？', 'ピラミッドを見ることができます。', ['ピラミッドがすき。', 'ピラミッドを作った。', 'ピラミッドはない。'], 'can see ＝ 見られる'),
        Q('m', '「You can eat pizza in Italy.」の意味は？', 'イタリアではピザが食べられる。', ['イタリアのピザは高い。', 'ピザを作ろう。', 'ピザがすき。'], 'can eat ＝ 食べられる'),
    ])

    R.area('わたしたちの町と日本', S2, [
        Q('m', '「We have a big park in our town.」の意味は？', '町には大きな公園がある。', ['大きな公園に行こう。', '公園がほしい。', '公園はない。'], 'We have ～. ＝ ～がある'),
        Q('m', '「We don\'t have a swimming pool.」の意味は？', 'プールがない。', ['プールがある。', 'プールに行きたい。', 'プールがすき。'], 'don\'t have ＝ ない'),
        Q('m', '「I want a library in my town.」の意味は？', '町に図書館がほしい。', ['町の図書館が好き。', '図書館に行った。', '図書館はどこ？'], 'want ＝ ほしい'),
        Q('m', '「shrine」の意味は？', '神社', ['寺', '城', '橋'], 'shrine ＝ 神社'),
        Q('m', '「temple」の意味は？', '寺', ['神社', '教会', '城'], 'temple ＝ 寺'),
        Q('m', '「castle」の意味は？', '城', ['塔', '寺', '駅'], 'castle ＝ 城'),
        Q('m', '「New Year\'s Day」の意味は？', '元日', ['大みそか', 'こどもの日', '七夕'], 'New Year\'s Day ＝ 1月1日'),
        Q('m', '「Star Festival」は日本のどの行事？', '七夕', ['ひなまつり', 'お盆', '節分'], '7月7日の星まつり。'),
        Q('m', '「It\'s famous for its hot springs.」の意味は？', '温泉で有名です。', ['温泉がない。', '温泉がすき。', '温泉に行った。'], 'be famous for ～ ＝ ～で有名'),
        Q('m', '「clean」の意味は？', 'きれいな・そうじする', ['きたない', 'しずかな', 'にぎやかな'], 'clean ＝ きれいな'),
        Q('m', '「popular」の意味は？', '人気がある', ['有名ではない', 'めずらしい', '古い'], 'popular ＝ 人気の'),
        Q('m', '「I\'m proud of my town.」の意味は？', 'わたしは自分の町をほこりに思う。', ['町を出たい。', '町は小さい。', '町はきたない。'], 'be proud of ～ ＝ ～をほこりに思う'),
    ])

    R.area('中学校への準備', S2, [
        Q('m', '「junior high school」の意味は？', '中学校', ['小学校', '高校', '大学'], 'junior high school ＝ 中学校'),
        Q('m', '「What club do you want to join?」の意味は？', '何部に入りたい？', ['何部に入っている？', '部活はすき？', '部活はいつ？'], 'join ＝ 入る・参加する'),
        Q('m', '「I want to join the brass band.」の意味は？', '吹奏楽部に入りたい。', ['吹奏楽部をやめたい。', '吹奏楽を聞きたい。', '吹奏楽部はない。'], 'brass band ＝ 吹奏楽部'),
        Q('m', '「I want to study English hard.」の意味は？', '英語を一生けんめい勉強したい。', ['英語はむずかしい。', '英語がきらい。', '英語のテストがある。'], 'hard ＝ 一生けんめい'),
        Q('m', '「school uniform」の意味は？', '制服', ['教科書', '時間割', '通学路'], 'uniform ＝ 制服'),
        Q('m', '「I want to make many friends.」の意味は？', '友だちをたくさん作りたい。', ['友だちがたくさんいる。', '友だちに会いたい。', '友だちと遊んだ。'], 'make friends ＝ 友だちを作る'),
        Q('m', '「event」の意味は？', '行事', ['教科', '道具', '先生'], 'event ＝ 行事・できごと'),
        Q('m', '「school festival」の意味は？', '文化祭', ['運動会', '卒業式', '遠足'], 'school festival ＝ 文化祭'),
        Q('m', '「I\'m looking forward to it.」の意味は？', 'それを楽しみにしています。', ['それをさがしています。', 'それを見ています。', 'それがこわい。'], 'look forward to ～ ＝ ～を楽しみにする'),
        Q('m', '「volunteer」の意味は？', 'ボランティア（自分から進んで手伝う人）', ['先生', '選手', '店員'], 'volunteer ＝ 進んで活動する人'),
        Q('m', '「I want to be good at tennis.」の意味は？', 'テニスがうまくなりたい。', ['テニスが得意だ。', 'テニスを見たい。', 'テニスがきらい。'], 'be good at ～'),
        Q('m', '「memory」の意味は？', '思い出', ['夢', '約束', '手紙'], 'memory ＝ 思い出'),
    ])

    R.area('小学校英語の まとめ', S2, [
        Q('m', '「Germany」の意味は？', 'ドイツ', ['スペイン', 'オランダ', 'ロシア'], 'Germany ＝ ドイツ'),
        Q('m', '「We have a big festival in summer.」の意味は？', '夏に大きな祭りがある。', ['夏祭りに行きたい。', '夏はあつい。', '祭りがない。'], 'We have ～.'),
        Q('k', '「buy」の過去形は？', 'bought', ['buyed', 'buied', 'boughted'], 'buy → bought'),
        Q('m', '「carpenter」の意味は？', '大工', ['漁師', '画家', '店員'], 'carpenter ＝ 大工'),
        Q('m', '「What sport do you want to play in junior high school?」の意味は？', '中学校で何のスポーツをしたい？', ['中学校で何のスポーツをした？', 'スポーツはすき？', '中学校はどこ？'], 'want to play ＝ したい'),
        Q('m', '「I can\'t wait.」の意味は？', '待ちきれない。', ['待てます。', '待ってください。', '待たなくていい。'], '楽しみなときに言う。'),
        Q('m', '「bridge」の意味は？', '橋', ['川', '道', '塔'], 'bridge ＝ 橋'),
        Q('m', '「I want to see koalas in Australia.」の意味は？', 'オーストラリアでコアラが見たい。', ['コアラがすき。', 'コアラを見た。', 'オーストラリアに住んでいる。'], 'want to see'),
        Q('m', '「It\'s my treasure.」の意味は？', 'それはわたしの宝物です。', ['それはわたしの夢です。', 'それはわたしの家です。', 'それはわたしの本です。'], 'treasure ＝ 宝物'),
        Q('m', '「Thank you for everything.」の意味は？', 'いろいろとありがとう。', ['全部ください。', 'すべてわかった。', 'ありがとう、また明日。'], 'お世話になった人へのことば。'),
    ], boss=True)


# ------------------------------------------------------------------ 中1
def j1(R):
    S1 = '現在の文'
    S2 = '進行形・can・過去'
    R.area('be動詞', S1, [
        F('I (   ) a student.', 'am', ['is', 'are', 'be'], 'I のときは am。'),
        F('You (   ) my friend.', 'are', ['am', 'is', 'be'], 'you のときは are。'),
        F('This (   ) my bag.', 'is', ['am', 'are', 'be'], 'this（1つのもの）は is。'),
        F('Ken and Yumi (   ) classmates.', 'are', ['is', 'am', 'be'], '主語が2人なので are。'),
        F('(   ) you from Osaka?', 'Are', ['Is', 'Do', 'Am'], 'be動詞の疑問文は be動詞を前に。'),
        F('I am (   ) a teacher.', 'not', ['no', 'don\'t', 'isn\'t'], '否定は be動詞のあとに not。'),
        U('「Is this your pen?」に「はい」と答えると？', None, 'Yes, it is.', ['Yes, this is.', 'Yes, I am.', 'Yes, it does.'], 'this で聞かれたら it で答える。'),
        F('That (   ) not my cap.', 'is', ['are', 'am', 'do'], 'that は is。'),
        F('(   ) she your sister?', 'Is', ['Are', 'Does', 'Am'], 'she は is。'),
        F('We (   ) in the same class.', 'are', ['is', 'am', 'be'], 'we は are。'),
        Q('k', '「I am」の短縮形は？', 'I\'m', ['Im\'', 'I\'am', 'Iam'], 'I am → I\'m'),
        Q('k', '「is not」の短縮形は？', 'isn\'t', ['is\'nt', 'isnt', 'i\'snt'], 'is not → isn\'t'),
    ], lesson=[
        ('be動詞の使い分け', 'I → am、you と複数 → are、それ以外の1人・1つ → is。', 'I am / You are / He is'),
        ('否定文と疑問文', '否定は be動詞のあとに not、疑問文は be動詞を主語の前に。', 'Is he a student? — Yes, he is.'),
    ])

    R.area('一般動詞', S1, [
        F('I (   ) tennis every day.', 'play', ['am', 'plays', 'am play'], 'I のときは動詞はそのまま。'),
        F('(   ) you like music?', 'Do', ['Are', 'Does', 'Is'], '一般動詞の疑問文は Do。'),
        F('I (   ) like carrots.', 'don\'t', ['am not', 'not', 'isn\'t'], '一般動詞の否定は don\'t ＋ 動詞。'),
        U('「Do you have a dog?」に「いいえ」と答えると？', None, 'No, I don\'t.', ['No, I am not.', 'No, I haven\'t.', 'No, you don\'t.'], 'Do you ～? → No, I don\'t.'),
        F('We (   ) English on Monday.', 'study', ['studies', 'are study', 'studying'], 'we のときは動詞はそのまま。'),
        F('I (   ) to school by bus.', 'go', ['goes', 'am', 'going'], 'go ＝ 行く'),
        U('まちがっている文は？', None, 'I am like dogs.', ['I like dogs.', 'Do you like dogs?', 'I don\'t like dogs.'], 'be動詞と一般動詞はいっしょに使わない。'),
        F('They (   ) soccer after school.', 'practice', ['practices', 'are practice', 'practiced every'], 'they のときはそのまま。'),
        Q('m', '「I usually get up at six.」の usually の意味は？', 'たいてい', ['ときどき', 'いつも決して', 'たまに'], 'usually ＝ たいてい'),
        Q('m', '「I walk to school.」の意味は？', 'わたしは歩いて学校に行く。', ['学校まで走る。', '学校を歩き回る。', '学校から帰る。'], 'walk to ～ ＝ ～へ歩いて行く'),
        F('Do you (   ) a pen?', 'have', ['has', 'are', 'having'], 'Do のあとは動詞の元の形。'),
        Q('m', '「I often read books.」の often の意味は？', 'よく', ['決して', 'たった今', 'ゆっくり'], 'often ＝ よく・しばしば'),
    ])

    R.area('3人称単数現在', S1, [
        F('He (   ) baseball.', 'plays', ['play', 'playing', 'is play'], '主語が he なので s をつける。'),
        F('My mother (   ) a car.', 'has', ['have', 'haves', 'is have'], 'have → has'),
        F('(   ) she like cats?', 'Does', ['Do', 'Is', 'Are'], '3人称単数の疑問文は Does。'),
        F('Tom (   ) not eat natto.', 'does', ['do', 'is', 'doesn\'t'], 'does not ＋ 動詞の元の形。'),
        F('Does he (   ) English?', 'speak', ['speaks', 'speaking', 'spoke'], 'Does のあとは元の形。'),
        F('She (   ) her homework after dinner.', 'does', ['do', 'dos', 'doing'], 'do → does'),
        F('Emi (   ) TV every night.', 'watches', ['watchs', 'watch', 'watching'], 'ch で終わる語は es。'),
        F('My brother (   ) math.', 'studies', ['studys', 'study', 'studyes'], '子音字＋y は y を i にして es。'),
        U('「Does your father cook?」に「はい」と答えると？', None, 'Yes, he does.', ['Yes, he do.', 'Yes, he is.', 'Yes, does he.'], 'Does ～? → Yes, he does.'),
        F('Ken (   ) to the library on Sundays.', 'goes', ['go', 'gos', 'going'], 'go → goes'),
        Q('k', '3人称単数にあたる主語は？', 'my sister', ['I', 'you', 'we'], '自分・相手以外の1人・1つ。'),
        F('The cat (   ) on the sofa every day.', 'sleeps', ['sleep', 'sleepes', 'is sleep'], 'the cat は3人称単数。'),
    ], lesson=[
        ('3単現の s', '主語が he / she / it や1人・1つのとき、現在の動詞に s をつける。', 'He plays tennis.'),
        ('does の文', '否定は doesn\'t ＋ 動詞の元の形、疑問は Does ＋ 主語 ＋ 動詞の元の形。', 'Does she like music?'),
    ])

    R.area('名詞の複数形と代名詞', S1, [
        Q('k', '「box」の複数形は？', 'boxes', ['boxs', 'boxies', 'box'], 'x で終わる語は es。'),
        Q('k', '「child」の複数形は？', 'children', ['childs', 'childes', 'childrens'], '不規則に変化する。'),
        Q('k', '「city」の複数形は？', 'cities', ['citys', 'cityes', 'citis'], '子音字＋y は ies。'),
        Q('k', '「knife」の複数形は？', 'knives', ['knifes', 'knifs', 'knive'], 'f(e) → ves'),
        F('This is (   ) bag.', 'my', ['I', 'me', 'mine'], '名詞の前は「～の」の形。'),
        F('Do you know (   )? — Yes, he is my friend.', 'him', ['he', 'his', 'he\'s'], '動詞のあとは「～を」の形。'),
        F('That book is (   ).', 'mine', ['my', 'me', 'I'], '「わたしのもの」は mine。'),
        F('(   ) are good friends.', 'They', ['Them', 'Their', 'Theirs'], '主語は「～は」の形。'),
        F('I have two (   ).', 'brothers', ['brother', 'brotheres', 'a brothers'], '2人なので複数形。'),
        F('Whose notebook is this? — It\'s (   ).', 'Ken\'s', ['Ken', 'Kens', 'of Ken'], '「ケンのもの」は Ken\'s。'),
        F('Look at (   ) dog. It\'s cute.', 'that', ['those', 'it', 'they'], '1ぴきなので that。'),
        F('These (   ) my pencils.', 'are', ['is', 'am', 'be'], 'these は複数なので are。'),
    ])

    R.area('現在の文の まとめ', S1, [
        F('My sister (   ) in Tokyo.', 'lives', ['live', 'is live', 'living'], '3単現の s。'),
        F('(   ) your parents work on Saturday?', 'Do', ['Does', 'Are', 'Is'], 'your parents は複数。'),
        F('He (   ) a new bike.', 'has', ['have', 'is', 'haves'], 'have → has'),
        F('Those (   ) Mr. Sato\'s cars.', 'are', ['is', 'am', 'does'], 'those は複数。'),
        F('Kumi doesn\'t (   ) coffee.', 'drink', ['drinks', 'drinking', 'drank'], 'doesn\'t のあとは元の形。'),
        Q('k', '「woman」の複数形は？', 'women', ['womans', 'womens', 'woman'], 'woman → women'),
        F('I love (   ). They are kind.', 'them', ['they', 'their', 'theirs'], '動詞のあとは目的格。'),
        F('Is this (   ) umbrella? — Yes, it\'s mine.', 'your', ['you', 'yours', 'you\'re'], '名詞の前は your。'),
        F('Mike (   ) Japanese very well.', 'speaks', ['speak', 'is speak', 'speaking'], '3単現。'),
        U('まちがっている文は？', None, 'She don\'t like milk.', ['She doesn\'t like milk.', 'I don\'t like milk.', 'They don\'t like milk.'], 'she なら doesn\'t。'),
    ], boss=True)

    R.area('疑問詞', S2, [
        F('(   ) is your birthday? — It\'s June 3rd.', 'When', ['Where', 'What', 'Who'], '時をたずねるのは when。'),
        F('(   ) do you live? — In Kyoto.', 'Where', ['When', 'What', 'How'], '場所は where。'),
        F('(   ) is that girl? — She is Mai.', 'Who', ['Whose', 'What', 'Which'], '人をたずねるのは who。'),
        F('(   ) bag is this? — It\'s mine.', 'Whose', ['Who', 'What', 'Which'], '「だれの」は whose。'),
        F('(   ) do you go to school? — By bike.', 'How', ['What', 'Where', 'Why'], '方法は how。'),
        F('How (   ) books do you have?', 'many', ['much', 'long', 'old'], '数は how many。'),
        F('How (   ) is this T-shirt? — It\'s 2,000 yen.', 'much', ['many', 'old', 'long'], '値段は how much。'),
        F('(   ) time is it? — It\'s ten.', 'What', ['Which', 'How', 'When'], '時刻は what time。'),
        F('(   ) do you like, dogs or cats?', 'Which', ['What', 'Who', 'Where'], 'どちらは which。'),
        F('How (   ) is your brother? — He\'s fifteen.', 'old', ['many', 'much', 'tall'], '年れいは how old。'),
        F('(   ) do you like summer? — Because I like swimming.', 'Why', ['What', 'How', 'When'], '理由は why。'),
        F('What (   ) does Ken play? — He plays the guitar.', 'instrument', ['color', 'time', 'sport'], '楽器は instrument。'),
    ])

    R.area('現在進行形', S2, [
        F('I am (   ) a letter now.', 'writing', ['write', 'writes', 'wrote'], 'be ＋ ～ing。write は e をとって ing。'),
        F('They (   ) playing soccer.', 'are', ['is', 'do', 'am'], 'they は are。'),
        F('She is (   ) in the pool.', 'swimming', ['swiming', 'swim', 'swims'], 'swim → swimming（m を重ねる）'),
        F('(   ) you listening to music?', 'Are', ['Do', 'Is', 'Does'], '進行形の疑問は be動詞を前に。'),
        F('He is not (   ) TV.', 'watching', ['watch', 'watches', 'watched'], 'is not ＋ ～ing。'),
        U('「What are you doing?」の意味は？', None, '何をしているの？', ['何をするのがすき？', '何をしたの？', '何をするつもり？'], 'What are you doing? ＝ 今何をしている？'),
        Q('k', '「run」の ing 形は？', 'running', ['runing', 'runnning', 'runs'], 'run → running'),
        Q('k', '「make」の ing 形は？', 'making', ['makeing', 'makking', 'maked'], 'e をとって ing。'),
        F('Look! The bird (   ) flying.', 'is', ['are', 'does', 'am'], 'the bird は is。'),
        U('進行形にしないのがふつうの動詞は？', None, 'know', ['play', 'run', 'cook'], 'know・like など状態の動詞は進行形にしない。'),
        F('Ken (   ) studying in his room now.', 'is', ['are', 'do', 'does'], 'Ken は is。'),
        Q('k', '「sit」の ing 形は？', 'sitting', ['siting', 'sitteing', 'sits'], 'sit → sitting'),
    ])

    R.area('can と命令文', S2, [
        F('My brother can (   ) fast.', 'run', ['runs', 'running', 'ran'], 'can ＋ 動詞の元の形。'),
        F('(   ) you play the piano? — No, I can\'t.', 'Can', ['Do', 'Are', 'Does'], 'Can を主語の前に。'),
        F('I (   ) swim well.', 'can\'t', ['don\'t can', 'am not', 'not can'], '否定は can\'t / cannot。'),
        F('(   ) I use your pen? — Sure.', 'Can', ['Do', 'Am', 'Does'], 'Can I ～? ＝ ～してもいい？'),
        F('(   ) quiet in the library.', 'Be', ['Are', 'Is', 'Do'], 'be動詞の命令文は Be ～.'),
        F('(   ) run in the classroom.', 'Don\'t', ['Not', 'No', 'Aren\'t'], '否定の命令文は Don\'t ～.'),
        F('(   ) play tennis after school.', 'Let\'s', ['Let', 'Lets', 'We\'re'], 'Let\'s ～. ＝ ～しよう'),
        U('「Can you help me?」の意味は？', None, '手伝ってくれる？', ['手伝ってもいい？', '手伝える？（能力）だけ', '手伝った？'], 'Can you ～? は「～してくれる？」の依頼にも使う。'),
        F('Please (   ) the window.', 'open', ['opens', 'opening', 'to open'], '命令文は動詞の元の形で始める。'),
        F('She can (   ) Chinese.', 'speak', ['speaks', 'speaking', 'spoke'], 'can のあとは元の形。'),
        U('「Can she ski?」に「いいえ」と答えると？', None, 'No, she can\'t.', ['No, she doesn\'t.', 'No, she isn\'t.', 'No, she cannot ski is.'], 'Can ～? → can で答える。'),
        F('(   ) careful!', 'Be', ['Do', 'Is', 'Are'], 'Be careful! ＝ 気をつけて！'),
    ])

    R.area('過去形', S2, [
        F('I (   ) to Hokkaido last summer.', 'went', ['go', 'goes', 'going'], 'last summer なので過去形。'),
        F('(   ) you watch the game yesterday?', 'Did', ['Do', 'Were', 'Does'], '一般動詞の過去の疑問は Did。'),
        F('He didn\'t (   ) breakfast.', 'eat', ['ate', 'eats', 'eating'], 'didn\'t のあとは元の形。'),
        F('We (   ) in the park an hour ago.', 'were', ['was', 'are', 'did'], 'we の過去は were。'),
        F('I (   ) tired yesterday.', 'was', ['were', 'am', 'did'], 'I の過去は was。'),
        Q('k', '「study」の過去形は？', 'studied', ['studyed', 'studid', 'studies'], '子音字＋y は ied。'),
        Q('k', '「stop」の過去形は？', 'stopped', ['stoped', 'stopt', 'stops'], 'p を重ねて ed。'),
        Q('k', '「come」の過去形は？', 'came', ['comed', 'come', 'comes'], 'come → came'),
        Q('k', '「write」の過去形は？', 'wrote', ['writed', 'written', 'writes'], 'write → wrote'),
        F('What (   ) you doing at seven last night?', 'were', ['did', 'are', 'was'], '過去進行形 were ＋ ～ing。'),
        F('There (   ) a lot of people at the station yesterday.', 'were', ['was', 'is', 'are'], '複数・過去なので were。'),
        U('「Did you enjoy the party?」に「はい」と答えると？', None, 'Yes, I did.', ['Yes, I do.', 'Yes, I was.', 'Yes, I enjoyed.'], 'Did ～? → did で答える。'),
    ], lesson=[
        ('一般動詞の過去', 'ふつうは ed、不規則動詞は形が変わる。否定・疑問は did を使い、動詞は元の形。', 'Did you go? — Yes, I did.'),
        ('be動詞の過去', 'am / is → was、are → were。', 'I was busy.'),
    ])

    R.area('中1の まとめ', S2, [
        F('(   ) did you go last Sunday? — To the zoo.', 'Where', ['When', 'What', 'Who'], '場所は where。'),
        F('Ken was (   ) a book then.', 'reading', ['read', 'reads', 'to read'], '過去進行形。'),
        F('She (   ) her room every day.', 'cleans', ['clean', 'cleaning', 'is clean'], '3単現。'),
        F('There (   ) two cats under the table.', 'are', ['is', 'be', 'am'], '複数なので are。'),
        F('How (   ) water do you need?', 'much', ['many', 'long', 'old'], '数えられない量は how much。'),
        Q('k', '「take」の過去形は？', 'took', ['taked', 'taken', 'takes'], 'take → took'),
        F('Don\'t (   ) late.', 'be', ['are', 'is', 'being'], 'Don\'t be late. ＝ おくれないで'),
        F('I (   ) my homework last night.', 'did', ['do', 'does', 'done'], 'do → did'),
        F('Can your sister (   )?', 'skate', ['skates', 'skating', 'skated'], 'can ＋ 元の形。'),
        U('「How many students are there in your class?」に合う答えは？', None, 'There are thirty.', ['It is thirty.', 'They are students.', 'Yes, there are.'], 'There are ～. で数を答える。'),
    ], boss=True)


# ------------------------------------------------------------------ 中2
def j2(R):
    S1 = '未来・助動詞・不定詞'
    S2 = '接続詞・比較・受け身'
    R.area('未来の表現', S1, [
        F('I (   ) visit my uncle tomorrow.', 'will', ['am', 'did', 'was'], '未来は will ＋ 元の形。'),
        F('It will (   ) rainy tomorrow.', 'be', ['is', 'are', 'being'], 'will のあとは be。'),
        F('I\'m going (   ) play tennis this afternoon.', 'to', ['for', 'at', 'will'], 'be going to ＋ 元の形。'),
        F('(   ) you going to watch the movie?', 'Are', ['Do', 'Will', 'Did'], 'be going to の疑問は be動詞を前に。'),
        F('She (   ) not come to the party.', 'will', ['is', 'does', 'did'], 'will not（won\'t）。'),
        Q('k', '「will not」の短縮形は？', 'won\'t', ['willn\'t', 'wo\'nt', 'wont\'t'], 'will not → won\'t'),
        U('「Will it be sunny tomorrow?」に「いいえ」と答えると？', None, 'No, it won\'t.', ['No, it isn\'t.', 'No, it doesn\'t.', 'No, it willn\'t.'], 'Will ～? → won\'t。'),
        F('What are you going to (   ) this weekend?', 'do', ['does', 'doing', 'did'], 'to のあとは元の形。'),
        F('He is going to (   ) a new bike.', 'buy', ['buys', 'bought', 'buying'], 'to ＋ 元の形。'),
        F('I (   ) be fourteen next month.', 'will', ['am', 'was', 'can'], '未来の年れい。'),
        U('「next year」と使う文として正しいのは？', None, 'I will go to Canada next year.', ['I went to Canada next year.', 'I go to Canada last year.', 'I am going Canada next year.'], 'next ～ は未来の文。'),
        F('They are going (   ) the park tomorrow.', 'to visit', ['visit', 'visiting', 'visited'], 'be going to ＋ 元の形。'),
    ])

    R.area('助動詞', S1, [
        F('You (   ) do your homework.', 'must', ['must to', 'have', 'are'], 'must ＝ ～しなければならない'),
        F('I have (   ) get up early tomorrow.', 'to', ['for', 'must', 'at'], 'have to ＝ ～しなければならない'),
        F('She (   ) to wash the dishes.', 'has', ['have', 'must', 'is'], '3単現は has to。'),
        F('You (   ) not swim here.', 'must', ['have', 'don\'t', 'are'], 'must not ＝ ～してはいけない'),
        F('You don\'t (   ) to hurry.', 'have', ['must', 'has', 'are'], 'don\'t have to ＝ ～しなくてよい'),
        F('You (   ) see a doctor.', 'should', ['should to', 'are', 'has'], 'should ＝ ～したほうがよい'),
        F('(   ) I open the window? — Yes, please.', 'Shall', ['Will', 'Must', 'Do'], 'Shall I ～? ＝ ～しましょうか'),
        F('(   ) you help me? — Sure.', 'Will', ['Shall', 'Must', 'Should'], 'Will you ～? ＝ ～してくれませんか'),
        F('(   ) I use your dictionary? — Of course.', 'May', ['Must', 'Shall', 'Should'], 'May I ～? ＝ ～してもよいですか'),
        U('「must not」と「don\'t have to」の意味のちがいで正しいのは？', None, 'must not は禁止、don\'t have to は不必要', ['どちらも禁止', 'どちらも不必要', 'must not は不必要、don\'t have to は禁止'], '意味がまったくちがう。'),
        F('(   ) we go shopping? — Yes, let\'s.', 'Shall', ['Will', 'May', 'Must'], 'Shall we ～? ＝ ～しませんか'),
        F('He had (   ) stay home yesterday.', 'to', ['for', 'must', 'have'], '過去は had to。'),
    ])

    R.area('不定詞', S1, [
        F('I want (   ) a doctor.', 'to be', ['be', 'being', 'to being'], 'want to ～ ＝ ～したい'),
        F('I went to the library (   ) study.', 'to', ['for', 'by', 'and'], '目的「～するために」は to ＋ 元の形。'),
        F('I have a lot of homework (   ) do.', 'to', ['for', 'doing', 'with'], '形容詞的用法「～するべき」。'),
        F('I\'m happy (   ) see you.', 'to', ['for', 'at', 'and'], '感情の原因「～して」。'),
        F('She likes (   ) pictures.', 'to draw', ['draw', 'draws', 'drew'], 'like to ～ ＝ ～するのが好き'),
        U('「I need something to drink.」の意味は？', None, '何か飲むものが必要だ。', ['何か飲みたい。', '飲むのが必要だ。', '何かを飲んだ。'], 'something to drink ＝ 飲むもの'),
        U('「He got up early to catch the first train.」の to の用法は？', None, '目的（～するために）', ['名詞的（～すること）', '形容詞的（～するべき）', '原因（～して）'], '副詞的用法の目的。'),
        F('I decided (   ) abroad.', 'to study', ['study', 'studying', 'studied'], 'decide to ～ ＝ ～しようと決める'),
        F('My dream is (   ) a pilot.', 'to become', ['become', 'became', 'becomes'], '「～になること」は to become。'),
        F('There are many places (   ) in Kyoto.', 'to visit', ['visit', 'visited', 'visits'], '「訪れるべき場所」。'),
        F('He hopes (   ) you again.', 'to see', ['see', 'seeing', 'saw'], 'hope to ～'),
        F('I was surprised (   ) the news.', 'to hear', ['hear', 'hearing', 'heard'], '感情の原因。'),
    ], lesson=[
        ('不定詞の3つの用法', 'to ＋ 動詞の元の形。名詞的「～すること」、副詞的「～するために／～して」、形容詞的「～するための」。', 'I want to go. / I came to see you. / time to go'),
    ])

    R.area('動名詞', S1, [
        F('I enjoyed (   ) with you.', 'talking', ['to talk', 'talk', 'talked'], 'enjoy のあとは ～ing。'),
        F('He finished (   ) the book.', 'reading', ['to read', 'read', 'reads'], 'finish のあとは ～ing。'),
        F('(   ) English is fun.', 'Learning', ['Learn', 'Learns', 'Learned'], '動名詞が主語「～すること」。'),
        F('Thank you for (   ) me.', 'helping', ['help', 'to help', 'helped'], '前置詞のあとは ～ing。'),
        F('She is good at (   ).', 'singing', ['sing', 'to sing', 'sings'], 'be good at ～ing。'),
        F('Stop (   ) and listen.', 'talking', ['to talking', 'talk', 'talked'], 'stop ～ing ＝ ～するのをやめる'),
        U('ふつう不定詞（to ～）だけを目的語にとる動詞は？', None, 'want', ['enjoy', 'finish', 'stop'], 'want / hope / decide は to ～。'),
        U('ふつう動名詞（～ing）だけを目的語にとる動詞は？', None, 'enjoy', ['want', 'hope', 'decide'], 'enjoy / finish / stop は ～ing。'),
        F('How about (   ) to the movies?', 'going', ['go', 'to go', 'went'], 'How about ～ing? ＝ ～するのはどう？'),
        F('I like (   ) soccer.', 'playing', ['play', 'plays', 'played'], 'like は to ～も ～ing も OK。'),
        F('My hobby is (   ) stamps.', 'collecting', ['collect', 'collects', 'collected'], '「集めること」。'),
        F('Without (   ) anything, he left.', 'saying', ['say', 'to say', 'said'], '前置詞のあとは ～ing。'),
    ])

    R.area('未来・助動詞・不定詞の まとめ', S1, [
        F('You (   ) be quiet in the library.', 'must', ['must to', 'have', 'will to'], 'must ＋ 元の形。'),
        F('I\'m going (   ) my grandmother next week.', 'to visit', ['visit', 'visiting', 'visited'], 'be going to。'),
        F('I hope (   ) a good time.', 'to have', ['have', 'having', 'had'], 'hope to ～。'),
        F('We enjoyed (   ) in the sea.', 'swimming', ['to swim', 'swim', 'swam'], 'enjoy ～ing。'),
        F('(   ) I carry your bag?', 'Shall', ['Will', 'Must', 'Am'], '申し出の Shall I ～?'),
        F('She doesn\'t have (   ) cook today.', 'to', ['for', 'must', 'at'], 'don\'t have to。'),
        F('I have nothing (   ) today.', 'to do', ['do', 'doing', 'did'], 'nothing to do ＝ することがない'),
        F('It will (   ) cold tonight.', 'be', ['is', 'being', 'are'], 'will be。'),
        F('He stopped (   ) TV and went to bed.', 'watching', ['to watch', 'watch', 'watched'], 'stop ～ing。'),
        F('You (   ) eat more vegetables.', 'should', ['should to', 'have', 'are'], 'should ＋ 元の形。'),
    ], boss=True)

    R.area('接続詞', S2, [
        F('I was watching TV (   ) my mother came home.', 'when', ['if', 'because', 'but'], '「～したとき」は when。'),
        F('(   ) it rains tomorrow, I\'ll stay home.', 'If', ['When', 'Because', 'That'], '「もし～なら」は if。'),
        F('I stayed home (   ) I had a cold.', 'because', ['if', 'but', 'so'], '理由は because。'),
        F('I think (   ) he is right.', 'that', ['what', 'if', 'and'], 'I think that ～ ＝ ～だと思う'),
        F('I was tired, (   ) I went to bed early.', 'so', ['because', 'but', 'or'], '結果は so。'),
        F('Hurry up, (   ) you\'ll be late.', 'or', ['and', 'so', 'if'], '命令文, or ～ ＝ さもないと'),
        F('If it (   ) sunny tomorrow, we will go hiking.', 'is', ['will be', 'was', 'be'], 'if の中は未来でも現在形。'),
        F('I like tea, (   ) my sister likes coffee.', 'but', ['so', 'or', 'because'], '反対の内容は but。'),
        U('「I know that she is busy.」の that の役わりは？', None, '「～ということ」をつなぐ', ['「あの」', '「あれ」', '「それほど」'], '接続詞の that（省略できる）。'),
        F('Study hard, (   ) you will pass the test.', 'and', ['or', 'but', 'so'], '命令文, and ～ ＝ そうすれば'),
        F('Wash your hands (   ) you eat.（食べる前に）', 'before', ['after', 'because', 'if'], '「食べる前に」。'),
        F('I didn\'t go out (   ) it was very cold.', 'because', ['so', 'and', 'if'], '理由。'),
    ])

    R.area('比較', S2, [
        F('Ken is (   ) than Tom.', 'taller', ['tall', 'tallest', 'more tall'], '比較級 ＋ than。'),
        F('This is the (   ) mountain in Japan.', 'highest', ['higher', 'high', 'most high'], '最上級 the ～est。'),
        F('This book is (   ) interesting than that one.', 'more', ['most', 'much', 'very'], '長い語は more ～。'),
        F('She is as (   ) as her mother.', 'tall', ['taller', 'tallest', 'more tall'], 'as ～ as はもとの形。'),
        Q('k', '「good」の比較級は？', 'better', ['gooder', 'more good', 'best'], 'good → better → best'),
        Q('k', '「big」の比較級は？', 'bigger', ['biger', 'more big', 'biggest'], 'g を重ねる。'),
        Q('k', '「easy」の最上級は？', 'easiest', ['easyest', 'most easy', 'easier'], 'y を i にして est。'),
        F('Which do you like (   ), summer or winter?', 'better', ['good', 'best', 'well'], '2つでは better。'),
        F('He is the fastest runner (   ) the five.', 'of', ['in', 'than', 'at'], '複数を表す語の前は of。'),
        F('Tokyo is the largest city (   ) Japan.', 'in', ['of', 'than', 'on'], '場所・範囲の前は in。'),
        F('My bag is not as heavy (   ) yours.', 'as', ['than', 'so', 'like'], 'not as ～ as ＝ ～ほど…ない'),
        F('This is the (   ) beautiful picture of all.', 'most', ['more', 'very', 'much'], '長い語の最上級は most。'),
    ], lesson=[
        ('比較級と最上級', '2つをくらべて「より～」は ～er than、3つ以上で「いちばん～」は the ～est。長い語は more / most。', 'taller than / the tallest'),
        ('as ～ as', '「同じくらい～」。否定は「～ほど…ない」。', 'as tall as / not as tall as'),
    ])

    R.area('受け身', S2, [
        F('English is (   ) in many countries.', 'spoken', ['speak', 'spoke', 'speaking'], 'be ＋ 過去分詞。'),
        F('This room is cleaned (   ) Ken every day.', 'by', ['of', 'with', 'for'], '「～によって」は by。'),
        F('The temple was (   ) 500 years ago.', 'built', ['build', 'builds', 'building'], 'build → built'),
        F('These pictures (   ) taken in Kyoto.', 'were', ['was', 'are be', 'did'], '複数・過去は were。'),
        F('(   ) this song sung by many people?', 'Is', ['Does', 'Do', 'Are'], '受け身の疑問は be動詞を前に。'),
        F('The window was not (   ) by me.', 'broken', ['break', 'broke', 'breaking'], 'break → broken'),
        Q('k', '「write」の過去分詞は？', 'written', ['wrote', 'writed', 'writing'], 'write - wrote - written'),
        Q('k', '「make」の過去分詞は？', 'made', ['maked', 'make', 'making'], 'make - made - made'),
        F('The mountain is covered (   ) snow.', 'with', ['by', 'of', 'in'], 'be covered with ～ ＝ ～でおおわれている'),
        F('He is known (   ) everyone.', 'to', ['by', 'for', 'with'], 'be known to ～ ＝ ～に知られている'),
        U('「This car was made in Japan.」の意味は？', None, 'この車は日本で作られた。', ['この車は日本で作る。', 'この車は日本で売っている。', 'この車は日本に行った。'], '受け身の過去。'),
        F('Many stars can (   ) seen tonight.', 'be', ['are', 'is', 'been'], '助動詞 ＋ be ＋ 過去分詞。'),
    ])

    R.area('いろいろな文型', S2, [
        F('You look (   ) today.', 'happy', ['happily', 'happiness', 'to happy'], 'look ＋ 形容詞 ＝ ～に見える'),
        F('He became (   ) teacher.', 'a', ['to', 'for', 'as to'], 'become ＋ 名詞。'),
        F('My father gave (   ) a watch.', 'me', ['my', 'I', 'mine'], 'give 人 物。'),
        F('I\'ll show the picture (   ) you.', 'to', ['for', 'at', 'with'], 'show 物 to 人。'),
        F('My mother made a cake (   ) me.', 'for', ['to', 'at', 'by'], 'make 物 for 人。'),
        F('We call (   ) Kenny.', 'him', ['he', 'his', 'he is'], 'call A B ＝ A を B と呼ぶ'),
        F('The news made us (   ).', 'sad', ['sadly', 'sadness', 'to sad'], 'make A B ＝ A を B にする'),
        F('There (   ) a big tree in the park.', 'is', ['are', 'be', 'has'], '1本なので is。'),
        F('It sounds (   ).', 'interesting', ['interestingly', 'interest', 'to interest'], 'sound ＋ 形容詞。'),
        U('「Please tell me the way to the station.」の文型は？', None, 'S V O O', ['S V C', 'S V O C', 'S V'], 'tell 人 物。'),
        F('Ms. Kato teaches (   ) English.', 'us', ['we', 'our', 'ours'], 'teach 人 物。'),
        F('Please keep the door (   ).', 'open', ['opened to', 'opening to', 'opens'], 'keep A B ＝ A を B にしておく'),
    ])

    R.area('中2の まとめ', S2, [
        F('This bridge was (   ) in 1990.', 'built', ['build', 'building', 'builds'], '受け身の過去。'),
        F('Mt. Fuji is higher (   ) any other mountain in Japan.', 'than', ['as', 'of', 'in'], '比較級 than any other ～。'),
        F('If you (   ) free tomorrow, let\'s go out.', 'are', ['will be', 'were', 'be'], 'if の中は現在形。'),
        F('I have to (   ) this report by Friday.', 'finish', ['finishes', 'finishing', 'finished'], 'have to ＋ 元の形。'),
        F('She went to Canada (   ) English.', 'to study', ['study', 'studying', 'studied'], '目的の不定詞。'),
        F('I\'m interested (   ) Japanese history.', 'in', ['at', 'of', 'with'], 'be interested in ～。'),
        F('He told (   ) an interesting story.', 'us', ['we', 'our', 'ours'], 'tell 人 物。'),
        F('Which is (   ), this or that?', 'cheaper', ['cheap', 'cheapest', 'more cheap'], '2つは比較級。'),
        F('Thank you for (   ) me.', 'inviting', ['invite', 'to invite', 'invited'], '前置詞のあと。'),
        F('I think (   ) English is useful.', 'that', ['what', 'who', 'it'], 'think that ～。'),
    ], boss=True)


# ------------------------------------------------------------------ 中3
def j3(R):
    S1 = '現在完了と不定詞'
    S2 = '後置修飾と仮定法'
    R.area('現在完了（完了・経験）', S1, [
        F('I have just (   ) my homework.', 'finished', ['finish', 'finishing', 'finishes'], 'have ＋ 過去分詞。'),
        F('Have you (   ) lunch yet?', 'eaten', ['eat', 'ate', 'eating'], 'eat - ate - eaten'),
        F('I have (   ) been to Hokkaido.', 'never', ['ever', 'yet', 'already'], '経験の否定 never。'),
        F('Have you (   ) seen a koala?', 'ever', ['never', 'yet', 'just'], '経験の疑問 ever。'),
        F('She has (   ) left home.', 'already', ['yet', 'ever', 'since'], '肯定文「もう」は already。'),
        F('I haven\'t read the book (   ).', 'yet', ['already', 'just', 'ever'], '否定文「まだ」は yet。'),
        F('How many times have you (   ) Kyoto?', 'visited', ['visit', 'visiting', 'visits'], '回数をたずねる経験。'),
        F('I have climbed Mt. Fuji (   ).', 'twice', ['two', 'second', 'two time'], '2回は twice。'),
        U('「I have lost my key.」の意味として近いのは？', None, 'かぎをなくして、今もない。', ['かぎをなくしたことがある（今はある）。', 'かぎをさがしている。', 'かぎをなくすつもり。'], '完了・結果。'),
        F('He has (   ) to London.', 'gone', ['go', 'went', 'going'], 'has gone to ＝ 行ってしまった（今はいない）'),
        Q('k', '「see」の過去分詞は？', 'seen', ['saw', 'seed', 'seeing'], 'see - saw - seen'),
        U('現在完了とふつういっしょに使わない語は？', None, 'yesterday', ['already', 'since', 'ever'], '過去を表す語は過去形で。'),
    ], lesson=[
        ('現在完了', 'have / has ＋ 過去分詞。過去のことが今とつながっている。', 'I have finished. / I have been there.'),
        ('完了・経験・継続', 'just / already / yet、ever / never / ～ times、for / since が目印。', 'I have lived here for ten years.'),
    ])

    R.area('現在完了（継続）・現在完了進行形', S1, [
        F('I have lived here (   ) ten years.', 'for', ['since', 'from', 'during'], '期間は for。'),
        F('She has been sick (   ) last Monday.', 'since', ['for', 'from', 'ago'], '起点は since。'),
        F('How (   ) have you known him?', 'long', ['many', 'much', 'often'], '期間は How long。'),
        F('I have been (   ) for two hours.', 'studying', ['study', 'studied', 'studies'], '現在完了進行形 have been ～ing。'),
        F('It has been raining (   ) this morning.', 'since', ['for', 'ago', 'from'], '起点 since。'),
        F('We (   ) known each other since childhood.', 'have', ['are', 'has', 'were'], 'we は have。'),
        U('「He has been playing the game for three hours.」の意味は？', None, '彼は3時間ずっとゲームをしている。', ['彼は3時間前にゲームをした。', '彼は3回ゲームをした。', '彼はゲームを3時間するつもり。'], '動作の継続。'),
        F('Ken (   ) been busy since yesterday.', 'has', ['have', 'is', 'was'], 'Ken は has。'),
        U('「I have known her for five years.」の known が進行形にならない理由は？', None, 'know は状態を表す動詞だから', ['know は不規則動詞だから', 'five years が短いから', 'her があるから'], '状態動詞は継続の現在完了で。'),
        F('How long (   ) she been waiting?', 'has', ['have', 'is', 'did'], 'she は has。'),
        F('I have wanted this bag (   ) a long time.', 'for', ['since', 'during', 'ago'], 'for a long time ＝ 長い間'),
        F('They have been friends (   ) 2020.', 'since', ['for', 'in', 'from'], '起点 since。'),
    ])

    R.area('不定詞の発展', S1, [
        F('It is important (   ) us to study every day.', 'for', ['of', 'to', 'by'], 'It is ～ for 人 to …。'),
        F('It is difficult for me (   ) this question.', 'to answer', ['answer', 'answering', 'answered'], 'It is ～ for 人 to …。'),
        F('I want you (   ) me.', 'to help', ['help', 'helping', 'helped'], 'want 人 to ～ ＝ 人に～してほしい'),
        F('My mother told me (   ) my room.', 'to clean', ['clean', 'cleaning', 'cleaned'], 'tell 人 to ～ ＝ 人に～するように言う'),
        F('Please ask him (   ) me back.', 'to call', ['call', 'calling', 'called'], 'ask 人 to ～ ＝ 人に～するよう頼む'),
        F('I don\'t know (   ) to do.', 'what', ['how', 'where', 'when'], 'what to do ＝ 何をすべきか'),
        F('Do you know how (   ) this machine?', 'to use', ['use', 'using', 'used'], 'how to ～ ＝ ～のしかた'),
        F('This box is too heavy (   ) carry.', 'to', ['for', 'that', 'so'], 'too ～ to … ＝ ～すぎて…できない'),
        F('He is old enough (   ) drive a car.', 'to', ['for', 'that', 'so'], '～ enough to … ＝ …するのに十分～'),
        F('Tell me where (   ) the bus.', 'to get on', ['get on', 'getting on', 'got on'], 'where to ～ ＝ どこで～すべきか'),
        F('Let me (   ) myself.', 'introduce', ['to introduce', 'introducing', 'introduced'], 'let 人 ＋ 元の形。'),
        F('My sister helped me (   ) dinner.', 'cook', ['cooking', 'cooked', 'cooks'], 'help 人 ＋ 元の形（to ～も可）。'),
    ])

    R.area('間接疑問', S1, [
        F('I don\'t know where he (   ).', 'lives', ['does live', 'live', 'living'], '間接疑問は「疑問詞 ＋ 主語 ＋ 動詞」。'),
        F('Do you know what time it (   )?', 'is', ['does', 'be', 'it is is'], '主語 ＋ 動詞の順。'),
        F('Tell me what you (   ) yesterday.', 'did', ['do you', 'did you', 'does'], '過去の内容は過去形。'),
        U('正しい文は？', None, 'I know who she is.', ['I know who is she.', 'I know who does she.', 'I know she who is.'], '疑問詞 ＋ 主語 ＋ 動詞。'),
        F('Can you tell me how old your brother (   )?', 'is', ['does', 'are', 'be'], 'your brother is の順。'),
        F('I wonder why she (   ) angry.', 'is', ['does', 'do', 'be'], '疑問詞 ＋ 主語 ＋ 動詞。'),
        F('Do you know when the party (   ) start?', 'will', ['does', 'do', 'is'], '未来の内容は will。'),
        F('I don\'t know (   ) he will come or not.', 'if', ['that', 'what', 'who'], '「～かどうか」は if / whether。'),
        U('「Where is the station?」を「わたしは駅がどこか知らない」にすると？', None, 'I don\'t know where the station is.', ['I don\'t know where is the station.', 'I don\'t know the station where.', 'I don\'t know where does the station.'], '主語 ＋ 動詞の順に。'),
        F('Please tell me which bus (   ) to the museum.', 'goes', ['does go', 'go', 'going'], 'which bus が主語。'),
        F('I asked him what he (   ) to eat.', 'wanted', ['want', 'did want', 'wants to'], '時制を合わせる。'),
        F('She knows how many books I (   ).', 'have', ['do have', 'having', 'has'], '主語 I ＋ have。'),
    ])

    R.area('現在完了と不定詞の まとめ', S1, [
        F('I have (   ) this movie three times.', 'seen', ['saw', 'see', 'seeing'], '経験。'),
        F('It is fun (   ) play games with friends.', 'to', ['for', 'that', 'of'], 'It is ～ to …。'),
        F('I want him (   ) here.', 'to come', ['come', 'coming', 'came'], 'want 人 to ～。'),
        F('Do you know who (   ) this picture?', 'drew', ['did draw', 'draws to', 'drawing'], 'who が主語のときは 疑問詞 ＋ 動詞。'),
        F('She has lived in Osaka (   ) she was born.', 'since', ['for', 'when', 'ago'], 'since ＋ 文。'),
        F('I didn\'t know (   ) to say.', 'what', ['how', 'that', 'it'], 'what to say。'),
        F('He has (   ) finished his work.', 'already', ['yet', 'ever', 'since'], '肯定文の already。'),
        F('It\'s too cold (   ) swim today.', 'to', ['for', 'so', 'that'], 'too ～ to …。'),
        F('How long have you (   ) English?', 'studied', ['study', 'studying to', 'studies'], '継続。'),
        F('I\'ll show you how (   ) origami.', 'to make', ['make', 'making', 'made'], 'how to ～。'),
    ], boss=True)

    R.area('分詞の後置修飾', S2, [
        F('Look at the boy (   ) under the tree.', 'sitting', ['sat', 'sits', 'to sit'], '「～している」は ～ing。'),
        F('This is a car (   ) in Germany.', 'made', ['making', 'make', 'makes'], '「～された」は過去分詞。'),
        F('The girl (   ) with Ken is my sister.', 'talking', ['talked', 'talks', 'to talk'], '進行の意味は ～ing。'),
        F('I have a friend (   ) in Canada.', 'living', ['lived', 'lives', 'live'], '「住んでいる」は living。'),
        F('English is a language (   ) all over the world.', 'spoken', ['speaking', 'spoke', 'speaks'], '「話される」は spoken。'),
        F('Do you know the man (   ) the guitar?', 'playing', ['played', 'plays', 'play'], '「ひいている」。'),
        F('I read a book (   ) by Natsume Soseki.', 'written', ['writing', 'wrote', 'writes'], '「書かれた」。'),
        U('「the broken window」の意味は？', None, 'われた窓', ['窓をわること', '窓をわっている人', 'われそうな窓'], '過去分詞が前から修飾。'),
        U('「a sleeping baby」の意味は？', None, 'ねむっている赤ちゃん', ['ねむらされた赤ちゃん', 'ねむるための赤ちゃん', 'ねむい赤ちゃん'], '現在分詞が前から修飾。'),
        F('The pictures (   ) by him are beautiful.', 'taken', ['taking', 'took', 'takes'], '「とられた写真」。'),
        F('Who is the woman (   ) a red hat?', 'wearing', ['wore', 'worn', 'wears'], '「かぶっている」。'),
        F('This is the temple (   ) 1,000 years ago.', 'built', ['building', 'builds', 'build'], '「建てられた」。'),
    ])

    R.area('関係代名詞', S2, [
        F('I have a friend (   ) lives in Kobe.', 'who', ['which', 'whose', 'what'], '人が先行詞の主格は who。'),
        F('This is the bus (   ) goes to the airport.', 'which', ['who', 'whom', 'what'], 'もの・動物は which。'),
        F('The cake (   ) my mother made was delicious.', 'that', ['who', 'what', 'whose'], '目的格は that / which（省略できる）。'),
        F('He is the boy (   ) won the race.', 'who', ['which', 'what', 'where'], '人 ＋ who。'),
        F('The book (   ) I bought yesterday is interesting.', 'which', ['who', 'what', 'where'], 'もの ＋ which。'),
        U('関係代名詞を省略できるのは？', None, '目的格のとき', ['主格のとき', 'いつでも', '先行詞が人のとき'], '目的格は省略できる。'),
        U('「The girl I met yesterday is Mika.」の意味は？', None, 'わたしがきのう会った女の子はミカです。', ['きのうミカに会った。', 'ミカはきのう女の子に会った。', 'ミカはきのう会った。'], 'The girl (that) I met'),
        F('I know a girl (   ) can speak four languages.', 'who', ['which', 'whose', 'she'], '主格の who。'),
        F('Is there anything (   ) I can do for you?', 'that', ['who', 'what', 'whose'], 'anything の後は that が多い。'),
        F('The dog (   ) is running there is mine.', 'which', ['who', 'whom', 'what'], '動物 ＋ which。'),
        F('This is the best movie (   ) I have ever seen.', 'that', ['who', 'what', 'whose'], '最上級のあとは that が多い。'),
        F('The people (   ) work here are kind.', 'who', ['which', 'whose', 'what'], 'people ＋ who。'),
    ], lesson=[
        ('関係代名詞', '名詞（先行詞）のあとに文をつけて説明する。人 → who、もの → which、どちらも → that。', 'a friend who lives in Kobe'),
        ('目的格の省略', '「名詞 ＋ 主語 ＋ 動詞」なら that / which を省略できる。', 'the book (that) I bought'),
    ])

    R.area('仮定法', S2, [
        F('I wish I (   ) a cat.', 'had', ['have', 'has', 'will have'], '現実とちがう願い：I wish ＋ 過去形。'),
        F('If I (   ) you, I would ask him.', 'were', ['am', 'was being', 'be'], '仮定法では be動詞は were がふつう。'),
        F('If I had a lot of money, I (   ) buy a house.', 'would', ['will', 'can', 'am'], '仮定法は would ＋ 元の形。'),
        F('I wish I (   ) fly like a bird.', 'could', ['can', 'will', 'am'], 'can → could。'),
        U('「If I were a bird, I could fly to you.」の意味は？', None, 'もし鳥なら、あなたのところへ飛んで行けるのに。', ['鳥だったので飛んで行った。', '鳥になって飛んで行く。', '鳥は飛べる。'], '現実ではないことの仮定。'),
        F('If it (   ) sunny tomorrow, we will go out.', 'is', ['were', 'would be', 'was'], 'これは実際にありうる条件なので現在形。'),
        F('I wish you (   ) here.', 'were', ['are', 'be', 'will be'], 'I wish ＋ were。'),
        F('If I knew her number, I (   ) call her.', 'could', ['can', 'will', 'am'], 'could ＋ 元の形。'),
        U('仮定法の文として正しいのは？', None, 'If I were rich, I would travel.', ['If I am rich, I would travel.', 'If I were rich, I will travel.', 'If I was rich, I can travel.'], 'were ～, would ～。'),
        F('What (   ) you do if you were a teacher?', 'would', ['will', 'do', 'did'], '仮定法の疑問。'),
        U('「I wish I were taller.」の意味は？', None, 'もっと背が高ければいいのに。', ['背が高くなった。', '背が高い。', '背が高くなるつもり。'], '現実は背が高くない。'),
        F('If he (   ) more time, he would help us.', 'had', ['has', 'have', 'will have'], 'if ＋ 過去形。'),
    ])

    R.area('会話表現と読み取り', S2, [
        U('「Would you like some tea?」への答えとして合うのは？', None, 'Yes, please.', ['Yes, I would like.', 'No, I wouldn\'t like.', 'You\'re welcome.'], 'すすめられたら Yes, please. / No, thank you.'),
        U('「May I help you?」は、どんな場面で言う？', None, 'お店で店員が客に', ['客が店員に', '先生が生徒に名前を聞く', '電話を切るとき'], 'いらっしゃいませ・何かおさがしですか。'),
        U('「Why don\'t we go to the park?」の意味は？', None, '公園に行かない？（さそい）', ['なぜ公園に行かないの？', '公園には行かない。', '公園に行ったのはなぜ？'], 'Why don\'t we ～? ＝ ～しませんか'),
        U('「Could you say that again?」の意味は？', None, 'もう一度言っていただけますか。', ['それを言えますか。', 'また言ったのですか。', 'それはだれが言った？'], 'Could you ～? ＝ ていねいな依頼'),
        U('「That\'s too bad.」はどんなときに言う？', None, '相手に悪いことがあったとき', ['うれしいとき', 'お礼を言うとき', 'あいさつのとき'], 'お気の毒に。'),
        U('電話で「ケンをお願いします」は？', None, 'May I speak to Ken?', ['Are you Ken?', 'I am Ken.', 'Where is Ken?'], 'May I speak to ～?'),
        U('「Hold on, please.」の意味は？（電話）', None, '少々お待ちください。', ['切ってください。', 'もう一度かけてください。', 'お元気で。'], '電話の表現。'),
        U('「How about you?」の意味は？', None, 'あなたはどう？', ['あなたはだれ？', 'どうやって？', 'いくら？'], '相手にも同じことをたずねる。'),
        Q('u', '「Ken got up late. He missed the bus. So he walked to school.」ケンはどうやって学校に行った？', '歩いて', ['バスで', '自転車で', '車で'], 'So he walked to school. とある。', s='Ken got up late. He missed the bus. So he walked to school.'),
        Q('u', '「Mai likes music. She plays the flute in the brass band. She practices every day.」マイは毎日何をしている？', 'フルートの練習', ['ピアノの練習', '歌の練習', '絵をかく'], 'plays the flute / practices every day。', s='Mai likes music. She plays the flute in the brass band. She practices every day.'),
        Q('u', '「It was rainy this morning, but it is sunny now.」今の天気は？', '晴れ', ['雨', 'くもり', '雪'], 'but のあとが今のようす。', s='It was rainy this morning, but it is sunny now.'),
        Q('u', '「Tom has a sister. She is two years older than Tom. Tom is thirteen.」姉は何さい？', '15さい', ['11さい', '13さい', '2さい'], '13 + 2 = 15。', s='Tom has a sister. She is two years older than Tom. Tom is thirteen.'),
    ])

    R.area('中学英語の まとめ', S2, [
        F('The man (   ) is standing there is my uncle.', 'who', ['which', 'whose', 'what'], '人 ＋ who。'),
        F('If I (   ) a car, I would drive to the sea.', 'had', ['have', 'has', 'will have'], '仮定法。'),
        F('Look at the cat (   ) on the bed.', 'sleeping', ['slept', 'sleeps', 'to sleep'], '～している。'),
        F('I have been (   ) for you for an hour.', 'waiting', ['wait', 'waited', 'to wait'], '現在完了進行形。'),
        F('Do you know where she (   ) from?', 'is', ['does', 'do', 'be'], '間接疑問。'),
        F('This is a picture (   ) by my father.', 'painted', ['painting', 'paints', 'paint'], '「かかれた」。'),
        F('She asked me (   ) the door.', 'to close', ['close', 'closing', 'closed'], 'ask 人 to ～。'),
        F('I wish I (   ) speak French.', 'could', ['can', 'will', 'am'], 'I wish ＋ could。'),
        F('The song (   ) we sang was beautiful.', 'that', ['who', 'what', 'whose'], '目的格。'),
        F('It is necessary for you (   ) enough.', 'to sleep', ['sleep', 'sleeping', 'slept'], 'It is ～ for 人 to …。'),
    ], boss=True)
