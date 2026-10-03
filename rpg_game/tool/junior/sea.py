"""定期テストの海（英語）：中1〜中3 の文法23単元と、中学英単語の単語帳。"""
import json

from english import F, U
from lib import CAT, QDIR, ROOT, Q

UNITS = {}


def unit(uid, qs):
    assert len(qs) >= 10, (uid, len(qs))
    UNITS[uid] = qs


# ---------------- 中1
unit('sea_g1_01', [
    F('My father (   ) a doctor.', 'is', ['are', 'am', 'does'], 'my father は is。'),
    F('(   ) they your classmates? — Yes, they are.', 'Are', ['Is', 'Do', 'Does'], 'they は are。'),
    F('I (   ) not hungry now.', 'am', ['do', 'is', 'are'], 'I am not。'),
    F('Do you (   ) a computer?', 'use', ['uses', 'are', 'using'], 'Do ＋ 主語 ＋ 元の形。'),
    F('We don\'t (   ) on Sundays.', 'study', ['studies', 'are', 'studying'], 'don\'t ＋ 元の形。'),
    U('正しい文は？', None, 'Are you a student?', ['Do you a student?', 'You are a student?', 'Is you a student?'], 'be動詞の疑問文。'),
    U('正しい文は？', None, 'I don\'t like spiders.', ['I am not like spiders.', 'I not like spiders.', 'I doesn\'t like spiders.'], '一般動詞の否定。'),
    F('This (   ) not my notebook.', 'is', ['are', 'does', 'do'], 'this は is。'),
    U('「Are you busy?」に「いいえ」と答えると？', None, 'No, I\'m not.', ['No, I don\'t.', 'No, you aren\'t.', 'No, I amn\'t.'], 'Are you ～? → No, I\'m not.'),
    F('They (   ) to school by train.', 'go', ['goes', 'are', 'going'], 'they はそのまま。'),
    F('(   ) you and Ken brothers?', 'Are', ['Is', 'Am', 'Do'], 'you and Ken は複数。'),
    F('I (   ) a piano at home.', 'have', ['has', 'am', 'having'], 'I have。'),
])
unit('sea_g1_02', [
    Q('k', '「leaf」の複数形は？', 'leaves', ['leafs', 'leafes', 'leaf'], 'f → ves'),
    Q('k', '「tooth」の複数形は？', 'teeth', ['tooths', 'toothes', 'teeths'], '不規則変化。'),
    Q('k', '「potato」の複数形は？', 'potatoes', ['potatos', 'potatoies', 'potato'], 'o で終わる語の一部は es。'),
    Q('k', '「fish」の複数形は？', 'fish', ['fishes（いつも）', 'fishs', 'fishies'], '単数と同じ形がふつう。'),
    F('Is this (   ) cap? — No, it\'s not mine.', 'your', ['you', 'yours', 'you\'re'], '名詞の前は your。'),
    F('These books are (   ).', 'hers', ['her', 'she', 'she\'s'], '「彼女のもの」は hers。'),
    F('I like (   ) very much. — Who? — Ms. Brown.', 'her', ['she', 'hers', 'herself'], '動詞のあとは her。'),
    F('(   ) is a picture of my family.', 'This', ['These', 'Those', 'They'], '1枚なので This。'),
    F('Those (   ) my shoes.', 'are', ['is', 'am', 'be'], 'those は複数。'),
    F('Our teacher is kind to (   ).', 'us', ['we', 'our', 'ours'], '前置詞のあとは目的格。'),
    F('I have three (   ).', 'dictionaries', ['dictionarys', 'dictionary', 'dictionaryes'], 'y → ies'),
    F('Whose bike is that? — It\'s (   ).', 'my brother\'s', ['my brother', 'my brothers', 'brother of me'], '「兄のもの」。'),
])
unit('sea_g1_03', [
    F('My sister (   ) a new bag.', 'wants', ['want', 'is want', 'wanting'], '3単現。'),
    F('Kenta (   ) not like math.', 'does', ['do', 'is', 'isn\'t'], 'does not。'),
    F('(   ) Mr. Tanaka teach science?', 'Does', ['Do', 'Is', 'Are'], '3単現の疑問。'),
    F('She (   ) her teeth after meals.', 'brushes', ['brushs', 'brush', 'brushing'], 'sh → es'),
    F('He (   ) to bed at ten.', 'goes', ['go', 'gos', 'is go'], 'go → goes'),
    F('My cat (   ) milk every morning.', 'drinks', ['drink', 'is drink', 'drinkes'], '3単現。'),
    U('正しい文は？', None, 'Does he play the violin?', ['Does he plays the violin?', 'Do he play the violin?', 'Is he play the violin?'], 'Does ＋ 元の形。'),
    U('正しい文は？', None, 'Mika doesn\'t eat meat.', ['Mika don\'t eat meat.', 'Mika doesn\'t eats meat.', 'Mika isn\'t eat meat.'], 'doesn\'t ＋ 元の形。'),
    F('Who (   ) this room? — My mother does.', 'cleans', ['clean', 'does clean', 'cleaning'], 'who が主語なら3単現。'),
    F('What does your brother (   )? — He plays games.', 'do', ['does', 'doing', 'did'], 'What does ～ do?'),
    U('「Does your sister cook?」に「いいえ」と答えると？', None, 'No, she doesn\'t.', ['No, she don\'t.', 'No, she isn\'t.', 'No, he doesn\'t.'], 'sister → she。'),
    F('The store (   ) at nine.', 'opens', ['open', 'is open to', 'opening'], '3単現。'),
])
unit('sea_g1_04', [
    F('(   ) do you play tennis? — In the park.', 'Where', ['When', 'What', 'Who'], '場所。'),
    F('(   ) is your favorite subject? — Music.', 'What', ['Which', 'Who', 'How'], 'もの・こと。'),
    F('(   ) old is your grandfather?', 'How', ['What', 'When', 'Who'], 'How old。'),
    F('(   ) is this cap? — It\'s Ken\'s.', 'Whose', ['Who', 'What', 'Which'], '持ち主。'),
    F('How many (   ) do you have?', 'pens', ['pen', 'a pen', 'pen\'s'], 'How many ＋ 複数形。'),
    F('(   ) do you get up? — At six.', 'When', ['Where', 'What', 'Who'], '時。'),
    F('How (   ) is it today? — It\'s cloudy.', 'is the weather', ['weather', 'the weather is', 'weather is'], 'How is the weather?'),
    F('(   ) do you like better, rice or bread?', 'Which', ['What', 'Where', 'Who'], 'どちら。'),
    F('(   ) is the boy over there? — He\'s Taku.', 'Who', ['Whose', 'What', 'Where'], '人。'),
    F('What (   ) is it? — It\'s Friday.', 'day', ['date', 'time', 'month'], '曜日は What day。'),
    F('How (   ) does it take to the station? — Ten minutes.', 'long', ['many', 'much', 'far'], '時間の長さ。'),
    F('(   ) don\'t you come with us?', 'Why', ['What', 'How', 'Which'], 'Why don\'t you ～? ＝ ～したら？'),
])
unit('sea_g1_05', [
    F('Mom is (   ) dinner now.', 'making', ['makeing', 'make', 'makes'], 'e をとって ing。'),
    F('The children (   ) running in the yard.', 'are', ['is', 'do', 'be'], 'children は複数。'),
    F('Are you (   ) to the radio?', 'listening', ['listen', 'listens', 'listened'], 'be ＋ ～ing。'),
    F('I\'m not (   ) a book.', 'reading', ['read', 'reads', 'to read'], 'not ＋ ～ing。'),
    F('What is she (   )? — She is writing an e-mail.', 'doing', ['do', 'does', 'done'], 'What is ～ doing?'),
    Q('k', '「lie（横になる）」の ing 形は？', 'lying', ['lieing', 'liing', 'lies'], 'ie → ying'),
    Q('k', '「begin」の ing 形は？', 'beginning', ['begining', 'beginnig', 'begins'], 'n を重ねる。'),
    Q('k', '「dance」の ing 形は？', 'dancing', ['danceing', 'dancting', 'dances'], 'e をとる。'),
    U('進行形にできない文は？', None, 'I am having a brother.', ['I am having lunch.', 'I am playing tennis.', 'He is eating.'], '「持っている」の have は進行形にしない。'),
    U('「Is Ken studying?」に「いいえ」と答えると？', None, 'No, he isn\'t.', ['No, he doesn\'t.', 'No, he not.', 'No, Ken don\'t.'], 'be動詞で答える。'),
    F('Listen! Someone (   ) singing.', 'is', ['are', 'do', 'does'], 'someone は単数。'),
    F('Look! The sun (   ) rising.', 'is', ['are', 'does', 'has'], '進行形。'),
])
unit('sea_g1_06', [
    F('My grandmother can (   ) a bike.', 'ride', ['rides', 'riding', 'to ride'], 'can ＋ 元の形。'),
    F('(   ) you hear me? — Yes, I can.', 'Can', ['Do', 'Are', 'Will'], 'Can で答えている。'),
    F('Ken can\'t (   ) natto.', 'eat', ['eats', 'eating', 'ate'], 'can\'t ＋ 元の形。'),
    F('(   ) touch the paintings.', 'Don\'t', ['Not', 'No', 'Doesn\'t'], '否定の命令文。'),
    F('(   ) kind to animals.', 'Be', ['Are', 'Do', 'Is'], 'be動詞の命令文。'),
    F('(   ) go to the beach. — Yes, let\'s.', 'Let\'s', ['Let', 'Shall', 'Do'], 'Let\'s ～.'),
    F('Please (   ) here.', 'sit', ['sits', 'sitting', 'to sit'], '命令文は元の形。'),
    U('「Can I have some water?」の意味は？', None, '水をもらえますか。', ['水を持っていますか。', '水が飲めますか。', '水がありますか。'], 'Can I ～? ＝ ～してもいい？'),
    F('What can you (   ) well?', 'do', ['does', 'doing', 'did'], 'can ＋ 元の形。'),
    F('Who can (   ) the fastest in your class?', 'run', ['runs', 'running', 'ran'], 'can ＋ 元の形。'),
    U('「Wash your hands, Ken.」の文の種類は？', None, '命令文', ['疑問文', '否定文', '過去の文'], '動詞の元の形で始まる。'),
    F('Don\'t be (   ). — I\'m sorry.', 'late', ['lately', 'later', 'lating'], 'Don\'t be late.'),
])
unit('sea_g1_07', [
    F('I (   ) my room last Sunday.', 'cleaned', ['clean', 'cleans', 'cleaning'], '過去の時を表す語がある。'),
    F('Did she (   ) the letter?', 'write', ['wrote', 'writes', 'written'], 'Did ＋ 元の形。'),
    F('We (   ) not at home yesterday.', 'were', ['was', 'did', 'are'], 'we の過去。'),
    F('It (   ) very cold last night.', 'was', ['were', 'is', 'did'], 'it の過去。'),
    Q('k', '「teach」の過去形は？', 'taught', ['teached', 'thought', 'tought'], 'teach → taught'),
    Q('k', '「think」の過去形は？', 'thought', ['thinked', 'thank', 'taught'], 'think → thought'),
    Q('k', '「cry」の過去形は？', 'cried', ['cryed', 'cryd', 'crid'], 'y → ied'),
    Q('k', '「read」の過去形は？', 'read（発音は［red］）', ['readed', 'red（つづりも変わる）', 'reading'], 'つづりは同じ、発音が変わる。'),
    U('「Where did you go?」に合う答えは？', None, 'I went to the library.', ['I go to the library.', 'Yes, I did.', 'I was go to the library.'], '過去形で答える。'),
    F('What time (   ) you get up this morning?', 'did', ['do', 'were', 'are'], '過去の疑問 did。'),
    F('I (   ) a strange sound two hours ago.', 'heard', ['hear', 'heared', 'hears'], 'hear → heard'),
    F('They didn\'t (   ) the bus.', 'catch', ['caught', 'catches', 'catching'], 'didn\'t ＋ 元の形。'),
])
unit('sea_g1_08', [
    F('I (   ) studying when you called me.', 'was', ['were', 'am', 'did'], '過去進行形。'),
    F('They were (   ) volleyball at that time.', 'playing', ['play', 'played', 'plays'], 'were ＋ ～ing。'),
    F('(   ) you sleeping at ten last night?', 'Were', ['Did', 'Was', 'Are'], 'you の過去は were。'),
    F('There (   ) a lot of water in the bottle.', 'is', ['are', 'be', 'have'], 'water は数えられない → is。'),
    F('There (   ) some apples on the table.', 'are', ['is', 'be', 'has'], '複数。'),
    F('(   ) there a bank near here?', 'Is', ['Are', 'Does', 'Do'], 'There is の疑問。'),
    U('「Are there any parks in your town?」に「はい」と答えると？', None, 'Yes, there are.', ['Yes, they are.', 'Yes, there is.', 'Yes, it is.'], 'there で答える。'),
    F('How many students (   ) there in the gym?', 'are', ['is', 'do', 'have'], 'How many ～ are there?'),
    F('What were you (   ) then?', 'doing', ['do', 'did', 'done'], '過去進行形の疑問。'),
    F('There (   ) two tall trees here ten years ago.', 'were', ['was', 'are', 'is'], '複数・過去。'),
    F('My father was (   ) a bath when I came home.', 'taking', ['take', 'took', 'taken'], 'take a bath。'),
    U('「There is a cat under the chair.」の意味は？', None, 'いすの下にネコがいる。', ['いすの上にネコがいる。', 'ネコがいすを持っている。', 'ネコはいすが好きだ。'], 'under ＝ ～の下に'),
])

# ---------------- 中2
unit('sea_g2_01', [
    F('I think it (   ) snow tonight.', 'will', ['is', 'does', 'was'], 'will ＋ 元の形。'),
    F('We\'re going to (   ) a party.', 'have', ['has', 'having', 'had'], 'be going to ＋ 元の形。'),
    F('(   ) he going to join the team?', 'Is', ['Does', 'Will', 'Are'], 'be going to の疑問。'),
    F('I (   ) be late. I promise.', 'won\'t', ['don\'t', 'am not', 'willn\'t'], 'will not ＝ won\'t。'),
    F('What will you (   ) tomorrow?', 'do', ['does', 'doing', 'did'], 'will ＋ 元の形。'),
    U('「Look at those clouds. It\'s going to rain.」の意味は？', None, 'あの雲を見て。雨がふりそうだ。', ['雨がふっている。', '雨がやんだ。', '雨がふればいいのに。'], '今の様子から予測。'),
    F('The concert (   ) start at seven.', 'will', ['is', 'does', 'has'], '未来。'),
    F('He will (   ) sixteen next year.', 'be', ['is', 'being', 'been'], 'will be。'),
    F('I\'m (   ) to visit Nara this weekend.', 'going', ['go', 'will', 'went'], 'be going to。'),
    U('「Will you open the door?」の意味として最も近いのは？', None, 'ドアを開けてくれませんか。', ['ドアを開けるつもりですか（予定のみ）。', 'ドアを開けましたか。', 'ドアを開けてもいいですか。'], 'Will you ～? は依頼にもなる。'),
    F('It (   ) be sunny this afternoon.', 'will', ['is', 'does', 'are'], '天気の予測。'),
    U('正しい文は？', None, 'She will come tomorrow.', ['She will comes tomorrow.', 'She wills come tomorrow.', 'She will coming tomorrow.'], 'will ＋ 元の形。'),
])
unit('sea_g2_02', [
    F('Students (   ) follow the school rules.', 'must', ['must to', 'are must', 'has'], 'must ＋ 元の形。'),
    F('I (   ) to finish this today.', 'have', ['must', 'has', 'am'], 'have to。'),
    F('You (   ) not use your phone during the test.', 'must', ['have', 'don\'t', 'aren\'t'], '禁止の must not。'),
    F('You (   ) have to bring lunch tomorrow.', 'don\'t', ['must', 'not', 'aren\'t'], '不必要 don\'t have to。'),
    F('(   ) I close the door? — No, thank you.', 'Shall', ['Will', 'Must', 'Am'], '申し出。'),
    F('(   ) I sit here? — Sure.', 'May', ['Must', 'Shall we', 'Will'], '許可。'),
    F('You (   ) go to bed early.', 'should', ['should to', 'are', 'had'], '助言。'),
    F('Did you have (   ) wait long?', 'to', ['for', 'at', 'must'], 'have to の過去の疑問。'),
    U('「You must be tired.」の must の意味は？', None, '～にちがいない', ['～しなければならない', '～してはいけない', '～してもよい'], '推量の must。'),
    F('Ken (   ) to practice hard.', 'has', ['have', 'must', 'is'], '3単現 has to。'),
    F('(   ) we dance? — Yes, let\'s.', 'Shall', ['Will', 'May', 'Must'], 'さそい。'),
    F('You (   ) be careful on the road.', 'must', ['must to', 'are', 'has to'], 'must ＋ be。'),
])
unit('sea_g2_03', [
    F('I want (   ) a new computer.', 'to buy', ['buy', 'buying', 'bought'], 'want to。'),
    F('She came to Japan (   ) Japanese.', 'to learn', ['learn', 'learning', 'learned'], '目的。'),
    F('Give me something (   ) eat.', 'to', ['for', 'and', 'with'], 'something to eat。'),
    F('We were sad (   ) the news.', 'to hear', ['hear', 'hearing', 'heard'], '感情の原因。'),
    F('It started (   ) rain.', 'to', ['for', 'at', 'with'], 'start to ～。'),
    U('「I have no time to watch TV.」の意味は？', None, 'テレビを見る時間がない。', ['テレビを見ない時間だ。', 'テレビを見たい。', 'テレビを見るのをやめた。'], 'time to ～ ＝ ～する時間'),
    U('「To read books is fun.」と同じ意味の文は？', None, 'It is fun to read books.', ['It is fun reading of books.', 'Reading is books fun.', 'Books is fun to reading.'], 'It is ～ to …。'),
    F('I went to the shop (   ) some milk.', 'to buy', ['buy', 'for buy', 'buying to'], '目的の不定詞。'),
    F('My plan is (   ) Kyoto.', 'to visit', ['visit', 'visits', 'visited'], '「訪れること」。'),
    F('Do you have anything (   )?', 'to do', ['do', 'doing', 'did'], 'anything to do。'),
    F('He tried (   ) the box.', 'to open', ['open', 'opened', 'opens'], 'try to ～。'),
    F('I\'m glad (   ) you.', 'to meet', ['meet', 'meeting', 'met'], '感情の原因。'),
])
unit('sea_g2_04', [
    F('My father likes (   ) fishing.', 'going', ['go', 'goes', 'went'], '動名詞（to go も可）。'),
    F('She finished (   ) the dishes.', 'washing', ['to wash', 'wash', 'washed'], 'finish ～ing。'),
    F('(   ) books is important.', 'Reading', ['Read', 'Reads', 'To reading'], '主語の動名詞。'),
    F('I\'m interested in (   ) pictures.', 'taking', ['take', 'to take', 'took'], '前置詞のあと。'),
    F('Let\'s stop (   ) a break.', 'to take', ['taking', 'take', 'took'], 'stop to ～ ＝ ～するために立ち止まる。（ここでは休けいのため）'),
    F('We enjoyed (   ) the game.', 'watching', ['to watch', 'watch', 'watched'], 'enjoy ～ing。'),
    U('to ～ と ～ing のどちらも目的語にとれるのは？', None, 'begin', ['enjoy', 'finish', 'want'], 'begin / start / like は両方 OK。'),
    F('He left (   ) goodbye.', 'without saying', ['without say', 'without to say', 'not saying'], 'without ～ing。'),
    F('I\'m looking forward to (   ) you.', 'seeing', ['see', 'saw', 'seen'], 'look forward to ～ing（to は前置詞）。'),
    F('Thank you for (   ) to my party.', 'coming', ['come', 'to come', 'came'], '前置詞のあと。'),
    F('Do you mind (   ) the window?', 'opening', ['to open', 'open', 'opened'], 'mind ～ing。'),
    F('(   ) up early is good for your health.', 'Getting', ['Get', 'Gets', 'Got'], '主語。'),
])
unit('sea_g2_05', [
    F('Call me (   ) you get home.', 'when', ['because', 'but', 'that'], '「～したら（とき）」。'),
    F('(   ) you are busy, I\'ll help you.', 'If', ['That', 'But', 'So'], '条件。'),
    F('I can\'t go out (   ) I have a lot of homework.', 'because', ['so', 'if', 'but'], '理由。'),
    F('She was hungry, (   ) she ate two sandwiches.', 'so', ['because', 'if', 'or'], '結果。'),
    F('I hope (   ) you will like it.', 'that', ['what', 'which', 'if not'], 'hope that ～。'),
    F('Take an umbrella, (   ) you\'ll get wet.', 'or', ['and', 'so', 'but'], 'さもないと。'),
    F('When I (   ) to London, I\'ll visit the museum.', 'go', ['will go', 'went', 'going'], '時の when の中は現在形。'),
    F('I know (   ) he is a good singer.', 'that', ['what', 'who', 'it'], 'know that ～。'),
    F('Both Ken (   ) Mike are tall.', 'and', ['or', 'but', 'so'], 'both A and B。'),
    F('Either you (   ) I must go.', 'or', ['and', 'nor', 'but'], 'either A or B。'),
    F('I waited (   ) he came back.', 'until', ['while', 'because', 'if'], '「～まで」。'),
    F('(   ) I was walking, I met Yumi.', 'While', ['Because', 'If', 'So'], '「～している間に」。'),
])
unit('sea_g2_06', [
    F('This river is (   ) than that one.', 'longer', ['long', 'longest', 'more long'], '比較級。'),
    F('She is the (   ) student in our class.', 'tallest', ['taller', 'tall', 'most tall'], '最上級。'),
    F('This question is (   ) difficult than that one.', 'more', ['most', 'much more than', 'very'], '長い語。'),
    F('I like summer the (   ) of all seasons.', 'best', ['better', 'good', 'well'], 'like ～ the best。'),
    F('My bag is as (   ) as yours.', 'big', ['bigger', 'biggest', 'more big'], 'as ～ as。'),
    Q('k', '「bad」の比較級は？', 'worse', ['badder', 'more bad', 'worst'], 'bad - worse - worst'),
    Q('k', '「many」の最上級は？', 'most', ['manyest', 'more', 'mostest'], 'many - more - most'),
    F('Who runs (   ), Ken or Taro?', 'faster', ['fast', 'fastest', 'more fast'], '2人の比較。'),
    F('This is (   ) than that.', 'much better', ['very better', 'more better', 'much best'], '比較級の強調は much。'),
    F('Tom is not as old (   ) Jim.', 'as', ['than', 'so', 'like'], 'not as ～ as。'),
    F('Lake Biwa is the largest lake (   ) Japan.', 'in', ['of', 'than', 'at'], '範囲は in。'),
    F('Which is the most popular sport (   ) the five?', 'of', ['in', 'than', 'at'], '複数は of。'),
])
unit('sea_g2_07', [
    F('This letter was (   ) by my grandmother.', 'written', ['wrote', 'write', 'writing'], '受け身。'),
    F('Soccer is (   ) all over the world.', 'played', ['plays', 'playing', 'play'], '受け身。'),
    F('The store is (   ) on Mondays.', 'closed', ['close', 'closing', 'closes'], 'be closed ＝ 閉まっている'),
    F('(   ) these cakes made by Mika?', 'Were', ['Did', 'Was', 'Do'], '複数・過去の受け身。'),
    F('The game wasn\'t (   ) because of the rain.', 'held', ['hold', 'holded', 'holding'], 'hold - held - held'),
    F('This book is read (   ) many students.', 'by', ['with', 'of', 'to'], 'by ～。'),
    F('Wine is made (   ) grapes.', 'from', ['of', 'by', 'with'], '原料が変化 → from。'),
    F('This desk is made (   ) wood.', 'of', ['from', 'by', 'in'], '材料がそのまま → of。'),
    F('I was surprised (   ) the news.', 'at', ['by only', 'with', 'of'], 'be surprised at ～。'),
    F('Kyoto is visited (   ) many tourists.', 'by', ['with', 'to', 'from'], '受け身の by。'),
    Q('k', '「speak」の過去分詞は？', 'spoken', ['spoke', 'speaked', 'speaking'], 'speak - spoke - spoken'),
    Q('k', '「give」の過去分詞は？', 'given', ['gave', 'gived', 'giving'], 'give - gave - given'),
])
unit('sea_g2_08', [
    F('This flower smells (   ).', 'sweet', ['sweetly', 'sweetness', 'to sweet'], 'smell ＋ 形容詞。'),
    F('She looks (   ) a singer.', 'like', ['as', 'to', 'for'], 'look like ＋ 名詞。'),
    F('Can you lend (   ) your pen?', 'me', ['my', 'I', 'mine'], 'lend 人 物。'),
    F('He bought a hat (   ) his son.', 'for', ['to', 'at', 'with'], 'buy 物 for 人。'),
    F('Please send the photo (   ) me.', 'to', ['for', 'with', 'by'], 'send 物 to 人。'),
    F('What do you call this flower (   ) English?', 'in', ['by', 'with', 'for'], 'in English。'),
    F('The movie made me (   ).', 'happy', ['happily', 'to happy', 'happiness'], 'make A B。'),
    F('Please leave the window (   ).', 'open', ['opens', 'to open', 'opening to'], 'leave A B。'),
    U('「My grandfather told me an old story.」の文型は？', None, 'S V O O', ['S V C', 'S V O C', 'S V O'], 'tell 人 物。'),
    U('「They named the baby Hana.」の意味は？', None, '彼らは赤ちゃんをハナと名づけた。', ['彼らはハナに赤ちゃんをあげた。', 'ハナは赤ちゃんを名づけた。', '赤ちゃんの名前を知らない。'], 'name A B ＝ A を B と名づける'),
    F('The soup tastes (   ).', 'good', ['well', 'goodly', 'to good'], 'taste ＋ 形容詞。'),
    F('I\'ll get (   ) a drink.', 'you', ['your', 'yours', 'to you'], 'get 人 物。'),
])

# ---------------- 中3
unit('sea_g3_01', [
    F('I have (   ) here since I was five.', 'lived', ['live', 'living', 'lives'], '継続。'),
    F('Have you ever (   ) to Okinawa?', 'been', ['gone', 'went', 'go'], '経験は have been to。'),
    F('He has just (   ) home.', 'come', ['came', 'comes', 'coming'], 'come - came - come'),
    F('I haven\'t seen him (   ) last year.', 'since', ['for', 'ago', 'from'], '起点。'),
    F('How many times (   ) you seen the movie?', 'have', ['did', 'do', 'are'], '経験の回数。'),
    F('We have been (   ) for an hour.', 'walking', ['walk', 'walked', 'walks'], '現在完了進行形。'),
    U('「She has gone to Paris.」の意味は？', None, '彼女はパリへ行ってしまった（今ここにいない）。', ['彼女はパリへ行ったことがある。', '彼女はパリから帰ってきた。', '彼女はパリへ行くつもりだ。'], 'have gone to。'),
    F('I have (   ) finished reading this book.', 'already', ['yet', 'ever', 'still'], '肯定文の already。'),
    F('Has the movie started (   )?', 'yet', ['already', 'ever', 'just'], '疑問文の yet ＝ もう'),
    U('まちがっている文は？', None, 'I have seen him yesterday.', ['I saw him yesterday.', 'I have seen him before.', 'I have known him for years.'], 'yesterday は現在完了と使えない。'),
    F('It (   ) been raining since morning.', 'has', ['have', 'is', 'was'], 'it は has。'),
    F('How long have they (   ) married?', 'been', ['be', 'being', 'were'], 'have been ＋ 形容詞。'),
])
unit('sea_g3_02', [
    F('It is easy (   ) me to swim.', 'for', ['of', 'to', 'with'], 'It is ～ for 人 to …。'),
    F('I want my sister (   ) the piano.', 'to play', ['play', 'playing', 'plays'], 'want 人 to ～。'),
    F('The teacher told us (   ) quiet.', 'to be', ['be', 'being', 'are'], 'tell 人 to be。'),
    F('Please show me how (   ) this camera.', 'to use', ['use', 'using', 'used'], 'how to ～。'),
    F('I don\'t know which bus (   ) take.', 'to', ['for', 'I', 'and'], 'which ～ to。'),
    F('She was too tired (   ) walk.', 'to', ['for', 'that', 'so'], 'too ～ to …。'),
    F('This book is easy enough for children (   ) read.', 'to', ['for', 'that', 'so'], 'enough to。'),
    F('I asked my father (   ) me to the station.', 'to take', ['take', 'taking', 'took'], 'ask 人 to ～。'),
    U('「It was kind of you to help me.」の意味は？', None, '手伝ってくれてありがとう（親切でした）。', ['あなたを手伝うのは親切だ。', '手伝ってほしい。', 'あなたは手伝わなかった。'], 'It is kind of 人 to ～。'),
    F('Do you know when (   ) start?', 'to', ['for', 'it', 'and'], 'when to ～。'),
    F('My mother made me (   ) my room.', 'clean', ['to clean', 'cleaning', 'cleaned'], 'make 人 ＋ 元の形（させる）。'),
    F('Let me (   ) you a question.', 'ask', ['to ask', 'asking', 'asked'], 'let 人 ＋ 元の形。'),
])
unit('sea_g3_03', [
    F('The man (   ) to Ms. Ito is our coach.', 'talking', ['talked', 'talks', 'to talk'], '進行の意味。'),
    F('I want a bike (   ) in Italy.', 'made', ['making', 'make', 'makes'], '受け身の意味。'),
    F('Do you know the girl (   ) tennis there?', 'playing', ['played', 'plays', 'play'], '～している。'),
    F('This is a book (   ) in easy English.', 'written', ['writing', 'wrote', 'writes'], '書かれた。'),
    F('Look at the (   ) leaves.', 'fallen', ['falling only', 'fell', 'falls'], '落ちた葉（完了）。'),
    F('The language (   ) in Brazil is Portuguese.', 'spoken', ['speaking', 'spoke', 'speaks'], '話される。'),
    U('「a boy named Taro」の意味は？', None, 'タロウという名前の男の子', ['タロウを名づけた男の子', 'タロウと名づける男の子', 'タロウの男の子'], '過去分詞の後置修飾。'),
    F('The students (   ) in the gym are practicing.', 'running', ['ran', 'run to', 'runs'], '～している。'),
    F('I have a cousin (   ) in Australia.', 'living', ['lived', 'live', 'lives in'], '住んでいる。'),
    F('These are photos (   ) last summer.', 'taken', ['taking', 'took', 'takes'], 'とられた。'),
    F('The baby (   ) in the bed is my brother.', 'sleeping', ['slept', 'sleeps', 'sleep'], 'ねている。'),
    F('Who is the man (   ) glasses?', 'wearing', ['worn', 'wore', 'wears'], 'かけている。'),
])
unit('sea_g3_04', [
    F('I have a friend (   ) father is a pilot.', 'whose', ['who', 'which', 'that'], '所有格 whose。'),
    F('The woman (   ) lives next door is a nurse.', 'who', ['which', 'whose', 'whom only'], '主格（人）。'),
    F('This is the computer (   ) I use every day.', 'that', ['who', 'whose', 'what'], '目的格。'),
    F('The museum (   ) we visited was great.', 'which', ['who', 'whose', 'where'], '目的格（もの）。'),
    U('関係代名詞を省略できる文は？', None, 'This is the cake that I made.', ['I know a boy who can swim fast.', 'The bus which goes to Ueno is here.', 'He is the man who helped me.'], '目的格だけ省略できる。'),
    F('Is this the key (   ) you were looking for?', 'that', ['who', 'what', 'whose'], '目的格。'),
    F('He is the first man (   ) climbed the mountain.', 'that', ['which', 'what', 'whose'], 'the first ～ のあとは that が多い。'),
    F('The boy and the dog (   ) are running are Ken and Shiro.', 'that', ['who', 'which', 'whose'], '人＋動物は that。'),
    F('Tell me the name of the song (   ) you like.', 'which', ['who', 'whose', 'where'], '目的格。'),
    U('「The girl I talked with was Mika.」で省略されている語は？', None, 'that（who / whom）', ['which だけ', 'whose', 'what'], '人の目的格。'),
    F('Anyone (   ) wants to come is welcome.', 'who', ['which', 'whose', 'what'], '主格。'),
    F('This is all (   ) I have.', 'that', ['what', 'which', 'who'], 'all のあとは that。'),
])
unit('sea_g3_05', [
    F('I don\'t know what (   ).', 'this is', ['is this', 'does this', 'this'], '主語 ＋ 動詞。'),
    F('Can you tell me where (   )?', 'he lives', ['does he live', 'lives he', 'he live'], '主語 ＋ 動詞。'),
    F('I wonder (   ) she will come.', 'if', ['that', 'what', 'which'], '～かどうか。'),
    F('Do you know why (   ) late?', 'she was', ['was she', 'did she', 'she did'], '主語 ＋ 動詞。'),
    F('Please tell me when the store (   ).', 'opens', ['does open', 'open', 'opening'], '3単現。'),
    F('I know how much (   ).', 'it costs', ['does it cost', 'cost it', 'it cost to'], '主語 ＋ 動詞。'),
    U('「Who is he?」を「彼がだれか知っていますか」にすると？', None, 'Do you know who he is?', ['Do you know who is he?', 'Do you know he is who?', 'Do you know who does he?'], '主語 ＋ 動詞。'),
    F('I asked him where he (   ) going.', 'was', ['is', 'does', 'did'], '時制の一致。'),
    F('Tell me what you (   ) for your birthday.', 'want', ['do want', 'wants', 'wanting'], '主語 you。'),
    F('Nobody knows who (   ) the window.', 'broke', ['did break', 'breaks to', 'broken'], 'who が主語。'),
    F('I want to know how many people (   ) coming.', 'are', ['do', 'is', 'does'], '主語 ＋ 動詞。'),
    F('Do you remember what time the movie (   )?', 'started', ['did start', 'start', 'starting'], '過去形。'),
])
unit('sea_g3_06', [
    F('I wish I (   ) a brother.', 'had', ['have', 'has', 'having'], '仮定法過去。'),
    F('If I (   ) free, I would go with you.', 'were', ['am', 'be', 'will be'], 'were。'),
    F('If I had wings, I (   ) fly.', 'could', ['can', 'will', 'am'], 'could ＋ 元の形。'),
    F('I wish it (   ) sunny today.', 'were', ['is', 'will be', 'be'], 'I wish ＋ were。'),
    F('What would you do if you (   ) a million yen?', 'had', ['have', 'has', 'will have'], 'if ＋ 過去形。'),
    U('「If I knew the answer, I would tell you.」が表す事実は？', None, '答えを知らないので、教えられない。', ['答えを知っているので教える。', '答えを教えた。', '答えを知りたくない。'], '現実とちがう仮定。'),
    F('I wish I (   ) play the guitar.', 'could', ['can', 'will', 'am able'], 'I wish ＋ could。'),
    F('If it (   ) tomorrow, the game will be canceled.', 'rains', ['rained', 'would rain', 'will rain'], '実際にありうる条件 → 現在形。'),
    F('If she (   ) here, she would help us.', 'were', ['is', 'be', 'will be'], '仮定法。'),
    U('仮定法の文は？', None, 'I wish I lived near the sea.', ['I live near the sea.', 'If it is fine, I will go.', 'I lived near the sea last year.'], 'I wish ＋ 過去形。'),
    F('If I were you, I (   ) not do that.', 'would', ['will', 'do', 'am'], 'would not ＋ 元の形。'),
    F('He talks as if he (   ) everything.', 'knew', ['knows', 'know', 'will know'], 'as if ＋ 過去形。'),
])
unit('sea_g3_07', [
    F('My mother let me (   ) the cake.', 'eat', ['to eat', 'eating', 'ate'], 'let 人 ＋ 元の形。'),
    F('The teacher made us (   ) the essay again.', 'write', ['to write', 'writing', 'written'], 'make 人 ＋ 元の形。'),
    F('Please help me (   ) this bag.', 'carry', ['carrying', 'carried', 'carries'], 'help 人 ＋ 元の形。'),
    F('I saw him (   ) the street.', 'cross', ['to cross', 'crossed', 'crosses'], 'see 人 ＋ 元の形。'),
    F('I heard someone (   ) my name.', 'call', ['to call', 'called', 'calls'], 'hear 人 ＋ 元の形。'),
    U('「My father didn\'t let me go out.」の意味は？', None, '父はわたしを外出させてくれなかった。', ['父は外出しなかった。', '父はわたしを外に出した。', 'わたしは父と出かけた。'], 'let ＝ （許して）させる'),
    U('「make 人 ～」と「let 人 ～」のちがいは？', None, 'make は（無理に）させる、let は（望みどおり）させる', ['同じ意味', 'make は許す、let は強制', 'let は過去形だけ'], '強制と許可。'),
    F('I felt the ground (   ).', 'shake', ['to shake', 'shook', 'shaken'], 'feel 人・物 ＋ 元の形。'),
    F('I watched the children (   ) soccer.', 'play', ['to play', 'played', 'plays'], 'watch 人 ＋ 元の形。'),
    F('Let\'s (   ) him know the result.', 'let', ['make', 'have', 'to let'], 'let 人 know ＝ 人に知らせる'),
    F('She had her hair (   ).', 'cut', ['to cut', 'cutting', 'cuts'], 'have 物 ＋ 過去分詞。'),
    F('Don\'t make me (   ).', 'laugh', ['to laugh', 'laughing', 'laughed'], 'make 人 ＋ 元の形。'),
])

WORDS = {
    'words_j1': ('中1の単語', [
        ('student', '生徒'), ('teacher', '先生'), ('friend', '友だち'), ('family', '家族'), ('morning', '朝'),
        ('afternoon', '午後'), ('evening', '夕方'), ('night', '夜'), ('week', '週'), ('month', '月'),
        ('year', '年'), ('house', '家'), ('room', '部屋'), ('kitchen', '台所'), ('window', '窓'),
        ('door', 'ドア'), ('desk', '机'), ('chair', 'いす'), ('book', '本'), ('notebook', 'ノート'),
        ('picture', '写真・絵'), ('music', '音楽'), ('sport', 'スポーツ'), ('club', '部活・クラブ'), ('library', '図書館'),
        ('station', '駅'), ('river', '川'), ('sea', '海'), ('mountain', '山'), ('animal', '動物'),
        ('flower', '花'), ('tree', '木'), ('water', '水'), ('food', '食べ物'), ('breakfast', '朝食'),
        ('lunch', '昼食'), ('dinner', '夕食'), ('big', '大きい'), ('small', '小さい'), ('long', '長い'),
        ('short', '短い'), ('new', '新しい'), ('old', '古い・年をとった'), ('young', '若い'), ('busy', 'いそがしい'),
        ('free', 'ひまな'), ('easy', 'かんたんな'), ('difficult', 'むずかしい'), ('happy', '幸せな'), ('beautiful', '美しい'),
        ('speak', '話す'), ('listen', '聞く'), ('read', '読む'), ('write', '書く'), ('walk', '歩く'),
        ('help', '手伝う'), ('know', '知っている'), ('live', '住む'), ('come', '来る'), ('make', '作る'),
    ]),
    'words_j2': ('中2の単語', [
        ('weather', '天気'), ('future', '未来・将来'), ('plan', '計画'), ('idea', '考え'), ('problem', '問題'),
        ('reason', '理由'), ('example', '例'), ('history', '歴史'), ('culture', '文化'), ('country', '国'),
        ('world', '世界'), ('language', '言語'), ('dream', '夢'), ('job', '仕事'), ('volunteer', 'ボランティア'),
        ('trip', '旅行'), ('airport', '空港'), ('museum', '博物館・美術館'), ('hospital', '病院'), ('message', '伝言'),
        ('important', '大切な'), ('interesting', 'おもしろい'), ('popular', '人気のある'), ('famous', '有名な'), ('different', 'ちがう'),
        ('same', '同じ'), ('useful', '役に立つ'), ('tired', 'つかれた'), ('sick', '病気の'), ('kind', '親切な'),
        ('strong', '強い'), ('quiet', '静かな'), ('careful', '注意深い'), ('dangerous', '危険な'), ('special', '特別な'),
        ('decide', '決める'), ('remember', '覚えている・思い出す'), ('forget', '忘れる'), ('arrive', '到着する'), ('leave', '出発する・残す'),
        ('build', '建てる'), ('carry', '運ぶ'), ('change', '変える'), ('finish', '終える'), ('invite', '招待する'),
        ('practice', '練習する'), ('travel', '旅行する'), ('understand', '理解する'), ('borrow', '借りる'), ('lend', '貸す'),
        ('believe', '信じる'), ('explain', '説明する'), ('answer', '答える'), ('collect', '集める'), ('protect', '守る'),
        ('without', '～なしで'), ('during', '～の間に'), ('until', '～まで'), ('through', '～を通って'), ('again', 'もう一度'),
    ]),
    'words_j3': ('中3の単語', [
        ('environment', '環境'), ('energy', 'エネルギー'), ('pollution', '汚染'), ('nature', '自然'), ('earth', '地球'),
        ('technology', '技術'), ('information', '情報'), ('communication', 'コミュニケーション'), ('society', '社会'), ('peace', '平和'),
        ('war', '戦争'), ('experience', '経験'), ('opinion', '意見'), ('effort', '努力'), ('chance', '機会'),
        ('difference', 'ちがい'), ('result', '結果'), ('purpose', '目的'), ('situation', '状況'), ('solution', '解決策'),
        ('local', '地元の'), ('global', '世界的な'), ('foreign', '外国の'), ('necessary', '必要な'), ('possible', '可能な'),
        ('impossible', '不可能な'), ('serious', '深刻な・まじめな'), ('similar', '似ている'), ('enough', '十分な'), ('wonderful', 'すばらしい'),
        ('develop', '発展させる'), ('increase', '増える'), ('decrease', '減る'), ('reduce', '減らす'), ('solve', '解決する'),
        ('improve', '改善する'), ('realize', '気づく・実現する'), ('share', '共有する'), ('support', '支える'), ('respect', '尊敬する'),
        ('produce', '生産する'), ('save', '救う・節約する'), ('spread', '広がる'), ('discover', '発見する'), ('invent', '発明する'),
        ('express', '表現する'), ('continue', '続ける'), ('agree', '賛成する'), ('disagree', '反対する'), ('prepare', '準備する'),
        ('however', 'しかしながら'), ('though', '～だけれども'), ('instead', 'その代わりに'), ('actually', '実は'), ('especially', '特に'),
        ('probably', 'たぶん'), ('suddenly', '突然'), ('finally', 'ついに'), ('each other', 'おたがい'), ('all over the world', '世界中で'),
    ]),
    'idioms_j': ('中学の熟語', [
        ('get up', '起きる'), ('go to bed', 'ねる'), ('look at ～', '～を見る'), ('listen to ～', '～を聞く'), ('look for ～', '～をさがす'),
        ('wait for ～', '～を待つ'), ('take care of ～', '～の世話をする'), ('look forward to ～', '～を楽しみに待つ'), ('be interested in ～', '～に興味がある'), ('be good at ～', '～が得意だ'),
        ('be famous for ～', '～で有名だ'), ('be afraid of ～', '～をこわがる'), ('be proud of ～', '～をほこりに思う'), ('be different from ～', '～とちがう'), ('be full of ～', '～でいっぱいだ'),
        ('a lot of ～', 'たくさんの～'), ('a little', '少し'), ('a few ～', '少しの～（数）'), ('each other', 'おたがい'), ('for example', 'たとえば'),
        ('at first', '最初は'), ('at last', 'ついに'), ('for the first time', '初めて'), ('in the future', '将来'), ('right now', 'ちょうど今'),
        ('after school', '放課後'), ('in front of ～', '～の前に'), ('next to ～', '～のとなりに'), ('because of ～', '～のために（理由）'), ('thanks to ～', '～のおかげで'),
        ('take a picture', '写真をとる'), ('have a good time', '楽しい時をすごす'), ('get to ～', '～に着く'), ('get on ～', '～に乗る'), ('get off ～', '～から降りる'),
        ('give up', 'あきらめる'), ('come back', 'もどる'), ('find out', 'わかる・見つけ出す'), ('grow up', '成長する'), ('pick up', '拾う・車でむかえに行く'),
        ('such as ～', '～のような'), ('not only A but also B', 'A だけでなく B も'), ('both A and B', 'A と B の両方'), ('either A or B', 'A か B のどちらか'), ('as ～ as possible', 'できるだけ～'),
        ('How about ～?', '～はどうですか'), ('Why don\'t we ～?', '～しませんか'), ('Shall I ～?', '～しましょうか'), ('Would you like ～?', '～はいかがですか'), ('Here you are.', 'はい、どうぞ。'),
        ('You\'re welcome.', 'どういたしまして。'), ('Excuse me.', 'すみません。'), ('That\'s right.', 'その通りです。'), ('Of course.', 'もちろん。'), ('No problem.', 'いいですよ・問題ないです。'),
    ]),
}


def write():
    out = QDIR / 'sea'
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob('*.json'):
        f.unlink()
    total = 0
    import random
    for uid, qs in UNITS.items():
        data = []
        for n, q in enumerate(qs, 1):
            qid = f'{uid}_{n:03d}'
            ch = [q['a']] + q['w']
            assert len(set(ch)) == 4, (qid, ch)
            o = ch[:]
            random.Random(qid).shuffle(o)
            d = dict(id=qid, category=CAT[q['c']], prompt=q['p'])
            if q['s']:
                d['sentence'] = q['s']
            d.update(choices=o, answerIndex=o.index(q['a']), explanation=q['e'],
                     targetGrade=f'中{uid[5]}', phase='teikiTest')
            data.append(d)
        total += len(data)
        (out / f'{uid}.json').write_text(json.dumps(
            dict(setId=uid, worldId='english', origin='original', version=1, questions=data),
            ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    words = ROOT / 'assets' / 'words'
    for f in words.glob('*.json'):
        f.unlink()
    for lid, (title, pairs) in WORDS.items():
        terms = [p[0] for p in pairs]
        assert len(set(terms)) == len(terms), (lid, [t for t in terms if terms.count(t) > 1])
        (words / f'{lid}.json').write_text(json.dumps(dict(
            listId=lid, title=title, origin='original',
            words=[dict(number=i, term=t, meaning=m) for i, (t, m) in enumerate(pairs, 1)]),
            ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    return total
