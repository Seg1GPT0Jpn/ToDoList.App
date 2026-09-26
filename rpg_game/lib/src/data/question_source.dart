import 'dart:convert';

import '../models/question.dart';

/// 問題セットの読み込み元。
///
/// 移植時は rootBundle.loadString('assets/questions/...') で読んだ文字列を
/// [JsonQuestionSource.parse] に渡すか、Firestore 版を実装する。
abstract class QuestionSource {
  /// 問題セットを返す。まだ用意されていない場合は null。
  Future<QuestionSet?> load(String setId);
}

/// JSON 文字列から問題セットを作る。読み込み方法（アセット・ファイル・Firestore）は
/// [loader] に任せる。
class JsonQuestionSource implements QuestionSource {
  JsonQuestionSource(this.loader);

  /// setId から JSON 文字列を返す。存在しなければ null。
  final Future<String?> Function(String setId) loader;
  final Map<String, QuestionSet> _cache = {};

  static QuestionSet parse(String json) =>
      QuestionSet.fromJson(jsonDecode(json) as Map<String, dynamic>);

  @override
  Future<QuestionSet?> load(String setId) async {
    final cached = _cache[setId];
    if (cached != null) return cached;
    final raw = await loader(setId);
    if (raw == null) return null;
    final set = parse(raw);
    if (set.setId != setId) {
      throw FormatException('setId が一致しません: 要求 $setId / 実際 ${set.setId}');
    }
    return _cache[setId] = set;
  }
}
