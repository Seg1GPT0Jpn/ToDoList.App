import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';

// 情報Ⅰの問題の作り方。答えはすべて計算で出す。

String _bin(int v, [int width = 0]) => v.toRadixString(2).padLeft(width, '0');
String _hex(int v) => v.toRadixString(16).toUpperCase();

/// 2進数・16進数と10進数
GenQ? _radix(Random r) {
  final kind = r.nextInt(4);
  if (kind == 0) {
    final v = r.range(5, 255);
    final b = _bin(v);
    return GenQ(
      prompt: '2進数 $b を10進数で表すと？',
      answer: '$v',
      wrong: ['${v + 1}', '${v - 1}', '${v * 2}', '${v ~/ 2}', b],
      explanation: '各桁に 2 の累乗（1, 2, 4, 8, …）をかけてたす。',
    );
  }
  if (kind == 1) {
    final v = r.range(5, 255);
    return GenQ(
      prompt: '10進数の $v を2進数で表すと？',
      answer: _bin(v),
      wrong: [
        _bin(v + 1),
        _bin(v - 1),
        _bin(v).split('').reversed.join(),
        _bin(v ^ 2)
      ],
      explanation: '2で割った余りを下から順に並べる。',
    );
  }
  if (kind == 2) {
    final v = r.range(16, 255);
    return GenQ(
      prompt: '16進数 ${_hex(v)} を10進数で表すと？',
      answer: '$v',
      wrong: [
        '${v + 1}',
        '${v - 1}',
        '${v + 16}',
        '${(v ~/ 16) * 10 + v % 16}'
      ],
      explanation: '上の桁×16＋下の桁＝${v ~/ 16}×16＋${v % 16}',
    );
  }
  final v = r.range(16, 255);
  final b = _bin(v, 8);
  return GenQ(
    prompt: '2進数 $b を16進数で表すと？',
    answer: _hex(v),
    wrong: [_hex(v + 1), _hex(v ^ 16), _hex(((v & 15) << 4) | (v >> 4)), '$v'],
    explanation:
        '4桁ずつ区切る：${b.substring(0, 4)}→${_hex(v >> 4)}、${b.substring(4)}→${_hex(v & 15)}',
  );
}

/// 2進数のたし算
GenQ? _binAdd(Random r) {
  final a = r.range(3, 60), b = r.range(3, 60);
  return GenQ(
    prompt: '2進数の計算 ${_bin(a)}＋${_bin(b)} の答えは？（2進数で）',
    answer: _bin(a + b),
    wrong: [_bin(a + b + 1), _bin(a + b - 1), _bin(a ^ b), _bin(a | b)],
    explanation: '10進数では $a＋$b＝${a + b}',
  );
}

/// n ビットで表せる数
GenQ? _bits(Random r) {
  final kind = r.nextInt(3);
  final n = r.range(2, 16);
  final v = 1 << n;
  if (kind == 0) {
    return GenQ(
      prompt: '$n ビットで表せる値は何通り？',
      answer: '$v通り',
      wrong: ['${v - 1}通り', '${2 * n}通り', '${n * n}通り', '${v * 2}通り'],
      explanation: '1ビットで2通りなので 2${Fmt.sup(n)}＝$v',
    );
  }
  if (kind == 1) {
    final c = r.range(3, 1000);
    var bits = 0;
    while ((1 << bits) < c) {
      bits++;
    }
    return GenQ(
      prompt: '$c 種類のものを区別するのに、最低何ビット必要？',
      answer: '$bitsビット',
      wrong: ['${bits + 1}ビット', '${bits - 1}ビット', '${bits + 2}ビット', '$cビット'],
      explanation:
          '2${Fmt.sup(bits - 1)}＝${1 << (bits - 1)}<$c≦2${Fmt.sup(bits)}＝${1 << bits}',
      category: QuestionCategory.thinking,
    );
  }
  final px = r.pick([1, 2, 4, 8, 16, 24]);
  final colors = pow(2, px).toInt();
  return GenQ(
    prompt: '1画素を $px ビットで表すとき、表せる色は何色？',
    answer: '$colors色',
    wrong: ['${px * 2}色', '${colors - 1}色', '${colors * 2}色', '$px色'],
    explanation: '2${Fmt.sup(px)}＝$colors',
  );
}

/// 2の補数（8ビット）
GenQ? _twosComplement(Random r) {
  final v = r.range(1, 127);
  final enc = (256 - v) & 255;
  return GenQ(
    prompt: '−$v を 8 ビットの 2 の補数で表すと？',
    answer: _bin(enc, 8),
    wrong: [
      _bin(v, 8),
      _bin(255 - v, 8),
      _bin((enc + 1) & 255, 8),
      _bin(v | 128, 8)
    ],
    explanation: '$v（${_bin(v, 8)}）の各ビットを反転して 1 をたす。',
  );
}

/// 文字コード：n ビットで区別できる文字
GenQ? _textBits(Random r) {
  final n = r.pick([7, 8, 16]);
  final v = 1 << n;
  return GenQ(
    prompt: '1文字を $n ビットで表す文字コードでは、最大何種類の文字を区別できる？',
    answer: '$v種類',
    wrong: ['${v - 1}種類', '${n * 8}種類', '${v ~/ 2}種類', '${v * 2}種類'],
    explanation: '2${Fmt.sup(n)}＝$v',
  );
}

/// 画像のデータ量（バイト）
GenQ? _imageSize(Random r) {
  final w = r.pick([4, 8, 10, 16, 20, 32, 64, 100, 160, 320, 640]);
  final h = r.pick([4, 8, 10, 16, 20, 32, 48, 100, 120, 240, 480]);
  final bpp = r.pick([1, 8, 24]);
  final bits = w * h * bpp;
  if (bits % 8 != 0) return null;
  final bytes = bits ~/ 8;
  return GenQ(
    prompt: '横 $w 画素、縦 $h 画素、1画素 $bpp ビットの画像のデータ量は何バイト？（圧縮しない）',
    answer: '$bytesバイト',
    wrong: ['$bitsバイト', '${w * h}バイト', '${bytes * 3}バイト', '${bytes ~/ 2}バイト'],
    explanation: '$w×$h×$bpp＝$bits ビット＝$bytes バイト',
  );
}

/// 音のデータ量（バイト）
GenQ? _soundSize(Random r) {
  final hz = r.pick([8000, 11025, 22050, 44100, 48000]);
  final bits = r.pick([8, 16]);
  final ch = r.pick([1, 2]);
  final sec = r.range(1, 10);
  final bytes = hz * bits * ch * sec ~/ 8;
  return GenQ(
    prompt:
        '標本化周波数 $hz Hz、量子化ビット数 $bits ビット、${ch == 1 ? 'モノラル' : 'ステレオ'}で $sec 秒間録音したときのデータ量は何バイト？（圧縮しない）',
    answer: '$bytesバイト',
    wrong: [
      '${bytes * 8}バイト',
      '${ch == 1 ? bytes * 2 : bytes ~/ 2}バイト',
      '${hz * sec}バイト',
      '${bytes ~/ sec}バイト'
    ],
    explanation: '$hz×$bits×$ch×$sec÷8＝$bytes',
  );
}

/// 論理演算
GenQ? _logic(Random r) {
  final a = r.nextInt(2), b = r.nextInt(2);
  final ops = <(String, int)>[
    ('AND', a & b), ('OR', a | b), ('XOR', a ^ b), //
    ('NAND', 1 - (a & b)), ('NOR', 1 - (a | b)),
  ];
  final (op, v) = r.pick(ops);
  return GenQ(
    prompt: '$a $op $b の結果は？',
    answer: '$v',
    wrong: ['${1 - v}', 'エラー', '2', '−1'],
    explanation: '$op：${switch (op) {
      'AND' => '両方1のときだけ1',
      'OR' => 'どちらかが1なら1',
      'XOR' => '異なるときだけ1',
      'NAND' => 'AND の反対',
      _ => 'OR の反対',
    }}',
  );
}

/// 論理式 (A op B) op C
GenQ? _logicExpr(Random r) {
  final a = r.nextInt(2), b = r.nextInt(2), c = r.nextInt(2);
  final op1 = r.pick(['AND', 'OR']), op2 = r.pick(['AND', 'OR']);
  final neg = r.nextBool();
  int f(String op, int x, int y) => op == 'AND' ? x & y : x | y;
  final inner = f(op1, a, b);
  final v = f(op2, neg ? 1 - inner : inner, c);
  final expr = neg ? 'NOT (A $op1 B) $op2 C' : '(A $op1 B) $op2 C';
  return GenQ(
    prompt: 'A=$a、B=$b、C=$c のとき、$expr の値は？',
    answer: '$v',
    wrong: ['${1 - v}', '2', 'A と同じ', '決まらない'],
    explanation: 'かっこの中から計算：A $op1 B＝$inner${neg ? '、NOT で ${1 - inner}' : ''}',
    category: QuestionCategory.thinking,
  );
}

/// 半加算器
GenQ? _halfAdder(Random r) {
  final a = r.nextInt(2), b = r.nextInt(2);
  final s = a ^ b, c = a & b;
  String out(int ss, int cc) => 'S=$ss、C=$cc';
  return GenQ(
    prompt: '半加算器に A=$a、B=$b を入力したとき、出力 S（和）と C（桁上がり）は？',
    answer: out(s, c),
    wrong: [out(c, s), out(1 - s, c), out(s, 1 - c), out(1 - s, 1 - c)],
    explanation: 'S＝A XOR B、C＝A AND B',
  );
}

/// クロック周波数
GenQ? _clock(Random r) {
  final ghz = r.range(1, 5);
  return GenQ(
    prompt: 'クロック周波数 $ghz GHz の CPU は、1秒間に何回の信号を刻む？',
    answer: '${ghz * 10}億回',
    wrong: ['$ghz億回', '${ghz * 100}億回', '$ghz万回', '${ghz * 1000}万回'],
    explanation: '1 GHz＝10億 Hz なので $ghz GHz＝${ghz * 10}億回',
  );
}

/// 稼働率（直列・並列）
GenQ? _reliability(Random r) {
  // 稼働率は千分率の整数で計算して、最後に小数にする
  final a = r.pick([800, 900, 950, 990]), b = r.pick([800, 900, 950, 990]);
  final series = r.nextBool();
  final ab = a * b; // 1,000,000 分率
  final par = 1000000 - (1000 - a) * (1000 - b);
  String dec(int perMillion) {
    var s = (perMillion / 1000000).toStringAsFixed(6);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
  }

  final ans = dec(series ? ab : par);
  return GenQ(
    prompt:
        '稼働率 ${dec(a * 1000)} の装置と稼働率 ${dec(b * 1000)} の装置を${series ? '直列' : '並列'}につないだシステムの稼働率は？${series ? '' : '（どちらか1台が動けばよい）'}',
    answer: ans,
    wrong: [
      dec(series ? par : ab),
      dec(a * 1000),
      dec(b * 1000),
      dec((a + b) * 500)
    ],
    explanation: series
        ? '直列は両方動く必要があるので ${dec(a * 1000)}×${dec(b * 1000)}'
        : '並列は 1−(1−${dec(a * 1000)})(1−${dec(b * 1000)})',
  );
}

/// 転送時間
GenQ? _transfer(Random r) {
  final mbps = r.pick([10, 20, 50, 100, 200, 500, 1000]);
  final mb = r.pick([10, 25, 50, 100, 125, 250, 500, 1000, 2000]);
  final bits = mb * 8;
  if (bits % mbps != 0) return null;
  final sec = bits ~/ mbps;
  return GenQ(
    prompt: '$mbps Mbps の回線で $mb MB のファイルを送るのにかかる時間は？（1B＝8bit、伝送効率 100%）',
    answer: '$sec秒',
    wrong: [
      '${mb ~/ mbps == 0 ? sec * 2 : mb ~/ mbps}秒',
      '${sec * 8}秒',
      '${sec + 1}秒',
      '${sec * 10}秒'
    ],
    explanation: '$mb MB＝$bits Mbit。$bits÷$mbps＝$sec 秒',
  );
}

/// サブネット：割り当てられるアドレス数
GenQ? _subnet(Random r) {
  final p = r.range(22, 30);
  final total = 1 << (32 - p);
  return GenQ(
    prompt: 'サブネットマスクが /$p のネットワークで、機器に割り当てられるアドレスの数は？',
    answer: '${total - 2}',
    wrong: [
      '$total',
      '${total - 1}',
      '${total * 2 - 2}',
      '${(total ~/ 2) - 2}'
    ],
    explanation:
        'ホスト部 ${32 - p} ビットで 2${Fmt.sup(32 - p)}＝$total。ネットワークアドレスとブロードキャストアドレスの2つを除く。',
  );
}

/// パスワードの組み合わせ
GenQ? _password(Random r) {
  final kind = r.pick(
      [('数字', 10), ('英小文字', 26), ('英大文字と英小文字', 52), ('英数字（大文字・小文字・数字）', 62)]);
  final len = r.range(2, kind.$2 == 10 ? 8 : 4);
  final v = pow(kind.$2, len).toInt();
  return GenQ(
    prompt: '${kind.$1}（${kind.$2}種類）$len文字のパスワードは何通り？',
    answer: '$v通り',
    wrong: [
      '${kind.$2 * len}通り',
      '${pow(kind.$2, len + 1).toInt()}通り',
      '${v - 1}通り',
      '${pow(kind.$2, len - 1).toInt()}通り',
    ],
    explanation: '各文字が ${kind.$2} 通りなので ${kind.$2}${Fmt.sup(len)}',
  );
}

/// パリティビット
GenQ? _parity(Random r) {
  final v = r.range(0, 127);
  final data = _bin(v, 7);
  final ones = data.split('').where((c) => c == '1').length;
  final even = r.nextBool();
  final bit = even ? ones % 2 : 1 - ones % 2;
  return GenQ(
    prompt: '7ビットのデータ $data に${even ? '偶数' : '奇数'}パリティのビットを付ける。付けるビットは？',
    answer: '$bit',
    wrong: ['${1 - bit}', '2', '$ones', '7'],
    explanation: '1 の個数は $ones 個。全体の 1 の個数が${even ? '偶数' : '奇数'}になるようにする。',
  );
}

const _words = [
  'APPLE', 'BOOK', 'CAT', 'DOG', 'EGG', 'FISH', 'GAME', 'HELLO', 'INFO',
  'JAPAN', //
  'KEY', 'LIGHT', 'MUSIC', 'NOTE', 'OPEN', 'PASS', 'QUIZ', 'RAIN', 'STAR',
  'TIME',
  'WORLD', 'DATA', 'CODE', 'NET', 'SAFE',
];

String _caesar(String w, int k) => String.fromCharCodes(
      w.codeUnits.map((c) => (c - 65 + k) % 26 + 65),
    );

/// シーザー暗号
GenQ? _caesarQ(Random r) {
  final w = r.pick(_words), k = r.range(1, 5);
  final enc = _caesar(w, k);
  if (r.nextBool()) {
    return GenQ(
      prompt: '文字をアルファベット順に $k 文字ずらすシーザー暗号で「$w」を暗号化すると？',
      answer: enc,
      wrong: [
        _caesar(w, 26 - k),
        _caesar(w, k + 1),
        _caesar(w, k - 1 == 0 ? 2 : k - 1),
        w
      ],
      explanation: '各文字を $k 文字あとの文字に置きかえる（Z の次は A）。',
    );
  }
  return GenQ(
    prompt: 'アルファベット順に $k 文字ずらすシーザー暗号の暗号文「$enc」を復号すると？',
    answer: w,
    wrong: [_caesar(enc, k), _caesar(w, 1), _caesar(w, 25), enc],
    explanation: '各文字を $k 文字前の文字にもどす。',
  );
}

/// プログラムのトレース（くり返し）
GenQ? _trace(Random r) {
  final kind = r.nextInt(4);
  final a = r.range(0, 3), b = r.range(a + 3, a + 9);
  var s = kind == 2 ? 1 : 0;
  final lines = <String>[];
  switch (kind) {
    case 0:
      for (var i = a; i < b; i++) {
        s += i;
      }
      lines.addAll(
          ['s = 0', 'for i in range($a, $b):', '    s = s + i', 'print(s)']);
    case 1:
      final m = r.range(2, 3);
      for (var i = a; i < b; i++) {
        if (i % m == 0) s += i;
      }
      lines.addAll([
        's = 0',
        'for i in range($a, $b):',
        '    if i % $m == 0:',
        '        s = s + i',
        'print(s)'
      ]);
    case 2:
      final c = r.range(2, 3);
      final times = r.range(2, 6);
      for (var i = 0; i < times; i++) {
        s *= c;
      }
      lines.addAll(
          ['s = 1', 'for i in range($times):', '    s = s * $c', 'print(s)']);
    default:
      final step = r.range(2, 4);
      var x = r.range(20, 60);
      final start = x;
      var count = 0;
      while (x > 0) {
        x -= step;
        count++;
      }
      s = count;
      lines.addAll([
        'x = $start',
        'c = 0',
        'while x > 0:',
        '    x = x - $step',
        '    c = c + 1',
        'print(c)'
      ]);
  }
  return GenQ(
    prompt: '次のプログラムを実行したとき、表示される値は？\n${lines.join('\n')}',
    answer: '$s',
    wrong: ['${s + 1}', '${s - 1}', '${s + b}', '${s * 2}', '${s + 2}'],
    explanation: '変数の値を1回ずつ書き出して確かめる（トレース）。',
    category: QuestionCategory.thinking,
  );
}

/// 関数の戻り値
GenQ? _function(Random r) {
  final p = r.range(2, 5), q = r.range(1, 9);
  final x = r.range(1, 9), y = r.range(1, 9);
  final v = x * p + y - q;
  return GenQ(
    prompt:
        '次の関数で、calc($x, $y) の戻り値は？\ndef calc(a, b):\n    return a * $p + b - $q',
    answer: '$v',
    wrong: ['${y * p + x - q}', '${v + q * 2}', '${x * p}', '${v + 1}'],
    explanation: 'a＝$x、b＝$y を入れて $x×$p＋$y−$q＝$v',
    category: QuestionCategory.thinking,
  );
}

/// バブルソート1回目のパス
GenQ? _bubble(Random r) {
  final n = r.range(4, 6);
  final xs = <int>[];
  while (xs.length < n) {
    final v = r.range(1, 20);
    if (!xs.contains(v)) xs.add(v);
  }
  final a = [...xs];
  for (var i = 0; i < n - 1; i++) {
    if (a[i] > a[i + 1]) {
      final t = a[i];
      a[i] = a[i + 1];
      a[i + 1] = t;
    }
  }
  final sorted = [...xs]..sort();
  String f(List<int> v) => '[${v.join(', ')}]';
  // 右から比べていった場合（よくある勘ちがい）
  final b = [...xs];
  for (var i = n - 1; i > 0; i--) {
    if (b[i - 1] > b[i]) {
      final t = b[i];
      b[i] = b[i - 1];
      b[i - 1] = t;
    }
  }
  return GenQ(
    prompt: 'バブルソートで ${f(xs)} を昇順に並べる。左から順に隣どうしを比べて交換する1回目のパスが終わった後の配列は？',
    answer: f(a),
    wrong: [
      f(sorted),
      f(b),
      f(xs),
      f([...a.sublist(1), a.first])
    ],
    explanation: '1回目のパスで、最大値 ${sorted.last} がいちばん右へ移る。',
    category: QuestionCategory.thinking,
  );
}

/// 線形探索の比較回数
GenQ? _linearSearch(Random r) {
  final n = r.range(5, 9);
  final xs = <int>[];
  while (xs.length < n) {
    final v = r.range(1, 50);
    if (!xs.contains(v)) xs.add(v);
  }
  final pos = r.nextInt(n);
  return GenQ(
    prompt:
        '配列 [${xs.join(', ')}] を先頭から順に調べる線形探索で ${xs[pos]} を見つけるまでに、比較は何回行う？',
    answer: '${pos + 1}回',
    wrong: ['$pos回', '$n回', '${pos + 2}回', '${n - pos}回'],
    explanation: '${xs[pos]} は先頭から ${pos + 1} 番目。',
    category: QuestionCategory.thinking,
  );
}

/// 最頻値・平均値・中央値
GenQ? _stats(Random r) {
  final n = r.pick([5, 7]);
  final xs = [for (var i = 0; i < n; i++) r.range(1, 9)];
  final counts = <int, int>{};
  for (final x in xs) {
    counts[x] = (counts[x] ?? 0) + 1;
  }
  final top = counts.values.reduce(max);
  final modes = [
    for (final e in counts.entries)
      if (e.value == top) e.key
  ];
  final sorted = [...xs]..sort();
  if (r.nextBool() && modes.length == 1 && top >= 2) {
    return GenQ(
      prompt: 'データ ${xs.join(', ')} の最頻値は？',
      answer: '${modes.first}',
      wrong: [
        '${sorted[n ~/ 2]}',
        '${sorted.last}',
        '${sorted.first}',
        '$top',
        '${modes.first + 1}'
      ],
      explanation: '${modes.first} が $top 回で最も多い。',
    );
  }
  return GenQ(
    prompt: 'データ ${xs.join(', ')} の中央値は？',
    answer: '${sorted[n ~/ 2]}',
    wrong: [
      '${xs[n ~/ 2]}',
      '${sorted.last}',
      '${sorted.first}',
      '${sorted[n ~/ 2] + 1}'
    ],
    explanation: '小さい順に ${sorted.join(', ')}。真ん中は ${sorted[n ~/ 2]}。',
  );
}

final Map<String, List<Gen>> infoGens = {
  'information.info.computer.digital.binary': [_radix, _bits, _binAdd],
  'information.info.computer.digital.calc': [_twosComplement, _binAdd],
  'information.info.computer.digital': [_radix, _bits],
  'information.info.computer.media.text': [_textBits],
  'information.info.computer.media.image': [_imageSize, _bits],
  'information.info.computer.media.sound': [_soundSize],
  'information.info.computer.logic': [_logic, _logicExpr],
  'information.info.computer.logic.gate': [_logic, _logicExpr],
  'information.info.computer.logic.adder': [_halfAdder],
  'information.info.computer.hardware.cpu': [_clock],
  'information.info.computer.system.reliability': [_reliability],
  'information.info.network.basic': [_transfer, _subnet, _password],
  'information.info.network.basic.address': [_subnet],
  'information.info.network.protocol.error': [_parity],
  'information.info.network.crypto.cipher': [_caesarQ],
  'information.info.programming.program.trace': [_trace],
  'information.info.programming.program.function': [_function],
  'information.info.programming.algorithm.sort': [_bubble],
  'information.info.programming.algorithm.search': [_linearSearch],
  'information.info.data.analysis.stat': [_stats],
  'information.info.data.analysis': [_stats],
};
