import '../curriculum/curriculum.dart';
import '../curriculum/curriculum_progress.dart';

/// 学習ルートの1歩の状態
enum RouteStatus {
  /// 正答率80%以上
  mastered('できている'),

  /// 正答率60〜80%
  solid('おおむねできている'),

  /// 正答率60%未満（弱点）
  weak('弱点'),

  /// 少し解いたが、判定にはまだ足りない
  learning('学習中'),

  /// まだ解いていない
  untouched('まだ'),

  /// 問題がない（ほかの単元の問題で確かめる）
  noQuestions('問題なし');

  const RouteStatus(this.label);
  final String label;

  static RouteStatus of(NodeProgress p) {
    if (p.questionCount == 0 && p.answered == 0) return noQuestions;
    if (p.answered == 0) return untouched;
    if (!p.rated) return learning;
    final a = p.accuracy!;
    if (a >= 80) return mastered;
    if (a >= 60) return solid;
    return weak;
  }

  /// やり直しをすすめる状態か
  bool get needsWork => this == weak;
}

/// 学習ルートの1歩
class RouteStep {
  const RouteStep({
    required this.node,
    required this.progress,
    required this.depth,
  });

  final CurriculumNode node;
  final NodeProgress progress;

  /// 目標から何段さかのぼった前提か（目標は0）
  final int depth;

  RouteStatus get status => RouteStatus.of(progress);
}

/// 学習ルート：苦手な単元から前提をさかのぼり、「どこから学び直すか」を出す。
///
/// 例：数学Ⅱ 微分の最大・最小が苦手 → 前提の数学Ⅰ 2次関数も弱点なら、
/// そこが根本の原因。ルートは根本（いちばん前提）から目標の順に並ぶ。
class LearningRoute {
  const LearningRoute({required this.target, required this.steps});

  /// 目標の単元
  final RouteStep target;

  /// 前提から目標までの順（最後が目標）
  final List<RouteStep> steps;

  /// さかのぼる段数の上限
  static const maxDepth = 4;

  /// 目標より前の前提だけ
  List<RouteStep> get prerequisites => steps.sublist(0, steps.length - 1);

  /// 根本の原因：前提のうち、いちばん前にある弱点。なければ null
  RouteStep? get rootCause {
    for (final s in prerequisites) {
      if (s.status.needsWork) return s;
    }
    return null;
  }

  /// 次に学ぶ節：根本の原因 → まだ判定できない前提 → 目標
  RouteStep get nextStep {
    final root = rootCause;
    if (root != null) return root;
    for (final s in prerequisites) {
      if (s.status == RouteStatus.learning ||
          s.status == RouteStatus.untouched) {
        return s;
      }
    }
    return target;
  }

  /// [targetId] から前提をさかのぼったルート
  factory LearningRoute.trace(String targetId, CurriculumProgress progress) {
    final order = <String>[];
    final depthOf = <String, int>{};
    final visiting = <String>{};

    void visit(String id, int depth) {
      if (!Curriculum.contains(id) || visiting.contains(id)) return;
      final known = depthOf[id];
      if (known != null) {
        if (depth > known) depthOf[id] = depth;
        return;
      }
      visiting.add(id);
      if (depth < maxDepth) {
        for (final p in Curriculum.prerequisitesOf(id)) {
          // 自分の祖先・子孫は前提にしない（同じ範囲の重なり）
          if (p == id || id.startsWith('$p.') || p.startsWith('$id.')) {
            continue;
          }
          visit(p, depth + 1);
        }
      }
      visiting.remove(id);
      depthOf[id] = depth;
      order.add(id);
    }

    visit(targetId, 0);
    // 目標は必ず最後。前提は深い（より前の）ものから
    final pre = order.where((id) => id != targetId).toList()
      ..sort((a, b) {
        final d = depthOf[b]!.compareTo(depthOf[a]!);
        return d != 0 ? d : order.indexOf(a).compareTo(order.indexOf(b));
      });
    RouteStep step(String id) => RouteStep(
        node: Curriculum.node(id), progress: progress[id], depth: depthOf[id]!);
    final target = step(targetId);
    return LearningRoute(
      target: target,
      steps: [for (final id in pre) step(id), target],
    );
  }

  /// 苦手な単元ごとのルート（[under] の教科・科目の中から、正答率の低い順に）
  static List<LearningRoute> forWeakUnits(
    CurriculumProgress progress, {
    String? under,
    int limit = 3,
  }) =>
      [
        for (final p in progress.weakest(under: under, limit: limit))
          if ((p.accuracy ?? 100) < 60)
            LearningRoute.trace(p.node.id, progress),
      ];
}
