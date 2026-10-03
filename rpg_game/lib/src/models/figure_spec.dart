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
