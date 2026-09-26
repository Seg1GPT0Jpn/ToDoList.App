/// 知識カードの効果
enum CardEffect {
  /// 正解ならダメージ2倍。不正解なら受けるダメージ1.5倍
  power,

  /// 正解するとHPを最大の30%回復
  heal,

  /// 次に間違えてもダメージを受けない
  guard,

  /// 間違いの選択肢を2つ消す
  hint,

  /// 制限時間 +10秒
  time,

  /// 次の正解でチェインを +2
  chain,

  /// 次の正解は必ずクリティカル
  critical,

  /// 正解でダメージ3倍。不正解なら受けるダメージ2倍
  gamble,
}

enum CardRarity { common, rare }

/// 知識カード。バトル中に手札から1枚使うと、次の回答に効果がつく。
class CardDef {
  const CardDef({
    required this.id,
    required this.name,
    required this.effect,
    required this.description,
    this.rarity = CardRarity.common,
  });

  final String id;
  final String name;
  final CardEffect effect;
  final String description;
  final CardRarity rarity;

  static const all = <CardDef>[
    CardDef(
        id: 'power',
        name: '強打の構文',
        effect: CardEffect.power,
        description: '正解ならダメージ2倍。不正解だと受けるダメージ1.5倍'),
    CardDef(
        id: 'heal',
        name: '回復の詩',
        effect: CardEffect.heal,
        description: '正解するとHPを最大の30%回復'),
    CardDef(
        id: 'guard',
        name: '守りの辞書',
        effect: CardEffect.guard,
        description: '間違えてもダメージを受けない'),
    CardDef(
        id: 'hint',
        name: 'ひらめきの栞',
        effect: CardEffect.hint,
        description: '間違いの選択肢を2つ消す'),
    CardDef(
        id: 'time',
        name: '時の砂',
        effect: CardEffect.time,
        description: '制限時間を10秒のばす',
        rarity: CardRarity.rare),
    CardDef(
        id: 'chain',
        name: '連鎖の糸',
        effect: CardEffect.chain,
        description: '正解するとチェインが一気に+2',
        rarity: CardRarity.rare),
    CardDef(
        id: 'critical',
        name: '会心のペン',
        effect: CardEffect.critical,
        description: '正解すると必ずクリティカル',
        rarity: CardRarity.rare),
    CardDef(
        id: 'gamble',
        name: '捨て身の一撃',
        effect: CardEffect.gamble,
        description: '正解ならダメージ3倍。不正解だと受けるダメージ2倍',
        rarity: CardRarity.rare),
  ];

  static CardDef byId(String id) => all.firstWhere((c) => c.id == id);

  /// 最初に持っているカード
  static const starterDeck = [
    'power',
    'power',
    'heal',
    'guard',
    'guard',
    'hint'
  ];

  static List<CardDef> get rares =>
      all.where((c) => c.rarity == CardRarity.rare).toList();
}

/// 仲間の常時効果
enum CompanionEffect {
  /// 与えるダメージ +10%
  attackUp,

  /// 受けるダメージ -15%
  defenseUp,

  /// 制限時間 +3秒
  moreTime,

  /// 1バトルに1回、HPが0になる攻撃をHP1で耐える
  lastStand,
}

/// 仲間（捕まっているのを助けると加わる）
class CompanionDef {
  const CompanionDef({
    required this.id,
    required this.name,
    required this.effect,
    required this.description,
  });

  final String id;
  final String name;
  final CompanionEffect effect;
  final String description;

  static const all = <CompanionDef>[
    CompanionDef(
        id: 'kotodama',
        name: '言霊の妖精',
        effect: CompanionEffect.attackUp,
        description: '与えるダメージ +10%'),
    CompanionDef(
        id: 'old_dict',
        name: '辞書じいさん',
        effect: CompanionEffect.defenseUp,
        description: '受けるダメージ -15%'),
    CompanionDef(
        id: 'clock_rabbit',
        name: '時計うさぎ',
        effect: CompanionEffect.moreTime,
        description: '制限時間 +3秒'),
    CompanionDef(
        id: 'cat_teacher',
        name: 'ねこ先生',
        effect: CompanionEffect.lastStand,
        description: '1バトルに1回、やられる攻撃をHP1で耐える'),
  ];

  static CompanionDef byId(String id) => all.firstWhere((c) => c.id == id);
}
