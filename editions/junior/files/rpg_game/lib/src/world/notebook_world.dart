import 'terrain.dart';

/// フィールドの紙の種類。「ノートの上で冒険している」世界観を、場所ごとに変える。
///
/// 地形（草原・洞窟…）と教科の国で決まる。描き方はアプリ側（paper_art.dart）。
enum PaperStyle {
  /// 方眼ノート（いちばん基本）
  grid('方眼ノート'),

  /// 罫線ノート（左に赤い余白線）
  ruled('罫線ノート'),

  /// ルーズリーフ（穴の列がある）
  looseLeaf('ルーズリーフ'),

  /// 原稿用紙（国語の国）
  manuscript('原稿用紙'),

  /// 五線譜（音楽の虹）
  staff('五線譜'),

  /// 製図用紙（青い方眼・数学や工房）
  blueprint('製図用紙'),

  /// クラフト紙（地図や古い記録）
  kraft('クラフト紙'),

  /// 付箋だらけのページ
  sticky('付箋のページ'),

  /// 古いページ（しみ・破れ・めくれ）
  oldPage('古いページ'),

  /// 黒板（夜・洞窟・溶岩）
  chalkboard('黒板');

  const PaperStyle(this.label);
  final String label;
}

/// 紙の上の小物・落書き（通れる床の上に、ときどき描く。通行のじゃまはしない）
enum NotebookMark {
  doodleStar('星の落書き'),
  doodleHeart('ハートの落書き'),
  doodleArrow('矢印'),
  doodleSpiral('ぐるぐる'),
  smiley('にこちゃん'),
  eraserSmudge('消し跡'),
  coffeeRing('マグカップのあと'),
  tape('マスキングテープ'),
  sticker('シール'),
  highlighter('マーカーの線'),
  paperclip('クリップ'),
  shavings('鉛筆の削りかす'),
  note('手書きのメモ'),
  checkmark('赤ペンのチェック');

  const NotebookMark(this.label);
  final String label;
}

/// 国（ワールド）ごとの紙と、ページの余白に書きこまれた手書きの文字。
abstract final class NotebookWorld {
  /// その地形・国の紙
  static PaperStyle paperOf(Terrain t, String worldId) {
    if (t.isVoyage) return PaperStyle.grid;
    switch (t) {
      case Terrain.lava || Terrain.cave:
        return PaperStyle.chalkboard;
      case Terrain.ruins || Terrain.desert:
        return PaperStyle.oldPage;
      case Terrain.harbor || Terrain.beach:
        return PaperStyle.kraft;
      case Terrain.workshop || Terrain.tower:
        return PaperStyle.blueprint;
      case Terrain.flower:
        return PaperStyle.sticky;
      default:
        break;
    }
    return switch (worldId) {
      'japanese' => t == Terrain.library || t == Terrain.shrine
          ? PaperStyle.manuscript
          : PaperStyle.ruled,
      'math' => t == Terrain.castle ? PaperStyle.blueprint : PaperStyle.grid,
      'english' => PaperStyle.ruled,
      'social' => t == Terrain.town ? PaperStyle.looseLeaf : PaperStyle.kraft,
      'science' => PaperStyle.grid,
      _ => PaperStyle.grid,
    };
  }

  /// 床の上の小物を置く割合（0〜1）。紙の種類でにぎやかさが変わる
  static double markDensity(PaperStyle p) => switch (p) {
        PaperStyle.sticky => 0.09,
        PaperStyle.oldPage || PaperStyle.kraft => 0.07,
        PaperStyle.chalkboard => 0.05,
        _ => 0.06,
      };

  /// ページの余白に書いてある手書きの文字（教科ごと）
  static List<String> scribblesOf(String worldId) =>
      _scribbles[worldId] ?? _scribbles['english']!;

  static const _scribbles = {
    'english': [
      'be動詞',
      'S+V+O',
      'if I were…',
      'have p.p.',
      'to不定詞',
      'which?',
      'ABC'
    ],
    'math': ['x²', 'Σ', '∫dx', 'sinθ', '√2', 'a+b', 'y=ax²', 'P(A)'],
    'science': ['H₂O', 'F=ma', 'DNA', 'mol', 'pH7', 'E=mc²', 'NaCl'],
    'social': ['1192', '645', 'GDP', '1789', '三権', '緯度', '産業革命'],
    'japanese': ['あはれ', '係り結び', '返り点', '漢字', '要旨', 'をかし', '句法'],
    'information': ['0101', 'if', 'for', 'IP', 'AND', 'HTTP', 'bit'],
    'music': ['♪', '♯', '♭', 'C dur', 'f', 'p', '4/4'],
  };
}

/// 宝箱の種類（ゲームのしかけ）
enum ChestVariant {
  /// 知識の封印：難問1問に正解すると開く
  seal('知識の封印', '難しい問題に1問正解すると開く'),

  /// 連続正解の宝箱：3問続けて正解するほど、中身が豪華になる
  chain('連続正解の宝箱', '3問に答える。全問正解でレアカード2枚、2問正解で1枚'),

  /// ミミック：宝箱のふりをした魔物。倒すと中身がもらえる
  mimic('あやしい宝箱', 'ミミックが化けている。倒すとレアカード'),

  /// 探索のごほうび：隠し通路の奥。見つけたこと自体がごほうび
  explore('探索のごほうび', '隠し通路を見つけた人だけが開けられる。問題なしで開く');

  const ChestVariant(this.label, this.description);
  final String label;
  final String description;

  /// エリアのいちばん奥の宝箱の種類（エリア番号で決まる。ボスの間はふつうの封印）
  static ChestVariant forMainChest(int area, {bool boss = false}) {
    if (boss) return seal;
    return switch (area % 4) {
      0 => chain,
      2 => mimic,
      _ => seal,
    };
  }
}

/// フィールドの発見率：見つけたもの÷全部
class FieldDiscovery {
  const FieldDiscovery({required this.found, required this.total});

  final int found;
  final int total;

  /// 0〜100
  int get percent => total == 0 ? 100 : (found * 100 / total).round();

  bool get complete => total > 0 && found >= total;
}
