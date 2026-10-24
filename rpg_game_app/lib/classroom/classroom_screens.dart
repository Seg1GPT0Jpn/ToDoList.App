import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../account/account_screen.dart';
import '../app/services.dart';
import '../app/theme.dart';
import '../app/usage_meter.dart';
import '../quiz/question_report.dart';
import '../versus/duel_screens.dart';
import '../vocab/vocab_session_screen.dart';
import '../vocab/vocab_store.dart';
import 'class_reminders.dart';
import 'classroom_backend.dart';
import 'classroom_store.dart';

/// 画面の言葉
class ClassText {
  const ClassText._();
  static const title = 'クラスルーム';
  static const intro =
      '友だちと6ケタのコードで集まって、単語の小テスト・定期テストの「範囲と日付」をいっしょに準備します。'
      '小テストは1週間前、定期テストは2週間前から、毎日の分が自動で出ます。';
  static const privacy =
      '共有するのは「単語帳の名前・番号の範囲・日付」とニックネームだけです。単語の中身は共有しません。'
      'みんなで削る共闘ボスには合計だけが出て、だれが何問解いたかは表示されません。';
  static const needLogin = 'クラスルームは、Google でログインすると使えます';
  static const noBackend = 'この版ではクラスルームを使えません（サーバーの設定がありません）';
}

/// クラスルームの一覧（入っているクラス・コードで入る・作る）
class ClassroomHubScreen extends StatefulWidget {
  const ClassroomHubScreen({super.key, this.joinCode});

  /// リンク（?class=123456）から来たときのコード
  final String? joinCode;

  @override
  State<ClassroomHubScreen> createState() => _ClassroomHubScreenState();
}

class _ClassroomHubScreenState extends State<ClassroomHubScreen> {
  @override
  void initState() {
    super.initState();
    UsageMeter.mark(context, 'classroom');
  }

  Map<String, Classroom?>? _rooms;
  bool _askedJoin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rooms == null) _load();
    final code = widget.joinCode;
    if (!_askedJoin && code != null && Classroom.validCode(code)) {
      _askedJoin = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _join(initial: code);
      });
    }
  }

  ClassroomBackend? get _backend => RpgServices.of(context).classrooms;

  Future<void> _load() async {
    final services = RpgServices.of(context);
    final backend = services.classrooms;
    final store = services.classroomStore;
    if (backend == null || backend.userId == null) {
      setState(() => _rooms = {});
      return;
    }
    final out = <String, Classroom?>{};
    for (final code in store.codes) {
      try {
        out[code] = await backend.fetch(code);
        await store.flush(backend, code);
      } on ClassroomException {
        out[code] = null;
      }
    }
    if (!mounted) return;
    setState(() => _rooms = out);
    // 小テスト・定期テストのお知らせを予定しなおす
    final uid = backend.userId;
    unawaited(
      ClassReminders.sync([
        for (final r in out.values)
          if (r != null && r.isMember(uid))
            for (final t in r.upcoming(DateTime.now())) (r, t),
      ]),
    );
  }

  Future<void> _open(String code) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ClassroomScreen(code: code)),
    );
    if (mounted) _load();
  }

  Future<void> _join({String? initial}) async {
    final services = RpgServices.of(context);
    final store = services.classroomStore;
    final backend = _backend;
    if (backend == null || backend.userId == null) return;
    final code = TextEditingController(text: initial ?? '');
    final nick = TextEditingController(
      text: store.nickname.isEmpty
          ? services.profiles.load().userName
          : store.nickname,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('コードで入る'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('class-join-code'),
              controller: code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: '6ケタのコード'),
            ),
            TextField(
              key: const ValueKey('class-join-nick'),
              controller: nick,
              maxLength: Classroom.maxName,
              decoration: const InputDecoration(
                labelText: 'クラスで使うニックネーム',
                helperText: '本名でなくてOK。クラスのメンバーに見えます',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('class-join-ok'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('入る'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final c = code.text.trim();
    if (!Classroom.validCode(c)) {
      _snack('コードは6ケタの数字です');
      return;
    }
    try {
      final room = await backend.join(c, nick.text);
      await store.add(room.code);
      await store.setNickname(nick.text.trim());
      if (!mounted) return;
      _snack('「${room.name}」に入りました');
      await _open(room.code);
    } on ClassroomException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _create() async {
    final services = RpgServices.of(context);
    final store = services.classroomStore;
    final backend = _backend;
    if (backend == null || backend.userId == null) return;
    final name = TextEditingController();
    final nick = TextEditingController(
      text: store.nickname.isEmpty
          ? services.profiles.load().userName
          : store.nickname,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('クラスを作る'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('class-create-name'),
              controller: name,
              maxLength: Classroom.maxName,
              decoration: const InputDecoration(
                labelText: 'クラスの名前（例：英語 小テスト組）',
                helperText: '学校名・クラス名は入れないでください',
              ),
            ),
            TextField(
              key: const ValueKey('class-create-nick'),
              controller: nick,
              maxLength: Classroom.maxName,
              decoration: const InputDecoration(labelText: 'あなたのニックネーム'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('class-create-ok'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('作る'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final room = await backend.create(name.text, nick.text);
      await store.add(room.code);
      await store.setNickname(nick.text.trim());
      if (!mounted) return;
      await _open(room.code);
    } on ClassroomException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final services = RpgServices.of(context);
    final backend = services.classrooms;
    final rooms = _rooms;
    return Scaffold(
      appBar: AppBar(title: Text(ClassText.title, style: serif(18))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(40, 12, 16, 32),
        children: [
          Text(ClassText.intro, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 8),
          Text(
            ClassText.privacy,
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
          const SizedBox(height: 16),
          if (backend == null)
            const Text(ClassText.noBackend)
          else if (backend.userId == null) ...[
            const Text(ClassText.needLogin),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('class-login'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountScreen(),
                  ),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.login),
              label: const Text('ログインする'),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('class-join'),
                    onPressed: () => _join(),
                    icon: const Icon(Icons.login),
                    label: const Text('コードで入る'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('class-create'),
                    onPressed: _create,
                    icon: const Icon(Icons.group_add),
                    label: const Text('クラスを作る'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('入っているクラス', style: serif(16)),
            const SizedBox(height: 6),
            if (rooms == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rooms.isEmpty)
              Text(
                'まだありません。友だちからコードを教えてもらうか、クラスを作ってコードを配りましょう。',
                style: TextStyle(color: TsuzuriColors.inkSoft),
              )
            else
              for (final MapEntry(key: code, value: room) in rooms.entries)
                _roomTile(code, room),
          ],
        ],
      ),
    );
  }

  Widget _roomTile(String code, Classroom? room) {
    final services = RpgServices.of(context);
    final uid = services.classrooms?.userId;
    if (room == null || !room.isMember(uid)) {
      return Card(
        child: ListTile(
          title: Text('コード $code'),
          subtitle: const Text('見つからないか、メンバーから外れました'),
          trailing: TextButton(
            onPressed: () async {
              await services.classroomStore.forget(code);
              _load();
            },
            child: const Text('一覧から消す'),
          ),
        ),
      );
    }
    final next = room.upcoming(DateTime.now());
    return Card(
      child: ListTile(
        key: ValueKey('class-room-$code'),
        leading: const Icon(Icons.groups),
        title: Text(room.name),
        subtitle: Text(
          next.isEmpty
              ? 'メンバー ${room.members.length}人　これからの範囲はまだありません'
              : 'メンバー ${room.members.length}人　次：${_taskLine(next.first)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(code),
      ),
    );
  }
}

String _taskLine(ClassTask t, {DateTime? now}) {
  final d = t.daysLeft(now ?? DateTime.now());
  final when = d == 0 ? '今日' : (d == 1 ? '明日' : 'あと$d日');
  final name = t.title.isEmpty ? t.kind.label : t.title;
  return '$name（${t.date.month}/${t.date.day}・$when）';
}

/// 1つのクラス
class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({super.key, required this.code});
  final String code;

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  late String _code = widget.code;

  ClassroomBackend get _backend => RpgServices.of(context).classrooms!;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _guard(Future<void> Function() f) async {
    try {
      await f();
    } on ClassroomException catch (e) {
      _snack(e.message);
    }
  }

  String _inviteText(Classroom r) =>
      'つづりクエストのクラス「${r.name}」に入ろう！\nコード：${r.code}\n'
      'https://tsuzuri-quest-v2.web.app/?class=${r.code}';

  /// 範囲の学習（今日の分・最終チェック）
  Future<void> _study(Classroom room, ClassTask task, VocabBook book) async {
    final services = RpgServices.of(context);
    final store = VocabStore.of(services.personalBooks);
    final cards = task.cardsIn(book);
    final now = DateTime.now();
    var tasks = ClassPlanner.today(task, cards, store.progress(book.id), now);
    var label = task.daysLeft(now) <= 1 ? '最終チェック' : '今日の分';
    if (tasks.isEmpty) {
      // 今日の分は終わった：もっとやりたい人は、範囲から20問
      tasks = VocabPlanner.drill(cards, VocabMode.choiceMeaning, count: 20);
      label = 'おかわり';
    }
    final backend = _backend;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VocabSessionScreen(
          store: store,
          book: book,
          title: '${task.title.isEmpty ? task.kind.label : task.title} $label',
          tasks: tasks,
          onFinished: (correct) {
            // 正解した数で、共闘ボスを削る（通信できなければ、あとで送る）
            unawaited(
              services.classroomStore.contribute(
                backend,
                room.code,
                task.id,
                correct,
              ),
            );
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editTask(Classroom room, [ClassTask? old]) async {
    final services = RpgServices.of(context);
    final books = [
      for (final b in VocabStore.of(services.personalBooks).visibleBooks)
        if (b.cards.any((c) => c.number != null)) b,
    ];
    if (books.isEmpty && old == null) {
      _snack('番号つきの単語帳がありません。先に単語帳を開いてください');
      return;
    }
    final result = await showDialog<ClassTask>(
      context: context,
      builder: (_) => _TaskDialog(books: books, old: old),
    );
    if (result == null) return;
    final tasks = [
      for (final t in room.tasks)
        if (t.id != result.id) t,
      result,
    ]..sort((a, b) => a.date.compareTo(b.date));
    // 終わった範囲が多すぎるときは、古いものから消す
    while (tasks.length > Classroom.maxTasks) {
      tasks.removeAt(0);
    }
    await _guard(() => _backend.saveTasks(room.code, tasks));
  }

  Future<void> _deleteTask(Classroom room, ClassTask task) async {
    final ok = await _confirm(
      '「${task.title}」を消しますか？',
      '範囲を消すと、メンバー全員の画面から消えます。',
    );
    if (!ok) return;
    await _guard(
      () => _backend.saveTasks(room.code, [
        for (final t in room.tasks)
          if (t.id != task.id) t,
      ]),
    );
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('やめる'),
            ),
            FilledButton(
              key: const ValueKey('class-confirm-ok'),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('OK'),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _menu(Classroom room, String action) async {
    final services = RpgServices.of(context);
    switch (action) {
      case 'members':
        await showDialog<void>(
          context: context,
          builder: (_) => _MembersDialog(
            room: room,
            me: _backend.userId,
            onRemove: (uid) => _guard(() => _backend.remove(room.code, uid)),
          ),
        );
      case 'rename':
        final name = TextEditingController(text: room.name);
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('クラスの名前'),
            content: TextField(controller: name, maxLength: Classroom.maxName),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('やめる'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('変える'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await _guard(() => _backend.rename(room.code, name.text));
        }
      case 'renew':
        if (!await _confirm(
          'コードを作り直しますか？',
          '今のコードでは、もう新しく入れなくなります。メンバーと範囲は新しいコードに引きつぎます。',
        )) {
          return;
        }
        await _guard(() async {
          final next = await _backend.renew(room.code);
          await services.classroomStore.rename(room.code, next);
          if (mounted) setState(() => _code = next);
          _snack('新しいコード：$next');
        });
      case 'close':
        if (!await _confirm(
          'クラスを閉じますか？',
          '新しく入れなくなります。今のメンバーは、範囲を見ることはできます。',
        )) {
          return;
        }
        await _guard(() => _backend.close(room.code));
      case 'leave':
        if (!await _confirm('クラスを抜けますか？', 'もう一度入るには、コードが必要です。')) {
          return;
        }
        await _guard(() async {
          await _backend.leave(room.code);
          await services.classroomStore.forget(room.code);
          if (mounted) Navigator.of(context).pop();
        });
      case 'report':
        await _report(room);
    }
  }

  Future<void> _report(Classroom room) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('このクラスを報告'),
        content: TextField(
          controller: note,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'いやな名前・いたずらなど、こまっていることを書いてください',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('やめる'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('送る'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await reportSink.send(
      QuestionReport(
        questionId: 'classroom:${room.code}',
        reason: 'クラスの報告',
        note: note.text.trim(),
        at: DateTime.now(),
      ),
    );
    _snack('報告しました。ありがとうございます');
  }

  @override
  Widget build(BuildContext context) {
    final backend = _backend;
    return StreamBuilder<Classroom?>(
      key: ValueKey(_code),
      stream: backend.watch(_code),
      builder: (context, snap) {
        final room = snap.data;
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(ClassText.title)),
            body: Center(
              child: snap.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : const Text('このクラスは見つかりません'),
            ),
          );
        }
        final uid = backend.userId;
        final owner = room.isOwner(uid);
        if (!room.isMember(uid)) {
          return Scaffold(
            appBar: AppBar(title: Text(room.name)),
            body: const Center(child: Text('このクラスのメンバーではありません')),
          );
        }
        return StreamBuilder<Map<String, int>>(
          stream: backend.watchBoss(room.code),
          builder: (context, bossSnap) =>
              _page(room, owner, bossSnap.data ?? const {}),
        );
      },
    );
  }

  /// 記録した結果（自分だけに見える）
  String _resultLabel(Classroom room, ClassTask t) {
    final r = RpgServices.of(context).classroomStore.result(room.code, t.id);
    if (r == null) return '\nタップして、本番の点数を記録（自分だけに見えます）';
    return '\n覚えた単語 ${r.learned}/${r.size} → 本番 ${r.score}/${r.max}点';
  }

  /// 本番の点数を記録する。そのとき覚えていた単語の数と並べて残す
  Future<void> _recordResult(
    Classroom room,
    ClassTask t,
    List<VocabBook> books,
  ) async {
    final services = RpgServices.of(context);
    final store = services.classroomStore;
    final old = store.result(room.code, t.id);
    final score = TextEditingController(
      text: old == null ? '' : '${old.score}',
    );
    final max = TextEditingController(text: '${old?.max ?? 10}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('「${t.title.isEmpty ? t.kind.label : t.title}」は何点だった？'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('class-result-score'),
                controller: score,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '点数'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey('class-result-max'),
                controller: max,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '満点'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            key: const ValueKey('class-result-save'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('記録する'),
          ),
        ],
      ),
    );
    // 入力欄は、閉じる動きが終わってから捨てる（すぐ捨てると、閉じる途中で使われる）
    final s = int.tryParse(score.text.trim());
    final m = int.tryParse(max.text.trim());
    Future<void>.delayed(const Duration(seconds: 1), () {
      score.dispose();
      max.dispose();
    });
    if (ok != true || s == null || m == null || m <= 0 || s < 0 || s > m) {
      return;
    }
    final vocab = VocabStore.of(services.personalBooks);
    final book = ClassBooks.match(t, books);
    final cards = book == null ? const <VocabCard>[] : t.cardsIn(book);
    final learned = book == null
        ? 0
        : ClassPlanner.learnedCount(
            cards,
            vocab.progress(book.id),
            DateTime.now(),
          );
    await store.setResult(
      room.code,
      t.id,
      ClassResult(s, m, old?.learned ?? learned, old?.size ?? cards.length),
    );
    if (mounted) setState(() {});
  }

  Widget _page(Classroom room, bool owner, Map<String, int> boss) {
    final now = DateTime.now();
    final services = RpgServices.of(context);
    final books = VocabStore.of(services.personalBooks).visibleBooks;
    final upcoming = room.upcoming(now);
    final past = [
      for (final t in room.tasks)
        if (t.over(now)) t,
    ]..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(
        title: Text(room.name, style: serif(18)),
        actions: [
          PopupMenuButton<String>(
            key: const ValueKey('class-menu'),
            onSelected: (v) => _menu(room, v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'members', child: Text('メンバー')),
              if (owner) ...[
                const PopupMenuItem(value: 'rename', child: Text('名前を変える')),
                const PopupMenuItem(value: 'renew', child: Text('コードを作り直す')),
                if (!room.closed)
                  const PopupMenuItem(value: 'close', child: Text('クラスを閉じる')),
              ] else
                const PopupMenuItem(value: 'leave', child: Text('クラスを抜ける')),
              const PopupMenuItem(value: 'report', child: Text('報告する')),
            ],
          ),
        ],
      ),
      floatingActionButton: owner
          ? FloatingActionButton.extended(
              key: const ValueKey('class-add-task'),
              onPressed: () => _editTask(room),
              icon: const Icon(Icons.add),
              label: const Text('範囲を追加'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(40, 12, 16, 96),
        children: [
          _codeCard(room),
          const SizedBox(height: 12),
          if (upcoming.isEmpty)
            Text(
              owner
                  ? '「範囲を追加」から、小テストや定期テストの範囲と日付を入れましょう。'
                  : 'まだ範囲がありません。作った人が範囲を入れるのを待ちましょう。',
              style: TextStyle(color: TsuzuriColors.inkSoft),
            )
          else
            for (final t in upcoming)
              _taskCard(room, t, books, boss[t.id] ?? 0, owner),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('終わった範囲', style: serif(15)),
            for (final t in past.take(5))
              ListTile(
                dense: true,
                title: Text(t.title.isEmpty ? t.kind.label : t.title),
                subtitle: Text(
                  '${t.bookTitle} ${t.from}〜${t.to}　${t.date.month}/${t.date.day}'
                  '　共闘ボス ${_bossLabel(t, room, boss[t.id] ?? 0)}'
                  '${_resultLabel(room, t)}',
                ),
                onTap: () => _recordResult(room, t, books),
                trailing: owner
                    ? IconButton(
                        tooltip: '消す',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTask(room, t),
                      )
                    : null,
              ),
          ],
        ],
      ),
    );
  }

  String _bossLabel(ClassTask t, Classroom room, int dealt) =>
      ClassBoss.hpLeft(t, room.members.length, dealt) == 0
      ? 'たおした！'
      : '残り ${ClassBoss.hpLeft(t, room.members.length, dealt)}';

  Widget _codeCard(Classroom room) => Card(
    color: TsuzuriColors.tint(0xFFFFF8E1),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'コード ${room.code}',
                  key: const ValueKey('class-code'),
                  style: serif(20),
                ),
                Text(
                  room.closed
                      ? '閉じています（新しく入れません）'
                      : 'メンバー ${room.members.length}/${Classroom.maxMembers}人'
                            '${room.expiresAt == null ? '' : '　${room.expiresAt!.month}/${room.expiresAt!.day}まで有効'}',
                  style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
                ),
              ],
            ),
          ),
          if (!room.closed)
            TextButton.icon(
              key: const ValueKey('class-copy'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _inviteText(room)));
                _snack('招待の文をコピーしました。LINE などに貼ってください');
              },
              icon: const Icon(Icons.copy),
              label: const Text('招待をコピー'),
            ),
        ],
      ),
    ),
  );

  Widget _taskCard(
    Classroom room,
    ClassTask t,
    List<VocabBook> books,
    int dealt,
    bool owner,
  ) {
    final now = DateTime.now();
    final services = RpgServices.of(context);
    final book = ClassBooks.match(t, books);
    final store = VocabStore.of(services.personalBooks);
    final active = t.active(now);
    final hp = ClassBoss.maxHp(t, room.members.length);
    final left = ClassBoss.hpLeft(t, room.members.length, dealt);
    final mine = services.classroomStore.mine(room.code, t.id);
    Widget body;
    if (book == null) {
      body = Text(
        'この範囲は「${t.bookTitle}」の単語帳で出題します。'
        '単語帳の画面で「${t.bookTitle}」を開く（取り込む）と、ここから練習できます。',
        style: TextStyle(color: TsuzuriColors.inkSoft),
      );
    } else {
      final cards = t.cardsIn(book);
      final learned = ClassPlanner.learnedCount(
        cards,
        store.progress(book.id),
        now,
      );
      final plan = ClassPlanner.today(
        t,
        cards,
        store.progress(book.id),
        now,
      ).length;
      final last = t.daysLeft(now) <= 1;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('覚えた単語 $learned / ${cards.length}'),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: cards.isEmpty ? 0 : learned / cards.length,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: ValueKey('class-study-${t.id}'),
            onPressed: () => _study(room, t, book),
            icon: Icon(last ? Icons.flag : Icons.play_arrow),
            label: Text(
              !active
                  ? '先に始める（$plan問）'
                  : plan == 0
                  ? '今日の分は終わり！（おかわり20問）'
                  : last
                  ? '最終チェック（$plan問）'
                  : '今日の分（$plan問）',
            ),
          ),
          // 同じ範囲で友だちと早押し（リンクで送る）
          TextButton.icon(
            key: ValueKey('class-duel-${t.id}'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    DuelHubScreen(bookId: book.id, from: t.from, to: t.to),
              ),
            ),
            icon: const Icon(Icons.flash_on, size: 18),
            label: const Text('この範囲で単語チャレンジ'),
          ),
        ],
      );
    }
    return Card(
      key: ValueKey('class-task-${t.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(t.kind.label),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _taskLine(t, now: now),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (owner)
                  PopupMenuButton<String>(
                    onSelected: (v) =>
                        v == 'edit' ? _editTask(room, t) : _deleteTask(room, t),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('なおす')),
                      PopupMenuItem(value: 'delete', child: Text('消す')),
                    ],
                  ),
              ],
            ),
            Text('${t.bookTitle}　${t.from}〜${t.to}（${t.size}語）'),
            if (!active && !t.over(now))
              Text(
                '${t.prepStart.month}/${t.prepStart.day}から毎日の分が出ます',
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
            const SizedBox(height: 8),
            body,
            const SizedBox(height: 10),
            // 共闘ボス：合計だけを出す（だれが何問かは出さない）
            Row(
              children: [
                const Text('👾 共闘ボス '),
                Expanded(
                  child: LinearProgressIndicator(
                    value: hp == 0 ? 0 : left / hp,
                    minHeight: 8,
                    color: const Color(0xFFB0413E),
                  ),
                ),
                const SizedBox(width: 6),
                Text(left == 0 ? 'たおした！' : '$left/$hp'),
              ],
            ),
            Text(
              'クラスの正解 合計$dealt問　あなた $mine問',
              key: ValueKey('class-boss-${t.id}'),
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

/// 範囲を追加・なおす
class _TaskDialog extends StatefulWidget {
  const _TaskDialog({required this.books, this.old});
  final List<VocabBook> books;
  final ClassTask? old;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late ClassTaskKind _kind = widget.old?.kind ?? ClassTaskKind.quiz;
  late final _title = TextEditingController(text: widget.old?.title ?? '');
  late VocabBook? _book = widget.old == null
      ? (widget.books.isEmpty ? null : widget.books.first)
      : ClassBooks.match(widget.old!, widget.books);
  late final _from = TextEditingController(
    text: widget.old?.from.toString() ?? '',
  );
  late final _to = TextEditingController(text: widget.old?.to.toString() ?? '');
  late DateTime _date =
      widget.old?.date ??
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day + 7,
      );
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _save() {
    final from = int.tryParse(_from.text.trim());
    final to = int.tryParse(_to.text.trim());
    final book = _book;
    final old = widget.old;
    String? err;
    if (book == null && old == null) err = '単語帳を選んでください';
    if (from == null || to == null || from < 1 || to < from) {
      err = '番号の範囲を正しく入れてください（例：1101〜1200）';
    } else if (to - from >= 2000) {
      err = '範囲が広すぎます（2000語まで）';
    } else if (book != null &&
        !book.cards.any(
          (c) => c.number != null && c.number! >= from && c.number! <= to,
        )) {
      err = 'その番号の単語が「${book.title}」にありません';
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(
      ClassTask(
        id: old?.id ?? 't${DateTime.now().millisecondsSinceEpoch}',
        kind: _kind,
        title: Classroom.cleanName(_title.text, fallback: _kind.label),
        bookKey: book == null ? old!.bookKey : ClassBooks.keyOf(book),
        bookTitle: book?.title ?? old!.bookTitle,
        from: from!,
        to: to!,
        date: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.old == null ? '範囲を追加' : '範囲をなおす'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<ClassTaskKind>(
              segments: const [
                ButtonSegment(value: ClassTaskKind.quiz, label: Text('小テスト')),
                ButtonSegment(value: ClassTaskKind.exam, label: Text('定期テスト')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              _kind == ClassTaskKind.quiz ? '1週間前から毎日の分が出ます' : '2週間前から毎日の分が出ます',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            TextField(
              key: const ValueKey('class-task-title'),
              controller: _title,
              maxLength: Classroom.maxName,
              decoration: const InputDecoration(labelText: '名前（例：第7回 単語テスト）'),
            ),
            if (widget.books.isNotEmpty)
              DropdownButtonFormField<VocabBook>(
                initialValue: _book,
                decoration: const InputDecoration(labelText: '単語帳'),
                items: [
                  for (final b in widget.books)
                    DropdownMenuItem(value: b, child: Text(b.title)),
                ],
                onChanged: (b) => setState(() => _book = b),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('class-task-from'),
                    controller: _from,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '番号（から）'),
                  ),
                ),
                const Text('〜'),
                Expanded(
                  child: TextField(
                    key: const ValueKey('class-task-to'),
                    controller: _to,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '番号（まで）'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('class-task-date'),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: DateTime(now.year + 1, now.month, now.day),
                );
                if (d != null) setState(() => _date = d);
              },
              icon: const Icon(Icons.event),
              label: Text('試験日：${_date.year}/${_date.month}/${_date.day}'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('やめる'),
        ),
        FilledButton(
          key: const ValueKey('class-task-save'),
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// メンバー（ニックネームだけ。作った人は外せる）
class _MembersDialog extends StatelessWidget {
  const _MembersDialog({
    required this.room,
    required this.me,
    required this.onRemove,
  });
  final Classroom room;
  final String? me;
  final Future<void> Function(String uid) onRemove;

  @override
  Widget build(BuildContext context) {
    final owner = room.isOwner(me);
    return AlertDialog(
      title: Text('メンバー（${room.members.length}人）'),
      content: SizedBox(
        width: 320,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final MapEntry(key: uid, value: name) in room.members.entries)
              ListTile(
                dense: true,
                leading: Icon(
                  uid == room.ownerId ? Icons.star : Icons.person_outline,
                ),
                title: Text('$name${uid == me ? '（あなた）' : ''}'),
                trailing: owner && uid != room.ownerId
                    ? TextButton(
                        onPressed: () async {
                          await onRemove(uid);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('外す'),
                      )
                    : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('とじる'),
        ),
      ],
    );
  }
}
