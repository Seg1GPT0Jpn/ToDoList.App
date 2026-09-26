/// 敵の種族（見た目 look ごと）。図鑑・演出・SE に使う。
///
/// ゲームの敵は「文房具 × 生き物・職業・ファンタジー」の組み合わせで、
/// 同じ種族でもエリアごとに名前・色・セリフが変わる（EnemyDef）。

enum SpeciesCategory {
  writing('筆記具系', '✎'),
  paper('紙・ノート系', '📄'),
  measure('計測・製図系', '📐'),
  crafting('整理・加工系', '✂'),
  school('学校用品系', '🎒'),
  ancient('古き魔物系', '🗝');

  const SpeciesCategory(this.label, this.mark);
  final String label;
  final String mark;
}

enum SpeciesSize {
  small('小型'),
  medium('中型'),
  large('大型');

  const SpeciesSize(this.label);
  final String label;
}

/// レア度。色だけでなく、枠の形・星の数・名前でも区別する
enum Rarity {
  common('COMMON', 1),
  rare('RARE', 2),
  epic('EPIC', 3),
  legendary('LEGENDARY', 4);

  const Rarity(this.label, this.stars);
  final String label;
  final int stars;
}

class EnemySpecies {
  const EnemySpecies({
    required this.look,
    required this.name,
    required this.motif,
    required this.category,
    required this.size,
    required this.rarity,
    required this.personality,
    required this.attack,
    required this.lore,
    required this.sound,
  });

  /// 描画のキー（EnemyDef.look と同じ）
  final String look;

  /// 種族名
  final String name;

  /// 何と何の組み合わせか（例：鉛筆 × 槍兵）
  final String motif;
  final SpeciesCategory category;
  final SpeciesSize size;
  final Rarity rarity;

  /// 性格
  final String personality;

  /// 攻撃のしかた
  final String attack;

  /// 図鑑の説明
  final String lore;

  /// 固有 SE のキー（assets/audio/se/<sound>.mp3）
  final String sound;
}

class EnemySpeciesCatalog {
  const EnemySpeciesCatalog._();

  static const all = <EnemySpecies>[
    EnemySpecies(
      look: 'eraser',
      name: 'ケシゴムン',
      motif: '消しゴム × スライム',
      category: SpeciesCategory.writing,
      size: SpeciesSize.small,
      rarity: Rarity.common,
      personality: 'まちがいを見つけると、うれしそうにはねる',
      attack: '体当たりで答えをこすり消し、消しカスをまき散らす',
      lore: '机の角で削れた角を気にしている。消したはずの答えを、ときどきこっそり覚えている。',
      sound: 'se_rub',
    ),
    EnemySpecies(
      look: 'crayon',
      name: 'クレヨンぶんぶん',
      motif: 'クレヨン × 羽虫',
      category: SpeciesCategory.writing,
      size: SpeciesSize.small,
      rarity: Rarity.common,
      personality: '落ち着きがなく、同じ色で二度描かない',
      attack: '色の軌跡を引いて、問題文をぐちゃぐちゃに塗る',
      lore: '12色の群れで飛ぶ。いちばん短くなった一本が群れの長になるらしい。',
      sound: 'se_scribble',
    ),
    EnemySpecies(
      look: 'sticky',
      name: 'フセンチョウ',
      motif: '付箋 × 蝶',
      category: SpeciesCategory.paper,
      size: SpeciesSize.small,
      rarity: Rarity.common,
      personality: '大事なところにだけ、ひらりと止まる',
      attack: '顔にはりついて視界をふさぐ',
      lore: '「ここ重要」の羽をもつ。はがすと、なぜかその単元が気になってくる。',
      sound: 'se_flap',
    ),
    EnemySpecies(
      look: 'pencil',
      name: 'エンピツランサー',
      motif: '鉛筆 × 槍兵',
      category: SpeciesCategory.writing,
      size: SpeciesSize.medium,
      rarity: Rarity.common,
      personality: 'まっすぐで、削られるほど強気になる',
      attack: 'とがった芯で一直線に突く',
      lore: '芯の硬さで性格が変わる。HB は真面目、2B は情熱的、H は冷静。',
      sound: 'se_scratch',
    ),
    EnemySpecies(
      look: 'stubpencil',
      name: 'ちびエンピツ老兵',
      motif: '短い鉛筆 × 老兵',
      category: SpeciesCategory.writing,
      size: SpeciesSize.small,
      rarity: Rarity.rare,
      personality: '昔の試験の話ばかりする',
      attack: '長年の経験で、ひっかけ問題をしかける',
      lore: '何百枚ものノートを書ききった歴戦の鉛筆。補助軸の杖をついている。',
      sound: 'se_scratch',
    ),
    EnemySpecies(
      look: 'pen',
      name: 'ボールペン剣士',
      motif: 'ボールペン × 剣士',
      category: SpeciesCategory.writing,
      size: SpeciesSize.medium,
      rarity: Rarity.common,
      personality: '一度書いたことは曲げない頑固者',
      attack: 'ノックして芯を出し、居合い斬り',
      lore: '消せないインクが誇り。まちがえたときは二重線で潔く訂正する。',
      sound: 'se_click',
    ),
    EnemySpecies(
      look: 'mechpencil',
      name: 'シャーペンロボ',
      motif: 'シャープペンシル × ロボット',
      category: SpeciesCategory.writing,
      size: SpeciesSize.medium,
      rarity: Rarity.rare,
      personality: '几帳面で、0.5 mm 単位で計算する',
      attack: 'ノックのたびに芯のミサイルを発射する',
      lore: '内部に芯のストックを12本持つ。折れても次がすぐ出てくる。',
      sound: 'se_click',
    ),
    EnemySpecies(
      look: 'marker',
      name: '蛍光ペンウィザード',
      motif: '蛍光ペン × 魔法使い',
      category: SpeciesCategory.writing,
      size: SpeciesSize.medium,
      rarity: Rarity.rare,
      personality: '大事なことを光らせずにはいられない',
      attack: '蛍光インクの魔法陣で、答えを見えにくくする',
      lore: '引いた線が光って浮かび上がる。引きすぎると、何が大事か分からなくなる。',
      sound: 'se_magic',
    ),
    EnemySpecies(
      look: 'ruler',
      name: '定規ナイト',
      motif: '定規 × 騎士',
      category: SpeciesCategory.measure,
      size: SpeciesSize.medium,
      rarity: Rarity.common,
      personality: '曲がったことが大きらい',
      attack: '目盛りの剣でまっすぐ斬りつける',
      lore: '30 cm の剣を持つ。1 mm のずれも見のがさない正確さが自慢。',
      sound: 'se_slash',
    ),
    EnemySpecies(
      look: 'triangle',
      name: '三角定規シールダー',
      motif: '三角定規 × 盾兵',
      category: SpeciesCategory.measure,
      size: SpeciesSize.medium,
      rarity: Rarity.common,
      personality: '二人一組で行動する（30°・60°と45°の兄弟）',
      attack: '直角の盾で攻撃をはね返す',
      lore: '2枚を組み合わせると、どんな平行線でも引ける。仲間思い。',
      sound: 'se_block',
    ),
    EnemySpecies(
      look: 'protractor',
      name: '分度器メイジ',
      motif: '分度器 × 魔術師',
      category: SpeciesCategory.measure,
      size: SpeciesSize.medium,
      rarity: Rarity.rare,
      personality: '角度にうるさい理屈屋',
      attack: '半円の魔法陣から、180度の光線を放つ',
      lore: '目盛りの内側と外側を読みまちがえた者を、容赦なく笑う。',
      sound: 'se_magic',
    ),
    EnemySpecies(
      look: 'compass',
      name: 'コンパススパイダー',
      motif: 'コンパス × クモ',
      category: SpeciesCategory.measure,
      size: SpeciesSize.medium,
      rarity: Rarity.rare,
      personality: '中心を決めたら、一歩も動かない',
      attack: '針の脚で円をえがき、幾何学の巣に閉じこめる',
      lore: '完全な円の巣をはる。半径が少しでもずれると、作り直すまで眠れない。',
      sound: 'se_scratch',
    ),
    EnemySpecies(
      look: 'stapler',
      name: 'ホッチキスクラブ',
      motif: 'ホッチキス × カニ',
      category: SpeciesCategory.crafting,
      size: SpeciesSize.medium,
      rarity: Rarity.common,
      personality: 'まとめたがり。ばらばらの紙を見ると落ち着かない',
      attack: '「カチッ」と閉じる口で、針を撃ちこむ',
      lore: '横歩きで机の上をうろつく。針が切れると急におとなしくなる。',
      sound: 'se_staple',
    ),
    EnemySpecies(
      look: 'scissors',
      name: 'ハサミビートル',
      motif: 'はさみ × カブトムシ',
      category: SpeciesCategory.crafting,
      size: SpeciesSize.medium,
      rarity: Rarity.rare,
      personality: '白黒はっきりつけたい',
      attack: '二本の刃の角で、問題文を切りきざむ',
      lore: '左右の刃は別々の意思をもつが、閉じる瞬間だけは息が合う。',
      sound: 'se_snip',
    ),
    EnemySpecies(
      look: 'binder',
      name: 'バインダートータス',
      motif: 'バインダー × 亀',
      category: SpeciesCategory.crafting,
      size: SpeciesSize.large,
      rarity: Rarity.epic,
      personality: 'のんびりしているが、なんでも覚えている',
      attack: '金具の甲羅をばちんと閉じて、はさみこむ',
      lore: '甲羅の中に、これまで出会ったすべてのプリントを保管している。',
      sound: 'se_snap',
    ),
    EnemySpecies(
      look: 'page',
      name: 'プリント兵',
      motif: 'プリント × 紙兵',
      category: SpeciesCategory.paper,
      size: SpeciesSize.small,
      rarity: Rarity.common,
      personality: '配られるとすぐ整列する',
      attack: '紙飛行機になって突撃する',
      lore: '名前を書き忘れると、持ち主のもとに帰れなくなる。',
      sound: 'se_page',
    ),
    EnemySpecies(
      look: 'ghost',
      name: 'ノートゴースト',
      motif: 'ノート × 幽霊',
      category: SpeciesCategory.paper,
      size: SpeciesSize.medium,
      rarity: Rarity.rare,
      personality: '書かれなかった答えの未練でできている',
      attack: 'ページをめくる風で、記憶をあいまいにする',
      lore: '白紙のページほど強い。一度でも書きこまれると、少しだけ満足する。',
      sound: 'se_ghost',
    ),
    EnemySpecies(
      look: 'book',
      name: '魔導教科書',
      motif: '教科書 × 魔導書',
      category: SpeciesCategory.paper,
      size: SpeciesSize.large,
      rarity: Rarity.epic,
      personality: '知識を独り占めしたがる',
      attack: '重要語句を呪文のように唱え、ページで押しつぶす',
      lore: '索引から自在に章を呼び出す。最後まで読んだ者にだけ心を開く。',
      sound: 'se_page',
    ),
    EnemySpecies(
      look: 'bat',
      name: 'しおりコウモリ',
      motif: 'しおり × コウモリ',
      category: SpeciesCategory.paper,
      size: SpeciesSize.small,
      rarity: Rarity.common,
      personality: '途中でやめたページにぶら下がる',
      attack: '超音波で「どこまで読んだっけ」と迷わせる',
      lore: '読みかけの本にすみつく。最後まで読むと、どこかへ飛んでいく。',
      sound: 'se_flap',
    ),
    EnemySpecies(
      look: 'slime',
      name: 'のりスライム',
      motif: 'スティックのり × スライム',
      category: SpeciesCategory.school,
      size: SpeciesSize.small,
      rarity: Rarity.common,
      personality: 'くっつきたがりで、寂しがり',
      attack: 'べたべたの体で動きを止める',
      lore: '乾くと固まって動けなくなる。キャップを閉めると安心して眠る。',
      sound: 'se_squish',
    ),
    EnemySpecies(
      look: 'goblin',
      name: 'クリップ小鬼',
      motif: 'ゼムクリップ × 小鬼',
      category: SpeciesCategory.school,
      size: SpeciesSize.small,
      rarity: Rarity.common,
      personality: 'いたずら好きで、プリントの順番を入れかえる',
      attack: '曲げたクリップの鉤爪でひっかく',
      lore: '一本の針金を曲げて体を作っている。のばすと元に戻れない。',
      sound: 'se_click',
    ),
    EnemySpecies(
      look: 'golem',
      name: 'ぶんちんゴーレム',
      motif: '文鎮 × ゴーレム',
      category: SpeciesCategory.school,
      size: SpeciesSize.large,
      rarity: Rarity.epic,
      personality: '重くて動かない。動くときは本気',
      attack: '全体重で押さえつける',
      lore: '書道の時間から生まれた。半紙を押さえる役目を、今も律儀に守っている。',
      sound: 'se_thud',
    ),
    EnemySpecies(
      look: 'knight',
      name: 'ペーパーナイト',
      motif: 'ペーパーナイフ × 騎士',
      category: SpeciesCategory.ancient,
      size: SpeciesSize.large,
      rarity: Rarity.epic,
      personality: '礼儀正しく、封を切る前に必ず一礼する',
      attack: '封を開くように、守りを切り開く',
      lore: '手紙を開けるための刃を持つ騎士。知識の封印を守ってきた。',
      sound: 'se_slash',
    ),
    EnemySpecies(
      look: 'dragon',
      name: '万年筆ドラゴン',
      motif: '万年筆 × ドラゴン',
      category: SpeciesCategory.ancient,
      size: SpeciesSize.large,
      rarity: Rarity.legendary,
      personality: '誇り高く、自分の書いた文字を愛している',
      attack: 'インクの炎を吐き、ペン先の爪で刻む',
      lore: '何百年も書き続けてきた古いペン先が竜になった。そのインクは乾かない。',
      sound: 'se_roar',
    ),
  ];

  static final _byLook = {for (final s in all) s.look: s};

  /// 見た目のキーから種族を返す（未知なら のりスライム）
  static EnemySpecies of(String look) => _byLook[look] ?? _byLook['slime']!;
}
