/// 問題の図・グラフ（QuizQuestion.figure）の形式チェック。
///
/// 形式は3種類。
/// - 図形: {"w":240,"h":160,"items":[...]}（座標は左上が原点、y は下向き）
///   items の1つは次のどれか1つのキーを持つ。
///   line:[x1,y1,x2,y2]（"dash":true で点線） / path:[x1,y1,x2,y2,...]（開いた折れ線）
///   poly:[x1,y1,...]（閉じた多角形、"fill":true でうすく塗る） / circle:[cx,cy,r]
///   arc:[cx,cy,r,開始角,回転角]（度。x 軸の正の向きから時計回り） / dot:[x,y]
///   arrow:[x1,y1,x2,y2] / text:"A" と at:[x,y]（中央ぞろえ）
/// - 棒グラフ: {"chart":"bar","labels":[...],"values":[...],"unit":"人"}
/// - 折れ線グラフ: {"chart":"line","labels":[...],
///   "series":[{"name":"A","values":[...]}],"unit":"℃"}
abstract final class FigureSpec {
  static const _shapeKeys = {
    'line': 4,
    'path': -2,
    'poly': -2,
    'circle': 3,
    'arc': 5,
    'dot': 2,
    'arrow': 4,
  };

  /// 形式のまちがいを返す（なければ空）
  static List<String> problems(Map<String, dynamic> f) {
    final out = <String>[];
    // 予想問題の原本の図の切り抜き
    if (f.containsKey('yosou')) {
      final v = f['yosou'];
      return v is String && YosouCrop.tryParse(v) != null
          ? out
          : ['yosou の切り抜きの書き方がちがう'];
    }
    bool nums(Object? v, int n) {
      if (v is! List || v.any((e) => e is! num)) return false;
      return n > 0 ? v.length == n : v.length >= -n * 2 && v.length.isEven;
    }

    final chart = f['chart'];
    if (chart != null) {
      final labels = f['labels'];
      if (labels is! List || labels.isEmpty) out.add('labels がない');
      final n = labels is List ? labels.length : 0;
      if (chart == 'bar') {
        if (!nums(f['values'], n)) out.add('values の数が labels と合わない');
      } else if (chart == 'line') {
        final series = f['series'];
        if (series is! List || series.isEmpty) {
          out.add('series がない');
        } else {
          for (final s in series) {
            if (s is! Map || !nums(s['values'], n)) {
              out.add('series の values の数が labels と合わない');
            }
          }
        }
      } else {
        out.add('不明な chart: $chart');
      }
      return out;
    }
    if (f['w'] is! num || f['h'] is! num) out.add('w と h がない');
    final items = f['items'];
    if (items is! List || items.isEmpty) return [...out, 'items がない'];
    for (final it in items) {
      if (it is! Map) {
        out.add('items の要素がオブジェクトでない');
        continue;
      }
      if (it.containsKey('text')) {
        if (!nums(it['at'], 2)) out.add('text の at がない: ${it['text']}');
        continue;
      }
      final keys = it.keys.where(_shapeKeys.containsKey).toList();
      if (keys.length != 1) {
        out.add('図形の種類が決まらない: $it');
      } else if (!nums(it[keys.first], _shapeKeys[keys.first]!)) {
        out.add('${keys.first} の数値の数がちがう: $it');
      }
    }
    return out;
  }
}

/// 予想問題の原本のページ画像の一部（図・表・漢文など）。
///
/// 書き方は「<予想問題のid>:<ページ>:<左>,<上>,<右>,<下>」（位置はページの幅・高さに対する
/// 0〜1 の割合）。問題の図（figure の "yosou"）や、本文の段落（"@yosou:" で始まる）に使う。
class YosouCrop {
  const YosouCrop(
      this.examId, this.page, this.left, this.top, this.right, this.bottom);

  final String examId;
  final int page;
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// 本文の段落を画像にするときの印
  static const paragraphPrefix = '@yosou:';

  static YosouCrop? tryParse(String s) {
    final m = RegExp(r'^([\w-]+):(\d+):([\d.]+),([\d.]+),([\d.]+),([\d.]+)$')
        .firstMatch(s.trim());
    if (m == null) return null;
    final v = [for (var i = 3; i <= 6; i++) double.parse(m.group(i)!)];
    if (v.any((x) => x < 0 || x > 1) || v[0] >= v[2] || v[1] >= v[3]) {
      return null;
    }
    final page = int.parse(m.group(2)!);
    if (page < 1) return null;
    return YosouCrop(m.group(1)!, page, v[0], v[1], v[2], v[3]);
  }

  /// 本文の段落が画像なら、その切り抜き
  static YosouCrop? ofParagraph(String p) => p.startsWith(paragraphPrefix)
      ? tryParse(p.substring(paragraphPrefix.length))
      : null;

  /// 横の長さ÷縦の長さ（ページの縦横比 [pageAspect] をかける）
  double aspect(double pageAspect) =>
      (right - left) / (bottom - top) * pageAspect;
}
