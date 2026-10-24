import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 「この問題がおかしい」の報告
class QuestionReport {
  const QuestionReport({
    required this.questionId,
    required this.reason,
    required this.note,
    required this.at,
  });

  final String questionId;
  final String reason;
  final String note;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'reason': reason,
    'note': note,
    'at': at.toIso8601String(),
  };

  factory QuestionReport.fromJson(Map<String, dynamic> j) => QuestionReport(
    questionId: j['questionId'] as String,
    reason: j['reason'] as String,
    note: j['note'] as String? ?? '',
    at: DateTime.parse(j['at'] as String),
  );
}

/// 報告の送り先。端末に残し、Firebase があればクラウドにも送る。
class ReportSink {
  ReportSink({this.upload});

  static const prefsKey = 'question_reports';

  /// クラウドへ送る処理（Firebase がなければ null）
  final Future<void> Function(QuestionReport r)? upload;

  Future<void> send(QuestionReport r) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(prefsKey) ?? [];
    list.add(jsonEncode(r.toJson()));
    await prefs.setStringList(
      prefsKey,
      list.length > 200 ? list.sublist(list.length - 200) : list,
    );
    try {
      await upload?.call(r);
    } catch (_) {
      // オフラインなど。端末には残っている
    }
  }

  static Future<List<QuestionReport>> saved() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final s in prefs.getStringList(prefsKey) ?? const <String>[])
        QuestionReport.fromJson(jsonDecode(s) as Map<String, dynamic>),
    ];
  }
}

/// アプリ全体で使う送り先（main.dart で Firebase 版に差しかえる）
ReportSink reportSink = ReportSink();

const reportReasons = ['正解がちがう', '解説がおかしい', '問題文・選択肢が不自然', '誤字・表示のくずれ', 'その他'];

/// 報告ダイアログを出す。送ったら true。
Future<bool> showReportDialog(BuildContext context, QuizQuestion q) async {
  var reason = reportReasons.first;
  final note = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('この問題を報告'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                q.prompt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in reportReasons)
                    ChoiceChip(
                      label: Text(r),
                      selected: reason == r,
                      onSelected: (_) => setState(() => reason = r),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('report-note'),
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'どこがおかしいか（書かなくてもOK）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('report-send'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('送る'),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  await reportSink.send(
    QuestionReport(
      questionId: q.id,
      reason: reason,
      note: note.text.trim(),
      at: DateTime.now(),
    ),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('報告しました。ありがとう！')));
  }
  return true;
}
