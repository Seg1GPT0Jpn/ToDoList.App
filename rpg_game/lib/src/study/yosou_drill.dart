import '../models/question.dart';

/// 予想問題を小問ごとに解く。
///
/// 大問ごとのまとまり（本文・前書き＝Passage）をそのまま使い、順番どおりに出す
/// （前の小問が次の小問の誘導になっていることがあるため）。
class YosouGroup {
  const YosouGroup(
      {required this.id, required this.title, required this.questions});

  final String id;
  final String title;
  final List<QuizQuestion> questions;

  /// 問題データを大問ごとに分ける（出てきた順。本文がない問題は直前の大問に続ける）
  static List<YosouGroup> of(List<QuizQuestion> questions) {
    final out = <YosouGroup>[];
    final order = <String>[];
    final byId = <String, List<QuizQuestion>>{};
    final titles = <String, String>{};
    for (final q in questions) {
      final id = groupId(q);
      if (!byId.containsKey(id)) {
        order.add(id);
        byId[id] = [];
        titles[id] = q.passage?.title ?? id;
      }
      byId[id]!.add(q);
    }
    for (final id in order) {
      out.add(YosouGroup(id: id, title: titles[id]!, questions: byId[id]!));
    }
    return out;
  }

  /// 大問のまとまりの名前（本文の id。なければ問題 id の先頭）
  static String groupId(QuizQuestion q) =>
      q.passage?.id ??
      q.id.substring(0, q.id.lastIndexOf('_').clamp(0, q.id.length));
}
