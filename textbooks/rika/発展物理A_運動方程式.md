# 発展理科 物理A「力と運動の発展（加速度・運動方程式・力の分解）」

<p class="lead">LEVEL 4（高校への橋渡し）｜高校「物理基礎」の運動の法則｜使う単元：中3 物理7（力の分解）・物理8（運動の規則性）・物理9（エネルギー）、数学の比例・反比例・一次関数・関数 y＝ax²・相似｜中学で「一定の割合で速くなる」と言っていたことを、数式 ma＝F ひとつで説明できるようになろう。</p>

<div class="memo" markdown="1">

**先生のひとこと**　中学の運動の単元は「斜面では速さが一定の割合で増える」「質量を変えても速さの増え方は同じ」と、**結果**を覚える場面が多かった。高校では、それをたった1本の式 **ma＝F（運動方程式）** から**導く**。この単元では、①加速度という「ものさし」を作り、②グラフ（数学の一次関数・二次関数）で運動を読み、③運動方程式で「なぜそうなるか」を説明する。難関私立・国立高校の入試で出る「2物体」「滑車」「摩擦」の問題も、この手順で解ける。

</div>

## 要点まとめ

### 1　速さと速度 ― 「向き」をもつ量

- **速さ**は「どれだけ速いか」だけを表す。**速度**は「速さ」と「向き」をセットにした量。
- 一直線上の運動では、向きを**＋と−**で表す。右向きを＋と決めたら、左向きに 3 m/s は「**−3 m/s**」。
- 「どこにいるか」を**位置 x**、位置の変化（終わりの位置 − はじめの位置）を**変位**という。
　**速度 ＝ 変位 ÷ 時間**　　（中学の「速さ ＝ 距離 ÷ 時間」に向きがついたもの）
- **x-t グラフ（位置と時間）の傾き ＝ 速度**。直線なら速度一定（等速直線運動）、曲線なら速度が変化している。

<div class="memo" markdown="1">

**本質**　「速さ」と「速度」を分けるのは、**向きが変わるだけでも運動の状態は変わる**から。カーブを一定の速さで曲がる車も「速度は変化している」。だから力（ハンドルを切ってタイヤが受ける力）が必要になる。これが天体の運動（物理C）につながる。

</div>

### 2　加速度 ― 速度の変わりぐあい<span class="deru">入試</span>

<div class="point" markdown="1">

**POINT 1　加速度の定義**

**加速度 ＝ 速度の変化 ÷ かかった時間**　　a ＝（v − v₀）/ t
- 単位は **m/s²**（メートル毎秒毎秒）。「**1秒あたり、速度が何 m/s 変わるか**」。
- 例：静止していた自動車が 5.0 秒で 20 m/s になった → a ＝ 20 ÷ 5.0 ＝ **4.0 m/s²**（1秒ごとに 4 m/s ずつ速くなる）
- 例：20 m/s で走る自転車が 4.0 秒で止まった → a ＝（0 − 20）÷ 4.0 ＝ **−5.0 m/s²**（マイナス ＝ 運動と逆向きの加速度）
- **v-t グラフ（速度と時間）の傾き ＝ 加速度**。v-t グラフの下の面積 ＝ 移動距離（変位）。

</div>

- 中学の記録タイマーの実験で「テープの長さが一定ずつ増える」は「**加速度が一定**」のこと。
- **自由落下の加速度 ＝ 重力加速度 g ＝ 9.8 m/s²**。1秒ごとに 9.8 m/s ずつ速くなる。

### 3　等加速度直線運動の3つの式<span class="deru">入試</span>

加速度が一定の運動を**等加速度直線運動**という。はじめの速度 v₀、加速度 a、時間 t、変位 x とすると、v-t グラフから次の3つの式が**導ける**。

<figure><svg width="640" viewBox="0 0 640 235" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="50" y="165" width="200" height="30" fill="#e4e4e4"/><polygon points="50,165 250,45 250,165" fill="#c8c8c8"/><line x1="50" y1="195" x2="280" y2="195" stroke="#000" stroke-width="1.2" marker-end="url(#ah0)"/><line x1="50" y1="195" x2="50" y2="20" stroke="#000" stroke-width="1.2" marker-end="url(#ah0)"/><text x="284" y="199" font-size="12">t</text><text x="50" y="14" font-size="12" text-anchor="middle">v</text><line x1="50" y1="165" x2="250" y2="45" stroke="#000" stroke-width="2.2"/><line x1="250" y1="195" x2="250" y2="45" stroke="#000" stroke-width="1" stroke-dasharray="4 3"/><line x1="50" y1="45" x2="250" y2="45" stroke="#000" stroke-width="0.8" stroke-dasharray="2 3"/><text x="45" y="169" font-size="12" text-anchor="end">v₀</text><text x="45" y="49" font-size="12" text-anchor="end">v</text><text x="250" y="211" font-size="12" text-anchor="middle">t</text><text x="46" y="209" font-size="12" text-anchor="end">O</text><text x="150" y="184" font-size="11" text-anchor="middle">v₀t（長方形）</text><text x="195" y="132" font-size="11" text-anchor="middle">(1/2)at²</text><text x="195" y="148.5" font-size="10" text-anchor="middle">（三角形）</text><line x1="100" y1="135" x2="150" y2="135" stroke="#000" stroke-width="0.8" stroke-dasharray="2 2"/><line x1="150" y1="135" x2="150" y2="105" stroke="#000" stroke-width="0.8" stroke-dasharray="2 2"/><text x="125" y="100.5" font-size="11" text-anchor="end">傾き ＝ a</text><text x="256" y="105" font-size="11">at</text><line x1="252" y1="165" x2="252" y2="45" stroke="#000" stroke-width="0.8" marker-end="url(#ah0)" marker-start="url(#ah0)"/><text x="140" y="228" font-size="11.5" text-anchor="middle" font-weight="700">v-t グラフ：傾き ＝ 加速度、面積 ＝ 移動距離</text><line x1="370" y1="195" x2="600" y2="195" stroke="#000" stroke-width="1.2" marker-end="url(#ah0)"/><line x1="370" y1="195" x2="370" y2="20" stroke="#000" stroke-width="1.2" marker-end="url(#ah0)"/><text x="604" y="199" font-size="12">t</text><text x="370" y="14" font-size="12" text-anchor="middle">x</text><polyline points="370,195 375,194.9 380,194.6 385,194.1 390,193.5 395,192.6 400,191.6 405,190.3 410,188.9 415,187.3 420,185.5 425,183.5 430,181.3 435,178.9 440,176.4 445,173.6 450,170.7 455,167.5 460,164.2 465,160.7 470,157 475,153.1 480,149 485,144.7 490,140.3 495,135.6 500,130.8 505,125.7 510,120.5 515,115.1 520,109.5 525,103.7 530,97.7 535,91.5 540,85.2 545,78.6 550,71.9 555,64.9 560,57.8 565,50.5 570,43" fill="none" stroke="#000" stroke-width="2.2"/><circle cx="420" cy="185.5" r="2.5" fill="#000"/><line x1="420" y1="195" x2="420" y2="185.5" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="420" y="209" font-size="11" text-anchor="middle">1</text><line x1="370" y1="185.5" x2="420" y2="185.5" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="366" y="189.5" font-size="11" text-anchor="end">1</text><circle cx="470" cy="157" r="2.5" fill="#000"/><line x1="470" y1="195" x2="470" y2="157" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="470" y="209" font-size="11" text-anchor="middle">2</text><line x1="370" y1="157" x2="470" y2="157" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="366" y="161" font-size="11" text-anchor="end">4</text><circle cx="520" cy="109.5" r="2.5" fill="#000"/><line x1="520" y1="195" x2="520" y2="109.5" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="520" y="209" font-size="11" text-anchor="middle">3</text><line x1="370" y1="109.5" x2="520" y2="109.5" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="366" y="113.5" font-size="11" text-anchor="end">9</text><circle cx="570" cy="43" r="2.5" fill="#000"/><line x1="570" y1="195" x2="570" y2="43" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="570" y="209" font-size="11" text-anchor="middle">4</text><line x1="370" y1="43" x2="570" y2="43" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="366" y="47" font-size="11" text-anchor="end">16</text><text x="366" y="209" font-size="12" text-anchor="end">O</text><text x="382" y="65.8" font-size="12">x ＝ (1/2)at²</text><text x="382" y="81" font-size="11">（y＝ax² と同じ形）</text><text x="490" y="228" font-size="11.5" text-anchor="middle" font-weight="700">x-t グラフ（v₀＝0, a＝2 m/s²）：放物線</text></svg><figcaption>図1　左：v-t グラフの面積から x ＝ v₀t ＋ (1/2)at² が出る。右：静止から出発すると x は t² に比例し、x-t グラフは放物線になる（1：4：9：16）。</figcaption></figure>

<div class="point" markdown="1">

**POINT 2　等加速度直線運動の式（3つとも v-t グラフから出る）**

① **v ＝ v₀ ＋ at**　　……v-t グラフは**傾き a、切片 v₀ の直線**（数学の一次関数 y＝ax＋b と同じ形）
② **x ＝ v₀t ＋ (1/2)at²**　　……グラフの下の**台形の面積**（長方形 v₀t ＋ 三角形 (1/2)×t×at）
③ **v² − v₀² ＝ 2ax**　　……①と②から t を消去したもの（時間がわからないときに使う）

</div>

- ③の導き方：台形の面積 ＝（上底 ＋ 下底）× 高さ ÷ 2 より x ＝（v₀ ＋ v）× t ÷ 2。①から t ＝（v − v₀）/ a を代入すると x ＝（v ＋ v₀）（v − v₀）/ 2a ＝（v² − v₀²）/ 2a。**和と差の積（中3の乗法公式）**が使われている。
- **x-t グラフが放物線になる理由**：静止から出発（v₀ ＝ 0）すると x ＝ (1/2)at²。これは数学の **y ＝ ax² と同じ形**。だから x-t グラフは原点を頂点とする**放物線**になる。自由落下なら x ＝ 4.9t²（1秒で 4.9 m、2秒で 19.6 m、3秒で 44.1 m）。
- **0.1秒ごとの移動距離の比は 1：3：5：7：…**（奇数の比）。合計は 1、4、9、16、…（2乗）だから、差をとると奇数になる。となり合う区間の差はいつも **aT²**（T は区切る時間）。物理8の自由落下のストロボ写真（4.9 cm、14.7 cm、24.5 cm、…）は差が 9.8 cm ＝ a ×（0.1）² なので a ＝ 980 cm/s² ＝ **9.8 m/s²** とわかる。

### 4　運動の3法則と運動方程式 ma＝F<span class="deru">入試</span>

| 法則 | 内容 | 中学とのつながり |
|---|---|---|
| **第1法則（慣性の法則）** | 力がはたらかない（つり合う）とき、物体は静止または等速直線運動を続ける | 物理8で学習ずみ |
| **第2法則（運動方程式）** | **ma ＝ F**（質量 × 加速度 ＝ 物体にはたらく力の合計） | 「力が大きいほど速さの変わり方が大きい」を式にしたもの |
| **第3法則（作用・反作用の法則）** | AがBに力を加えると、BもAに同じ大きさで逆向きの力を加える | 物理8で学習ずみ |

**実験で確かめる**：なめらかな水平面で台車を一定の力で引き、加速度を測る（記録タイマーや速度センサーを使う）。

| 実験1（台車 1.0 kg） | 引く力 0.50 N | 1.0 N | 1.5 N | 2.0 N |
|---|---|---|---|---|
| 加速度〔m/s²〕 | 0.50 | 1.0 | 1.5 | 2.0 |

| 実験2（引く力 1.2 N） | 質量 0.40 kg | 0.60 kg | 0.80 kg | 1.2 kg |
|---|---|---|---|---|
| 加速度〔m/s²〕 | 3.0 | 2.0 | 1.5 | 1.0 |

- 実験1：加速度は**力に比例**（数学の比例 y＝ax）。　実験2：加速度は**質量に反比例**（a × m ＝ 1.2 でいつも一定）。
- 2つをまとめると **a ＝ F/m**、つまり **ma ＝ F**。
- **1 N の定義**：質量 1 kg の物体に 1 m/s² の加速度を生じさせる力が **1 N**（1 N ＝ 1 kg·m/s²）。
- **重力 W ＝ mg**（g ＝ 9.8 m/s²）。質量 100 g（0.1 kg）の物体の重力は 0.1 × 9.8 ＝ **0.98 N**。中学の「100 g の物体にはたらく重力を 1 N とする」は、これを約 1 N とみなしたもの。

<div class="memo" markdown="1">

**本質**　なぜ重い物も軽い物も同じように落ちるのか。質量 m の物体にはたらく重力は mg。運動方程式 ma ＝ mg の両辺を m でわると **a ＝ g**。重い物は重力が大きいが、そのぶん**慣性（動かしにくさ）も大きい**ので、ちょうど打ち消し合う。質量 m が「力を受ける量」と「動かしにくさ」の両方を表しているのが、この式のすごいところ。

</div>

### 5　運動方程式の使い方 ― 4つの手順

<div class="point" markdown="1">

**POINT 3　運動方程式を立てる手順**

① **注目する物体を1つ決める**（2つあるときは1つずつ、または「ひとまとめ」にする）
② その物体にはたらく**力をすべて書き出す**：**重力**（地球から）＋**ふれている物から受ける力**（糸の張力・垂直抗力・摩擦力・手でおす力）
③ **運動の向きを＋**と決め、運動の向きの力の合計（合力）F を求める
④ **ma ＝ F** を立てて解く。求めた a を等加速度直線運動の式に入れれば、速度や距離もわかる

</div>

**例題（滑車でつながった2物体）**　なめらかな机の上の台車（0.40 kg）と、机の端の滑車を通してつるしたおもり（0.10 kg）を糸でつなぎ、静かに手をはなす。

<figure><svg width="440" viewBox="0 0 520 220" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="30" y="110" width="330" height="14" fill="#e4e4e4" stroke="#000" stroke-width="1.2"/><line x1="60" y1="124" x2="60" y2="210" stroke="#000" stroke-width="2"/><line x1="330" y1="124" x2="330" y2="210" stroke="#000" stroke-width="2"/><rect x="130" y="72" width="90" height="32" fill="#fff" stroke="#000" stroke-width="1.5"/><circle cx="150" cy="105" r="5" fill="#fff" stroke="#000" stroke-width="1.2"/><circle cx="200" cy="105" r="5" fill="#fff" stroke="#000" stroke-width="1.2"/><text x="175" y="93" font-size="11" text-anchor="middle">台車 0.40 kg</text><circle cx="372" cy="98" r="12" fill="#fff" stroke="#000" stroke-width="1.5"/><line x1="360" y1="110" x2="372" y2="98" stroke="#000" stroke-width="1.2"/><line x1="220" y1="86" x2="372" y2="86" stroke="#000" stroke-width="1.2"/><line x1="384" y1="98" x2="384" y2="160" stroke="#000" stroke-width="1.2"/><rect x="370" y="160" width="28" height="30" fill="#e4e4e4" stroke="#000" stroke-width="1.5"/><text x="404" y="180" font-size="11">おもり 0.10 kg</text><line x1="220" y1="86" x2="270" y2="86" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><text x="250" y="78" font-size="13" text-anchor="middle" font-style="italic">T</text><line x1="384" y1="160" x2="384" y2="128" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><text x="392" y="140" font-size="13" font-style="italic">T</text><line x1="384" y1="190" x2="384" y2="214" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><text x="392" y="212" font-size="11">0.98 N（重力）</text><line x1="110" y1="60" x2="160" y2="60" stroke="#000" stroke-width="1" marker-end="url(#ah0)"/><text x="105" y="64" font-size="12" text-anchor="end" font-style="italic">a</text><text x="195" y="140" font-size="11" text-anchor="middle">なめらかな机</text></svg><figcaption>図2　滑車でつながった2物体。糸の張力 T は、台車を右に、おもりを上に引く。</figcaption></figure>

- 台車：右向きに糸の張力 T だけ（重力と垂直抗力はつり合う）→ **0.40a ＝ T**
- おもり：下向きに重力 0.10 × 9.8 ＝ 0.98 N、上向きに張力 T → **0.10a ＝ 0.98 − T**
- 2式をたすと T が消えて 0.50a ＝ 0.98 → **a ＝ 1.96 m/s²**、T ＝ 0.40 × 1.96 ＝ **0.784 N**
- 「ひとまとめ」に考えると、全体（0.50 kg）を動かす力はおもりの重力 0.98 N だけ → 0.50a ＝ 0.98 と一気に出せる（糸の張力は**内力**なので消える）。
- 張力（0.784 N）はおもりの重力（0.98 N）より**小さい**。等しいとすると、おもりにはたらく力がつり合って加速できなくなる。

### 6　斜面の力の分解と加速度 ― 相似で考える<span class="deru">入試</span>

<figure><svg width="640" viewBox="0 0 640 250" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><polygon points="40,230 320,230 40,20" fill="#f4f4f4" stroke="#000" stroke-width="1.5"/><rect x="40" y="220" width="10" height="10" fill="none" stroke="#000" stroke-width="1"/><polygon points="137.6,93.2 182.4,126.8 204,98 159.2,64.4" fill="#fff" stroke="#000" stroke-width="1.5"/><polygon points="170.8,95.6 223.6,135.2 170.8,205.6" fill="#e4e4e4"/><line x1="223.6" y1="135.2" x2="170.8" y2="205.6" stroke="#000" stroke-width="1" stroke-dasharray="4 3"/><line x1="118" y1="166" x2="170.8" y2="205.6" stroke="#000" stroke-width="1" stroke-dasharray="4 3"/><line x1="170.8" y1="95.6" x2="170.8" y2="205.6" stroke="#000" stroke-width="2.4" marker-end="url(#ah0)"/><line x1="170.8" y1="95.6" x2="223.6" y2="135.2" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><line x1="170.8" y1="95.6" x2="118" y2="166" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><line x1="170.8" y1="95.6" x2="223.6" y2="25.2" stroke="#000" stroke-width="1.6" stroke-dasharray="5 3" marker-end="url(#ah0)"/><circle cx="170.8" cy="95.6" r="3" fill="#000"/><text x="176.8" y="207.6" font-size="13" font-style="italic">mg</text><text x="231.6" y="131.2" font-size="11">平行な分力</text><text x="112" y="180" font-size="11" text-anchor="end">垂直な分力</text><text x="229.6" y="25.2" font-size="11">垂直抗力 N</text><text x="30" y="128" font-size="13" text-anchor="end" font-style="italic">h</text><text x="180" y="247" font-size="13" text-anchor="middle" font-style="italic">d</text><text x="276" y="176" font-size="13" font-style="italic">L</text><text x="400" y="60" font-size="12" font-weight="700">灰色の三角形 ∽ 斜面の三角形</text><text x="400" y="84" font-size="12">平行な分力 ： mg ＝ h ： L</text><text x="400" y="106" font-size="12">→ 平行な分力 ＝ mg × h/L</text><text x="400" y="130" font-size="12">垂直な分力 ： mg ＝ d ： L</text><text x="400" y="152" font-size="12">→ 垂直な分力 ＝ mg × d/L</text><text x="400" y="184" font-size="12">運動方程式 ma ＝ mg × h/L</text><text x="400" y="206" font-size="12" font-weight="700">→ a ＝ g × h/L（m が消える）</text></svg><figcaption>図3　斜面上の物体にはたらく力（図は h：d：L ＝ 3：4：5 の斜面）。力の三角形と斜面の三角形は相似。</figcaption></figure>

- 斜面上の物体にはたらく重力 mg を、**斜面に平行な分力**と**斜面に垂直な分力**に分ける（物理7）。
- 力の矢印でできる直角三角形（灰色）と、斜面の直角三角形は**相似**（直角と、1つの鋭角が等しい）。だから
　**平行な分力 ＝ mg × h/L**　　**垂直な分力 ＝ mg × d/L**（L：斜面の長さ、h：高さ、d：底辺）
- 垂直な分力は**垂直抗力 N** とつり合う。運動方程式は ma ＝ mg × h/L より **a ＝ g × h/L**。**質量 m が消える**ので、質量を変えても加速度は同じ（物理8の結論の理由）。
- 角度 30° の斜面：h/L ＝ 1/2（正三角形を半分にした形）→ **a ＝ 9.8 × 1/2 ＝ 4.9 m/s²**。
　長さ 9.8 m の斜面を静止からすべり下りると、9.8 ＝ (1/2) × 4.9 × t² より t² ＝ 4、**t ＝ 2.0 s**、v ＝ 4.9 × 2.0 ＝ **9.8 m/s**。
- 確かめ（物理9のエネルギー）：高さ 4.9 m から落とした速さと同じ。v² ＝ 2 × 9.8 × 4.9 ＝ 96.04 より v ＝ 9.8 m/s。**斜面でも自由落下でも、下りた高さが同じなら速さは同じ**。

<div class="memo" markdown="1">

**発展**　高校では、h/L を **sin θ**、d/L を **cos θ**（θ は斜面の角度）と書く（数学Ⅰの三角比）。平行な分力 ＝ mg sin θ、加速度 a ＝ g sin θ。θ ＝ 90° で sin θ ＝ 1（自由落下）、θ ＝ 0° で sin θ ＝ 0（動かない）。三角比は「相似な直角三角形の辺の比」に名前をつけたものだ。

</div>

### 7　作用・反作用と2つの物体<span class="deru">入試</span>

<figure><svg width="460" viewBox="0 0 560 120" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><line x1="20" y1="95" x2="540" y2="95" stroke="#000" stroke-width="1.5"/><rect x="170" y="35" width="90" height="60" fill="#e4e4e4" stroke="#000" stroke-width="1.5"/><rect x="260" y="55" width="60" height="40" fill="#fff" stroke="#000" stroke-width="1.5"/><text x="215" y="70" font-size="12" text-anchor="middle">A 2.0 kg</text><text x="290" y="80" font-size="12" text-anchor="middle">B</text><text x="290" y="50" font-size="10" text-anchor="middle">1.0 kg</text><line x1="90" y1="65" x2="168" y2="65" stroke="#000" stroke-width="2.4" marker-end="url(#ah0)"/><text x="95" y="57" font-size="12">6.0 N</text><line x1="320" y1="75" x2="380" y2="75" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><text x="385" y="79" font-size="11">AがBをおす力 2.0 N</text><line x1="258" y1="45" x2="210" y2="45" stroke="#000" stroke-width="1.6" stroke-dasharray="4 3" marker-end="url(#ah0)"/><text x="140" y="25" font-size="11">BがAをおす力 2.0 N（反作用）</text><text x="280" y="113" font-size="11" text-anchor="middle">なめらかな床</text></svg><figcaption>図4　接した2物体をおす。AとBがおし合う力は作用・反作用で、大きさが等しく向きが逆。</figcaption></figure>

- なめらかな床の上で、接している物体A（2.0 kg）とB（1.0 kg）を、Aの左から 6.0 N でおす。
- ひとまとめ：3.0a ＝ 6.0 → **a ＝ 2.0 m/s²**
- B だけに注目：BにはたらくのはAがBをおす力 f だけ → f ＝ 1.0 × 2.0 ＝ **2.0 N**
- A だけに注目：右向き 6.0 N と、BがAをおし返す力 f（左向き、**作用・反作用で同じ 2.0 N**）→ 2.0 × 2.0 ＝ 6.0 − 2.0 ✓
- スケートをはいた2人がおし合うと、受ける力の大きさは等しいので、**加速度は質量に反比例**（軽い人のほうが大きく加速する）。

### 8　摩擦力の入り口

<figure><svg width="440" viewBox="0 0 560 210" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><line x1="60" y1="175" x2="390" y2="175" stroke="#000" stroke-width="1.2" marker-end="url(#ah0)"/><line x1="60" y1="175" x2="60" y2="25" stroke="#000" stroke-width="1.2" marker-end="url(#ah0)"/><text x="394" y="179" font-size="12">引く力</text><text x="60" y="19" font-size="12" text-anchor="middle">摩擦力</text><line x1="60" y1="175" x2="210" y2="55" stroke="#000" stroke-width="2.2"/><line x1="210" y1="55" x2="210" y2="95" stroke="#000" stroke-width="1.2" stroke-dasharray="4 3"/><line x1="210" y1="95" x2="380" y2="95" stroke="#000" stroke-width="2.2"/><line x1="60" y1="55" x2="210" y2="55" stroke="#000" stroke-width="0.7" stroke-dasharray="2 3"/><line x1="60" y1="95" x2="210" y2="95" stroke="#000" stroke-width="0.7" stroke-dasharray="2 3"/><text x="56" y="59" font-size="10.5" text-anchor="end">最大摩擦力</text><text x="56" y="99" font-size="10.5" text-anchor="end">動摩擦力</text><text x="130" y="155" font-size="11">静止摩擦力</text><text x="130" y="169" font-size="10">（引く力とつり合う）</text><text x="295" y="83" font-size="11" text-anchor="middle">すべっている</text><line x1="210" y1="175" x2="210" y2="55" stroke="#000" stroke-width="0.6" stroke-dasharray="2 3"/><text x="210" y="190" font-size="10.5" text-anchor="middle">動き出す</text><text x="56" y="189" font-size="12" text-anchor="end">O</text></svg><figcaption>図5　引く力を少しずつ大きくしたときの摩擦力。</figcaption></figure>

- **静止摩擦力**：物体が動かないとき、引く力と**つり合う**ように大きさが変わる（引く力が 2 N なら 2 N）。
- **最大摩擦力**：静止摩擦力の限界。これをこえると動き出す。
- **動摩擦力**：すべっている間にはたらく摩擦力。速さによらず**ほぼ一定**で、ふつう最大摩擦力より**小さい**（動き出すと少し楽になる）。
- 最大摩擦力・動摩擦力は、**垂直抗力 N に比例**する（高校では 動摩擦力 ＝ μ′N と書く。μ′ は面で決まる数で**動摩擦係数**という）。重い物ほど床を強くおすので、摩擦も大きい。
- 例：水平な床を 3.92 m/s ですべる 5.0 kg の物体に、動摩擦力 9.8 N がはたらく → a ＝ −9.8 ÷ 5.0 ＝ **−1.96 m/s²**、止まるまで 3.92 ÷ 1.96 ＝ **2.0 s**、距離は v-t グラフの三角形 3.92 × 2.0 ÷ 2 ＝ **3.92 m**。

<div class="point" markdown="1">

**まとめチェック（できたら□にチェック）**

□ 加速度 ＝ 速度の変化 ÷ 時間（m/s²）。**v-t グラフの傾き**。減速はマイナス。
□ v ＝ v₀ ＋ at、x ＝ v₀t ＋ (1/2)at²、v² − v₀² ＝ 2ax。**v-t グラフの面積 ＝ 移動距離**。
□ 静止から出発すると x ＝ (1/2)at²（**y＝ax² と同じ形**）なので、x-t グラフは**放物線**。
□ **ma ＝ F**。F は「その物体にはたらく力の合計」。重力 ＝ mg、g ＝ 9.8 m/s²。
□ 斜面の加速度 ＝ g × h/L（**相似**で出す）。30° なら g/2。質量によらない。
□ 2物体：**ひとまとめ**で a、**片方だけ**で糸の張力やおし合う力。作用・反作用は同じ大きさ。
□ 動摩擦力はほぼ一定で垂直抗力に比例。最大摩擦力より小さい。

</div>

## 練習問題

### 基本

#### <span class="no">1</span> 次の文の（　）にあてはまる言葉や数値を書きなさい。重力加速度は 9.8 m/s² とする。

(1) 1秒あたりの速度の変化を（　　　）といい、単位は（　　　）である。
(2) v-t グラフ（速度と時間のグラフ）の傾きは（　　　）を、グラフの下の面積は（　　　）を表す。
(3) 質量 1 kg の物体に 1 m/s² の加速度を生じさせる力の大きさを（　　　）という。
(4) 物体どうしが接している面で、すべっている物体の運動をさまたげる向きにはたらく摩擦力を（　　　）という。
(5) 質量 50 kg の物体にはたらく重力の大きさは（　　　）N である。

#### <span class="no">2</span> 次の問いに答えなさい。

<div class="cols2" markdown="1">

(1) 静止していた物体が 4.0 秒間で 12 m/s になった。加速度は何 m/s² か。
(2) 20 m/s で進む物体が、3.0 秒間で 8.0 m/s になった。加速度は何 m/s² か（向きは＋・−で表す）。
(3) 72 km/h で走る自動車が一定の割合で減速し、5.0 秒で止まった。加速度の大きさは何 m/s² か。
(4) 質量 2.0 kg の物体に 6.0 N の力がはたらく。加速度は何 m/s² か。
(5) 質量 0.50 kg の物体に 1.5 m/s² の加速度を生じさせる力は何 N か。
(6) ある物体に 8.0 N の力を加えると、4.0 m/s² の加速度が生じた。物体の質量は何 kg か。

</div>

#### <span class="no">3</span> グラフは、直線の道路を走る自動車の速度と時間の関係（v-t グラフ）を表したものである。自動車の質量は 1000 kg とする。

<div class="cols2" markdown="1">

<figure><svg width="280" viewBox="0 0 300 200" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><line x1="40" y1="170" x2="40" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="70" y1="170" x2="70" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="100" y1="170" x2="100" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="130" y1="170" x2="130" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="160" y1="170" x2="160" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="190" y1="170" x2="190" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="220" y1="170" x2="220" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="250" y1="170" x2="250" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="280" y1="170" x2="280" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="170" x2="280" y2="170" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="150" x2="280" y2="150" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="130" x2="280" y2="130" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="110" x2="280" y2="110" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="90" x2="280" y2="90" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="70" x2="280" y2="70" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="50" x2="280" y2="50" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="30" x2="280" y2="30" stroke="#000" stroke-width="0.5" stroke-opacity="0.35"/><line x1="40" y1="170" x2="295" y2="170" stroke="#000" stroke-width="1.2" marker-end="url(#ah0)"/><line x1="40" y1="170" x2="40" y2="15" stroke="#000" stroke-width="1.2" marker-end="url(#ah0)"/><text x="299" y="174" font-size="12"></text><text x="40" y="9" font-size="12" text-anchor="middle"></text><polyline points="40,170 100,50 220,50 280,170" fill="none" stroke="#000" stroke-width="2.4"/><text x="40" y="184" font-size="11" text-anchor="middle">0</text><text x="100" y="184" font-size="11" text-anchor="middle">2</text><text x="160" y="184" font-size="11" text-anchor="middle">4</text><text x="220" y="184" font-size="11" text-anchor="middle">6</text><text x="280" y="184" font-size="11" text-anchor="middle">8</text><text x="35" y="174" font-size="11" text-anchor="end">0</text><text x="35" y="134" font-size="11" text-anchor="end">2</text><text x="35" y="94" font-size="11" text-anchor="end">4</text><text x="35" y="54" font-size="11" text-anchor="end">6</text><text x="160" y="198" font-size="11" text-anchor="middle">時間〔s〕</text><text x="44" y="26" font-size="11">速度〔m/s〕</text></svg></figure>

(1) 0〜2 秒の加速度は何 m/s² か。
(2) 0〜8 秒の間に進んだ距離は何 m か。
(3) 2〜6 秒の間について述べたものとして最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．自動車には、運動の向きに一定の大きさの力がはたらき続けている。
　2．自動車にはたらく力の合力は 0 である。
　3．自動車にはたらく力は重力だけである。
　4．自動車の加速度は 6 m/s² である。
(4) 6〜8 秒の間に自動車にはたらく力の合力の大きさは何 N か。また、その向きは運動の向きと同じか、逆か。

</div>

### 標準

#### <span class="no">4</span> 静止していた台車が、一直線上を一定の加速度 2.0 m/s² で動き出した。

(1) 動き出してから 5.0 秒後の速さは何 m/s か。
(2) 動き出してから 5.0 秒間に進んだ距離は何 m か。
(3) 動き出してから 100 m 進んだときの速さは何 m/s か。また、それは動き出してから何秒後か。
(4) この台車の位置 x と時間 t の関係を表すグラフ（x-t グラフ）として最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．原点を通る右上がりの直線　　　2．原点を頂点とし、時間がたつほど傾きが大きくなる放物線
　3．時間がたつほど傾きが小さくなる曲線　　4．時間の軸に平行な直線

#### <span class="no">5</span> 50 Hz の記録タイマーを使って、斜面を下る台車（質量 0.50 kg）の運動を記録した。台車から手をはなした瞬間の打点から、打点の間隔5つ分ごとにテープを切ると、長さは順に 1.0 cm、3.0 cm、5.0 cm、7.0 cm だった。

(1) 3本目のテープの区間の平均の速さは何 cm/s か。
(2) 台車の加速度は何 m/s² か。
(3) 台車にはたらく、斜面に平行な向きの力の合計は何 N か。
(4) 手をはなしてからの移動距離の合計は、0.1 秒ごとに 1.0 cm、4.0 cm、9.0 cm、16.0 cm になる。時間を t〔s〕、移動距離を x〔cm〕として、x を t の式で表しなさい。

#### <span class="no">6</span> 要点まとめの実験1・実験2（台車を水平面で一定の力で引く実験）について、次の問いに答えなさい。

(1) 実験1から、加速度と引く力の間にはどのような関係があるといえるか。
(2) 実験2で、台車の質量を 1.5 kg にすると加速度は何 m/s² になると考えられるか。
(3) 実験2の結果を、横軸に「質量の逆数（1/質量）」、たて軸に「加速度」をとってグラフにした。グラフの形として最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．原点を通る直線　　2．右下がりの直線　　3．原点を頂点とする放物線　　4．双曲線

#### <span class="no">7</span> なめらかな斜面に物体を置き、静かに手をはなした。重力加速度は 9.8 m/s² とする。

(1) 角度 30° の斜面に、質量 2.0 kg の物体を置いた。物体にはたらく重力の、斜面に平行な分力は何 N か。
(2) (1) の物体の加速度は何 m/s² か。
(3) (1) の物体が、手をはなしてから 2.0 秒間に進んだ距離は何 m か。また、2.0 秒後の速さは何 m/s か。
(4) 長さ 5.0 m・高さ 3.0 m の斜面（底辺 4.0 m）に物体を置いた。加速度は何 m/s² か。
(5) (1) の物体を質量 4.0 kg の物体にかえた。加速度について述べたものとして最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．2倍になる。　　2．1/2 倍になる。　　3．変わらない。　　4．0 になる。

### 入試にチャレンジ

#### <span class="no">8</span> 要点まとめの例題（図2）と同じ装置で、台車（質量 0.40 kg）とおもり（質量 0.10 kg）を糸でつなぎ、静かに手をはなした。摩擦と糸・滑車の質量は考えず、重力加速度は 9.8 m/s² とする。

(1) 台車とおもりをひとまとめにして運動方程式を立て、加速度を求めなさい。
(2) 糸が台車を引く力（張力）は何 N か。
(3) 糸の張力とおもりにはたらく重力の大きさの関係として最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．張力のほうが大きい。　2．等しい。　3．張力のほうが小さい。　4．時間とともに変わる。
(4) 手をはなしてから 0.50 秒後の台車の速さは何 m/s か。

#### <span class="no">9</span> なめらかな水平面の上で、物体A（3.0 kg）と物体B（1.0 kg）を接して置き、Aを左から右向きに 8.0 N の力でおした。

(1) A・B全体の加速度は何 m/s² か。
(2) AがBをおす力は何 N か。
(3) BがAをおす力の大きさと向きを答えなさい。また、その力と (2) の力の関係を何というか。
(4) 次に、Bを右から左向きに 8.0 N の力でおした。AとBがおし合う力は何 N か。
(5) スケートをはいたKさん（40 kg）とLさん（60 kg）が向かい合って立ち、おし合った。このときのようすとして最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．Kさんのほうが大きな力を受けるので、Kさんの加速度が大きい。
　2．2人は同じ大きさの力を受け、Kさんの加速度はLさんの 1.5 倍である。
　3．2人は同じ大きさの力を受け、加速度も等しい。
　4．強くおしたほうの人だけが動く。

#### <span class="no">10</span> 水平な床の上の物体に、ばねばかりで水平に引く力を少しずつ大きくしながら加えた。引く力が 6.0 N をこえると物体は動き出し、その後は 4.9 N の力で引くと一定の速さで動き続けた。重力加速度は 9.8 m/s² とする。

(1) 引く力が 4.0 N のとき（物体は止まっている）、物体にはたらく摩擦力は何 N か。
(2) 最大摩擦力と動摩擦力は、それぞれ何 N か。
(3) この物体の質量は 5.0 kg である。同じ床の上で、この物体を 3.92 m/s の速さですべらせた。止まるまでの時間と距離を求めなさい。
(4) (3) で、同じ面のまま物体の質量だけを 2 倍にして同じ速さですべらせると、止まるまでの距離はどうなるか。理由とともに説明しなさい。

<div class="line"></div>

<div class="line"></div>

#### <span class="no">11</span> 静止しているエレベーターの床に体重計を置き、質量 50 kg のKさんが乗った。体重計は、Kさんが体重計をおす力〔N〕を表示する。重力加速度は 9.8 m/s² とする。

(1) エレベーターが静止しているとき、体重計の表示は何 N か。
(2) エレベーターが上向きに 1.2 m/s² の加速度で動き出したとき、体重計の表示は何 N か。（ヒント：Kさんにはたらく力は、重力と、体重計がKさんをおす力）
(3) エレベーターが下向きに 1.2 m/s² の加速度で動き出したとき、体重計の表示は何 N か。
(4) もしエレベーターが下向きに 9.8 m/s² の加速度で動いたら（自由落下）、体重計の表示はどうなるか。最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．980 N　　2．490 N　　3．245 N　　4．0 N

#### <span class="no">12</span> 自分で問題を作ってみよう

問題 8 の装置で、**台車とおもりの質量を自分で決めて**（おもりの重力が計算しやすい質量がおすすめ）、「加速度」「糸の張力」「手をはなしてから t 秒後の速さ」を求める問題を作り、自分で解きなさい。さらに、「おもりの質量を台車よりずっと大きくすると、加速度は何 m/s² に近づくか」を考えなさい。

<div class="line"></div>

<div class="line"></div>

## 解答・解説

<div class="kaito" markdown="1">

#### <span class="no">1</span>

(1) **加速度**、**m/s²**　(2) **加速度**、**移動距離（変位）**　(3) **1 N（1ニュートン）**　(4) **動摩擦力**　(5) **490**
(5) W ＝ mg ＝ 50 × 9.8 ＝ 490 N。

#### <span class="no">2</span>

(1) 12 ÷ 4.0 ＝ **3.0 m/s²**
(2)（8.0 − 20）÷ 3.0 ＝ **−4.0 m/s²**（運動と逆向き）
(3) 72 km/h ＝ 20 m/s。20 ÷ 5.0 ＝ **4.0 m/s²**
(4) a ＝ F/m ＝ 6.0 ÷ 2.0 ＝ **3.0 m/s²**
(5) F ＝ ma ＝ 0.50 × 1.5 ＝ **0.75 N**
(6) m ＝ F/a ＝ 8.0 ÷ 4.0 ＝ **2.0 kg**

#### <span class="no">3</span>

(1) 6 ÷ 2 ＝ **3 m/s²**
(2) **36 m**　台形の面積。0〜2 秒：2 × 6 ÷ 2 ＝ 6 m、2〜6 秒：4 × 6 ＝ 24 m、6〜8 秒：6 m。合計 36 m。
(3) **2**　速度一定 ＝ 加速度 0 ＝ 合力 0（慣性の法則）。1 を選ぶのは「動き続けるには力が必要」という誤解。実際は駆動力と空気の抵抗などがつり合っている。
(4) **3000 N、逆向き**　加速度は（0 − 6）÷ 2 ＝ −3 m/s²。F ＝ 1000 × 3 ＝ 3000 N。

#### <span class="no">4</span>

(1) v ＝ 2.0 × 5.0 ＝ **10 m/s**
(2) x ＝ (1/2) × 2.0 × 5.0² ＝ **25 m**
(3) **20 m/s、10 秒後**　v² ＝ 2 × 2.0 × 100 ＝ 400 より v ＝ 20。t ＝ 20 ÷ 2.0 ＝ 10。（x ＝ t² ＝ 100 から t ＝ 10 でもよい）
(4) **2**　x ＝ t²（y ＝ ax² の形）。傾き（速度）がだんだん大きくなる。

#### <span class="no">5</span>

(1) 5.0 ÷ 0.1 ＝ **50 cm/s**
(2) **2.0 m/s²**　各区間の平均の速さは 10、30、50、70 cm/s で、0.1 秒ごとに 20 cm/s 増える。20 ÷ 0.1 ＝ 200 cm/s² ＝ 2.0 m/s²。（となりの区間の差 2.0 cm ＝ a × 0.1² からも出る）
(3) F ＝ ma ＝ 0.50 × 2.0 ＝ **1.0 N**
(4) **x ＝ 100t²**　x ＝ (1/2)at² ＝ (1/2) × 200 × t²。t ＝ 0.2 なら 100 × 0.04 ＝ 4.0 ✓

#### <span class="no">6</span>

(1) **加速度は引く力に比例する。**
(2) **0.80 m/s²**　a ＝ F/m ＝ 1.2 ÷ 1.5。（a × m ＝ 1.2 で一定）
(3) **1**　a ＝ 1.2 × (1/m) なので、1/m に比例。反比例のグラフ（双曲線）を「逆数」で直線にするのは、実験のデータ整理でよく使うワザ。

#### <span class="no">7</span>

(1) 重力は 2.0 × 9.8 ＝ 19.6 N。30° の斜面では h/L ＝ 1/2 なので **9.8 N**
(2) a ＝ 9.8 ÷ 2.0 ＝ **4.9 m/s²**
(3) **9.8 m、9.8 m/s**　x ＝ (1/2) × 4.9 × 2.0² ＝ 9.8、v ＝ 4.9 × 2.0 ＝ 9.8。
(4) a ＝ 9.8 × 3.0/5.0 ＝ **5.88 m/s²**（約 5.9 m/s²）
(5) **3**　a ＝ g × h/L で、質量が入っていない。

#### <span class="no">8</span>

(1) 全体を動かす力はおもりの重力 0.10 × 9.8 ＝ 0.98 N。（0.40 ＋ 0.10）a ＝ 0.98 より **a ＝ 1.96 m/s²**（約 2.0 m/s²）
(2) 台車だけ：T ＝ 0.40 × 1.96 ＝ **0.784 N**（約 0.78 N）
確かめ：おもりだけ 0.10 × 1.96 ＝ 0.98 − 0.784 ＝ 0.196 ✓
(3) **3**　おもりが下向きに加速するには、下向きの重力が上向きの張力より大きい必要がある。
(4) v ＝ 1.96 × 0.50 ＝ **0.98 m/s**

#### <span class="no">9</span>

(1) 4.0a ＝ 8.0 → **2.0 m/s²**
(2) Bだけ：f ＝ 1.0 × 2.0 ＝ **2.0 N**
(3) **2.0 N、左向き**。**作用・反作用**（の関係）。Aだけ：3.0 × 2.0 ＝ 8.0 − 2.0 ✓
(4) 加速度は同じ 2.0 m/s²（左向き）。今度はBがAをおす力がAを動かすので f ＝ 3.0 × 2.0 ＝ **6.0 N**。重いほうを後ろからおされる側にすると、おし合う力は大きくなる。
(5) **2**　作用・反作用で力は等しい。a ＝ F/m なので、加速度は質量に反比例し 60 ÷ 40 ＝ 1.5 倍。

#### <span class="no">10</span>

(1) **4.0 N**　静止しているので引く力とつり合う（静止摩擦力）。
(2) 最大摩擦力 **6.0 N**、動摩擦力 **4.9 N**　一定の速さ ＝ 力がつり合う。
(3) **4.0 秒、7.84 m**　すべっている間は動摩擦力 4.9 N だけが運動と逆向きにはたらく。a ＝ −4.9 ÷ 5.0 ＝ −0.98 m/s²。t ＝ 3.92 ÷ 0.98 ＝ 4.0。x ＝ 3.92 × 4.0 ÷ 2 ＝ 7.84（v² − v₀² ＝ 2ax でも 0 − 3.92² ＝ 2 ×（−0.98）× x → x ＝ 7.84）。
(4)（例）**変わらない。質量が2倍になると垂直抗力も2倍になり動摩擦力も2倍になるが、動かしにくさ（質量）も2倍なので、加速度 ＝ 動摩擦力 ÷ 質量 は変わらないから。**

#### <span class="no">11</span>

(1) **490 N**（50 × 9.8）
(2) **550 N**　体重計がKさんをおす力を N とすると、上向きを＋として 50 × 1.2 ＝ N − 490、N ＝ 550。作用・反作用で、Kさんが体重計をおす力も 550 N。
(3) **430 N**　50 × 1.2 ＝ 490 − N より N ＝ 430。
(4) **4**　50 × 9.8 ＝ 490 − N より N ＝ 0。体重計とKさんがいっしょに落ちるので、おし合わない（**無重量状態**）。宇宙ステーションの中で体が浮くのも同じしくみ（物理Cで学ぶ）。

#### <span class="no">12</span>

（解答例）台車 0.80 kg、おもり 0.20 kg とする。おもりの重力は 0.20 × 9.8 ＝ 1.96 N。
加速度：1.0a ＝ 1.96 → **a ＝ 1.96 m/s²**。張力：T ＝ 0.80 × 1.96 ＝ **1.568 N**。2.0 秒後の速さ：1.96 × 2.0 ＝ **3.92 m/s**。
一般に、台車 M、おもり m のとき a ＝ mg/(M ＋ m)。m を M よりずっと大きくすると、分母 M ＋ m がほぼ m になるので a は **g ＝ 9.8 m/s² に近づく**（台車がほぼ「ないもの」になり、おもりは自由落下に近づく）。このように、**極端な場合を考えて答えを確かめる**のは、物理の強力なチェック方法。

</div>
