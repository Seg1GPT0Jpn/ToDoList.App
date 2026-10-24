import 'dart:math';

import '../models/question.dart';
import 'gen_core.dart';

// 物理・化学の問題の作り方。数値は整数（または 0.1 単位の整数）で計算して、まちがいが入らないようにする。

String _d1(int tenths) => Fmt.dec(tenths, 1);
String _d2(int hundredths) => Fmt.dec(hundredths, 2);

// ---------------- 物理：力学 ----------------

GenQ? _work(Random r) {
  final f = r.range(2, 50), s = r.range(2, 20);
  return GenQ(
    prompt: '$f N の力で物体を力の向きに $s m 動かしたときの仕事は？',
    answer: '${f * s} J',
    wrong: ['${f + s} J', '${f * s * 2} J', '${Rat(f, s)} J', '${f * s} N'],
    explanation: '仕事＝力×移動距離＝$f×$s',
  );
}

GenQ? _kinetic(Random r) {
  final m = r.range(1, 10), v = r.range(1, 12);
  final k = Rat(m * v * v, 2);
  return GenQ(
    prompt: '質量 $m kg の物体が速さ $v m/s で動いている。運動エネルギーは？',
    answer: '$k J',
    wrong: [
      '${m * v} J',
      '${m * v * v} J',
      '${Rat(m * v, 2)} J',
      '${k + Rat(m)} J'
    ],
    explanation: 'K＝(1/2)mv²＝(1/2)×$m×$v²',
  );
}

GenQ? _potential(Random r) {
  final m = r.range(1, 10), h = r.range(1, 20);
  final u = m * h * 98; // ×0.1
  return GenQ(
    prompt: '質量 $m kg の物体が基準面から高さ $h m にある。重力による位置エネルギーは？（g＝9.8 m/s²）',
    answer: '${_d1(u)} J',
    wrong: [
      '${m * h} J',
      '${_d1(u * 2)} J',
      '${_d1(u ~/ 2)} J',
      '${_d1(m * 98)} J'
    ],
    explanation: 'U＝mgh＝$m×9.8×$h',
  );
}

GenQ? _friction(Random r) {
  final mu = r.range(1, 9), nn = r.range(2, 50);
  final kinetic = r.nextBool();
  return GenQ(
    prompt:
        '垂直抗力 $nn N、${kinetic ? '動摩擦係数' : '静止摩擦係数'} ${_d1(mu)} のとき、${kinetic ? '動摩擦力' : '最大摩擦力'}の大きさは？',
    answer: '${_d1(mu * nn)} N',
    wrong: [
      '$nn N',
      '${_d1(nn * 10 ~/ mu * 1)} N',
      '${_d1(mu * nn + 10)} N',
      '${_d1(mu * nn * 2)} N'
    ],
    explanation: '摩擦力＝係数×垂直抗力＝${_d1(mu)}×$nn',
  );
}

GenQ? _newton(Random r) {
  final kind = r.nextInt(2);
  final m = r.range(1, 10), a = r.range(1, 10);
  if (kind == 0) {
    return GenQ(
      prompt: '質量 $m kg の物体に、$a m/s² の加速度を生じさせる力は？',
      answer: '${m * a} N',
      wrong: ['${m + a} N', '${Rat(m, a)} N', '${m * a * 2} N', '${m * a} kg'],
      explanation: '運動方程式 F＝ma＝$m×$a',
    );
  }
  final f = m * a;
  return GenQ(
    prompt: '質量 $m kg の物体に $f N の力を加えた。加速度の大きさは？（ほかの力ははたらかない）',
    answer: '$a m/s²',
    wrong: ['${f * m} m/s²', '${f + m} m/s²', '${Rat(m, f)} m/s²', '$f m/s²'],
    explanation: 'a＝F/m＝$f÷$m',
  );
}

GenQ? _velocity(Random r) {
  final kind = r.nextInt(3);
  final v0 = r.range(0, 10), a = r.range(1, 5), t = r.range(1, 8);
  if (kind == 0) {
    return GenQ(
      prompt: '初速度 $v0 m/s、加速度 $a m/s² で等加速度直線運動をする物体の、$t 秒後の速さは？',
      answer: '${v0 + a * t} m/s',
      wrong: [
        '${v0 + a} m/s',
        '${a * t} m/s',
        '${v0 * t + a} m/s',
        '${v0 + a * t * t} m/s'
      ],
      explanation: 'v＝v₀＋at＝$v0＋$a×$t',
    );
  }
  if (kind == 1) {
    final x = Rat(v0 * t) + Rat(a * t * t, 2);
    return GenQ(
      prompt: '初速度 $v0 m/s、加速度 $a m/s² で等加速度直線運動をする物体が、$t 秒間に進む距離は？',
      answer: '$x m',
      wrong: [
        '${Rat(v0 * t + a * t * t)} m',
        '${Rat(v0 + a * t)} m',
        '${Rat(v0 * t) + Rat(a * t, 2)} m',
        '${x + Rat(t)} m'
      ],
      explanation: 'x＝v₀t＋(1/2)at²',
    );
  }
  final d = r.range(10, 400), tt = r.range(2, 40);
  final v = Rat(d, tt);
  return GenQ(
    prompt: '$d m を $tt 秒で進んだ。平均の速さは？',
    answer: '$v m/s',
    wrong: [
      '${Rat(tt, d)} m/s',
      '${d * tt} m/s',
      '${v + Rat(1)} m/s',
      '${Rat(d, tt * 2)} m/s'
    ],
    explanation: '速さ＝距離÷時間＝$d÷$tt',
  );
}

GenQ? _fall(Random r) {
  final t = r.range(1, 6);
  if (r.nextBool()) {
    return GenQ(
      prompt: '静かに落とした物体の $t 秒後の速さは？（g＝9.8 m/s²、空気抵抗なし）',
      answer: '${_d1(98 * t)} m/s',
      wrong: [
        '${_d1(49 * t * t)} m/s',
        '${_d1(98)} m/s',
        '${_d1(98 * t * t)} m/s',
        '${_d1(49 * t)} m/s'
      ],
      explanation: 'v＝gt＝9.8×$t',
    );
  }
  return GenQ(
    prompt: '静かに落とした物体が $t 秒間に落ちる距離は？（g＝9.8 m/s²、空気抵抗なし）',
    answer: '${_d1(49 * t * t)} m',
    wrong: [
      '${_d1(98 * t)} m',
      '${_d1(98 * t * t)} m',
      '${_d1(49 * t)} m',
      '${_d1(49 * (t + 1) * (t + 1))} m'
    ],
    explanation: 'y＝(1/2)gt²＝4.9×$t²',
  );
}

GenQ? _lever(Random r) {
  final f1 = r.range(2, 60), d1 = r.range(1, 9), d2 = r.range(1, 9);
  if (d1 == d2) return null;
  final f2 = Rat(f1 * d1, d2);
  return GenQ(
    prompt:
        '軽い棒の支点から ${_d1(d1)} m の所に $f1 N の力が下向きにかかっている。反対側の支点から ${_d1(d2)} m の所に何 N の力を下向きに加えるとつり合う？',
    answer: '$f2 N',
    wrong: [
      '${Rat(f1 * d2, d1)} N',
      '$f1 N',
      '${f2 + Rat(1)} N',
      '${Rat(f1 * (d1 + d2), d2)} N'
    ],
    explanation: '力のモーメントのつり合い：$f1×${_d1(d1)}＝F×${_d1(d2)}',
  );
}

GenQ? _hooke(Random r) {
  final k = r.range(2, 100), x = r.range(1, 20);
  if (r.nextBool()) {
    return GenQ(
      prompt: 'ばね定数 $k N/m のばねを ${_d2(x)} m 伸ばすのに必要な力は？',
      answer: '${_d2(k * x)} N',
      wrong: [
        '${_d2(k * x * 10)} N',
        '$k N',
        '${_d2(k * x * 2)} N',
        '${Rat(k * 100, x)} N'
      ],
      explanation: 'F＝kx＝$k×${_d2(x)}',
    );
  }
  final f = k * x;
  return GenQ(
    prompt: 'ばね定数 $k N/m のばねに ${_d2(f)} N の力を加えたときの伸びは？',
    answer: '${_d2(x)} m',
    wrong: [
      '${_d2(x * 10)} m',
      '${_d2(f * k)} m',
      '${_d2(x + 1)} m',
      '${_d2(x * 2)} m'
    ],
    explanation: 'x＝F/k＝${_d2(f)}÷$k',
  );
}

GenQ? _momentum(Random r) => _momentumKind(r, r.nextInt(2));
GenQ? _collision(Random r) => _momentumKind(r, 2);

GenQ? _momentumKind(Random r, int kind) {
  final m = r.range(1, 10), v = r.range(1, 20);
  if (kind == 0) {
    return GenQ(
      prompt: '質量 $m kg、速さ $v m/s の物体の運動量の大きさは？',
      answer: '${m * v} kg·m/s',
      wrong: [
        '${m + v} kg·m/s',
        '${Rat(m * v * v, 2)} kg·m/s',
        '${m * v * 2} kg·m/s',
        '${m * v} J'
      ],
      explanation: 'p＝mv＝$m×$v',
    );
  }
  if (kind == 1) {
    final f = r.range(2, 50), t = r.range(1, 10);
    return GenQ(
      prompt: '物体に $f N の力を ${_d1(t)} s 間加えた。物体が受けた力積の大きさは？',
      answer: '${_d1(f * t)} N·s',
      wrong: [
        '$f N·s',
        '${_d1(f * t * 10)} N·s',
        '${Rat(f * 10, t)} N·s',
        '${_d1(f * t + 10)} N·s'
      ],
      explanation: '力積＝力×時間＝$f×${_d1(t)}',
    );
  }
  // 完全非弾性衝突（一体になる）
  final m2 = r.range(1, 10);
  final v2 = Rat(m * v, m + m2);
  return GenQ(
    prompt:
        'なめらかな面上で、速さ $v m/s で動く質量 $m kg の台車が、静止している質量 $m2 kg の台車に衝突して一体になった。衝突後の速さは？',
    answer: '$v2 m/s',
    wrong: [
      '$v m/s',
      '${Rat(m2 * v, m + m2)} m/s',
      '${Rat(v, 2)} m/s',
      '${Rat(m * v, m2)} m/s'
    ],
    explanation: '運動量保存：$m×$v＝(${m}＋$m2)×V',
  );
}

// ---------------- 物理：電気 ----------------

GenQ? _ohm(Random r) {
  final i = r.range(1, 10), rr = r.range(2, 50);
  final v = i * rr;
  switch (r.nextInt(3)) {
    case 0:
      return GenQ(
        prompt: '$rr Ω の抵抗に $i A の電流が流れている。抵抗にかかる電圧は？',
        answer: '$v V',
        wrong: ['${Rat(rr, i)} V', '${rr + i} V', '${v * 2} V', '$v A'],
        explanation: 'V＝RI＝$rr×$i',
      );
    case 1:
      return GenQ(
        prompt: '$rr Ω の抵抗に $v V の電圧をかけた。流れる電流は？',
        answer: '$i A',
        wrong: ['${v * rr} A', '${Rat(rr, v)} A', '${i + 1} A', '$i V'],
        explanation: 'I＝V/R＝$v÷$rr',
      );
    default:
      return GenQ(
        prompt: 'ある抵抗に $v V の電圧をかけると $i A の電流が流れた。抵抗の大きさは？',
        answer: '$rr Ω',
        wrong: ['${v * i} Ω', '${Rat(i, v)} Ω', '${rr + 1} Ω', '${rr * 2} Ω'],
        explanation: 'R＝V/I＝$v÷$i',
      );
  }
}

GenQ? _resistors(Random r) {
  final a = r.range(1, 30), b = r.range(1, 30);
  final series = r.nextBool();
  final v = series ? Rat(a + b) : Rat(a * b, a + b);
  return GenQ(
    prompt: '$a Ω と $b Ω の抵抗を${series ? '直列' : '並列'}につないだときの合成抵抗は？',
    answer: '$v Ω',
    wrong: [
      '${series ? Rat(a * b, a + b) : Rat(a + b)} Ω',
      '${Rat(a * b)} Ω',
      '${Rat(a + b, 2)} Ω',
      '${v + Rat(1)} Ω'
    ],
    explanation: series ? '直列：R₁＋R₂' : '並列：1/R＝1/$a＋1/$b',
  );
}

GenQ? _power(Random r) {
  final kind = r.nextInt(3);
  final v = r.pick([10, 12, 20, 50, 100, 200]), i = r.range(1, 10);
  if (kind == 0) {
    return GenQ(
      prompt: '$v V の電圧で $i A の電流が流れる電気器具の消費電力は？',
      answer: '${v * i} W',
      wrong: ['${v + i} W', '${Rat(v, i)} W', '${v * i * i} W', '${v * i} J'],
      explanation: 'P＝VI＝$v×$i',
    );
  }
  if (kind == 1) {
    final p = r.pick([10, 20, 40, 60, 100, 500, 1000, 1200]),
        t = r.range(2, 60);
    return GenQ(
      prompt: '消費電力 $p W の電気器具を $t 秒間使ったときの電力量は？',
      answer: '${p * t} J',
      wrong: ['${p + t} J', '${Rat(p, t)} J', '${p * t * 60} J', '${p * t} W'],
      explanation: '電力量＝電力×時間＝$p×$t',
    );
  }
  final p = r.pick([10, 20, 40, 60, 100, 500, 1000, 1200]), h = r.range(2, 10);
  return GenQ(
    prompt: '消費電力 $p W の電気器具を $h 時間使ったときの電力量は何 Wh？',
    answer: '${p * h} Wh',
    wrong: [
      '${p * h * 60} Wh',
      '${p * h * 3600} Wh',
      '${p + h} Wh',
      '${Rat(p, h)} Wh'
    ],
    explanation: '$p W×$h h',
  );
}

GenQ? _coulombRatio(Random r) {
  final q1 = r.range(1, 4), q2 = r.range(1, 4), d = r.range(1, 4);
  if (q1 == 1 && q2 == 1 && d == 1) return null;
  final v = Rat(q1 * q2, d * d);
  return GenQ(
    prompt: '2つの点電荷の電気量をそれぞれ $q1 倍、$q2 倍にし、距離を $d 倍にした。静電気力の大きさは何倍？',
    answer: '$v倍',
    wrong: [
      '${Rat(q1 * q2, d)}倍',
      '${Rat(q1 * q2 * d * d)}倍',
      '${Rat(q1 + q2, d * d)}倍',
      '${v + Rat(1)}倍'
    ],
    explanation: 'F は電気量の積に比例し、距離の2乗に反比例する：$q1×$q2÷$d²',
  );
}

GenQ? _transformer(Random r) {
  final n1 = r.pick([100, 200, 300, 400, 500, 1000]),
      n2 = r.pick([50, 100, 200, 250, 500, 2000]);
  if (n1 == n2) return null;
  final v1 = r.pick([100, 200, 600]);
  final v2 = Rat(v1 * n2, n1);
  return GenQ(
    prompt: '一次コイル $n1 回巻き、二次コイル $n2 回巻きの変圧器の一次側に $v1 V の交流電圧をかけた。二次側の電圧は？',
    answer: '$v2 V',
    wrong: [
      '${Rat(v1 * n1, n2)} V',
      '$v1 V',
      '${v2 * Rat(2)} V',
      '${Rat(v1 * n2, n1 + n2)} V'
    ],
    explanation: 'V₁:V₂＝N₁:N₂ より V₂＝$v1×$n2/$n1',
  );
}

GenQ? _magForce(Random r) {
  final b = r.range(1, 9), i = r.range(1, 9), l = r.range(1, 9);
  // B は 0.1 単位、L は 0.1 単位
  return GenQ(
    prompt:
        '磁束密度 ${_d1(b)} T の磁場に垂直な、長さ ${_d1(l)} m の導線に $i A の電流が流れている。導線が受ける力の大きさは？',
    answer: '${_d2(b * i * l)} N',
    wrong: [
      '${_d1(b * i * l)} N',
      '${_d2(b * l)} N',
      '${_d2(b * i)} N',
      '${_d2(b * i * l * 2)} N'
    ],
    explanation: 'F＝IBL＝$i×${_d1(b)}×${_d1(l)}',
  );
}

// ---------------- 物理：熱・波・原子 ----------------

GenQ? _kelvin(Random r) {
  final c = r.range(-50, 400);
  if (r.nextBool()) {
    return GenQ(
      prompt: '${Fmt.n(c)} ℃ は絶対温度で何 K？',
      answer: '${c + 273} K',
      wrong: ['${c - 273} K', '${c + 237} K', '${c + 100} K', '${c + 273} ℃'],
      explanation: 'T＝t＋273',
    );
  }
  final k = c + 273;
  return GenQ(
    prompt: '$k K は何 ℃？',
    answer: '${Fmt.n(c)} ℃',
    wrong: ['${k + 273} ℃', '${Fmt.n(c + 1)} ℃', '${Fmt.n(k - 237)} ℃', '$k ℃'],
    explanation: 't＝T−273',
  );
}

GenQ? _heat(Random r) {
  final m = r.pick([50, 100, 200, 250, 500]), dt = r.range(2, 40);
  // 水の比熱 4.2 J/(g·K)
  final q = m * dt * 42; // ×0.1
  return GenQ(
    prompt: '水 $m g の温度を $dt K 上げるのに必要な熱量は？（水の比熱 4.2 J/(g·K)）',
    answer: '${_d1(q)} J',
    wrong: [
      '${m * dt} J',
      '${_d1(m * 42)} J',
      '${_d1(q * 10)} J',
      '${_d1(dt * 42)} J'
    ],
    explanation: 'Q＝mcΔT＝$m×4.2×$dt',
  );
}

GenQ? _wave(Random r) {
  final kind = r.nextInt(4);
  if (kind == 0) {
    final f = r.range(2, 50), lam = r.range(1, 20);
    return GenQ(
      prompt: '振動数 $f Hz、波長 $lam m の波の速さは？',
      answer: '${f * lam} m/s',
      wrong: [
        '${Rat(f, lam)} m/s',
        '${Rat(lam, f)} m/s',
        '${f + lam} m/s',
        '${f * lam * 2} m/s'
      ],
      explanation: 'v＝fλ＝$f×$lam',
    );
  }
  if (kind == 1) {
    final f1 = r.range(400, 450), d = r.range(1, 6);
    return GenQ(
      prompt: '$f1 Hz と ${f1 + d} Hz のおんさを同時に鳴らした。1 s 間のうなりの回数は？',
      answer: '$d回',
      wrong: ['${d * 2}回', '${2 * f1 + d}回', '${f1}回', '${d + 1}回'],
      explanation: 'うなりの回数＝振動数の差＝$d',
    );
  }
  if (kind == 2) {
    final l = r.range(1, 20);
    return GenQ(
      prompt: '両端を固定した長さ ${_d1(l * 10 ~/ 10 * 1)} m の弦の、基本振動の波長は？',
      answer: '${_d1(l * 2)} m',
      wrong: [
        '${_d1(l)} m',
        '${_d1(l * 4)} m',
        '${Rat(l, 20)} m',
        '${_d1(l * 3)} m'
      ],
      explanation: '基本振動では弦の長さが半波長なので λ＝2L',
    );
  }
  final t = r.range(1, 10);
  return GenQ(
    prompt: '花火が見えてから $t 秒後に音が聞こえた。花火までのおよその距離は？（音の速さ 340 m/s）',
    answer: '${340 * t} m',
    wrong: [
      '${340 * t * 2} m',
      '${340 + t} m',
      '${Rat(340, t)} m',
      '${340 * t ~/ 2} m'
    ],
    explanation: '距離＝速さ×時間＝340×$t',
  );
}

GenQ? _lens(Random r) {
  final f = r.range(5, 20), a = r.range(f + 1, 60);
  final b = Rat(a * f, a - f);
  return GenQ(
    prompt: '焦点距離 $f cm の凸レンズの前方 $a cm に物体を置いた。像ができるのはレンズの後方何 cm？',
    answer: '$b cm',
    wrong: [
      '${Rat(a - f)} cm',
      '${Rat(a * f, a + f)} cm',
      '${b + Rat(1)} cm',
      '$a cm'
    ],
    explanation: '1/a＋1/b＝1/f より 1/b＝1/$f−1/$a',
  );
}

const _isotopes = <(String, String, int, int)>[
  // 記号・名前・原子番号・質量数
  ('H', '水素', 1, 1), ('H', '水素（重水素）', 1, 2), ('He', 'ヘリウム', 2, 4),
  ('Li', 'リチウム', 3, 7), ('C', '炭素', 6, 12), ('C', '炭素', 6, 13),
  ('C', '炭素', 6, 14),
  ('N', '窒素', 7, 14), ('O', '酸素', 8, 16), ('O', '酸素', 8, 18),
  ('F', 'フッ素', 9, 19),
  ('Ne', 'ネオン', 10, 20), ('Na', 'ナトリウム', 11, 23), ('Mg', 'マグネシウム', 12, 24),
  ('Al', 'アルミニウム', 13, 27), ('Si', 'ケイ素', 14, 28), ('P', 'リン', 15, 31),
  ('S', '硫黄', 16, 32), ('Cl', '塩素', 17, 35), ('Cl', '塩素', 17, 37),
  ('Ar', 'アルゴン', 18, 40),
  ('K', 'カリウム', 19, 39), ('Ca', 'カルシウム', 20, 40), ('Fe', '鉄', 26, 56),
  ('Cu', '銅', 29, 63), ('U', 'ウラン', 92, 235), ('U', 'ウラン', 92, 238),
];

String _nuclide(String sym, int a, int z) => '${Fmt.sup(a)}${_subN(z)}$sym';
String _subN(int v) => '$v'
    .split('')
    .map((c) => const {
          '0': '₀',
          '1': '₁',
          '2': '₂',
          '3': '₃',
          '4': '₄',
          '5': '₅',
          '6': '₆',
          '7': '₇',
          '8': '₈',
          '9': '₉'
        }[c]!)
    .join();

GenQ? _decay(Random r) {
  final (sym, _, z, a) = r.pick(_isotopes.where((e) => e.$3 >= 6).toList());
  final alpha = r.nextBool();
  final na = alpha ? a - 4 : a, nz = alpha ? z - 2 : z + 1;
  String res(int aa, int zz) => '質量数 $aa、原子番号 $zz';
  return GenQ(
    prompt:
        '${_nuclide(sym, a, z)} が${alpha ? 'α' : 'β'}崩壊を1回したあとの原子核の質量数と原子番号は？',
    answer: res(na, nz),
    wrong: [
      res(a - 4, z - 2),
      res(a, z + 1),
      res(a, z - 1),
      res(a - 2, z - 4),
      res(a - 4, z + 2)
    ],
    explanation: alpha ? 'α崩壊：質量数が4、原子番号が2減る。' : 'β崩壊：質量数は変わらず、原子番号が1増える。',
  );
}

GenQ? _halfLife(Random r) {
  final half = r.pick([5, 8, 10, 12, 30, 5730]);
  final k = r.range(1, 5);
  final v = Rat(1, 1 << k);
  return GenQ(
    prompt: '半減期 $half 年の放射性物質がある。${half * k} 年後に残っている量は、はじめの何分のいくつ？',
    answer: '$v',
    wrong: [
      '${Rat(1, 2 * k)}',
      '${Rat(1, (1 << k) * 2)}',
      '${Rat(1, k + 1)}',
      '${Rat(k, 1 << (k + 1))}'
    ],
    explanation: '${half * k} 年は半減期の $k 回分なので (1/2)${Fmt.sup(k)}',
  );
}

// ---------------- 化学 ----------------

/// 原子量（教科書でよく使う値。0.1 単位の整数で持つ）
const _atomic = {
  'H': 10, 'C': 120, 'N': 140, 'O': 160, 'Na': 230, 'Mg': 240, 'Al': 270, //
  'S': 320, 'Cl': 355, 'K': 390, 'Ca': 400, 'Fe': 560, 'Cu': 640,
};

/// 物質（化学式の表記・名前・組成）
const _compounds = <(String, String, Map<String, int>)>[
  ('H₂O', '水', {'H': 2, 'O': 1}),
  ('CO₂', '二酸化炭素', {'C': 1, 'O': 2}),
  ('O₂', '酸素', {'O': 2}),
  ('N₂', '窒素', {'N': 2}),
  ('H₂', '水素', {'H': 2}),
  ('NH₃', 'アンモニア', {'N': 1, 'H': 3}),
  ('CH₄', 'メタン', {'C': 1, 'H': 4}),
  ('C₂H₆', 'エタン', {'C': 2, 'H': 6}),
  ('C₃H₈', 'プロパン', {'C': 3, 'H': 8}),
  ('C₂H₅OH', 'エタノール', {'C': 2, 'H': 6, 'O': 1}),
  ('C₆H₁₂O₆', 'グルコース', {'C': 6, 'H': 12, 'O': 6}),
  ('NaCl', '塩化ナトリウム', {'Na': 1, 'Cl': 1}),
  ('NaOH', '水酸化ナトリウム', {'Na': 1, 'O': 1, 'H': 1}),
  ('HCl', '塩化水素', {'H': 1, 'Cl': 1}),
  ('H₂SO₄', '硫酸', {'H': 2, 'S': 1, 'O': 4}),
  ('CaCO₃', '炭酸カルシウム', {'Ca': 1, 'C': 1, 'O': 3}),
  ('MgO', '酸化マグネシウム', {'Mg': 1, 'O': 1}),
  ('CuO', '酸化銅(Ⅱ)', {'Cu': 1, 'O': 1}),
  ('Fe₂O₃', '酸化鉄(Ⅲ)', {'Fe': 2, 'O': 3}),
  ('KCl', '塩化カリウム', {'K': 1, 'Cl': 1}),
  ('Al₂O₃', '酸化アルミニウム', {'Al': 2, 'O': 3}),
  ('SO₂', '二酸化硫黄', {'S': 1, 'O': 2}),
  ('Ca(OH)₂', '水酸化カルシウム', {'Ca': 1, 'O': 2, 'H': 2}),
  ('NaHCO₃', '炭酸水素ナトリウム', {'Na': 1, 'H': 1, 'C': 1, 'O': 3}),
];

/// 分子量・式量（0.1 単位）
int _mass(Map<String, int> f) =>
    f.entries.fold(0, (s, e) => s + _atomic[e.key]! * e.value);

String _atomsUsed(Map<String, int> f) =>
    f.keys.map((k) => '$k=${_d1(_atomic[k]!)}').join(', ');

GenQ? _molarMass(Random r) {
  final (formula, name, f) = r.pick(_compounds);
  final m = _mass(f);
  return GenQ(
    prompt:
        '$name $formula の${f.length == 1 && f.values.first == 2 ? '分子量' : '分子量（式量）'}は？（${_atomsUsed(f)}）',
    answer: _d1(m),
    wrong: [
      _d1(m + 10),
      _d1(m - 10),
      _d1(m + 160),
      _d1(f.values.fold(0, (s, v) => s + v) * 10 + m ~/ 2)
    ],
    explanation:
        '原子量×個数をたす：${f.entries.map((e) => '${_d1(_atomic[e.key]!)}×${e.value}').join('＋')}',
  );
}

/// 物質量（0.05 単位で持つ）
final _mols = [5, 10, 20, 25, 50, 100, 150, 200, 250, 300]; // ×0.01 mol

GenQ? _moleMass(Random r) {
  final (formula, name, f) = r.pick(_compounds);
  final m = _mass(f); // ×0.1
  final n = r.pick(_mols); // ×0.01
  final g = m * n; // ×0.001
  if (r.nextBool()) {
    return GenQ(
      prompt: '$name $formula ${_d2(n)} mol の質量は何 g？（${_atomsUsed(f)}）',
      answer: '${Fmt.dec(g, 3)} g',
      wrong: [
        '${_d1(m)} g',
        '${Fmt.dec(g * 2, 3)} g',
        '${Fmt.dec(m * 100 ~/ (n == 0 ? 1 : 1), 3)} g',
        '${Fmt.dec(g + m * 10, 3)} g'
      ],
      explanation: '質量＝物質量×モル質量＝${_d2(n)}×${_d1(m)}',
    );
  }
  return GenQ(
    prompt: '$name $formula ${Fmt.dec(g, 3)} g は何 mol？（${_atomsUsed(f)}）',
    answer: '${_d2(n)} mol',
    wrong: [
      '${_d2(n * 2)} mol',
      '${_d2(n ~/ 5 == 0 ? n + 5 : n ~/ 5)} mol',
      '${_d2(n + 50)} mol',
      '${_d1(m)} mol'
    ],
    explanation: '物質量＝質量÷モル質量＝${Fmt.dec(g, 3)}÷${_d1(m)}',
  );
}

GenQ? _particles(Random r) {
  final (formula, name, _) = r.pick(_compounds);
  final n = r.pick([5, 10, 20, 25, 50, 100, 150, 200, 300]); // ×0.01
  // 6.0×10²³ × n/100 → 仮数×10 で表す
  final mant = 60 * n; // (6.0×n/100)×10²³ の 6.0×n … 仮数×10 は 60*n/100
  // 粒子数 = 6.0e23 * n/100 = (60*n) × 10^(23-1-2)（仮数×10 として扱う）
  final ans = Fmt.sci(mant, 23 - 2);
  return GenQ(
    prompt:
        '$name $formula ${_d2(n)} mol に含まれる分子（粒子）の数は？（アボガドロ定数 6.0×10²³/mol）',
    answer: ans,
    wrong: [
      Fmt.sci(mant * 10, 21),
      Fmt.sci(mant, 22),
      Fmt.sci(60, 23),
      Fmt.sci(mant + 60, 21)
    ],
    explanation: '6.0×10²³×${_d2(n)}',
  );
}

GenQ? _gasVolume(Random r) {
  final n = r.pick(_mols); // ×0.01
  final v = 224 * n; // ×0.001 L
  if (r.nextBool()) {
    return GenQ(
      prompt: '標準状態で ${_d2(n)} mol の気体の体積は何 L？（1 mol＝22.4 L）',
      answer: '${Fmt.dec(v, 3)} L',
      wrong: [
        '22.4 L',
        '${Fmt.dec(v * 2, 3)} L',
        '${Fmt.dec(v + 22400, 3)} L',
        '${_d2(n)} L'
      ],
      explanation: '22.4×${_d2(n)}',
    );
  }
  return GenQ(
    prompt: '標準状態で ${Fmt.dec(v, 3)} L の気体は何 mol？（1 mol＝22.4 L）',
    answer: '${_d2(n)} mol',
    wrong: [
      '${_d2(n * 2)} mol',
      '${_d2(n + 100)} mol',
      '${Fmt.dec(v, 3)} mol',
      '${_d2(n ~/ 5 == 0 ? n + 5 : n ~/ 5)} mol'
    ],
    explanation: '${Fmt.dec(v, 3)}÷22.4',
  );
}

GenQ? _molarity(Random r) {
  final n = r.pick([5, 10, 20, 25, 50, 100]); // ×0.01 mol
  final ml = r.pick([100, 200, 250, 500, 1000]);
  final c = Rat(n * 1000, 100 * ml); // mol/L
  final cs = c.den == 1 || 1000 % c.den == 0
      ? Fmt.dec(c.num * (1000 ~/ c.den), 3)
      : '$c';
  return GenQ(
    prompt: '溶質 ${_d2(n)} mol を水に溶かして $ml mL の水溶液にした。モル濃度は何 mol/L？',
    answer: '$cs mol/L',
    wrong: [
      '${_d2(n)} mol/L',
      '${Fmt.dec(n * ml, 5)} mol/L',
      '${Fmt.dec(c.num * (1000 ~/ c.den) * 10, 3)} mol/L',
      '${Fmt.dec(c.num * (1000 ~/ c.den) ~/ 10, 3)} mol/L'
    ],
    explanation: '${_d2(n)} mol÷${Fmt.dec(ml, 3)} L',
  );
}

/// 反応式の量的関係（係数・物質）
const _reactions =
    <(String, String, int, String, int, Map<String, int>, Map<String, int>)>[
  // 反応式、反応物の式、係数、生成物の式、係数、反応物の組成、生成物の組成
  (
    'CH₄ ＋ 2O₂ → CO₂ ＋ 2H₂O',
    'CH₄',
    1,
    'CO₂',
    1,
    {'C': 1, 'H': 4},
    {'C': 1, 'O': 2}
  ),
  (
    'CH₄ ＋ 2O₂ → CO₂ ＋ 2H₂O',
    'CH₄',
    1,
    'H₂O',
    2,
    {'C': 1, 'H': 4},
    {'H': 2, 'O': 1}
  ),
  ('2Mg ＋ O₂ → 2MgO', 'Mg', 2, 'MgO', 2, {'Mg': 1}, {'Mg': 1, 'O': 1}),
  ('2H₂ ＋ O₂ → 2H₂O', 'H₂', 2, 'H₂O', 2, {'H': 2}, {'H': 2, 'O': 1}),
  ('C ＋ O₂ → CO₂', 'C', 1, 'CO₂', 1, {'C': 1}, {'C': 1, 'O': 2}),
  ('2Cu ＋ O₂ → 2CuO', 'Cu', 2, 'CuO', 2, {'Cu': 1}, {'Cu': 1, 'O': 1}),
  (
    'CaCO₃ → CaO ＋ CO₂',
    'CaCO₃',
    1,
    'CO₂',
    1,
    {'Ca': 1, 'C': 1, 'O': 3},
    {'C': 1, 'O': 2}
  ),
  ('N₂ ＋ 3H₂ → 2NH₃', 'N₂', 1, 'NH₃', 2, {'N': 2}, {'N': 1, 'H': 3}),
  (
    'C₃H₈ ＋ 5O₂ → 3CO₂ ＋ 4H₂O',
    'C₃H₈',
    1,
    'CO₂',
    3,
    {'C': 3, 'H': 8},
    {'C': 1, 'O': 2}
  ),
];

GenQ? _stoich(Random r) {
  final (eq, a, ca, b, cb, fa, fb) = r.pick(_reactions);
  final ma = _mass(fa), mb = _mass(fb); // ×0.1
  final mol = r.pick([10, 20, 50, 100, 200]); // ×0.1 mol（反応物の物質量）
  final ga = ma * mol; // ×0.01 g
  final gb = mb * mol * cb ~/ ca; // ×0.01 g（必ず割り切れるように係数を選んでいる）
  if (mb * mol * cb % ca != 0) return null;
  final atoms =
      {...fa, ...fb}.keys.map((k) => '$k=${_d1(_atomic[k]!)}').join(', ');
  return GenQ(
    prompt: '$eq の反応で、$a ${_d2(ga)} g がすべて反応したとき、生じる $b は何 g？（$atoms）',
    answer: '${_d2(gb)} g',
    wrong: [
      '${_d2(mb * mol)} g',
      '${_d2(gb * 2)} g',
      '${_d2(ga)} g',
      '${_d2(mb * mol * ca ~/ cb)} g'
    ],
    explanation:
        '$a は ${_d1(mol)} mol。係数の比 $ca:$cb より $b は ${_d1(mol * cb ~/ ca)} mol。',
  );
}

GenQ? _ph(Random r) {
  if (r.nextBool()) {
    final p = r.range(1, 13);
    return GenQ(
      prompt: '[H⁺]＝1.0×10${Fmt.sup(-p)} mol/L の水溶液の pH は？',
      answer: '$p',
      wrong: ['${14 - p}', Fmt.n(-p), '${p + 1}', '${p - 1 == 0 ? 2 : p - 1}'],
      explanation: 'pH＝−log₁₀[H⁺]＝$p',
    );
  }
  final a = r.range(1, 6), b = r.range(a + 1, 7);
  final times = pow(10, b - a).toInt();
  return GenQ(
    prompt: 'pH $a の水溶液の [H⁺] は、pH $b の水溶液の何倍？',
    answer: '$times倍',
    wrong: [
      '${b - a}倍',
      '${(b - a) * 10}倍',
      '${Rat(1, times)}倍',
      '${times * 10}倍'
    ],
    explanation: 'pH が1小さいと [H⁺] は10倍。差は ${b - a}。',
  );
}

GenQ? _gasLaw(Random r) {
  if (r.nextBool()) {
    // ボイルの法則
    final p1 = r.range(1, 5), v1 = r.range(2, 12), p2 = r.range(1, 6);
    if (p1 == p2) return null;
    final v2 = Rat(p1 * v1, p2);
    return GenQ(
      prompt:
          '温度一定で、${_d1(p1 * 10)}×10⁵ Pa で $v1 L の気体を ${_d1(p2 * 10)}×10⁵ Pa にした。体積は何 L？',
      answer: '$v2 L',
      wrong: [
        '${Rat(p2 * v1, p1)} L',
        '$v1 L',
        '${v2 + Rat(1)} L',
        '${Rat(p1 * p2, v1)} L'
      ],
      explanation: 'ボイルの法則 p₁V₁＝p₂V₂',
    );
  }
  // シャルルの法則（27℃＝300 K など）
  final t1 = r.pick([0, 27, 77, 127]), t2 = r.pick([27, 127, 227, 327]);
  if (t1 == t2) return null;
  final v1 = r.range(2, 12);
  final v2 = Rat(v1 * (t2 + 273), t1 + 273);
  return GenQ(
    prompt: '圧力一定で、$t1 ℃ で $v1 L の気体を $t2 ℃ にした。体積は何 L？',
    answer: '$v2 L',
    wrong: [
      '${Rat(v1 * t2, t1 == 0 ? 1 : t1)} L',
      '$v1 L',
      '${Rat(v1 * (t1 + 273), t2 + 273)} L',
      '${v2 + Rat(1)} L'
    ],
    explanation: 'シャルルの法則 V/T は一定。T＝t＋273',
  );
}

GenQ? _atomParts(Random r) {
  final (sym, name, z, a) = r.pick(_isotopes);
  final ask = r.nextInt(3);
  final v = [z, a - z, z][ask];
  final label = ['陽子', '中性子', '電子'][ask];
  return GenQ(
    prompt: '${_nuclide(sym, a, z)}（$name）の原子1個に含まれる$labelの数は？',
    answer: '$v',
    wrong: [
      '$a',
      '${a + z}',
      '${v + 1}',
      '${ask == 1 ? z : a - z}',
      '${(v - 1).abs()}'
    ],
    explanation: '陽子＝電子＝原子番号 $z、中性子＝質量数−原子番号＝${a - z}',
  );
}

const _elements = <(String, String, int)>[
  ('H', '水素', 1),
  ('He', 'ヘリウム', 2),
  ('Li', 'リチウム', 3),
  ('Be', 'ベリリウム', 4),
  ('B', 'ホウ素', 5),
  ('C', '炭素', 6),
  ('N', '窒素', 7),
  ('O', '酸素', 8),
  ('F', 'フッ素', 9),
  ('Ne', 'ネオン', 10),
  ('Na', 'ナトリウム', 11),
  ('Mg', 'マグネシウム', 12),
  ('Al', 'アルミニウム', 13),
  ('Si', 'ケイ素', 14),
  ('P', 'リン', 15),
  ('S', '硫黄', 16),
  ('Cl', '塩素', 17),
  ('Ar', 'アルゴン', 18),
  ('K', 'カリウム', 19),
  ('Ca', 'カルシウム', 20),
  ('Fe', '鉄', 26),
  ('Cu', '銅', 29),
  ('Zn', '亜鉛', 30),
  ('Ag', '銀', 47),
  ('Au', '金', 79),
  ('I', 'ヨウ素', 53),
  ('Br', '臭素', 35),
  ('Mn', 'マンガン', 25),
  ('Pb', '鉛', 82),
  ('Hg', '水銀', 80),
];

GenQ? _elementName(Random r) {
  final (sym, name, z) = r.pick(_elements);
  final others = [..._elements]..shuffle(r);
  switch (r.nextInt(3)) {
    case 0:
      return GenQ(
        prompt: '元素記号 $sym の元素名は？',
        answer: name,
        wrong: [for (final e in others) e.$2],
        explanation: '$sym は$name。',
        category: QuestionCategory.knowledge,
      );
    case 1:
      return GenQ(
        prompt: '$nameの元素記号は？',
        answer: sym,
        wrong: [for (final e in others) e.$1],
        explanation: '$nameは $sym。',
        category: QuestionCategory.knowledge,
      );
    default:
      return GenQ(
        prompt: '$name（$sym）の原子番号は？',
        answer: '$z',
        wrong: ['${z + 1}', '${z - 1}', '${z * 2}', '${z + 2}'],
        explanation: '$nameの原子番号は $z。',
        category: QuestionCategory.knowledge,
      );
  }
}

/// 電子配置（原子番号 1〜20）
GenQ? _electronShell(Random r) {
  final (sym, name, z) = r.pick(_elements.where((e) => e.$3 <= 20).toList());
  final shells = <int>[];
  var left = z;
  for (final cap in [2, 8, 8, 2]) {
    final n = min(left, cap);
    if (n == 0) break;
    shells.add(n);
    left -= n;
  }
  final valence = z == 2 || z == 10 || z == 18 ? 0 : shells.last;
  String cfg(List<int> s) => ['K', 'L', 'M', 'N']
      .take(s.length)
      .toList()
      .asMap()
      .entries
      .map((e) => '${e.value}${s[e.key]}')
      .join(' ');
  if (r.nextBool()) {
    final alt = [...shells];
    if (alt.length >= 2) {
      alt[alt.length - 1] += 1;
      alt[alt.length - 2] -= 1;
    }
    return GenQ(
      prompt: '$name（$sym、原子番号 $z）の電子配置は？',
      answer: cfg(shells),
      wrong: [
        cfg(alt),
        cfg([...shells.take(shells.length - 1), shells.last + 1]),
        cfg([2, z - 2 > 0 ? z - 2 : 1]),
        cfg([z])
      ],
      explanation: 'K殻に2個、L殻に8個、M殻に8個…の順に入る。',
      category: QuestionCategory.knowledge,
    );
  }
  return GenQ(
    prompt: '$name（$sym、原子番号 $z）の価電子の数は？',
    answer: '$valence',
    wrong: [
      '${shells.last == valence ? valence + 1 : shells.last}',
      '$z',
      '8',
      '${valence + 2}',
      '2'
    ],
    explanation:
        '電子配置 ${cfg(shells)}。${valence == 0 ? '貴ガスの価電子は0とする。' : '最外殻電子が価電子。'}',
    category: QuestionCategory.knowledge,
  );
}

GenQ? _shellMax(Random r) {
  final n = r.range(1, 4);
  const names = ['K', 'L', 'M', 'N'];
  return GenQ(
    prompt: '${names[n - 1]} 殻に入ることができる電子の最大数は？',
    answer: '${2 * n * n}',
    wrong: ['${2 * n}', '${n * n}', '8', '${2 * (n + 1) * (n + 1)}', '2'],
    explanation: '内側から n 番目の殻には 2n² 個まで入る。',
    category: QuestionCategory.knowledge,
  );
}

const _flame = [
  ('リチウム Li', '赤'),
  ('ナトリウム Na', '黄'),
  ('カリウム K', '赤紫'),
  ('カルシウム Ca', '橙赤'),
  ('ストロンチウム Sr', '紅'),
  ('バリウム Ba', '黄緑'),
  ('銅 Cu', '青緑'),
];

GenQ? _flameTest(Random r) {
  final (el, color) = r.pick(_flame);
  return GenQ(
    prompt: '$el の炎色反応の色は？',
    answer: color,
    wrong: [
      for (final f in [..._flame]..shuffle(r)) f.$2
    ],
    explanation: '$el は$color色。',
    category: QuestionCategory.knowledge,
  );
}

const _oxnum = <(String, String, int)>[
  ('H₂SO₄', 'S', 6),
  ('SO₂', 'S', 4),
  ('H₂S', 'S', -2),
  ('S', 'S', 0),
  ('HNO₃', 'N', 5),
  ('NO₂', 'N', 4),
  ('NO', 'N', 2),
  ('NH₃', 'N', -3),
  ('N₂', 'N', 0),
  ('KMnO₄', 'Mn', 7),
  ('MnO₂', 'Mn', 4),
  ('K₂Cr₂O₇', 'Cr', 6),
  ('CO₂', 'C', 4),
  ('CO', 'C', 2),
  ('CH₄', 'C', -4),
  ('Fe₂O₃', 'Fe', 3),
  ('FeO', 'Fe', 2),
  ('CuO', 'Cu', 2),
  ('Cu₂O', 'Cu', 1),
  ('HClO', 'Cl', 1),
  ('Cl₂', 'Cl', 0),
  ('HCl', 'Cl', -1),
  ('H₂O₂', 'O', -1),
  ('H₂O', 'O', -2),
];

String _signed(int v) => v > 0 ? '+$v' : Fmt.n(v);

GenQ? _oxidation(Random r) {
  final (f, el, v) = r.pick(_oxnum);
  return GenQ(
    prompt: '$f の $el の酸化数は？',
    answer: _signed(v),
    wrong: [
      _signed(-v == v ? 1 : -v),
      _signed(v + 1),
      _signed(v - 2),
      _signed(v + 2),
      '+8'
    ],
    explanation: '化合物全体で0、O は −2、H は +1（例外あり）として計算する。',
  );
}

GenQ? _faraday(Random r) {
  final i = r.range(1, 10), k = r.range(1, 10);
  final t = 9650 * k;
  final mol = Rat(i * k, 10);
  return GenQ(
    prompt: '$i A の電流を $t 秒間流した。流れた電子の物質量は？（F＝9.65×10⁴ C/mol）',
    answer: '${_dec(mol)} mol',
    wrong: [
      '${_dec(mol * Rat(2))} mol',
      '${_dec(Rat(i * k))} mol',
      '${_dec(mol * Rat(1, 2))} mol',
      '${i * t} mol'
    ],
    explanation: '電気量 $i×$t＝${i * t} C。÷96500',
  );
}

String _dec(Rat q) {
  if (q.isInt) return '$q';
  for (final d in [10, 100, 1000]) {
    if (d % q.den == 0) return Fmt.dec(q.num * (d ~/ q.den), '$d'.length - 1);
  }
  return '$q';
}

final Map<String, List<Gen>> scienceGens = {
  // 物理
  'science.physics.mechanics.energy.work': [_work],
  'science.physics.mechanics.energy.kinetic': [_kinetic],
  'science.physics.mechanics.energy.potential': [_potential],
  'science.physics.mechanics.energy': [_kinetic, _potential, _work],
  'science.physics.mechanics.force.friction': [_friction],
  'science.physics.mechanics.force.balance': [_lever],
  'science.physics.mechanics.rigid.moment': [_lever],
  'science.physics.mechanics.force.kinds': [_hooke],
  'science.physics.mechanics.newton': [_newton],
  'science.physics.mechanics.newton.equation': [_newton],
  'science.physics.mechanics.kinematics.velocity': [_velocity],
  'science.physics.mechanics.kinematics.fall': [_fall],
  'science.physics.mechanics.momentum.impulse': [_momentum],
  'science.physics.mechanics.momentum.conservation': [_collision],
  'science.physics.em.current.ohm': [_ohm, _resistors],
  'science.physics.em.current.power': [_power],
  'science.physics.em.current.charge': [_ohm],
  'science.physics.em.field': [_coulombRatio],
  'science.physics.em.field.coulomb': [_coulombRatio],
  'science.physics.em.magnetism.inductance': [_transformer],
  'science.physics.em.magnetism.force': [_magForce],
  'science.physics.thermo.heat': [_kelvin],
  'science.physics.thermo.heat.temperature': [_kelvin],
  'science.physics.thermo.heat.capacity': [_heat],
  'science.physics.waves.basic.describe': [_wave],
  'science.physics.waves.sound.beat': [_wave],
  'science.physics.waves.sound.string': [_wave],
  'science.physics.waves.light.lens': [_lens],
  'science.physics.atom.nucleus.decay': [_decay, _halfLife],
  // 化学
  'science.chemistry.change.mole': [_molarMass, _particles],
  'science.chemistry.change.mole.mass': [_molarMass, _moleMass, _gasVolume],
  'science.chemistry.change.mole.mole': [_moleMass, _particles, _gasVolume],
  'science.chemistry.change.mole.concentration': [_molarity],
  'science.chemistry.change.equation': [_stoich],
  'science.chemistry.change.equation.quantity': [_stoich],
  'science.chemistry.change.equation.write': [_stoich],
  'science.chemistry.change.acid.ph': [_ph],
  'science.chemistry.inorganic.nonmetal.gas': [_gasVolume],
  'science.chemistry.state.gas.law': [_gasLaw],
  'science.chemistry.structure.atom.structure': [_atomParts, _elementName],
  'science.chemistry.structure.atom.config': [_electronShell, _shellMax],
  'science.chemistry.structure.atom': [_shellMax, _atomParts],
  'science.chemistry.structure.periodic.law': [_elementName],
  'science.chemistry.structure.life.test': [_flameTest],
  'science.chemistry.change.redox.oxnum': [_oxidation],
  'science.chemistry.equilibrium.energy': [_faraday],
};
