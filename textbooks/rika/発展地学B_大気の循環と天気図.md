# 発展理科 地学B「大気の循環と天気図の解析」

<p class="lead">ねらい：「なぜ日本の天気は西から変わるのか」「なぜ低気圧の風はうずを巻くのか」を、太陽の熱のかたより・地球の自転・力のつり合いから自分で説明する。天気図の等圧線と前線から、風の強さ・向き・天気の変化を数字で予想できるようになる。</p>

<div class="memo" markdown="1">

**発展**　**LEVEL 3〜4**　高校「**地学基礎**」（大気と海洋：熱の収支・大気の大循環・海洋の循環・エルニーニョ現象）と「**地学**」（風にはたらく力）への橋渡し。使う道具は、**地学4**（気圧と風）・**地学5**（雲のでき方）・**地学6**（前線・偏西風）・**地学7**（南中高度）と、数学の**30°・60°の直角三角形（1：2：√3）**・**速さ＝距離÷時間**だけ。難関校の入試では「緯度と太陽の熱の量」「天気図から風向を決める」「前線が来る時刻を計算する」などが、考え方を問う形で出る。

</div>

## 要点まとめ

### 1　太陽の熱は、緯度によってかたよる<span class="deru">入試</span>

- 同じ量の光でも、**ななめに当たるほど広い面積に広がり**、1 m² あたりの熱は少なくなる（地学7）。春分・秋分の正午の太陽高度は「**90° − 緯度**」なので、赤道では 90°、北緯60°では 30°。

<figure><svg width="470" viewBox="0 0 680 290" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><circle cx="170" cy="150" r="110" fill="#f2f2f2" stroke="#000" stroke-width="1.6"/><line x1="60" y1="150" x2="280" y2="150" stroke="#000" stroke-width="0.8" stroke-dasharray="3 3"/><text x="284" y="154" font-size="10.5">赤道</text><line x1="115" y1="54.7" x2="225" y2="54.7" stroke="#000" stroke-width="0.8" stroke-dasharray="3 3"/><text x="229" y="58.7" font-size="10.5">北緯60°</text><line x1="170" y1="28" x2="170" y2="272" stroke="#000" stroke-width="1" stroke-dasharray="6 3"/><text x="174" y="26" font-size="10">地軸（春分・秋分の日）</text><polygon points="10,138 60.7,138 60.7,162 10,162" fill="#d0d0d0" stroke="none"/><line x1="10" y1="138" x2="60.7" y2="138" stroke="#000" stroke-width="1"/><line x1="10" y1="162" x2="60.7" y2="162" stroke="#000" stroke-width="1"/><path d="M60.7,138 A110,110 0 0,0 60.7,162" fill="none" stroke="#000" stroke-width="4"/><polygon points="10,42.7 145.6,42.7 98.1,66.7 10,66.7" fill="#d0d0d0" stroke="none"/><line x1="10" y1="42.7" x2="145.6" y2="42.7" stroke="#000" stroke-width="1"/><line x1="10" y1="66.7" x2="98.1" y2="66.7" stroke="#000" stroke-width="1"/><path d="M145.6,42.7 A110,110 0 0,0 98.1,66.7" fill="none" stroke="#000" stroke-width="4"/><line x1="10" y1="255" x2="50" y2="255" stroke="#000" stroke-width="1.6" marker-end="url(#ah0)"/><text x="10" y="270" font-size="10">太陽の光（平行）</text><text x="10" y="36.7" font-size="10">同じはば</text><text x="56" y="178" text-anchor="end" font-size="10.5" font-weight="700">面積 1</text><text x="105" y="32.7" text-anchor="end" font-size="10.5" font-weight="700">面積 2</text><line x1="380" y1="250" x2="660" y2="250" stroke="#000" stroke-width="1.2"/><line x1="380" y1="250" x2="380" y2="40" stroke="#000" stroke-width="1.2"/><line x1="380" y1="250" x2="380" y2="254" stroke="#000" stroke-width="1"/><text x="380" y="266" text-anchor="middle" font-size="10">0°</text><line x1="473.3" y1="250" x2="473.3" y2="254" stroke="#000" stroke-width="1"/><text x="473.3" y="266" text-anchor="middle" font-size="10">30°</text><line x1="566.7" y1="250" x2="566.7" y2="254" stroke="#000" stroke-width="1"/><text x="566.7" y="266" text-anchor="middle" font-size="10">60°</text><line x1="660" y1="250" x2="660" y2="254" stroke="#000" stroke-width="1"/><text x="660" y="266" text-anchor="middle" font-size="10">90°</text><text x="520" y="282" text-anchor="middle" font-size="10.5">緯度（北半球）</text><text x="376" y="44" text-anchor="end" font-size="10">多</text><text x="376" y="250" text-anchor="end" font-size="10">少</text><polygon points="380,50.5 381.6,50.5 383.1,50.5 384.7,50.6 386.2,50.7 387.8,50.8 389.3,50.9 390.9,51.1 392.4,51.3 394,51.5 395.6,51.7 397.1,51.9 398.7,52.2 400.2,52.5 401.8,52.8 403.3,53.1 404.9,53.5 406.4,53.9 408,54.3 409.6,54.7 411.1,55.2 412.7,55.7 414.2,56.1 415.8,56.7 417.3,57.2 418.9,57.8 420.4,58.4 422,59 423.6,59.6 425.1,60.2 426.7,60.9 428.2,61.6 429.8,62.3 431.3,63.1 432.9,63.8 434.4,64.6 436,65.4 437.6,66.2 439.1,67 440.7,67.9 442.2,68.8 443.8,69.7 445.3,70.6 446.9,71.5 448.4,72.5 450,73.4 451.6,74.4 453.1,75.4 454.7,76.4 456.2,77.5 457.8,78.5 459.3,79.6 460.9,80.7 462.4,81.8 464,82.9 465.6,84.1 467.1,85.2 468.7,86.4 470.2,87.6 471.8,88.8 473.3,90 474.9,91.2 476.4,92.5 478,93.7 479.6,95 481.1,96.3 482.7,97.5 484.2,98.9 485.8,100.2 487.3,101.5 488.9,102.8 490.4,104.2 492,105.6 493.6,106.9 495.1,108.3 496.7,109.7 498.2,111.1 499.8,112.5 501.3,113.9 502.9,115.4 502.9,115.5 501.3,115.2 499.8,115 498.2,114.7 496.7,114.4 495.1,114.1 493.6,113.8 492,113.5 490.4,113.2 488.9,112.9 487.3,112.6 485.8,112.3 484.2,112 482.7,111.8 481.1,111.5 479.6,111.2 478,110.9 476.4,110.6 474.9,110.3 473.3,110 471.8,109.7 470.2,109.4 468.7,109.1 467.1,108.8 465.6,108.5 464,108.2 462.4,108 460.9,107.7 459.3,107.4 457.8,107.1 456.2,106.8 454.7,106.5 453.1,106.2 451.6,105.9 450,105.6 448.4,105.3 446.9,105 445.3,104.8 443.8,104.5 442.2,104.2 440.7,103.9 439.1,103.6 437.6,103.3 436,103 434.4,102.7 432.9,102.4 431.3,102.1 429.8,101.8 428.2,101.5 426.7,101.2 425.1,101 423.6,100.7 422,100.4 420.4,100.1 418.9,99.8 417.3,99.5 415.8,99.2 414.2,98.9 412.7,98.6 411.1,98.3 409.6,98 408,97.8 406.4,97.5 404.9,97.2 403.3,96.9 401.8,96.6 400.2,96.3 398.7,96 397.1,95.7 395.6,95.4 394,95.1 392.4,94.8 390.9,94.5 389.3,94.2 387.8,94 386.2,93.7 384.7,93.4 383.1,93.1 381.6,92.8 380,92.5" fill="#c8c8c8" stroke="#000" stroke-width="0"/><polygon points="502.9,115.4 504.4,116.8 506,118.3 507.6,119.7 509.1,121.2 510.7,122.6 512.2,124.1 513.8,125.6 515.3,127.1 516.9,128.5 518.4,130 520,131.5 521.6,133 523.1,134.5 524.7,136 526.2,137.5 527.8,139.1 529.3,140.6 530.9,142.1 532.4,143.6 534,145.1 535.6,146.6 537.1,148.2 538.7,149.7 540.2,151.2 541.8,152.7 543.3,154.2 544.9,155.7 546.4,157.2 548,158.8 549.6,160.3 551.1,161.8 552.7,163.3 554.2,164.7 555.8,166.2 557.3,167.7 558.9,169.2 560.4,170.7 562,172.1 563.6,173.6 565.1,175 566.7,176.5 568.2,177.9 569.8,179.3 571.3,180.8 572.9,182.2 574.4,183.6 576,185 577.6,186.3 579.1,187.7 580.7,189.1 582.2,190.4 583.8,191.7 585.3,193.1 586.9,194.4 588.4,195.7 590,196.9 591.6,198.2 593.1,199.5 594.7,200.7 596.2,201.9 597.8,203.1 599.3,204.3 600.9,205.5 602.4,206.6 604,207.8 605.6,208.9 607.1,210 608.7,211.1 610.2,212.1 611.8,213.2 613.3,214.2 614.9,215.2 616.4,216.2 618,217.2 619.6,218.1 621.1,219 622.7,219.9 624.2,220.8 625.8,221.6 627.3,222.4 628.9,223.2 630.4,224 632,224.7 633.6,225.4 635.1,226.1 636.7,226.8 638.2,227.4 639.8,228 641.3,228.6 642.9,229.1 644.4,229.6 646,230.1 647.6,230.5 649.1,230.9 650.7,231.3 652.2,231.6 653.8,231.9 655.3,232.1 656.9,232.3 658.4,232.4 660,232.5 660,145 658.4,144.7 656.9,144.4 655.3,144.1 653.8,143.8 652.2,143.5 650.7,143.2 649.1,143 647.6,142.7 646,142.4 644.4,142.1 642.9,141.8 641.3,141.5 639.8,141.2 638.2,140.9 636.7,140.6 635.1,140.3 633.6,140 632,139.8 630.4,139.5 628.9,139.2 627.3,138.9 625.8,138.6 624.2,138.3 622.7,138 621.1,137.7 619.6,137.4 618,137.1 616.4,136.8 614.9,136.5 613.3,136.2 611.8,136 610.2,135.7 608.7,135.4 607.1,135.1 605.6,134.8 604,134.5 602.4,134.2 600.9,133.9 599.3,133.6 597.8,133.3 596.2,133 594.7,132.8 593.1,132.5 591.6,132.2 590,131.9 588.4,131.6 586.9,131.3 585.3,131 583.8,130.7 582.2,130.4 580.7,130.1 579.1,129.8 577.6,129.5 576,129.2 574.4,129 572.9,128.7 571.3,128.4 569.8,128.1 568.2,127.8 566.7,127.5 565.1,127.2 563.6,126.9 562,126.6 560.4,126.3 558.9,126 557.3,125.8 555.8,125.5 554.2,125.2 552.7,124.9 551.1,124.6 549.6,124.3 548,124 546.4,123.7 544.9,123.4 543.3,123.1 541.8,122.8 540.2,122.5 538.7,122.2 537.1,122 535.6,121.7 534,121.4 532.4,121.1 530.9,120.8 529.3,120.5 527.8,120.2 526.2,119.9 524.7,119.6 523.1,119.3 521.6,119 520,118.8 518.4,118.5 516.9,118.2 515.3,117.9 513.8,117.6 512.2,117.3 510.7,117 509.1,116.7 507.6,116.4 506,116.1 504.4,115.8 502.9,115.5" fill="#ececec" stroke="#000" stroke-width="0"/><polyline points="380,50.5 389.3,50.9 398.7,52.2 408,54.3 417.3,57.2 426.7,60.9 436,65.4 445.3,70.6 454.7,76.4 464,82.9 473.3,90 482.7,97.5 492,105.6 501.3,113.9 510.7,122.6 520,131.5 529.3,140.6 538.7,149.7 548,158.8 557.3,167.7 566.7,176.5 576,185 585.3,193.1 594.7,200.7 604,207.8 613.3,214.2 622.7,219.9 632,224.7 641.3,228.6 650.7,231.3 660,232.5" fill="none" stroke="#000" stroke-width="2.2"/><polyline points="380,92.5 389.3,94.2 398.7,96 408,97.8 417.3,99.5 426.7,101.2 436,103 445.3,104.8 454.7,106.5 464,108.2 473.3,110 482.7,111.8 492,113.5 501.3,115.2 510.7,117 520,118.8 529.3,120.5 538.7,122.2 548,124 557.3,125.8 566.7,127.5 576,129.2 585.3,131 594.7,132.8 604,134.5 613.3,136.2 622.7,138 632,139.8 641.3,141.5 650.7,143.2 660,145" fill="none" stroke="#000" stroke-width="2" stroke-dasharray="6 3"/><text x="404.9" y="45.5" font-size="10.5" font-weight="700">受け取る太陽の熱</text><text x="572.9" y="118.7" font-size="10.5" font-weight="700">宇宙へ出ていく熱</text><text x="423.6" y="132" font-size="10.5">熱があまる</text><text x="585.3" y="175" font-size="10.5">熱が足りない</text><line x1="442.2" y1="194" x2="551.1" y2="194" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><text x="498.2" y="209" text-anchor="middle" font-size="10">大気と海が熱を運ぶ</text><text x="503.2" y="34" text-anchor="middle" font-size="10">約40°</text><line x1="503.2" y1="40" x2="503.2" y2="250" stroke="#000" stroke-width="0.8" stroke-dasharray="2 2"/></svg><figcaption>図1　左：同じはばの光が、北緯60°では赤道の2倍の面積に広がる（春分・秋分の正午）。右：緯度ごとの熱の出入り（年平均の模式図）。低緯度で熱があまり、高緯度で足りない。</figcaption></figure>

<div class="point" markdown="1">

**POINT 1　光の広がりを直角三角形で求める**

太陽高度 30° で、はば 1 の光が地面に当たると、地面・光・はばのつくる直角三角形は **30°・60°・90°**。辺の比 **1：2：√3** より、光が当たる地面の長さは **2** → 1 m² あたりの熱は **2分の1**。太陽高度 45° なら、直角二等辺三角形（1：1：√2）より **√2 ≒ 1.41** → 熱は約 **0.71倍**。

</div>

- 地球全体では、**低緯度は熱があまり**、**高緯度は熱が足りない**（境目はおよそ**緯度40°**）。それでも赤道が熱くなり続けないのは、**大気と海水が低緯度から高緯度へ熱を運ぶ**から。この「熱の運び屋」が、**大気の大循環**と**海流**である。

### 2　大気の大循環 ― 地球規模の風のベルト<span class="deru">入試</span>

- **ハドレー循環**：赤道付近であたためられた空気が**上昇**（雲ができて大雨）→ 上空を高緯度へ → **緯度30°付近で下降** → 地表を赤道へもどる。この地表の風が**貿易風**（北半球では**北東**から、南半球では**南東**から。理由は3で）。
- **緯度30°〜60°**の地表は西寄りの**偏西風**。日本（北緯約35°）はこの帯にあるので、**天気は西から東へ変わる**（地学6）。上空の特に強い偏西風が**ジェット気流**。
- **緯度60°〜90°**は極から流れ出す**極偏東風**。偏西風とぶつかる緯度60°付近が**寒帯前線帯**。

<figure><svg width="480" viewBox="0 0 680 320" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><circle cx="160" cy="160" r="130" fill="#f6f6f6" stroke="#000" stroke-width="1.6"/><line x1="95" y1="47.4" x2="225" y2="47.4" stroke="#000" stroke-width="0.8" stroke-dasharray="4 3"/><line x1="47.4" y1="95" x2="272.6" y2="95" stroke="#000" stroke-width="0.8" stroke-dasharray="4 3"/><line x1="30" y1="160" x2="290" y2="160" stroke="#000" stroke-width="1.2"/><line x1="47.4" y1="225" x2="272.6" y2="225" stroke="#000" stroke-width="0.8" stroke-dasharray="4 3"/><line x1="95" y1="272.6" x2="225" y2="272.6" stroke="#000" stroke-width="0.8" stroke-dasharray="4 3"/><line x1="170" y1="35" x2="150" y2="44" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="98.5" y1="73" x2="120.4" y2="63.2" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="149.1" y1="73" x2="170.9" y2="63.2" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="199.6" y1="73" x2="221.5" y2="63.2" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="101.9" y1="121.4" x2="80" y2="131.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="170.9" y1="121.4" x2="149.1" y2="131.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="240" y1="121.4" x2="218.1" y2="131.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="101.9" y1="198.6" x2="80" y2="188.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="170.9" y1="198.6" x2="149.1" y2="188.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="240" y1="198.6" x2="218.1" y2="188.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="98.5" y1="247" x2="120.4" y2="256.8" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="149.1" y1="247" x2="170.9" y2="256.8" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="199.6" y1="247" x2="221.5" y2="256.8" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="170" y1="285" x2="150" y2="276" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><text x="91" y="51.4" text-anchor="end" font-size="10">60°</text><text x="43.4" y="99" text-anchor="end" font-size="10">30°</text><text x="26" y="164" text-anchor="end" font-size="10">0°</text><text x="43.4" y="229" text-anchor="end" font-size="10">30°</text><text x="91" y="276.6" text-anchor="end" font-size="10">60°</text><text x="304" y="38.4" font-size="10.5" font-weight="700">極偏東風</text><text x="304" y="51.4" font-size="10">― 寒帯前線帯（低圧）</text><text x="304" y="72.1" font-size="10.5" font-weight="700">偏西風</text><text x="304" y="99" font-size="10">― 亜熱帯高圧帯（砂漠が多い）</text><text x="304" y="130.4" font-size="10.5" font-weight="700">北東貿易風</text><text x="304" y="164" font-size="10">― 熱帯収束帯（低圧・大雨）</text><text x="304" y="197.6" font-size="10.5" font-weight="700">南東貿易風</text><text x="304" y="229" font-size="10">― 亜熱帯高圧帯</text><text x="304" y="255.9" font-size="10.5" font-weight="700">偏西風</text><text x="304" y="276.6" font-size="10">― 寒帯前線帯</text><text x="304" y="289.6" font-size="10.5" font-weight="700">極偏東風</text><text x="570" y="24" text-anchor="middle" font-size="10.5" font-weight="700">北半球の断面</text><rect x="500" y="40" width="140" height="240" fill="#fff" stroke="#000" stroke-width="1"/><line x1="500" y1="200" x2="640" y2="200" stroke="#000" stroke-width="0.6" stroke-dasharray="2 2"/><line x1="500" y1="120" x2="640" y2="120" stroke="#000" stroke-width="0.6" stroke-dasharray="2 2"/><text x="496" y="284" text-anchor="end" font-size="10">0°</text><text x="496" y="204" text-anchor="end" font-size="10">30°</text><text x="496" y="124" text-anchor="end" font-size="10">60°</text><text x="496" y="44" text-anchor="end" font-size="10">90°</text><text x="570" y="296" text-anchor="middle" font-size="10">地表 ← → 上空</text><ellipse cx="570" cy="240" rx="56" ry="32" fill="none" stroke="#000" stroke-width="1.4"/><line x1="514" y1="234" x2="514" y2="246" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><line x1="626" y1="246" x2="626" y2="234" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><text x="570" y="244" text-anchor="middle" font-size="9.5" font-weight="700">ハドレー循環</text><ellipse cx="570" cy="160" rx="56" ry="32" fill="none" stroke="#000" stroke-width="1.4"/><line x1="514" y1="166" x2="514" y2="154" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><line x1="626" y1="154" x2="626" y2="166" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><text x="570" y="164" text-anchor="middle" font-size="9.5" font-weight="700">中緯度</text><ellipse cx="570" cy="80" rx="56" ry="32" fill="none" stroke="#000" stroke-width="1.4"/><line x1="514" y1="74" x2="514" y2="86" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><line x1="626" y1="86" x2="626" y2="74" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><text x="570" y="84" text-anchor="middle" font-size="9.5" font-weight="700">極</text></svg><figcaption>図2　大気の大循環（模式図）。左：地表付近の風（矢印）と気圧の帯。右：北半球を南北に切った断面。赤道で上昇した空気は緯度30°付近で下降し（ハドレー循環）、地表を赤道へもどる。</figcaption></figure>

| 緯度 | 気圧の帯 | 空気の動き | 天気・気候 |
|---|---|---|---|
| 0°付近 | **熱帯収束帯**（低圧） | 上昇気流 | 毎日のように雨。**熱帯雨林** |
| 30°付近 | **亜熱帯高圧帯** | 下降気流 | 雲ができにくい。**砂漠**が多い（サハラ砂漠など） |
| 60°付近 | **寒帯前線帯**（低圧） | 上昇気流 | 低気圧が発生しやすい |

<div class="memo" markdown="1">

**本質　下降気流で砂漠ができるわけ**　下降する空気はおし縮められて**温度が上がる**（地学5の「膨張すると冷える」の逆）。すると飽和水蒸気量が大きくなって湿度が下がり、**雲ができない**。社会科の「気候帯」も、この大循環で説明できる。

</div>

### 3　コリオリの力の入り口 ― 風がまっすぐふかない理由

回る台の上でボールを投げると、ボールはまっすぐ進んでいるのに、台の上の人からは曲がって見える。

<div class="cols2" markdown="1">

<figure><svg width="240" viewBox="0 0 330 300" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><circle cx="150" cy="150" r="120" fill="#f2f2f2" stroke="#000" stroke-width="1.6"/><circle cx="150" cy="150" r="4" fill="#000" stroke="#000" stroke-width="1"/><path d="M241.92533317427734,72.8654868376153 A134,134 0 0,0 126.7,18" fill="none" stroke="#000" stroke-width="1.6" marker-end="url(#ah0)"/><text x="236.4" y="282" font-size="10.5">台は反時計回り</text><line x1="150" y1="150" x2="150" y2="30" stroke="#000" stroke-width="1.4" stroke-dasharray="6 4" marker-end="url(#ah0)"/><text x="144" y="72" text-anchor="end" font-size="10">外から見ると</text><text x="144" y="85" text-anchor="end" font-size="10">まっすぐ</text><polyline points="150,150 150.1,147 150.3,144 150.7,141 151.2,138.1 151.9,135.1 152.7,132.2 153.7,129.3 154.8,126.5 156,123.7 157.4,120.9 159,118.2 160.6,115.6 162.5,113 164.4,110.5 166.5,108.1 168.7,105.8 171,103.5 173.5,101.4 176.1,99.3 178.8,97.3 181.6,95.5 184.5,93.7 187.5,92.1 190.7,90.6 193.9,89.2 197.2,87.9 200.6,86.8 204.1,85.8 207.7,84.9 211.3,84.1 215.1,83.6 218.9,83.1 222.7,82.8 226.6,82.7 230.6,82.7 234.6,82.9 238.6,83.2 242.7,83.7 246.8,84.3 251,85.2" fill="none" stroke="#000" stroke-width="2.2"/><line x1="242.7" y1="83.7" x2="251" y2="85.2" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><text x="257" y="99.2" font-size="10.5" font-weight="700">台の上から見ると</text><text x="257" y="113.2" font-size="10.5" font-weight="700">右へ曲がる</text><text x="158" y="166" font-size="10">中心から投げる</text></svg><figcaption>図3　回る台の上の人には、ボールが右へ曲がって見える（北半球と同じ回り方）。</figcaption></figure>

- 地球も回っている台と同じ。地表で動く空気や水は、**北半球では進む向きの右**へ、**南半球では左**へ曲がるように見える。この見かけの力を**コリオリの力**（転向力）という。
- コリオリの力は**赤道で 0**、**極で最大**。**速く動くものほど大きい**。
- 何百 km・何時間という大きな動きでやっと効く小さな力。「お風呂のうずの向きが北半球と南半球で逆になる」は**まちがい**。

</div>

<div class="point" markdown="1">

**POINT 2　貿易風が「東寄り」になるわけを、地面の速さで考える**

赤道の1周は約 4万 km、地球は24時間で1回転するので、赤道の地面は東へ **時速 約1670 km**（40000 ÷ 24）。地面が回る円の半径は、30°・60°の直角三角形の辺の比から、**緯度30°で √3/2 ≒ 0.87倍**（時速 約1440 km）、**緯度60°で 1/2倍**（時速 約830 km）。
緯度30°から赤道へ向かう空気は、東向きの速さ（約1440 km）のまま、より速く動く赤道の地面の上に来る → 地面から見ると**西へ取り残され**、**東から**ふく風になる（**北東貿易風**）。逆に 30°から 60°へ向かう空気は地面より速く東へ進み、**偏西風**になる。（ざっくりしたモデル。くわしくは高校で学ぶ）

</div>

### 4　高気圧・低気圧の風の向き ― 3つの力のつり合い<span class="deru">入試</span>

- 風のもとは**気圧の差による力**（高い所から低い所へおす力）。等圧線の間隔がせまいほど大きい。
- **上空**：「気圧の差による力」と「コリオリの力」が**つり合い**、風は**等圧線に平行**にふく（**地衡風**）。北半球では**低気圧を左に見て**ふく。
- **地表付近**：**摩擦**で風が弱まり、コリオリの力も弱くなるので、等圧線を**ななめに横切って**気圧の低い側へふく。→ 北半球では低気圧に**反時計回りにふきこみ**、高気圧から**時計回りにふき出す**（地学4）。南半球では**逆**。

<figure><svg width="420" viewBox="0 0 640 215" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="10" y="20" width="300" height="190" fill="#fff" stroke="#000" stroke-width="1"/><text x="160" y="14" text-anchor="middle" font-size="11.5" font-weight="700">上空（摩擦なし）</text><line x1="20" y1="55" x2="300" y2="55" stroke="#000" stroke-width="1.4"/><text x="24" y="50" font-size="10">996 hPa（低い）</text><line x1="20" y1="175" x2="300" y2="175" stroke="#000" stroke-width="1.4"/><text x="24" y="170" font-size="10">1000 hPa（高い）</text><line x1="160" y1="115" x2="160" y2="60" stroke="#000" stroke-width="2" marker-end="url(#ah0)"/><text x="155" y="72" text-anchor="end" font-size="10">気圧の差による力</text><line x1="160" y1="115" x2="160" y2="170" stroke="#000" stroke-width="2" marker-end="url(#ah0)"/><text x="165" y="168" font-size="10">コリオリの力</text><line x1="160" y1="115" x2="230" y2="115" stroke="#000" stroke-width="3" marker-end="url(#ah0)"/><text x="234" y="119" font-size="11.5" font-weight="700">風</text><circle cx="160" cy="115" r="3" fill="#000" stroke="#000" stroke-width="1"/><rect x="330" y="20" width="300" height="190" fill="#fff" stroke="#000" stroke-width="1"/><text x="480" y="14" text-anchor="middle" font-size="11.5" font-weight="700">地表付近（摩擦あり）</text><line x1="340" y1="55" x2="620" y2="55" stroke="#000" stroke-width="1.4"/><text x="344" y="50" font-size="10">996 hPa（低い）</text><line x1="340" y1="175" x2="620" y2="175" stroke="#000" stroke-width="1.4"/><text x="344" y="170" font-size="10">1000 hPa（高い）</text><line x1="480" y1="115" x2="480" y2="60" stroke="#000" stroke-width="2" marker-end="url(#ah0)"/><text x="475" y="72" text-anchor="end" font-size="10">気圧の差による力</text><line x1="480" y1="115" x2="540.6" y2="80" stroke="#000" stroke-width="3" marker-end="url(#ah0)"/><text x="544.6" y="80" font-size="11.5" font-weight="700">風</text><line x1="480" y1="115" x2="503.8" y2="156.2" stroke="#000" stroke-width="2" marker-end="url(#ah0)"/><text x="507.8" y="166.2" font-size="10">コリオリの力</text><line x1="480" y1="115" x2="456.2" y2="128.8" stroke="#000" stroke-width="2" marker-end="url(#ah0)"/><text x="452.2" y="140.8" text-anchor="end" font-size="10">摩擦</text><circle cx="480" cy="115" r="3" fill="#000" stroke="#000" stroke-width="1"/></svg><figcaption>図4　北半球で風にはたらく力（模式図）。上空では等圧線に平行に、地表付近では等圧線をななめに横切って、気圧の低い側へふく。</figcaption></figure>

<figure><svg width="440" viewBox="0 0 665 180" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="10" y="22" width="150" height="150" fill="#fff" stroke="#000" stroke-width="1"/><text x="85" y="16" text-anchor="middle" font-size="10.5" font-weight="700">北半球の低気圧</text><circle cx="85" cy="97" r="25" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><circle cx="85" cy="97" r="50" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><text x="85" y="102" text-anchor="middle" font-size="14" font-weight="700">低</text><line x1="136.8" y1="66" x2="103.9" y2="57.2" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="54" y1="45.2" x2="45.2" y2="78.1" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="33.2" y1="128" x2="66.1" y2="136.8" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="116" y1="148.8" x2="124.8" y2="115.9" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><rect x="175" y="22" width="150" height="150" fill="#fff" stroke="#000" stroke-width="1"/><text x="250" y="16" text-anchor="middle" font-size="10.5" font-weight="700">北半球の高気圧</text><circle cx="250" cy="97" r="25" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><circle cx="250" cy="97" r="50" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><text x="250" y="102" text-anchor="middle" font-size="14" font-weight="700">高</text><line x1="268.9" y1="57.2" x2="301.8" y2="66" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="210.2" y1="78.1" x2="219" y2="45.2" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="231.1" y1="136.8" x2="198.2" y2="128" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="289.8" y1="115.9" x2="281" y2="148.8" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><rect x="340" y="22" width="150" height="150" fill="#fff" stroke="#000" stroke-width="1"/><text x="415" y="16" text-anchor="middle" font-size="10.5" font-weight="700">南半球の低気圧</text><circle cx="415" cy="97" r="25" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><circle cx="415" cy="97" r="50" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><text x="415" y="102" text-anchor="middle" font-size="14" font-weight="700">低</text><line x1="446" y1="45.2" x2="454.8" y2="78.1" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="363.2" y1="66" x2="396.1" y2="57.2" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="384" y1="148.8" x2="375.2" y2="115.9" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="466.8" y1="128" x2="433.9" y2="136.8" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><rect x="505" y="22" width="150" height="150" fill="#fff" stroke="#000" stroke-width="1"/><text x="580" y="16" text-anchor="middle" font-size="10.5" font-weight="700">南半球の高気圧</text><circle cx="580" cy="97" r="25" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><circle cx="580" cy="97" r="50" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><text x="580" y="102" text-anchor="middle" font-size="14" font-weight="700">高</text><line x1="619.8" y1="78.1" x2="611" y2="45.2" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="561.1" y1="57.2" x2="528.2" y2="66" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="540.2" y1="115.9" x2="549" y2="148.8" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="598.9" y1="136.8" x2="631.8" y2="128" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/></svg><figcaption>図5　地表付近の風（上が北）。北半球では、低気圧に反時計回りにふきこみ、高気圧から時計回りにふき出す。南半球では回り方が逆。</figcaption></figure>

- **ボイス・バロットの法則**：北半球で**風を背中に受けて立つ**と、低気圧は**左手のやや前方**にある。
- 南半球の熱帯低気圧（サイクロン）は**時計回り**。コリオリの力がほとんどない**赤道のすぐ近くでは、台風はできにくい**（うずが巻けない）。

### 5　天気図の解析 ― 数字で天気を予想する<span class="deru">入試</span>

<div class="point" markdown="1">

**POINT 3　天気図を読む手順**（図6）

① **気圧**：等圧線は 1000 hPa を基準に **4 hPa ごと**（20 hPa ごとに太線）。点Aは 1000 hPa と 1004 hPa の線の間。
② **風の強さ**：等圧線の**間隔がせまいほど強い**。間隔が A付近 200 km、B付近 400 km なら、100 km あたりの気圧の差は A 2 hPa、B 1 hPa → **Aの風が強い**。
③ **風向**：「低気圧へ向かう向き」を北半球では**右へ**かたむける。点Aは低気圧の西なので **北北西〜北西の風**。
④ **天気**：点C（**暖域**）は南寄りの風であたたかい。点D（温暖前線の前方）は広い範囲でおだやかな雨。寒冷前線のすぐ後ろ（西側）はせまい範囲で強い雨。
⑤ **時刻**：**到着までの時間 ＝ 前線までの距離 ÷ 前線の速さ**。

</div>

<div class="cols2" markdown="1">

<figure><svg width="330" viewBox="0 0 520 320" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><clipPath id="cpB6"><rect x="10" y="10" width="500" height="300"/></clipPath><rect x="10" y="10" width="500" height="300" fill="#fff" stroke="#000" stroke-width="1"/><g clip-path="url(#cpB6)"><circle cx="230" cy="150" r="22" fill="none" stroke="#000" stroke-width="1.1"/><rect x="204" y="123.9" width="30" height="13" fill="#fff"/><text x="219" y="134.9" text-anchor="middle" font-size="10">996</text><circle cx="243.3" cy="150" r="62" fill="none" stroke="#000" stroke-width="2.2"/><rect x="197.3" y="89.3" width="30" height="13" fill="#fff"/><text x="212.3" y="100.3" text-anchor="middle" font-size="10">1000</text><circle cx="256.7" cy="150" r="102" fill="none" stroke="#000" stroke-width="1.1"/><rect x="190.7" y="54.7" width="30" height="13" fill="#fff"/><text x="205.7" y="65.7" text-anchor="middle" font-size="10">1004</text><circle cx="270" cy="150" r="142" fill="none" stroke="#000" stroke-width="1.1"/><rect x="184" y="20" width="30" height="13" fill="#fff"/><text x="199" y="31" text-anchor="middle" font-size="10">1008</text><circle cx="283.3" cy="150" r="182" fill="none" stroke="#000" stroke-width="1.1"/><rect x="177.3" y="-14.6" width="30" height="13" fill="#fff"/><text x="192.3" y="-3.6" text-anchor="middle" font-size="10">1012</text><circle cx="296.6" cy="150" r="222" fill="none" stroke="#000" stroke-width="1.1"/><rect x="170.7" y="-49.3" width="30" height="13" fill="#fff"/><text x="185.7" y="-38.3" text-anchor="middle" font-size="10">1016</text><polyline points="230,150 205,185 175,220 140,255 100,290 70,312" fill="none" stroke="#000" stroke-width="2.4"/><polygon points="225.6,156.2 216.3,169.2 229.4,168.7" fill="#000"/><polygon points="210.5,177.3 201.2,190.4 214.3,189.9" fill="#000"/><polygon points="194.2,197.6 183.8,209.7 196.9,210.4" fill="#000"/><polygon points="177.5,217.5 166.2,228.8 179.2,230.5" fill="#000"/><polygon points="159.1,235.9 147.8,247.2 160.8,248.9" fill="#000"/><polygon points="140.8,254.3 128.7,264.9 141.6,267.4" fill="#000"/><polygon points="121.2,271.5 109.1,282 122,284.6" fill="#000"/><polygon points="101.7,288.7 88.8,298.2 101.4,301.8" fill="#000"/><polyline points="230,150 280,172 335,185 395,192 460,196" fill="none" stroke="#000" stroke-width="2.4"/><path d="M237,153.1 A8,8 0 0,1 251.6,159.5 Z" fill="#000"/><path d="M260.8,163.5 A8,8 0 0,1 275.4,170 Z" fill="#000"/><path d="M284.8,173.1 A8,8 0 0,1 300.4,176.8 Z" fill="#000"/><path d="M310.1,179.1 A8,8 0 0,1 325.7,182.8 Z" fill="#000"/><path d="M335.5,185.1 A8,8 0 0,1 351.3,186.9 Z" fill="#000"/><path d="M361.3,188.1 A8,8 0 0,1 377.2,189.9 Z" fill="#000"/><path d="M387.1,191.5 A8,8 0 0,1 403,192.5 Z" fill="#000"/><path d="M413,193.1 A8,8 0 0,1 429,194.1 Z" fill="#000"/><path d="M439,194.7 A8,8 0 0,1 454.9,195.7 Z" fill="#000"/></g><rect x="219" y="139" width="22" height="22" fill="#fff"/><text x="230" y="156" text-anchor="middle" font-size="16" font-weight="700">低</text><circle cx="162" cy="150" r="4" fill="#000" stroke="#000" stroke-width="1"/><rect x="167" y="133" width="14" height="14" fill="#fff"/><text x="168" y="144" font-size="12" font-weight="700">A</text><circle cx="340" cy="150" r="4" fill="#000" stroke="#000" stroke-width="1"/><rect x="345" y="133" width="14" height="14" fill="#fff"/><text x="346" y="144" font-size="12" font-weight="700">B</text><circle cx="250" cy="235" r="4" fill="#000" stroke="#000" stroke-width="1"/><rect x="255" y="218" width="14" height="14" fill="#fff"/><text x="256" y="229" font-size="12" font-weight="700">C</text><circle cx="380" cy="140" r="4" fill="#000" stroke="#000" stroke-width="1"/><rect x="385" y="123" width="14" height="14" fill="#fff"/><text x="386" y="134" font-size="12" font-weight="700">D</text><rect x="160" y="281" width="56" height="15" fill="#fff"/><text x="188" y="293" text-anchor="middle" font-size="10.5" font-weight="700">寒冷前線</text><rect x="420" y="203" width="56" height="15" fill="#fff"/><text x="448" y="214" text-anchor="middle" font-size="10.5" font-weight="700">温暖前線</text><text x="500" y="28" text-anchor="end" font-size="10">上が北</text></svg><figcaption>図6　天気図の模式図（等圧線は4 hPaごと、1000 hPa は太線。前線での等圧線の折れ曲がりは省略）。</figcaption></figure>

- **計算例**：町の西 360 km に寒冷前線があり、時速 40 km で東へ進む → 360 ÷ 40 ＝ **9時間後**に通過。通過すると、**風向が南寄り → 北寄り**、**気温が急に下がり**、**気圧は上がり始める**（地学6）。
- 春や秋の低気圧・高気圧は、偏西風に流されて**1日に約1000 km**（時速 約40 km）ほど東へ進むことが多い。「明日の天気は今日の西の天気」。
- 寒冷前線は温暖前線より速く、追いつくと**閉塞前線**になる。2本の間が 300 km、速さの差が時速 15 km なら、300 ÷ 15 ＝ **20時間後**。

</div>

### 6　海洋の循環とエルニーニョ現象の入り口

<div class="cols2" markdown="1">

<figure><svg width="320" viewBox="0 0 550 260" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="10" y="20" width="70" height="230" fill="#d6d6d6" stroke="#000" stroke-width="1"/><text x="45" y="140" text-anchor="middle" font-size="11" font-weight="700">アジア</text><rect x="470" y="20" width="70" height="230" fill="#d6d6d6" stroke="#000" stroke-width="1"/><text x="505" y="132" text-anchor="middle" font-size="11" font-weight="700">北アメ</text><text x="505" y="148" text-anchor="middle" font-size="11" font-weight="700">リカ</text><polygon points="100,80 112,92 108,130 96,150 92,120" fill="#9a9a9a" stroke="#000" stroke-width="1"/><text x="86" y="104" text-anchor="end" font-size="10">日本</text><line x1="135" y1="190" x2="135" y2="100" stroke="#000" stroke-width="3" marker-end="url(#ah0)"/><text x="141" y="140" font-size="11" font-weight="700">黒潮</text><text x="141" y="154" font-size="9.5">（暖流）</text><line x1="155" y1="80" x2="420" y2="80" stroke="#000" stroke-width="3" marker-end="url(#ah0)"/><text x="287.5" y="96" text-anchor="middle" font-size="10.5" font-weight="700">北太平洋海流</text><line x1="440" y1="100" x2="440" y2="190" stroke="#000" stroke-width="2.6" stroke-dasharray="7 4" marker-end="url(#ah0)"/><text x="434" y="140" text-anchor="end" font-size="10.5" font-weight="700">カリフォルニア</text><text x="434" y="154" text-anchor="end" font-size="9.5">海流（寒流）</text><line x1="420" y1="210" x2="155" y2="210" stroke="#000" stroke-width="3" marker-end="url(#ah0)"/><text x="287.5" y="202" text-anchor="middle" font-size="10.5" font-weight="700">北赤道海流</text><path d="M135,100 Q135,80 155,80" fill="none" stroke="#000" stroke-width="3"/><path d="M420,80 Q440,80 440,100" fill="none" stroke="#000" stroke-width="2.6" stroke-dasharray="7 4"/><path d="M440,190 Q440,210 420,210" fill="none" stroke="#000" stroke-width="3"/><path d="M155,210 Q135,210 135,190" fill="none" stroke="#000" stroke-width="3"/><text x="287.5" y="149" text-anchor="middle" font-size="10.5">時計回りの大きなうず</text><path d="M200,28 Q150,40 120,72" fill="none" stroke="#000" stroke-width="2.6" stroke-dasharray="7 4" marker-end="url(#ah0)"/><text x="206" y="32" font-size="10.5" font-weight="700">親潮（寒流）</text><line x1="220" y1="50" x2="270" y2="50" stroke="#000" stroke-width="1.6" marker-end="url(#ah0)"/><line x1="330" y1="50" x2="380" y2="50" stroke="#000" stroke-width="1.6" marker-end="url(#ah0)"/><text x="390" y="54" font-size="10.5">偏西風</text><line x1="380" y1="240" x2="330" y2="240" stroke="#000" stroke-width="1.6" marker-end="url(#ah0)"/><line x1="270" y1="240" x2="220" y2="240" stroke="#000" stroke-width="1.6" marker-end="url(#ah0)"/><text x="160" y="244" text-anchor="end" font-size="10.5">貿易風</text></svg><figcaption>図7　北太平洋の表面の海流（模式図）。実線は暖流、点線は寒流。偏西風と貿易風に引きずられて、時計回りの大きなうず（環流）ができる。</figcaption></figure>

- 海流は、主に**風に引きずられて**できる。北太平洋では偏西風と貿易風で**時計回り**のうず（**環流**）ができる。
- **黒潮**（日本海流）は北上する**暖流**、**親潮**（千島海流）は南下する栄養分の多い**寒流**。ぶつかる**潮目**（三陸沖など）はよい漁場。
- 深い海にも、グリーンランド沖や南極のまわりで冷たく重い水が沈んで始まる、**1000年以上**かけて世界をめぐる**深層循環**がある。

</div>

<figure><svg width="480" viewBox="0 0 640 195" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="10" y="30" width="300" height="160" fill="#fff" stroke="#000" stroke-width="1"/><text x="160" y="22" text-anchor="middle" font-size="11.5" font-weight="700">平常時</text><line x1="10" y1="80" x2="310" y2="80" stroke="#000" stroke-width="1.4"/><path d="M10,80 L310,80 L310,90 C210,110 110,140 10,150 Z" fill="#bdbdbd" stroke="#000" stroke-width="1"/><text x="80" y="108" text-anchor="middle" font-size="10">あたたかい水</text><text x="160" y="178" text-anchor="middle" font-size="10">冷たい水</text><line x1="230" y1="62" x2="110" y2="62" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><text x="235" y="66" font-size="10">貿易風</text><path d="M32,62 Q30,46 46,46 Q52,34 66,42 Q86,40 86,56 Q92,62 82,62 Z" fill="#fff" stroke="#000" stroke-width="1.2"/><text x="60" y="58" text-anchor="middle" font-size="10" font-weight="700">雨</text><path d="M285,150 Q292,120 290,86" fill="none" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><text x="282" y="140" text-anchor="end" font-size="9.5">わき上がり</text><text x="16" y="186" font-size="9.5">西（インドネシア）</text><text x="304" y="46" text-anchor="end" font-size="9.5">東（ペルー沖）</text><rect x="330" y="30" width="300" height="160" fill="#fff" stroke="#000" stroke-width="1"/><text x="480" y="22" text-anchor="middle" font-size="11.5" font-weight="700">エルニーニョ現象のとき</text><line x1="330" y1="80" x2="630" y2="80" stroke="#000" stroke-width="1.4"/><path d="M330,80 L630,80 L630,112 C530,118 430,122 330,125 Z" fill="#bdbdbd" stroke="#000" stroke-width="1"/><text x="400" y="108" text-anchor="middle" font-size="10">あたたかい水</text><text x="480" y="178" text-anchor="middle" font-size="10">冷たい水</text><line x1="550" y1="62" x2="500" y2="62" stroke="#000" stroke-width="2.2" marker-end="url(#ah0)"/><text x="555" y="66" font-size="10">貿易風が弱い</text><path d="M452,62 Q450,46 466,46 Q472,34 486,42 Q506,40 506,56 Q512,62 502,62 Z" fill="#fff" stroke="#000" stroke-width="1.2"/><text x="480" y="58" text-anchor="middle" font-size="10" font-weight="700">雨</text><text x="336" y="186" font-size="9.5">西（インドネシア）</text><text x="624" y="46" text-anchor="end" font-size="9.5">東（ペルー沖）</text></svg><figcaption>図8　太平洋の赤道付近を東西に切った断面（模式図）。貿易風が弱まると、西にたまっていたあたたかい水が東へ広がる。</figcaption></figure>

- **平常時**：**貿易風（東風）**で、あたたかい海水が**西（インドネシア付近）**へふき寄せられ、西で雨が多い。東の**ペルー沖**では深い所から冷たい水が**わき上がり**（栄養分が多くよい漁場）、海面水温が低い。
- **エルニーニョ現象**：数年に1度、**貿易風が弱まり**、あたたかい水が**東へ広がる**。ペルー沖の海面水温が平年より高い状態が1年ほど続き、雨の多い場所も東へずれる（インドネシアなどで干ばつ）。日本は**冷夏・暖冬**になりやすい。名前はスペイン語の「男の子（神の子イエス）」。
- **ラニーニャ現象**（「女の子」）：逆に貿易風が強まり、ペルー沖の海面水温が平年より**低い**。日本は夏が暑く、冬が寒くなりやすい。

<div class="memo" markdown="1">

**本質　大気と海はつながった1つのしくみ**　風が海流をつくり（貿易風 → あたたかい水が西へ）、海面の温度が雨の場所と風を決める（あたたかい海の上で上昇気流）。片方が変わると、もう片方も変わる。エルニーニョ現象は、太平洋の反対側の変化が日本の夏まで変える「地球規模のドミノ」だ。

</div>

<div class="point" markdown="1">

**入試直前チェック（できたら□にチェック）**

□ 太陽高度 30° → 面積 **2倍**・熱 **2分の1**（1：2：√3）。低緯度は熱があまり、高緯度は足りない → **大気と海が熱を運ぶ**。
□ **ハドレー循環**：赤道で上昇（大雨）→ **30°で下降**（砂漠）→ 地表で**貿易風**（北半球は**北東**の風）。
□ 30°〜60°は**偏西風**（日本の天気は西から東へ）、60°〜90°は**極偏東風**。
□ コリオリの力：北半球は**右**、南半球は**左**。赤道で 0。赤道の地面は時速 約1670 km。
□ 上空の風は**等圧線に平行**、地表は摩擦で**ななめに低気圧側へ**。北半球の低気圧は**反時計回り**にふきこむ。
□ 等圧線は **4 hPa ごと**、間隔が**せまいほど強風**。到着時間 ＝ 距離 ÷ 速さ。
□ 寒冷前線の通過：**北寄りの風**・**気温が急に下がる**・**気圧が上がり始める**。
□ **黒潮**（暖流）・**親潮**（寒流）、北太平洋の環流は**時計回り**。
□ エルニーニョ：**貿易風が弱まり**、ペルー沖が**高温**。日本は**冷夏・暖冬**の傾向。

</div>

## 練習問題

### 基本

#### <span class="no">1</span> 次の文の（　）にあてはまる言葉を書きなさい。

(1) 赤道付近で上昇した空気が、緯度30°付近で下降し、地表を赤道へもどる大気の循環を（　　　）という。
(2) (1) で、地表を赤道へもどる東寄りの風を（　　　）という。
(3) 緯度30°〜60°の上空を中心に、1年中西からふく風を（　　　）という。
(4) 地球の自転のために、北半球では動くものが進む向きの右へ曲がるように見える。この見かけの力を（　　　）という。
(5) 日本の南岸を南から北上する暖流を（　　　）という。

#### <span class="no">2</span> 太陽の高度と、地面が受け取る熱について、次の問いに答えなさい。

(1) 太陽高度が 30° のとき、光が当たる地面の面積は、太陽が真上にあるときの何倍か。
(2) 北緯35°の地点での、春分の日の太陽の南中高度は何度か。
(3) 春分の日の正午に、赤道と北緯60°で、同じ面積の地面が受け取る熱の量を比べた。北緯60°の地面が受け取る熱の量は、赤道の何倍か。
(4) Kさんは、低緯度ほど気温が高い理由を調べた。その理由として最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．低緯度ほど、太陽からの距離が近いから。
　2．低緯度ほど、太陽の光が地面に垂直に近い角度で当たり、同じ面積が受け取る熱が多いから。
　3．低緯度ほど、地球の自転の速さがおそいから。
　4．低緯度ほど、大気が熱を高緯度から運んでくるから。

#### <span class="no">3</span> 図の1〜4は、地表付近の風のふき方を表したものである。

<figure><svg width="500" viewBox="0 0 585 158" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="10" y="22" width="130" height="130" fill="#fff" stroke="#000" stroke-width="1"/><text x="75" y="16" text-anchor="middle" font-size="12" font-weight="700">1</text><circle cx="75" cy="87" r="45" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><circle cx="75" cy="87" r="4" fill="#000" stroke="#000" stroke-width="1"/><line x1="121.3" y1="59.1" x2="92.3" y2="51.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="47.1" y1="40.7" x2="39.3" y2="69.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="28.7" y1="114.9" x2="57.7" y2="122.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="102.9" y1="133.3" x2="110.7" y2="104.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><rect x="155" y="22" width="130" height="130" fill="#fff" stroke="#000" stroke-width="1"/><text x="220" y="16" text-anchor="middle" font-size="12" font-weight="700">2</text><circle cx="220" cy="87" r="45" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><circle cx="220" cy="87" r="4" fill="#000" stroke="#000" stroke-width="1"/><line x1="247.9" y1="40.7" x2="255.7" y2="69.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="173.7" y1="59.1" x2="202.7" y2="51.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="192.1" y1="133.3" x2="184.3" y2="104.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="266.3" y1="114.9" x2="237.3" y2="122.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><rect x="300" y="22" width="130" height="130" fill="#fff" stroke="#000" stroke-width="1"/><text x="365" y="16" text-anchor="middle" font-size="12" font-weight="700">3</text><circle cx="365" cy="87" r="45" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><circle cx="365" cy="87" r="4" fill="#000" stroke="#000" stroke-width="1"/><line x1="382.3" y1="51.3" x2="411.3" y2="59.1" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="329.3" y1="69.7" x2="337.1" y2="40.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="347.7" y1="122.7" x2="318.7" y2="114.9" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="400.7" y1="104.3" x2="392.9" y2="133.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><rect x="445" y="22" width="130" height="130" fill="#fff" stroke="#000" stroke-width="1"/><text x="510" y="16" text-anchor="middle" font-size="12" font-weight="700">4</text><circle cx="510" cy="87" r="45" fill="none" stroke="#000" stroke-width="0.8" stroke-dasharray="3 2"/><circle cx="510" cy="87" r="4" fill="#000" stroke="#000" stroke-width="1"/><line x1="545.7" y1="69.7" x2="537.9" y2="40.7" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="492.7" y1="51.3" x2="463.7" y2="59.1" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="474.3" y1="104.3" x2="482.1" y2="133.3" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/><line x1="527.3" y1="122.7" x2="556.3" y2="114.9" stroke="#000" stroke-width="1.8" marker-end="url(#ah0)"/></svg><figcaption>上が北。●は中心、点線は等圧線、矢印は地表付近の風。</figcaption></figure>

(1) 北半球の低気圧のまわりの風のふき方として最も適するものを、図の1〜4の中から一つ選び、その番号を答えなさい。
(2) 北半球の高気圧のまわりの風のふき方を、1〜4から選びなさい。
(3) 南半球（オーストラリアなど）の低気圧のまわりの風のふき方を、1〜4から選びなさい。
(4) 北半球で、風を背中に受けて立ったとき、低気圧の中心はどちらにあるか。「左手のやや前方」「右手のやや前方」から選びなさい。

### 標準

#### <span class="no">4</span> 地球は24時間で1回転している。地球の周囲を 40000 km として、次の問いに答えなさい。

(1) 赤道上の地面は、地球の自転によって時速何 km で動いているか。小数第1位を四捨五入して整数で答えなさい。
(2) 北緯60°の地面が1日に回る円の半径は、地球の半径の半分である。北緯60°の地面は、時速約何 km で動いているか。(1) の答えを使って、整数で答えなさい。
(3) 緯度30°付近から赤道へ向かって、北から南へ動く空気がある。地面から見ると、この空気の動きはどうなるか。最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．東向きの速さが地面より大きいので、西寄りの風になる。
　2．東向きの速さが地面より小さいので、西へ取り残され、北東からの風になる。
　3．東向きの速さが地面と同じなので、真北からの風になる。
　4．東向きの速さが地面より小さいので、北西からの風になる。
(4) 南半球では、動く空気は進む向きのどちらへ曲がるように見えるか。

#### <span class="no">5</span> 図は、北半球の大気の大循環を、南北に切った断面で表したものである。

<div class="cols2" markdown="1">

<figure><svg width="270" viewBox="0 0 340 285" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="60" y="20" width="200" height="240" fill="#fff" stroke="#000" stroke-width="1"/><line x1="60" y1="180" x2="260" y2="180" stroke="#000" stroke-width="0.6" stroke-dasharray="2 2"/><line x1="60" y1="100" x2="260" y2="100" stroke="#000" stroke-width="0.6" stroke-dasharray="2 2"/><text x="56" y="264" text-anchor="end" font-size="10">0°</text><text x="56" y="184" text-anchor="end" font-size="10">30°</text><text x="56" y="104" text-anchor="end" font-size="10">60°</text><text x="56" y="24" text-anchor="end" font-size="10">90°</text><text x="56" y="276" text-anchor="end" font-size="10">緯度</text><text x="160" y="276" text-anchor="middle" font-size="10">地表 ← → 上空</text><ellipse cx="160" cy="220" rx="84" ry="32" fill="none" stroke="#000" stroke-width="1.4"/><line x1="76" y1="214" x2="76" y2="226" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><line x1="244" y1="226" x2="244" y2="214" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><text x="160" y="225" text-anchor="middle" font-size="13" font-weight="700">ア</text><ellipse cx="160" cy="140" rx="84" ry="32" fill="none" stroke="#000" stroke-width="1.4"/><line x1="76" y1="146" x2="76" y2="134" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><line x1="244" y1="134" x2="244" y2="146" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><text x="160" y="145" text-anchor="middle" font-size="13" font-weight="700"></text><ellipse cx="160" cy="60" rx="84" ry="32" fill="none" stroke="#000" stroke-width="1.4"/><line x1="76" y1="54" x2="76" y2="66" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><line x1="244" y1="66" x2="244" y2="54" stroke="#000" stroke-width="1.4" marker-end="url(#ah0)"/><text x="160" y="65" text-anchor="middle" font-size="13" font-weight="700"></text><text x="268" y="224" font-size="11" font-weight="700">地表の風 X</text><text x="268" y="144" font-size="11" font-weight="700">地表の風 Y</text><text x="268" y="184" font-size="10">― 緯度30°付近</text></svg><figcaption>北半球を南北に切った断面（模式図）。</figcaption></figure>

(1) 図のアの循環を何というか。
(2) 地表の風X・Yの名前を、それぞれ答えなさい。
(3) 緯度30°付近の空気の動きと天気について述べたものとして最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．上昇気流で、雲が多く雨が多い。
　2．上昇気流で、雲ができにくく乾燥している。
　3．下降気流で、雲が多く雨が多い。
　4．下降気流で、雲ができにくく乾燥している。

</div>

(4) 赤道付近に熱帯雨林が広がる理由を、「上昇気流」「雲」という言葉を使って説明しなさい。

<div class="line"></div>

#### <span class="no">6</span> 図は、ある日の日本付近の天気図の一部を表した模式図である。

<div class="cols2" markdown="1">

<figure><svg width="290" viewBox="0 0 380 350" xmlns="http://www.w3.org/2000/svg" font-family="Noto Sans JP, sans-serif" font-size="13"><defs><marker id="ah0" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect x="10" y="10" width="360" height="330" fill="#fff" stroke="#000" stroke-width="1"/><circle cx="170" cy="175" r="30" fill="none" stroke="#000" stroke-width="2.2"/><rect x="133.8" y="189.2" width="30" height="13" fill="#fff"/><text x="148.8" y="200.2" text-anchor="middle" font-size="10">1000</text><circle cx="183.3" cy="175" r="70" fill="none" stroke="#000" stroke-width="1.1"/><rect x="118.8" y="217.5" width="30" height="13" fill="#fff"/><text x="133.8" y="228.5" text-anchor="middle" font-size="10">1004</text><circle cx="196.7" cy="175" r="110" fill="none" stroke="#000" stroke-width="1.1"/><rect x="103.9" y="245.8" width="30" height="13" fill="#fff"/><text x="118.9" y="256.8" text-anchor="middle" font-size="10">1008</text><circle cx="210" cy="175" r="150" fill="none" stroke="#000" stroke-width="1.1"/><rect x="88.9" y="274.1" width="30" height="13" fill="#fff"/><text x="103.9" y="285.1" text-anchor="middle" font-size="10">1012</text><rect x="159" y="164" width="22" height="22" fill="#fff"/><text x="170" y="181" text-anchor="middle" font-size="16" font-weight="700">低</text><circle cx="100" cy="175" r="4.5" fill="#000" stroke="#000" stroke-width="1"/><rect x="106" y="173" width="15" height="15" fill="#fff"/><text x="107" y="186" font-size="12" font-weight="700">W</text><circle cx="280" cy="175" r="4.5" fill="#000" stroke="#000" stroke-width="1"/><rect x="286" y="173" width="15" height="15" fill="#fff"/><text x="287" y="186" font-size="12" font-weight="700">E</text><circle cx="196.7" cy="65" r="4.5" fill="#000" stroke="#000" stroke-width="1"/><rect x="202.7" y="63" width="15" height="15" fill="#fff"/><text x="203.7" y="76" font-size="12" font-weight="700">N</text><circle cx="210" cy="325" r="4.5" fill="#000" stroke="#000" stroke-width="1"/><rect x="216" y="323" width="15" height="15" fill="#fff"/><text x="217" y="336" font-size="12" font-weight="700">P</text><text x="362" y="28" text-anchor="end" font-size="10">上が北</text></svg><figcaption>等圧線は4 hPaごと（模式図）。</figcaption></figure>

(1) 点Pの気圧は何 hPa か。
(2) 点Wと点Eのうち、風が強いのはどちらか。理由も答えなさい。

<div class="line"></div>

(3) 点Nでふいている風の向きとして最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．東北東　　2．西南西　　3．北北西　　4．南南東

</div>

(4) 点W付近と点E付近で、となりあう等圧線の間隔は、それぞれ 200 km と 400 km だった。100 km あたりの気圧の差は、それぞれ何 hPa か。
(5) この低気圧の中心付近の空気の動きと天気を、簡単に説明しなさい。

<div class="line"></div>

#### <span class="no">7</span> 午前9時、Kさんの町の西 160 km に温暖前線が、西 520 km に寒冷前線があった。2本の前線は、どちらも時速 40 km で真東へ進むものとする。

(1) 温暖前線がKさんの町を通過するのは何時ごろか。
(2) 寒冷前線がKさんの町を通過するのは何時ごろか。
(3) (1) と (2) の間の時間帯のKさんの町のようすとして最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．北寄りの風がふき、気温が低い。　　2．南寄りの風がふき、気温が高い。
　3．積乱雲による強い雨が続く。　　　　4．乱層雲によるおだやかな雨が続く。
(4) 実際には、寒冷前線は温暖前線より速く進む。寒冷前線が時速 50 km、温暖前線が時速 30 km で東へ進むとすると、寒冷前線が温暖前線に追いつくのは午前9時の何時間後か。また、そのときにできる前線の名前を答えなさい。

#### <span class="no">8</span> 海洋の循環について、次の問いに答えなさい。

(1) 北太平洋の表面の大きな海流のうず（環流）は、北から見てどちら回りか。
(2) 千島列島の方から南下してくる寒流を何というか。
(3) (2) の寒流と黒潮がぶつかる三陸沖が、よい漁場になる理由を簡単に説明しなさい。

<div class="line"></div>

### 入試にチャレンジ

#### <span class="no">9</span> Kさんは、太平洋の赤道付近で起こる現象について調べ、次のようにまとめた。

<div class="ex" markdown="1">

平常時は、赤道付近で（ a ）がふき、あたたかい海水が太平洋の西側にふき寄せられている。東のペルー沖では、深い所から冷たい海水がわき上がっている。ところが、数年に1度、（ a ）が弱まり、あたたかい海水が東へ広がって、ペルー沖の海面水温が平年より高い状態が1年ほど続く。これを（ b ）現象という。

</div>

(1) （ a ）・（ b ）にあてはまる言葉を答えなさい。
(2) （ b ）現象が起きているときのようすとして最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．インドネシア付近で雨が多くなり、ペルー沖の漁獲量が増える。
　2．インドネシア付近で雨が少なくなり、雨の多い場所が太平洋の中央〜東へ移る。
　3．ペルー沖で冷たい水のわき上がりが強まり、海面水温が下がる。
　4．貿易風が強まり、あたたかい海水が西にさらに集まる。
(3) 平常時のペルー沖がよい漁場である理由を、「わき上がる」「栄養分」という言葉を使って説明しなさい。

<div class="line"></div>

(4) （ b ）現象が起こったとき、日本の夏と冬の天候の傾向として最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．猛暑・暖冬　　2．猛暑・寒冬　　3．冷夏・暖冬　　4．冷夏・寒冬

#### <span class="no">10</span> 表は、神奈川県のある地点での3時間ごとの気象観測の結果である。

| 時刻 | 6時 | 9時 | 12時 | 15時 | 18時 | 21時 |
|---|---|---|---|---|---|---|
| 気温〔℃〕 | 18.0 | 19.5 | 21.0 | 22.0 | 15.5 | 14.0 |
| 気圧〔hPa〕 | 1004.0 | 1002.5 | 1001.0 | 1000.5 | 1004.5 | 1006.0 |
| 風向 | 南南西 | 南 | 南西 | 南西 | 北北西 | 北西 |
| 天気 | くもり | くもり | くもり | くもり | 雨 | くもり |

(1) 寒冷前線がこの地点を通過したのは、何時から何時の間か。
(2) (1) のように判断した理由を、表の3つの項目にふれて説明しなさい。

<div class="line"></div>

<div class="line"></div>

(3) この寒冷前線は、地点Xを9時に通過し、地点Xの真東 210 km の地点Yを15時に通過した。寒冷前線の進む速さは時速何 km か。
(4) (3) の速さが変わらないとすると、地点Yの真東 140 km の地点Zを寒冷前線が通過するのは何時か。

#### <span class="no">11</span> 地球の自転と風について、次の問いに答えなさい。

(1) もし地球が自転していなかったとすると、北半球の緯度0°〜30°の地表でふく風はどの向きからの風になると考えられるか。最も適するものを次の1〜4の中から一つ選び、その番号を答えなさい。
　1．北からの風　　2．南からの風　　3．東からの風　　4．西からの風
(2) 赤道のすぐ近くでは、台風（熱帯低気圧）がほとんど発生しない。その理由を、「コリオリの力」「うず」という言葉を使って説明しなさい。

<div class="line"></div>


#### <span class="no">12</span> 自分で問題を作ってみよう

POINT 2 では、30°・60°の直角三角形を使って、緯度30°と60°の地面の速さを求めた。これにならって、次の(1)・(2)のどちらかの問題を自分で作り、自分で解きなさい。
(1) 緯度45°（直角二等辺三角形）の地面の速さを求める問題。
(2) 2本の前線の位置と速さを自分で決め、「町を通過する時刻」や「追いつく時刻」を求める問題。

<div class="line"></div>

<div class="line"></div>

## 解答・解説

<div class="kaito" markdown="1">

#### <span class="no">1</span>

(1) **ハドレー循環**　(2) **貿易風**　(3) **偏西風**
(4) **コリオリの力**（転向力）　(5) **黒潮**（日本海流）

#### <span class="no">2</span>

(1) **2倍**　(2) **55°**　(3) **2分の1倍**　(4) **2**
(1) 30°・60°・90°の直角三角形（1：2：√3）で、光のはば1に対して地面は2。
(2) 90° − 35° ＝ 55°。
(3) 赤道の南中高度は 90°、北緯60°は 30°。同じ光が2倍の面積に広がるので、熱は2分の1。
(4) 1：地球と太陽の距離（約1億5000万 km）に比べて、緯度による距離のちがいはごくわずか。4：大気は熱を低緯度から高緯度へ運ぶ。

#### <span class="no">3</span>

(1) **1**　(2) **3**　(3) **2**　(4) **左手のやや前方**
北半球は「右へ曲がる」。低気圧へ向かう風が右へ曲がると反時計回りのうず（1）、高気圧からふき出す風が右へ曲がると時計回り（3）。南半球は左へ曲がるので、低気圧は時計回りにふきこむ（2）。
(4) 北半球の低気圧は反時計回りにふきこむので、風を背に受けると中心は左手のやや前方（ボイス・バロットの法則）。

#### <span class="no">4</span>

(1) **時速 1667 km**　(2) **時速 約833 km**　(3) **2**　(4) **左**
(1) 40000 ÷ 24 ＝ 1666.6… → 1667。
(2) 回る円の半径が半分なら、円周も半分。1日に進む距離が半分なので、速さも半分。1666.6… ÷ 2 ≒ 833（(1) の 1667 を半分にした 834 でも正解）。
(3) 緯度30°の地面は時速約1440 km。赤道の地面（約1670 km）より遅いので、空気は西へ取り残され、北（北東）から南西へ向かう風になる。

#### <span class="no">5</span>

(1) **ハドレー循環**　(2) X **北東貿易風**（貿易風）、Y **偏西風**　(3) **4**
(4)（例）**赤道付近では、強くあたためられた空気が上昇気流となり、雲ができて雨が多いから。**
(3) 下降する空気はおし縮められて温度が上がり、湿度が下がるので雲ができにくい。サハラ砂漠などの多くの砂漠がこの緯度にある。

#### <span class="no">6</span>

(1) **1012 hPa**
(2) **W**。（理由の例）**等圧線の間隔がせまいから。**
(3) **1**
(4) W付近 **2 hPa**、E付近 **1 hPa**
(5)（例）**風がふきこんで上昇気流ができ、雲ができやすいので、くもりや雨になる。**
(1) 中心に近い順に 1000・1004・1008・1012。Pは外側から1本目の線の上。
(3) 点Nは低気圧の北。「低気圧に向かう向き（南）」を右へかたむけると、反時計回りのうずにそって西寄りに進む。風は東北東から西南西へふくので、**東北東の風**。2は、風が「ふいていく向き」と「ふいてくる向き」をとりちがえたミス。
(4) W：4 hPa ÷ 200 km → 100 km あたり 2 hPa。E：4 hPa ÷ 400 km → 1 hPa。

#### <span class="no">7</span>

(1) **午後1時（13時）ごろ**　(2) **午後10時（22時）ごろ**　(3) **2**
(4) **18時間後**、**閉塞前線**
(1) 160 ÷ 40 ＝ 4時間後。(2) 520 ÷ 40 ＝ 13時間後。
(3) 2本の前線の間は**暖域**。南寄りの風であたたかい。
(4) 前線の間は 520 − 160 ＝ 360 km。1時間に 50 − 30 ＝ 20 km ずつ近づくので、360 ÷ 20 ＝ 18時間。

#### <span class="no">8</span>

(1) **時計回り**　(2) **親潮**（千島海流）
(3)（例）**栄養分の多い寒流と暖流がぶつかり、プランクトンが多く集まるから。**
(1) 西側を黒潮が北上し、北を東へ、東側を南へ、南を西へ流れる。偏西風・貿易風が海の表面を引きずってできる。

#### <span class="no">9</span>

(1) a **貿易風**　b **エルニーニョ**　(2) **2**
(3)（例）**深い所から冷たい海水がわき上がり、栄養分が海面近くに運ばれるので、プランクトンや魚が多くなるから。**
(4) **3**
(2) 1：ペルー沖はわき上がりが弱まり、漁獲量が減る。3・4はラニーニャ現象のようす。
(4) エルニーニョ現象のときは冷夏・暖冬、ラニーニャ現象のときは猛暑・寒冬になりやすい（必ずそうなるわけではない）。

#### <span class="no">10</span>

(1) **15時から18時の間**
(2)（例）**この間に、気温が 22.0℃ から 15.5℃ に急に下がり、風向が南西から北北西に変わり、気圧が下がり続けていたのが上がり始めたから。**
(3) **時速 35 km**　(4) **19時**
(3) 210 ÷ (15 − 9) ＝ 35。
(4) 140 ÷ 35 ＝ 4時間。15時 ＋ 4時間 ＝ 19時。
(2) 18時の「雨」も、寒冷前線の積乱雲による短時間の雨と考えられる。

#### <span class="no">11</span>

(1) **1**
(2)（例）**赤道付近ではコリオリの力がほとんどはたらかないので、空気が中心に集まってもうずを巻くことができないから。**
(1) 自転がなければ風は曲がらないので、緯度30°付近から赤道へ、まっすぐ北から南へふく。

#### <span class="no">12</span>

（解答例 (1)）「地球の周囲を 40000 km とする。北緯45°の地面が1日に回る円の半径は、地球の半径の何倍か。また、北緯45°の地面は時速約何 km で動いているか。」
解：直角二等辺三角形（1：1：√2）より、半径は地球の半径の 1 ÷ √2 ≒ 0.71倍。速さは 1667 × 0.71 ≒ 時速約1180 km。
（解答例 (2)）「温暖前線が町の西 90 km、寒冷前線が西 300 km にある。温暖前線は時速 30 km、寒冷前線は時速 45 km で東へ進む。寒冷前線が温暖前線に追いつくのは何時間後か。」
解：間は 210 km、速さの差は 15 km なので 210 ÷ 15 ＝ 14時間後。そのとき温暖前線は 30 × 14 ＝ 420 km 進んでいて、町の東 330 km の所にある。

</div>
