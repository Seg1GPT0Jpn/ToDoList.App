import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../vocab/vocab_store.dart';
import '../app/edition.dart';

/// ゆるい連続記録とお休み券の保存先（この端末の中だけ）。
///
/// 勉強した日は、RPG（[LearningRecord.studyDays]）と単語帳（どの単語帳でも
/// 1問以上答えた日）を合わせて数える。
class StreakStore extends ChangeNotifier {
  StreakStore(this._prefs) : _state = _read(_prefs);

  static const _key = 'gentle_streak_v1';
  final SharedPreferences _prefs;
  GentleStreak _state;

  GentleStreak get state => _state;

  static GentleStreak _read(SharedPreferences p) {
    try {
      final raw = p.getString(_key);
      return raw == null
          ? const GentleStreak()
          : GentleStreak.fromMap(jsonDecode(raw));
    } catch (_) {
      return const GentleStreak();
    }
  }

  /// RPG と単語帳を合わせた、勉強した日
  static Set<int> studyDays(LearningRecord record, VocabStore vocab) {
    final out = {...record.studyDays};
    for (final b in vocab.books) {
      vocab.progress(b.id).days.forEach((key, d) {
        if (d.answered <= 0) return;
        final parts = key.split('-');
        if (parts.length != 3) return;
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (y == null || m == null || day == null) return;
        out.add(dayNumber(DateTime(y, m, day)));
      });
    }
    return out;
  }

  /// 休んだ日に券を使い、節目で券を渡す。変わったときだけ保存する
  StreakNews settle(Set<int> days, int today) {
    final (next, news) = _state.settle(days, today);
    final before = jsonEncode(_state.toMap());
    final after = jsonEncode(next.toMap());
    if (before != after) {
      _state = next;
      _prefs.setString(_key, after);
      notifyListeners();
    }
    return news;
  }
}

/// 連続の日数（Light は絵文字を使わない：絵文字のフォントをネットから取りに行くため）
const streakMark = lightEdition ? '' : '🔥 ';

/// お休み券の印
const ticketMark = lightEdition ? 'お休み券' : '🎫';

/// 「🔥 n 日連続」とお休み券の札。表示のたびに券の出し入れを済ませ、
/// 使った・もらったときはひとことだけ知らせる
class StreakTag extends StatefulWidget {
  const StreakTag({super.key, this.long = false});

  /// 単語帳ホーム用の、説明つきの表示
  final bool long;

  @override
  State<StreakTag> createState() => _StreakTagState();
}

class _StreakTagState extends State<StreakTag> {
  @override
  Widget build(BuildContext context) {
    final services = context.dependOnInheritedWidgetOfExactType<RpgServices>();
    if (services == null) return const SizedBox.shrink();
    final store = services.streak;
    return ListenableBuilder(
      listenable: Listenable.merge([store, services.meta]),
      builder: (context, _) {
        final today = RpgServices.today();
        final days = StreakStore.studyDays(
          services.meta.record,
          VocabStore.of(services.personalBooks),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final news = store.settle(days, today);
          if (news.isEmpty) return;
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text(StreakText.news(news))));
        });
        final n = store.state.length(days, today);
        final tickets = store.state.tickets;
        final tag = n > 0 ? '$streakMark$n 日連続' : '今日から始めよう';
        if (!widget.long) {
          return Container(
            key: const ValueKey('streak-tag'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (n > 0 ? const Color(0xFFD9822B) : TsuzuriColors.inkSoft)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tickets > 0 ? '$tag　$ticketMark×$tickets' : tag,
              style: TextStyle(
                fontSize: 12,
                color: n > 0 ? const Color(0xFFD9822B) : TsuzuriColors.inkSoft,
              ),
            ),
          );
        }
        return Column(
          key: const ValueKey('streak-long'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$tag　${lightEdition ? '' : '🎫 '}お休み券 ×$tickets'),
            Text(
              StreakText.help,
              style: TextStyle(fontSize: 11, color: TsuzuriColors.inkSoft),
            ),
          ],
        );
      },
    );
  }
}

class StreakText {
  const StreakText._();

  static const help = '7日続けるとお休み券が1枚（2枚まで）。休んだ日に自動で使われ、連続が切れません';

  static String news(StreakNews n) => [
    if (n.used > 0) 'お休み券を${n.used}枚使って、連続をつなぎました',
    if (n.earned > 0)
      '7日続きました！お休み券を${n.earned}枚もらいました${lightEdition ? '' : ' 🎫'}',
  ].join('。');
}
