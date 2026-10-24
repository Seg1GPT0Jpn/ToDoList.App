import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';

// 国語の問題の作り方。答えが一つに決まる表（敬語・対義語・再読文字・
// 歴史的仮名遣い・古文単語・助動詞・枕詞・作品と作者など）だけから作る。
// 意味が重なる語は同じ group にして、たがいにまちがいの候補にしない。

List<T> _shuffle<T>(Random r, Iterable<T> xs) => xs.toList()..shuffle(r);

/// 語と意味（group が同じものは意味が近いので、まちがいにしない）
class _Gloss {
  const _Gloss(this.word, this.gloss, [this.group]);
  final String word;
  final String gloss;
  final String? group;
  String get g => group ?? word;
}

List<Gen> _glossGens(
  List<_Gloss> table, {
  required String Function(String word) ask,
  required String Function(String gloss) askReverse,
  required String Function(_Gloss e) explain,
}) =>
    [
      (r) {
        final e = r.pick(table);
        return GenQ(
          prompt: ask(e.word),
          answer: e.gloss,
          wrong: _shuffle(r, [
            for (final o in table)
              if (o.g != e.g) o.gloss
          ]),
          explanation: explain(e),
          category: QuestionCategory.meaning,
        );
      },
      (r) {
        final e = r.pick(table);
        return GenQ(
          prompt: askReverse(e.gloss),
          answer: e.word,
          wrong: _shuffle(r, [
            for (final o in table)
              if (o.g != e.g) o.word
          ]),
          explanation: explain(e),
          category: QuestionCategory.meaning,
        );
      },
    ];

// ---------------- 敬語 ----------------

class _Keigo {
  const _Keigo(this.base,
      {this.sonkei = const [],
      this.kenjo = const [],
      this.sonkeiIn,
      this.kenjoIn,
      this.avoid = const []});

  /// 意味が近いので、まちがいの候補にしない敬語
  final List<String> avoid;
  final String base;
  final List<String> sonkei;
  final List<String> kenjo;

  /// 目上の人の動作の文（尊敬語を使う）
  final String? sonkeiIn;

  /// 自分の動作の文（謙譲語を使う）
  final String? kenjoIn;
}

const _keigo = [
  _Keigo('言う',
      sonkei: ['おっしゃる'],
      kenjo: ['申す', '申し上げる'],
      sonkeiIn: '先生が言う',
      kenjoIn: '私が先生に言う'),
  _Keigo('行く',
      sonkei: ['いらっしゃる', 'おいでになる', 'お越しになる'],
      kenjo: ['参る', '伺う'],
      sonkeiIn: '先生が会場へ行く',
      kenjoIn: '私が先生の家へ行く'),
  _Keigo('来る',
      sonkei: ['いらっしゃる', 'おいでになる', 'お見えになる', 'お越しになる'],
      kenjo: ['参る'],
      sonkeiIn: '先生が学校に来る'),
  _Keigo('いる',
      sonkei: ['いらっしゃる', 'おいでになる'],
      kenjo: ['おる'],
      sonkeiIn: '先生が職員室にいる',
      kenjoIn: '私は家にいる'),
  _Keigo('食べる',
      sonkei: ['召し上がる'],
      kenjo: ['いただく'],
      sonkeiIn: '先生がお弁当を食べる',
      kenjoIn: '私が先生の手料理を食べる'),
  _Keigo('飲む',
      sonkei: ['召し上がる'],
      kenjo: ['いただく'],
      sonkeiIn: '先生がお茶を飲む',
      kenjoIn: '私が先生の家でお茶を飲む'),
  _Keigo('見る',
      sonkei: ['ご覧になる'],
      kenjo: ['拝見する'],
      sonkeiIn: '先生が写真を見る',
      kenjoIn: '私が先生の作品を見る'),
  _Keigo('する',
      sonkei: ['なさる'],
      kenjo: ['いたす'],
      sonkeiIn: '先生が説明をする',
      kenjoIn: '私が先生の手伝いをする'),
  _Keigo('聞く',
      sonkei: ['お聞きになる'],
      kenjo: ['伺う', '承る', '拝聴する'],
      sonkeiIn: '先生が生徒の話を聞く',
      kenjoIn: '私が先生の話を聞く'),
  _Keigo('知っている',
      sonkei: ['ご存じだ'],
      kenjo: ['存じている'],
      sonkeiIn: '先生がその本を知っている',
      kenjoIn: '私はその本を知っている'),
  _Keigo('会う',
      sonkei: ['お会いになる'],
      kenjo: ['お目にかかる'],
      sonkeiIn: '先生が卒業生に会う',
      kenjoIn: '私が先生に会う'),
  _Keigo('与える（やる）', kenjo: ['差し上げる'], kenjoIn: '私が先生に花をやる'),
  _Keigo('もらう', kenjo: ['いただく', '頂戴する'], kenjoIn: '私が先生から本をもらう', avoid: ['承る']),
  _Keigo('くれる', sonkei: ['くださる'], sonkeiIn: '先生が私に本をくれる'),
  _Keigo('見せる',
      sonkei: ['お見せになる'],
      kenjo: ['お目にかける', 'ご覧に入れる'],
      sonkeiIn: '先生が写真を見せる',
      kenjoIn: '私が先生に作品を見せる'),
  _Keigo('読む',
      sonkei: ['お読みになる'],
      kenjo: ['拝読する'],
      sonkeiIn: '先生が本を読む',
      kenjoIn: '私が先生の論文を読む'),
  _Keigo('借りる', kenjo: ['拝借する'], kenjoIn: '私が先生の本を借りる'),
  _Keigo('思う', kenjo: ['存じる'], kenjoIn: '私もそう思う'),
  _Keigo('着る', sonkei: ['お召しになる'], sonkeiIn: '先生が着物を着る'),
  _Keigo('寝る', sonkei: ['お休みになる'], sonkeiIn: '先生がもう寝る'),
  _Keigo('訪ねる', kenjo: ['伺う'], kenjoIn: '私が先生の家を訪ねる'),
];

final _allKeigoWords = {
  for (final k in _keigo) ...[...k.sonkei, ...k.kenjo]
}.toList();

/// [right] 以外の敬語（まちがいの候補）。[first] を先に出す
List<String> _keigoWrong(
        Random r, _Keigo k, List<String> right, List<String> first) =>
    _keigoWrong0(r, [...right, ...k.avoid], first);

List<String> _keigoWrong0(Random r, List<String> right, List<String> first) => [
      ..._shuffle(r, first.where((w) => !right.contains(w))),
      ..._shuffle(
          r,
          _allKeigoWords
              .where((w) => !right.contains(w) && !first.contains(w))),
    ];

GenQ? _keigoAsk(Random r) {
  final k = r.pick(_keigo);
  final sonkei = r.nextBool();
  final right = sonkei ? k.sonkei : k.kenjo;
  final other = sonkei ? k.kenjo : k.sonkei;
  if (right.isEmpty) return null;
  final ans = r.pick(right);
  final kind = sonkei ? '尊敬語' : '謙譲語';
  final note =
      other.isEmpty ? '' : '「${other.first}」は${sonkei ? '謙譲語' : '尊敬語'}。';
  return GenQ(
    prompt: '「${k.base}」の$kindは？',
    answer: ans,
    wrong: _keigoWrong(r, k, right, other.take(1).toList()),
    explanation: '「${k.base}」の$kindは「${right.join('」「')}」。$note',
    category: QuestionCategory.usage,
  );
}

GenQ? _keigoReverse(Random r) {
  final k = r.pick(_keigo);
  final sonkei = r.nextBool();
  final words = sonkei ? k.sonkei : k.kenjo;
  if (words.isEmpty) return null;
  final w = r.pick(words);
  final kind = sonkei ? '尊敬語' : '謙譲語';
  final bases = [
    for (final o in _keigo)
      if ((sonkei ? o.sonkei : o.kenjo).contains(w)) o.base
  ];
  return GenQ(
    prompt: '「$w」は何の$kind？',
    answer: k.base,
    wrong: _shuffle(r, [
      for (final o in _keigo)
        if (!bases.contains(o.base)) o.base
    ]),
    explanation: '「$w」は「${bases.join('」「')}」の$kind。',
    category: QuestionCategory.usage,
  );
}

GenQ? _keigoKind(Random r) {
  final k = r.pick(_keigo);
  final sonkei = r.nextBool();
  final words = sonkei ? k.sonkei : k.kenjo;
  if (words.isEmpty) return null;
  final w = r.pick(words);
  // 尊敬語にも謙譲語にもなる語は出さない
  if (_keigo.any((o) => (sonkei ? o.kenjo : o.sonkei).contains(w))) {
    return null;
  }
  final kind = sonkei ? '尊敬語' : '謙譲語';
  return GenQ(
    prompt: '「$w」の敬語の種類は？',
    answer: kind,
    wrong: _shuffle(r, ['尊敬語', '謙譲語', '丁寧語', '美化語']),
    explanation: sonkei
        ? '「$w」は「${k.base}」の尊敬語。相手（目上の人）の動作を高める。'
        : '「$w」は「${k.base}」の謙譲語。自分の動作をへりくだって述べる。',
    category: QuestionCategory.usage,
  );
}

GenQ? _keigoSentence(Random r) {
  final k = r.pick(_keigo);
  final sonkei = r.nextBool();
  final text = sonkei ? k.sonkeiIn : k.kenjoIn;
  final right = sonkei ? k.sonkei : k.kenjo;
  final other = sonkei ? k.kenjo : k.sonkei;
  if (text == null || right.isEmpty) return null;
  final verb = k.base.replaceAll(RegExp('（.*）'), '');
  final shown = k.base.startsWith('与える') ? 'やる' : verb;
  return GenQ(
    prompt: '「$text」の「$shown」を、正しい敬語に直すと？',
    answer: r.pick(right),
    wrong: _keigoWrong(r, k, right, other),
    explanation: sonkei
        ? '先生（目上の人）の動作なので尊敬語「${right.join('」「')}」を使う。'
        : '自分の動作なので謙譲語「${right.join('」「')}」を使い、相手を高める。',
    category: QuestionCategory.usage,
  );
}

// ---------------- 対義語 ----------------

const _antonyms = [
  ('抽象', '具体'),
  ('主観', '客観'),
  ('絶対', '相対'),
  ('演繹', '帰納'),
  ('分析', '総合'),
  ('必然', '偶然'),
  ('普遍', '特殊'),
  ('理想', '現実'),
  ('肯定', '否定'),
  ('積極', '消極'),
  ('能動', '受動'),
  ('原因', '結果'),
  ('権利', '義務'),
  ('形式', '内容'),
  ('楽観', '悲観'),
  ('需要', '供給'),
  ('生産', '消費'),
  ('部分', '全体'),
  ('単純', '複雑'),
  ('拡大', '縮小'),
  ('増加', '減少'),
  ('保守', '革新'),
  ('創造', '模倣'),
  ('自律', '他律'),
  ('主体', '客体'),
  ('原則', '例外'),
  ('既知', '未知'),
  ('有限', '無限'),
  ('直接', '間接'),
  ('混沌', '秩序'),
  ('集中', '分散'),
  ('先天', '後天'),
  ('慎重', '軽率'),
  ('緊張', '弛緩'),
  ('求心', '遠心'),
  ('収入', '支出'),
  ('債権', '債務'),
  ('急性', '慢性'),
  ('長所', '短所'),
  ('好況', '不況'),
  ('往路', '復路'),
  ('前進', '後退'),
  ('延長', '短縮'),
  ('輸入', '輸出'),
  ('正常', '異常'),
  ('上昇', '下降'),
  ('内包', '外延'),
];

GenQ? _antonym(Random r) {
  final (a0, b0) = r.pick(_antonyms);
  final flip = r.nextBool();
  final a = flip ? b0 : a0, b = flip ? a0 : b0;
  return GenQ(
    prompt: '「$a」の対義語は？',
    answer: b,
    wrong: _shuffle(r, [
      for (final (x, y) in _antonyms)
        if (x != a0) ...[x, y]
    ]),
    explanation: '「$a」⇔「$b」。',
    category: QuestionCategory.meaning,
  );
}

GenQ? _antonymPair(Random r) {
  final (a, b) = r.pick(_antonyms);
  // 対義語でない組み合わせ（別の組から1語ずつ）
  final others = _shuffle(r, _antonyms.where((p) => p.$1 != a)).toList();
  final wrong = <String>[];
  for (var i = 0; i + 1 < others.length && wrong.length < 3; i += 2) {
    final x = r.nextBool() ? others[i].$1 : others[i].$2;
    final y = r.nextBool() ? others[i + 1].$1 : others[i + 1].$2;
    wrong.add('$x ⇔ $y');
  }
  return GenQ(
    prompt: '対義語の組み合わせとして正しいものは？',
    answer: r.nextBool() ? '$a ⇔ $b' : '$b ⇔ $a',
    wrong: wrong,
    explanation: '「$a」と「$b」は意味が反対の語。',
    category: QuestionCategory.meaning,
  );
}

// ---------------- ことわざ・慣用句 ----------------

const _idioms = [
  _Gloss('猫の手も借りたい', 'とても忙しい'),
  _Gloss('猫に小判', '価値のわからない者には何の役にも立たない', '価値'),
  _Gloss('豚に真珠', '価値のわからない者には何の役にも立たない', '価値'),
  _Gloss('石の上にも三年', 'しんぼう強く続ければ、いつかは報われる'),
  _Gloss('急がば回れ', '急ぐときこそ、確実な方法をとるほうがよい'),
  _Gloss('二兎を追う者は一兎をも得ず', '欲張って二つを同時にねらうと、どちらも得られない', '欲張り'),
  _Gloss('虻蜂取らず', '欲張って二つを同時にねらうと、どちらも得られない', '欲張り'),
  _Gloss('猿も木から落ちる', 'その道の名人でも失敗することがある', '名人'),
  _Gloss('弘法にも筆の誤り', 'その道の名人でも失敗することがある', '名人'),
  _Gloss('河童の川流れ', 'その道の名人でも失敗することがある', '名人'),
  _Gloss('焼け石に水', 'わずかな助けでは効き目がない', '効き目'),
  _Gloss('塵も積もれば山となる', '小さなことでも積み重なれば大きくなる'),
  _Gloss('七転び八起き', '何度失敗しても、くじけずに立ち上がる'),
  _Gloss('能ある鷹は爪を隠す', '実力のある者は、それをむやみに見せびらかさない'),
  _Gloss('雨降って地固まる', 'もめごとのあと、かえって前より安定する'),
  _Gloss('情けは人のためならず', '人に親切にすれば、めぐりめぐって自分によい報いがある'),
  _Gloss('馬の耳に念仏', 'いくら言い聞かせても効き目がない', '効き目'),
  _Gloss('糠に釘', '手ごたえがなく、効き目がない', '効き目'),
  _Gloss('暖簾に腕押し', '手ごたえがなく、効き目がない', '効き目'),
  _Gloss('石橋を叩いて渡る', 'とても用心深く物事を行う'),
  _Gloss('灯台下暗し', '身近なことは、かえって気づきにくい'),
  _Gloss('後悔先に立たず', '終わったあとで悔やんでも取り返しがつかない', '取り返し'),
  _Gloss('覆水盆に返らず', '一度してしまったことは、元にはもどらない', '取り返し'),
  _Gloss('良薬は口に苦し', 'ためになる忠告ほど、聞くのがつらい', '忠告'),
  _Gloss('百聞は一見に如かず', '何度も聞くより、一度自分の目で見るほうがよくわかる'),
  _Gloss('案ずるより産むが易し', '心配するより、やってみると案外たやすい'),
  _Gloss('出る杭は打たれる', '目立つ者は、人から憎まれたり邪魔されたりする'),
  _Gloss('泣き面に蜂', '不運の上に、さらに不運が重なる', '不運'),
  _Gloss('弱り目に祟り目', '不運の上に、さらに不運が重なる', '不運'),
  _Gloss('果報は寝て待て', '幸運はあせらずに待つのがよい'),
  _Gloss('光陰矢のごとし', '月日がたつのはとても早い'),
  _Gloss('二階から目薬', '思うようにいかず、もどかしい'),
  _Gloss('骨折り損のくたびれもうけ', '苦労したのに、何の成果もない'),
  _Gloss('腐っても鯛', 'すぐれたものは、落ちぶれても値打ちがある'),
  _Gloss('住めば都', 'どんな所でも、住み慣れればよい所に思える'),
  _Gloss('顔が広い', '知り合いが多い'),
  _Gloss('口が堅い', '秘密をむやみに話さない'),
  _Gloss('腕が上がる', '技術が上達する'),
  _Gloss('手を焼く', '扱いに困る'),
  _Gloss('目が高い', '物のよしあしを見分ける力がある'),
  _Gloss('耳が痛い', '自分の弱点を言われて、聞くのがつらい', '忠告'),
  _Gloss('鼻が高い', '得意である・誇らしい'),
  _Gloss('足が出る', '予算をこえてお金がかかる'),
  _Gloss('肩を持つ', '一方の味方をする'),
  _Gloss('舌を巻く', 'ひどく感心する'),
  _Gloss('気が置けない', '遠慮する必要がなく、気楽につき合える'),
  _Gloss('水に流す', '過去のもめごとをなかったことにする'),
  _Gloss('油を売る', 'むだ話をして仕事を怠ける'),
  _Gloss('猫をかぶる', '本性を隠して、おとなしそうにする'),
  _Gloss('首を長くする', '今か今かと待ちこがれる'),
  _Gloss('歯が立たない', '相手が強すぎて、とてもかなわない'),
];

// ---------------- 漢文：再読文字・詩の形 ----------------

class _Saidoku {
  const _Saidoku(this.chars, this.read, this.mean, this.pre, this.tail,
      {this.mizen = false});
  final List<String> chars;
  final String read;
  final String mean;

  /// 書き下しで字につける送りがな（「未だ」の「だ」）
  final String pre;

  /// 返って読む部分（動詞の後ろ）
  final String tail;

  /// 動詞を未然形にするか（しないなら終止形）
  final bool mizen;
}

const _saidoku = [
  _Saidoku(['未'], 'いまだ〜ず', 'まだ〜ない', 'だ', 'ず', mizen: true),
  _Saidoku(['将', '且'], 'まさに〜んとす', '今にも〜しようとする', 'に', 'んとす', mizen: true),
  _Saidoku(['当'], 'まさに〜べし', '当然〜すべきだ', 'に', 'べし'),
  _Saidoku(['応'], 'まさに〜べし', 'きっと〜だろう', 'に', 'べし'),
  _Saidoku(['宜'], 'よろしく〜べし', '〜するのがよい', 'しく', 'べし'),
  _Saidoku(['須'], 'すべからく〜べし', 'ぜひ〜する必要がある', 'らく', 'べし'),
  _Saidoku(['猶', '由'], 'なほ〜ごとし', 'ちょうど〜のようだ', 'ほ', 'ごとし'),
  _Saidoku(['盍'], 'なんぞ〜ざる', 'どうして〜しないのか', 'ぞ', 'ざる', mizen: true),
];

/// 漢文の動詞（字・未然形・終止形）
const _kVerbs = [
  ('知', '知ら', '知る'),
  ('行', '行か', '行く'),
  ('帰', '帰ら', '帰る'),
  ('学', '学ば', '学ぶ'),
  ('聞', '聞か', '聞く'),
  ('去', '去ら', '去る'),
  ('読', '読ま', '読む'),
  ('書', '書か', '書く'),
  ('見', '見', '見る'),
  ('死', '死せ', '死す'),
  ('言', '言は', '言ふ'),
  ('笑', '笑は', '笑ふ'),
];

String _kakikudashi(_Saidoku s, String ch, (String, String, String) v) =>
    '$ch${s.pre}${s.mizen ? v.$2 : v.$3}${s.tail}';

GenQ? _saidokuRead(Random r) {
  final s = r.pick(_saidoku);
  final ch = r.pick(s.chars);
  final askMean = r.nextBool();
  final ans = askMean ? s.mean : s.read;
  return GenQ(
    prompt: '再読文字「$ch」の${askMean ? '意味' : '読み'}は？',
    answer: ans,
    wrong: _shuffle(r, [
      for (final o in _saidoku)
        if (!identical(o, s) && (askMean ? o.mean : o.read) != ans)
          askMean ? o.mean : o.read
    ]),
    explanation: '「$ch」は「${s.read}」と読み、「${s.mean}」という意味。',
    category: QuestionCategory.meaning,
  );
}

GenQ? _saidokuWhich(Random r) {
  final s = r.pick(_saidoku);
  return GenQ(
    prompt: '「${s.read}」と読み、「${s.mean}」という意味を表す再読文字は？',
    answer: r.pick(s.chars),
    wrong: _shuffle(r, [
      for (final o in _saidoku)
        if (o.read != s.read) ...o.chars
    ]),
    explanation: '「${s.chars.join('」「')}」は「${s.read}」と読む再読文字。',
    category: QuestionCategory.meaning,
  );
}

GenQ? _saidokuKaki(Random r) {
  final s = r.pick(_saidoku);
  // 「猶」は動詞につくと「〜がごとし」になるので、ここでは出さない
  if (s.tail == 'ごとし') return null;
  final ch = r.pick(s.chars);
  final v = r.pick(_kVerbs);
  final ans = _kakikudashi(s, ch, v);
  final wrong = <String>[
    // 返って読む部分をほかの再読文字のものにしたもの
    for (final t in _shuffle(r, {for (final o in _saidoku) o.tail}))
      if (t != s.tail)
        '$ch${s.pre}${t == 'んとす' || t == 'ざる' || t == 'ず' ? v.$2 : v.$3}$t',
  ];
  // 2番目は二度目を読み落としたもの
  return GenQ(
    prompt: '「$chレ${v.$1}」の書き下し文は？',
    answer: ans,
    wrong: [wrong[0], '$ch${s.pre}${v.$3}', ...wrong.skip(1)],
    explanation:
        '「$ch」は「${s.read}」と読む再読文字。はじめに「$ch${s.pre}」と読み、返って「${s.tail}」と読む。',
    category: QuestionCategory.usage,
  );
}

class _PoemForm {
  const _PoemForm(this.name, this.chars, this.lines);
  final String name;
  final int chars;
  final int lines;
  String get shape => '1句$chars字・$lines句';
  String get rhyme => chars == 5 ? '偶数句の末' : '第1句末と偶数句末';
}

const _poemForms = [
  _PoemForm('五言絶句', 5, 4),
  _PoemForm('七言絶句', 7, 4),
  _PoemForm('五言律詩', 5, 8),
  _PoemForm('七言律詩', 7, 8),
];

GenQ? _poemForm(Random r) {
  final p = r.pick(_poemForms);
  final others = _poemForms.where((o) => o != p);
  final total = p.chars * p.lines;
  return switch (r.nextInt(4)) {
    0 => GenQ(
        prompt: '${p.name}の形は？',
        answer: p.shape,
        wrong: _shuffle(r, others.map((o) => o.shape)),
        explanation: '${p.name}は${p.chars}字×${p.lines}句で、全部で$total字。',
        category: QuestionCategory.knowledge,
      ),
    1 => GenQ(
        prompt: '1句${p.chars}字、${p.lines}句からなる漢詩の形式は？',
        answer: p.name,
        wrong: _shuffle(r, [...others.map((o) => o.name), '古体詩']),
        explanation: '${p.chars == 5 ? '五言' : '七言'}は1句${p.chars}字、'
            '${p.lines == 4 ? '絶句は4句' : '律詩は8句'}。',
        category: QuestionCategory.knowledge,
      ),
    2 => GenQ(
        prompt: '${p.name}は、全部で何字？',
        answer: '$total字',
        wrong: _shuffle(r, [
          for (final o in others) '${o.chars * o.lines}字',
          '${total + p.chars}字',
          '${total - p.chars}字',
        ]),
        explanation: '${p.chars}字×${p.lines}句＝$total字。',
        category: QuestionCategory.knowledge,
      ),
    _ => GenQ(
        prompt: '${p.name}の押韻の原則は？',
        answer: p.rhyme,
        wrong: _shuffle(r, [
          p.chars == 5 ? '第1句末と偶数句末' : '偶数句の末',
          '奇数句の末',
          '各句の初め',
          '最後の句の末だけ',
        ]),
        explanation: '五言詩は偶数句の末、七言詩は第1句末と偶数句末で韻をふむのが原則。',
        category: QuestionCategory.knowledge,
      ),
  };
}

// ---------------- 古文：歴史的仮名遣い ----------------

/// 歴史的仮名遣い・現代仮名遣い・よくあるまちがい
const _kana = [
  ('いふ', 'いう', ['ゆう', 'いぶ']),
  ('けふ', 'きょう', ['けう', 'きゅう']),
  ('てふてふ', 'ちょうちょう', ['てうてう', 'ちゅうちゅう']),
  ('ゐなか', 'いなか', ['うぃなか', 'えなか']),
  ('まうす', 'もうす', ['みょうす', 'まあす']),
  ('かはづ', 'かわず', ['かわづ', 'かはず']),
  ('はぢ', 'はじ', ['はち', 'わじ']),
  ('やうやう', 'ようよう', ['やうよう', 'ゆうゆう']),
  ('うつくしう', 'うつくしゅう', ['うつくしょう', 'うつくしい']),
  ('あはれ', 'あわれ', ['あばれ', 'あうれ']),
  ('をかし', 'おかし', ['うかし', 'わかし']),
  ('をとこ', 'おとこ', ['うとこ', 'わとこ']),
  ('をんな', 'おんな', ['うんな', 'わんな']),
  ('おもふ', 'おもう', ['おもぶ', 'おもお']),
  ('おもひ', 'おもい', ['おもび', 'おもえ']),
  ('いへ', 'いえ', ['いべ', 'いわ']),
  ('かほ', 'かお', ['かぼ', 'かう']),
  ('こほり', 'こおり', ['こうり', 'こぼり']),
  ('たふとし', 'とうとし', ['たうとし', 'たぶとし']),
  ('あふぎ', 'おうぎ', ['あうぎ', 'あおぎ']),
  ('かうべ', 'こうべ', ['かおべ', 'くうべ']),
  ('さうらふ', 'そうろう', ['さうらう', 'そうらう']),
  ('にほひ', 'におい', ['にほい', 'におひ']),
  ('にほふ', 'におう', ['におふ', 'にほう']),
  ('ゆゑ', 'ゆえ', ['ゆへ', 'ゆい']),
  ('こゑ', 'こえ', ['こへ', 'こい']),
  ('まゐる', 'まいる', ['まえる', 'まうぃる']),
  ('あぢきなし', 'あじきなし', ['あちきなし', 'あずきなし']),
  ('いづこ', 'いずこ', ['いつこ', 'いじこ']),
  ('みづ', 'みず', ['みつ', 'みじ']),
  ('しうと', 'しゅうと', ['しょうと', 'しいと']),
  ('いうなり', 'ゆうなり', ['ようなり', 'いゆなり']),
  ('にふだう', 'にゅうどう', ['にうだう', 'にゅうだう']),
  ('せうと', 'しょうと', ['しゅうと', 'せいと']),
  ('てうど', 'ちょうど', ['ちゅうど', 'ていど']),
  ('やうす', 'ようす', ['ゆうす', 'やおす']),
  ('やうやく', 'ようやく', ['ゆうやく', 'やおやく']),
  ('くわし', 'かし', ['くあし', 'こし']),
  ('ぐわん', 'がん', ['ぐあん', 'ごん']),
  ('かなふ', 'かなう', ['かなぶ', 'かのう']),
  ('なほ', 'なお', ['なぼ', 'なう']),
  ('とほし', 'とおし', ['とうし', 'とぼし']),
  ('おほし', 'おおし', ['おうし', 'おぼし']),
  ('いはく', 'いわく', ['いばく', 'いあく']),
  ('かへる', 'かえる', ['かべる', 'かいる']),
  ('うるはし', 'うるわし', ['うるばし', 'うるあし']),
  ('あやふし', 'あやうし', ['あやぶし', 'あようし']),
  ('まうづ', 'もうず', ['もうづ', 'まうず']),
  ('さうし', 'そうし', ['さおし', 'すうし']),
  ('らうたし', 'ろうたし', ['りょうたし', 'らおたし']),
  ('をさなし', 'おさなし', ['うさなし', 'わさなし']),
  ('いふかひなし', 'いうかいなし', ['ゆうかいなし', 'いうかひなし']),
];

const _haRow = {'は': 'わ', 'ひ': 'い', 'ふ': 'う', 'へ': 'え', 'ほ': 'お'};

/// ハ行・ワ行・ぢづだけを直し、母音の続きは直さない（よくある途中までの答え）
String _kanaHalf(String s) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    b.write(switch (c) {
      'ゐ' => 'い',
      'ゑ' => 'え',
      'を' => 'お',
      'ぢ' => 'じ',
      'づ' => 'ず',
      _ when i > 0 && _haRow.containsKey(c) => _haRow[c],
      _ => c,
    });
  }
  return b.toString();
}

GenQ? _kanaGen(Random r) {
  final (old, now, miss) = r.pick(_kana);
  return GenQ(
    prompt: '「$old」を現代仮名遣いに直すと？',
    answer: now,
    wrong: _shuffle(r, [old, ...miss, _kanaHalf(old)]),
    explanation: '語中・語尾のハ行はワ行に、「ゐ・ゑ・を」は「い・え・お」に、'
        '「ぢ・づ」は「じ・ず」に、「au・iu・eu」はのばす音に直す。「$old」→「$now」。',
    category: QuestionCategory.usage,
  );
}

// ---------------- 古文：単語・古典常識 ----------------

const _kogo = [
  _Gloss('おどろく', '目を覚ます'),
  _Gloss('ありがたし', 'めったにない'),
  _Gloss('いとほし', '気の毒だ'),
  _Gloss('うつくし', 'かわいらしい', 'かわいい'),
  _Gloss('かなし', 'いとしい', 'かわいい'),
  _Gloss('めでたし', 'すばらしい', 'すばらしい'),
  _Gloss('ゆかし', '見たい・知りたい'),
  _Gloss('あさまし', '驚きあきれる'),
  _Gloss('あやし', '不思議だ'),
  _Gloss('いみじ', 'はなはだしい', 'すばらしい'),
  _Gloss('おとなし', '大人びている'),
  _Gloss('ののしる', '大騒ぎする'),
  _Gloss('ながむ', 'もの思いにふける'),
  _Gloss('つれづれなり', 'することがなく退屈だ'),
  _Gloss('やがて', 'そのまま・すぐに', 'そのまま'),
  _Gloss('さながら', 'そのまま・すべて', 'そのまま'),
  _Gloss('なかなか', 'かえって'),
  _Gloss('あながちなり', '強引だ'),
  _Gloss('うしろめたし', '気がかりだ', '気がかり'),
  _Gloss('こころもとなし', 'じれったい', '気がかり'),
  _Gloss('はしたなし', '中途半端だ・きまりが悪い', 'きまり'),
  _Gloss('かたはらいたし', 'きまりが悪い', 'きまり'),
  _Gloss('つきづきし', 'ふさわしい'),
  _Gloss('すさまじ', '興ざめだ'),
  _Gloss('念ず', 'じっと我慢する'),
  _Gloss('かしづく', '大切に育てる'),
  _Gloss('ときめく', '寵愛を受けて栄える'),
  _Gloss('おぼゆ', '（自然に）思われる'),
  _Gloss('まもる', 'じっと見つめる'),
  _Gloss('ことわり', '道理'),
  _Gloss('本意', '本来の望み'),
  _Gloss('ありく', '歩き回る'),
  _Gloss('いたづらなり', '無駄だ'),
  _Gloss('よろし', 'まあよい'),
  _Gloss('わろし', 'よくない'),
  _Gloss('をこなり', '愚かだ', '愚か'),
  _Gloss('なまめかし', '優美だ', '高貴'),
  _Gloss('あてなり', '高貴だ・上品だ', '高貴'),
  _Gloss('やむごとなし', '身分が高い', '高貴'),
  _Gloss('さうざうし', '物足りない'),
  _Gloss('心憂し', 'つらい'),
  _Gloss('ゆゆし', '不吉だ・おそれ多い'),
  _Gloss('あまた', 'たくさん', 'たくさん'),
  _Gloss('ここら', 'たくさん', 'たくさん'),
  _Gloss('いつしか', '早く'),
  _Gloss('かたち', '容貌'),
  _Gloss('うたて', 'いやだ'),
  _Gloss('をり', '時・機会'),
  _Gloss('つとめて', '早朝・翌朝', '朝'),
  _Gloss('おろかなり', 'いいかげんだ', '愚か'),
];

const _months = [
  '睦月', '如月', '弥生', '卯月', '皐月', '水無月', //
  '文月', '葉月', '長月', '神無月', '霜月', '師走',
];

const _eto = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

GenQ? _month(Random r) {
  final m = r.range(1, 12);
  final name = _months[m - 1];
  final reverse = r.nextBool();
  return GenQ(
    prompt: reverse ? '陰暦の$m月の異名は？' : '「$name」は陰暦の何月？',
    answer: reverse ? name : '$m月',
    wrong: _shuffle(r, [
      for (var i = 1; i <= 12; i++)
        if (i != m) reverse ? _months[i - 1] : '$i月'
    ]),
    explanation: '睦月・如月・弥生・卯月・皐月・水無月・文月・葉月・長月・神無月・霜月・師走（1月〜12月）。',
    category: QuestionCategory.knowledge,
  );
}

String _hourRange(int i) {
  // 子の刻は午後11時〜午前1時。以後2時間ずつ
  final s = (23 + 2 * i) % 24, e = (s + 2) % 24;
  String h(int x) => x < 12 ? '午前$x時' : '午後${x - 12}時';
  return '${h(s)}〜${h(e)}';
}

GenQ? _etoTime(Random r) {
  final i = r.nextInt(12);
  return GenQ(
    prompt: '昔の時刻で「${_eto[i]}の刻」は、今のおよそ何時ごろ？',
    answer: _hourRange(i),
    wrong: _shuffle(r, [
      for (var j = 0; j < 12; j++)
        if (j != i) _hourRange(j)
    ]),
    explanation: '子の刻（午後11時〜午前1時）から、十二支の順に2時間ずつ進む。',
    category: QuestionCategory.knowledge,
  );
}

const _directions = {
  '子': '北',
  '卯': '東',
  '午': '南',
  '酉': '西',
  '丑寅（艮）': '北東',
  '辰巳（巽）': '南東',
  '未申（坤）': '南西',
  '戌亥（乾）': '北西',
};

GenQ? _etoDirection(Random r) {
  final e = r.pick(_directions.entries.toList());
  return GenQ(
    prompt: '昔の方角で「${e.key}」はどの方角？',
    answer: e.value,
    wrong: _shuffle(r, _directions.values.where((v) => v != e.value)),
    explanation: '子＝北、卯＝東、午＝南、酉＝西。その間は丑寅（北東）・辰巳（南東）・未申（南西）・戌亥（北西）。',
    category: QuestionCategory.knowledge,
  );
}

// ---------------- 古文：助動詞 ----------------

class _Jodoshi {
  const _Jodoshi(this.name, this.means, this.setsuzoku);
  final String name;
  final List<String> means;
  final String setsuzoku;
  String get meaning => means.join('・');
}

const _jMu = _Jodoshi('む', ['推量', '意志', '勧誘', '仮定', '婉曲'], '未然形');
const _jKi = _Jodoshi('き', ['過去'], '連用形');
const _jKeri = _Jodoshi('けり', ['過去', '詠嘆'], '連用形');
const _jTsu = _Jodoshi('つ', ['完了', '強意'], '連用形');
const _jNu = _Jodoshi('ぬ', ['完了', '強意'], '連用形');
const _jTari = _Jodoshi('たり（完了）', ['完了', '存続'], '連用形');
const _jRi = _Jodoshi('り', ['完了', '存続'], 'サ変の未然形・四段の已然形');
const _jZu = _Jodoshi('ず', ['打消'], '未然形');
const _jJi = _Jodoshi('じ', ['打消推量', '打消意志'], '未然形');
const _jMaji =
    _Jodoshi('まじ', ['打消推量', '打消意志', '不可能', '打消当然', '禁止', '不適当'], '終止形');
const _jBeshi = _Jodoshi('べし', ['推量', '意志', '可能', '当然', '命令', '適当'], '終止形');
const _jRamu = _Jodoshi('らむ', ['現在推量', '原因推量', '伝聞', '婉曲'], '終止形');
const _jKemu = _Jodoshi('けむ', ['過去推量', '過去の原因推量', '過去の伝聞', '過去の婉曲'], '連用形');
const _jMashi = _Jodoshi('まし', ['反実仮想', 'ためらいの意志', '実現不可能な希望'], '未然形');
const _jRu = _Jodoshi('る', ['受身', '尊敬', '自発', '可能'], '未然形');
const _jRaru = _Jodoshi('らる', ['受身', '尊敬', '自発', '可能'], '未然形');
const _jSu = _Jodoshi('す', ['使役', '尊敬'], '未然形');
const _jSasu = _Jodoshi('さす', ['使役', '尊敬'], '未然形');
const _jShimu = _Jodoshi('しむ', ['使役', '尊敬'], '未然形');
const _jNari = _Jodoshi('なり（断定）', ['断定', '存在'], '体言・連体形');
const _jNariD = _Jodoshi('なり（伝聞推定）', ['伝聞', '推定'], '終止形');
const _jMeri = _Jodoshi('めり', ['推定', '婉曲'], '終止形');
const _jRashi = _Jodoshi('らし', ['推定'], '終止形');
const _jTashi = _Jodoshi('たし', ['希望'], '連用形');
const _jMahoshi = _Jodoshi('まほし', ['希望'], '未然形');
const _jGotoshi = _Jodoshi('ごとし', ['比況', '例示'], '連体形・助詞「が」「の」');

const _jodoshiAll = [
  _jMu, _jKi, _jKeri, _jTsu, _jNu, _jTari, _jRi, _jZu, _jJi, _jMaji, //
  _jBeshi, _jRamu, _jKemu, _jMashi, _jRu, _jRaru, _jSu, _jSasu, _jShimu,
  _jNari, _jNariD, _jMeri, _jRashi, _jTashi, _jMahoshi, _jGotoshi,
];

/// その意味をもつ助動詞を答えさせる意味（ほかと取りちがえない、はっきりしたもの）
const _jodoshiLabels = [
  '反実仮想', '現在推量', '過去推量', '希望', '比況', '使役', '打消推量', //
  '断定', '詠嘆', '受身', '打消', '存続',
];

List<Gen> _jodoshiGens(List<_Jodoshi> focus) => [
      (r) {
        final j = r.pick(focus);
        return GenQ(
          prompt: '助動詞「${j.name}」の意味は？',
          answer: j.meaning,
          wrong: _shuffle(r, {
            for (final o in _jodoshiAll)
              if (!_overlap(o.meaning, j.meaning)) o.meaning
          }),
          explanation: '「${j.name}」の意味は${j.meaning}。接続は${j.setsuzoku}。',
          category: QuestionCategory.usage,
        );
      },
      (r) {
        final j = r.pick(focus);
        return GenQ(
          prompt: '助動詞「${j.name}」の接続は？',
          answer: j.setsuzoku,
          wrong: _shuffle(
              r,
              {
                '未然形', '連用形', '終止形', '連体形', '已然形', //
                for (final o in _jodoshiAll) o.setsuzoku,
              }.where((w) => !_overlap(w, j.setsuzoku))),
          explanation: '「${j.name}」は${j.setsuzoku}に接続する。',
          category: QuestionCategory.usage,
        );
      },
      (r) {
        final label = r.pick(_jodoshiLabels);
        final has = [
          for (final o in focus)
            if (o.means.contains(label)) o
        ];
        if (has.isEmpty) return null;
        final j = r.pick(has);
        final all = [
          for (final o in _jodoshiAll)
            if (o.means.contains(label)) '「${o.name}」'
        ];
        return GenQ(
          prompt: '「$label」の意味をもつ助動詞は？',
          answer: '「${j.name}」',
          wrong: _shuffle(r, [
            for (final o in _jodoshiAll)
              // 似た意味（「推量」に対する「打消推量」など）をもつものも外す
              if (!o.means.any((m) => m.contains(label) || label.contains(m)))
                '「${o.name}」'
          ]),
          explanation: '「$label」の意味をもつ助動詞は${all.join('')}。',
          category: QuestionCategory.usage,
        );
      },
    ];

/// 接続の答えが一部でも重なるか（「連体形」と「体言・連体形」など）
bool _overlap(String a, String b) {
  final xs = a.split('・'), ys = b.split('・');
  return xs.any((x) => ys.any((y) => x.contains(y) || y.contains(x)));
}

const _kakari = {
  'ぞ': ('連体形', '強意'),
  'なむ': ('連体形', '強意'),
  'こそ': ('已然形', '強意'),
  'や': ('連体形', '疑問・反語'),
  'か': ('連体形', '疑問・反語'),
};

GenQ? _kakariGen(Random r) {
  final e = r.pick(_kakari.entries.toList());
  final askForm = r.nextBool();
  return askForm
      ? GenQ(
          prompt: '係助詞「${e.key}」の結びの活用形は？',
          answer: e.value.$1,
          wrong: _shuffle(r, ['未然形', '連用形', '終止形', '連体形', '已然形', '命令形']),
          explanation: '「ぞ・なむ・や・か」の結びは連体形、「こそ」の結びは已然形（係り結び）。',
          category: QuestionCategory.usage,
        )
      : GenQ(
          prompt: '係助詞「${e.key}」の意味は？',
          answer: e.value.$2,
          wrong: _shuffle(r, ['強意', '疑問・反語', '詠嘆', '打消', '仮定', '願望']),
          explanation: '「ぞ・なむ・こそ」は強意、「や・か」は疑問・反語。',
          category: QuestionCategory.usage,
        );
}

// ---------------- 和歌：枕詞 ----------------

/// 枕詞とかかる語（最初の語を答えにする）
const _makura = [
  ('あしひきの', ['山']),
  ('たらちねの', ['母']),
  ('あをによし', ['奈良']),
  ('ちはやぶる', ['神']),
  ('ひさかたの', ['光', '天', '空', '月', '雨', '雲']),
  ('くさまくら', ['旅']),
  ('あらたまの', ['年']),
  ('いはばしる', ['垂水']),
  ('しきしまの', ['大和']),
  ('そらみつ', ['大和']),
  ('とぶとりの', ['明日香']),
  ('ももしきの', ['大宮']),
  ('たまきはる', ['命']),
  ('わかくさの', ['妻']),
];

GenQ? _makuraGen(Random r) {
  final (m, words) = r.pick(_makura);
  if (r.nextBool()) {
    return GenQ(
      prompt: '枕詞「$m」がかかる語は？',
      answer: words.first,
      wrong: _shuffle(r, {
        for (final (_, ws) in _makura)
          if (!words.contains(ws.first)) ws.first
      }),
      explanation: '「$m」は「${words.join('・')}」にかかる枕詞。',
      category: QuestionCategory.knowledge,
    );
  }
  final w = words.first;
  return GenQ(
    prompt: '「$w」にかかる枕詞は？',
    answer: m,
    wrong: _shuffle(r, [
      for (final (o, ws) in _makura)
        if (!ws.contains(w)) o
    ]),
    explanation: '「$m」は「${words.join('・')}」にかかる枕詞。',
    category: QuestionCategory.knowledge,
  );
}

// ---------------- 文学史：作品と作者 ----------------

const _classicWorks = [
  ('源氏物語', '紫式部'),
  ('紫式部日記', '紫式部'),
  ('枕草子', '清少納言'),
  ('方丈記', '鴨長明'),
  ('発心集', '鴨長明'),
  ('徒然草', '兼好法師'),
  ('土佐日記', '紀貫之'),
  ('蜻蛉日記', '藤原道綱母'),
  ('更級日記', '菅原孝標女'),
  ('和泉式部日記', '和泉式部'),
  ('十六夜日記', '阿仏尼'),
  ('おくのほそ道', '松尾芭蕉'),
  ('おらが春', '小林一茶'),
  ('雨月物語', '上田秋成'),
  ('好色一代男', '井原西鶴'),
  ('曽根崎心中', '近松門左衛門'),
  ('南総里見八犬伝', '曲亭馬琴'),
  ('東海道中膝栗毛', '十返舎一九'),
  ('玉勝間', '本居宣長'),
  ('風姿花伝', '世阿弥'),
  ('金槐和歌集', '源実朝'),
  ('山家集', '西行'),
  ('折たく柴の記', '新井白石'),
  ('蘭学事始', '杉田玄白'),
];

const _modernWorks = [
  ('吾輩は猫である', '夏目漱石'),
  ('こころ', '夏目漱石'),
  ('坊っちゃん', '夏目漱石'),
  ('舞姫', '森鷗外'),
  ('高瀬舟', '森鷗外'),
  ('羅生門', '芥川龍之介'),
  ('鼻', '芥川龍之介'),
  ('蜘蛛の糸', '芥川龍之介'),
  ('走れメロス', '太宰治'),
  ('人間失格', '太宰治'),
  ('斜陽', '太宰治'),
  ('城の崎にて', '志賀直哉'),
  ('暗夜行路', '志賀直哉'),
  ('雪国', '川端康成'),
  ('伊豆の踊子', '川端康成'),
  ('金閣寺', '三島由紀夫'),
  ('山月記', '中島敦'),
  ('銀河鉄道の夜', '宮沢賢治'),
  ('注文の多い料理店', '宮沢賢治'),
  ('たけくらべ', '樋口一葉'),
  ('にごりえ', '樋口一葉'),
  ('小説神髄', '坪内逍遙'),
  ('破戒', '島崎藤村'),
  ('若菜集', '島崎藤村'),
  ('夜明け前', '島崎藤村'),
  ('みだれ髪', '与謝野晶子'),
  ('一握の砂', '石川啄木'),
  ('赤光', '斎藤茂吉'),
  ('道程', '高村光太郎'),
  ('智恵子抄', '高村光太郎'),
  ('月に吠える', '萩原朔太郎'),
  ('檸檬', '梶井基次郎'),
  ('蟹工船', '小林多喜二'),
  ('細雪', '谷崎潤一郎'),
  ('山椒魚', '井伏鱒二'),
  ('黒い雨', '井伏鱒二'),
  ('蒲団', '田山花袋'),
  ('五重塔', '幸田露伴'),
  ('病牀六尺', '正岡子規'),
  ('武蔵野', '国木田独歩'),
  ('野菊の墓', '伊藤左千夫'),
  ('或る女', '有島武郎'),
  ('友情', '武者小路実篤'),
  ('恩讐の彼方に', '菊池寛'),
  ('風立ちぬ', '堀辰雄'),
  ('沈黙', '遠藤周作'),
  ('砂の女', '安部公房'),
];

List<Gen> _worksGens(List<(String, String)> works) => [
      (r) {
        final (w, a) = r.pick(works);
        return GenQ(
          prompt: '『$w』の作者は？',
          answer: a,
          wrong: _shuffle(r, {
            for (final (_, o) in works)
              if (o != a) o
          }),
          explanation: '『$w』は$aの作品。',
          category: QuestionCategory.knowledge,
        );
      },
      (r) {
        final (w, a) = r.pick(works);
        final mine = [
          for (final (x, o) in works)
            if (o == a) '『$x』'
        ];
        return GenQ(
          prompt: '$aの作品は？',
          answer: '『$w』',
          wrong: _shuffle(r, [
            for (final (x, o) in works)
              if (o != a) '『$x』'
          ]),
          explanation: '$aの作品には${mine.join('')}などがある。',
          category: QuestionCategory.knowledge,
        );
      },
    ];

// ---------------- 登録 ----------------

final japaneseGens = <String, List<Gen>>{
  'japanese.gendai.language.grammar.keigo': [
    _keigoAsk,
    _keigoReverse,
    _keigoKind,
    _keigoSentence,
  ],
  'japanese.gendai.vocab.meaning.antonym': [_antonym, _antonymPair],
  'japanese.gendai.vocab.meaning.critical': [_antonym],
  'japanese.gendai.vocab.idiom': _glossGens(
    _idioms,
    ask: (w) => '「$w」の意味は？',
    askReverse: (g) => '「$g」という意味の言葉は？',
    explain: (e) => '「${e.word}」：${e.gloss}。',
  ),
  'japanese.kanbun.kundoku.saidoku.saidoku': [
    _saidokuRead,
    _saidokuWhich,
    _saidokuKaki,
  ],
  'japanese.kanbun.text.poem.form': [_poemForm],
  'japanese.kobun.word.kana.kana': [_kanaGen],
  'japanese.kobun.word.word.basic': [
    ..._glossGens(
      _kogo,
      ask: (w) => '古文単語「$w」の意味として最も適切なものは？',
      askReverse: (g) => '「$g」という意味の古文単語は？',
      explain: (e) => '「${e.word}」：${e.gloss}。',
    ),
    _month,
    _etoTime,
    _etoDirection,
  ],
  'japanese.kobun.grammar.jodoshi': _jodoshiGens(_jodoshiAll),
  'japanese.kobun.grammar.jodoshi.past': _jodoshiGens([_jKi, _jKeri, _jKemu]),
  'japanese.kobun.grammar.jodoshi.negative': _jodoshiGens([_jZu, _jJi, _jMaji]),
  'japanese.kobun.grammar.jodoshi.guess': _jodoshiGens(
      [_jMu, _jBeshi, _jRamu, _jKemu, _jMashi, _jMeri, _jRashi, _jNariD]),
  'japanese.kobun.grammar.jodoshi.passive':
      _jodoshiGens([_jRu, _jRaru, _jSu, _jSasu, _jShimu]),
  'japanese.kobun.grammar.jodoshi.assert': _jodoshiGens([_jNari, _jGotoshi]),
  'japanese.kobun.grammar.discern': [_kakariGen],
  'japanese.kobun.reading.waka.rhetoric': [_makuraGen],
  'japanese.kobun.reading.history.works': _worksGens(_classicWorks),
};

/// 単元の上の階層 → 作り方
final japanesePrefixGens = <String, List<Gen>>{
  'japanese.gendai.language.literature':
      _worksGens([..._classicWorks, ..._modernWorks]),
};
