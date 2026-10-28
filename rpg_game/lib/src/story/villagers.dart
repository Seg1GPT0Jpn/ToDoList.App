import '../models/rpg_progress.dart';
import '../models/stage.dart';
import '../world/shadow_keeper.dart';
import '../world/terrain.dart';

/// 村や町を歩き回る人たちのおしゃべり。
///
/// 時間帯のあいさつ・あなたの冒険のうわさ・土地の話・勉強の小ネタを、
/// 日と人ごとに入れかえて話す（同じ日・同じ人なら同じ話）。
class VillagerChat {
  const VillagerChat._();

  /// 住人の服の色
  static const colors = [
    0xFF7EB7DA,
    0xFFE57373,
    0xFF8CC06B,
    0xFFF2C14E,
    0xFFB39DDB,
    0xFFF3A9BE,
  ];

  static String _greeting(int hour) => switch (hour) {
        >= 5 && < 10 => 'おはよう！ 朝の勉強は、頭にすっと入るんだって。',
        >= 10 && < 16 => 'いい天気だね。冒険日和だよ。',
        >= 16 && < 19 => '夕焼けがきれいだね。今日はどこまで進んだの？',
        >= 19 && < 22 => 'こんばんは。夜の復習は、ねむっているあいだに記憶に残るらしいよ。',
        _ => 'こんな時間まで冒険？ そろそろ休んでね。',
      };

  static const _tips = [
    'まちがえた問題は、亡霊になってうろつくらしい。たおすとすっきりするよ。',
    '宿の先生の授業を受けてから戦うと、ずいぶん楽になるんだって。',
    '3回続けて正解すると「習得」。教科のレベルが上がるよ。',
    '泉の問題に全部正解すると、次のバトルでHPが増えるんだ。',
    'わからない問題は、答えを見てから「なぜ」を考えると忘れにくいよ。',
    '「むずかしい」で勝つと、エリアに👑がつくんだって。',
  ];

  static List<String> _land(Terrain t) => switch (t) {
        Terrain.meadow || Terrain.hill || Terrain.flower => const [
            '風車の粉ひきさんは、ことばの粉をひいているんだって。',
            'この村の羊は、英語のあいさつを覚えているらしいよ。',
          ],
        Terrain.forest => const ['森の奥の大樹には、古い文字がきざまれているんだ。'],
        Terrain.beach || Terrain.harbor || Terrain.river => const [
            '灯台のあかりは、迷った冒険者を照らすためにあるんだよ。',
            '海の向こうには「定期テストの海」が広がっているらしい。',
          ],
        Terrain.snow => const ['雪だるまの鼻、鉛筆なんだよ。だれが作ったんだろう。'],
        Terrain.desert => const ['ピラミッドの中には、昔の人の知恵がねむっているんだって。'],
        Terrain.town => const [
            '噴水にコインを投げると、テストでヤマが当たるっていううわさ。',
            'この町には、いろんな国の旅人が集まってくるんだ。',
          ],
        _ => const ['このあたりは、ふしぎな場所が多いね。'],
      };

  /// [stages] はこのマップのエリア（順番どおり）
  static String _gossip(RpgProgress p, List<StageDef> stages) {
    if (stages.isEmpty) return '旅の人？ ゆっくりしていってね。';
    if (ShadowKeeper.defeated(p, stages)) {
      return 'あなたが影の番人をたおしたんだって！ この村の英雄だよ。';
    }
    if (ShadowKeeper.appears(p, stages)) {
      return 'ゴールのトロフィーの前に、黒い影が出るってうわさだよ…。';
    }
    final cleared = [
      for (final s in stages)
        if (p.clearedStageIds.contains(s.id)) s,
    ];
    final next = stages.where((s) => !p.clearedStageIds.contains(s.id)).first;
    if (cleared.isEmpty) {
      return '村の外に${next.enemy.name}が出て、道をふさいでいるの。気をつけてね。';
    }
    return '${cleared.last.enemy.name}をたおしたって聞いたよ！ '
        'この先の${next.name}には${next.enemy.name}がいるらしい…。';
  }

  /// その住人が今話すこと（[who] は住人の番号）
  static String line({
    required RpgProgress progress,
    required List<StageDef> stages,
    required Terrain terrain,
    required int hour,
    required int day,
    required int who,
  }) {
    final land = _land(terrain);
    final pool = [
      _greeting(hour),
      _gossip(progress, stages),
      ...land,
      _tips[(day + who) % _tips.length],
    ];
    return pool[(day * 3 + who * 5 + hour ~/ 6) % pool.length];
  }
}
