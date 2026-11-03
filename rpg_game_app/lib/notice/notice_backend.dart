import 'package:rpg_game/rpg_game.dart';

/// 管理者からのお知らせ（ホームに出す）。
///
/// [id] が変わると、前に「とじる」を押した人にもまた出る
class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    required this.body,
    this.linkUrl = '',
    this.linkLabel = '',
    this.testerSignup = false,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String body;

  /// ボタンで開くリンク（空なら出さない）
  final String linkUrl;
  final String linkLabel;

  /// 「テスターに申しこむ」ボタンを出すか
  final bool testerSignup;

  /// false ならだれにも出さない
  final bool enabled;

  static const maxTitle = 60;
  static const maxBody = 1000;

  /// Google Play のテスター募集のお知らせのひな形
  static const testerTemplate = AppNotice(
    id: '',
    title: 'Android 版のテスターを募集しています',
    body:
        'つづりクエストを Google Play で公開するために、テスター（12人以上・14日間）が必要です。\n'
        'Android のスマホを持っている人は、下の「テスターに申しこむ」から、スマホで使っている Gmail を送ってください。'
        '登録したら、テスト版の入れ方をお知らせします。\n'
        '※学校のアカウント（@gl.pen-kanagawa.ed.jp）では参加できないことがあるので、ふだんの Gmail でお願いします。',
    testerSignup: true,
  );

  Map<String, Object> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'linkUrl': linkUrl,
    'linkLabel': linkLabel,
    'testerSignup': testerSignup,
    'enabled': enabled,
  };

  static AppNotice? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    final id = m['id'];
    final title = m['title'];
    if (id is! String || id.isEmpty || title is! String) return null;
    return AppNotice(
      id: id,
      title: title,
      body: m['body'] is String ? m['body'] as String : '',
      linkUrl: m['linkUrl'] is String ? m['linkUrl'] as String : '',
      linkLabel: m['linkLabel'] is String ? m['linkLabel'] as String : '',
      testerSignup: m['testerSignup'] == true,
      enabled: m['enabled'] != false,
    );
  }

  AppNotice copyWith({
    String? id,
    String? title,
    String? body,
    String? linkUrl,
    String? linkLabel,
    bool? testerSignup,
    bool? enabled,
  }) => AppNotice(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    linkUrl: linkUrl ?? this.linkUrl,
    linkLabel: linkLabel ?? this.linkLabel,
    testerSignup: testerSignup ?? this.testerSignup,
    enabled: enabled ?? this.enabled,
  );
}

/// テスターの申しこみ
class TesterSignup {
  const TesterSignup({
    required this.uid,
    required this.email,
    required this.name,
    this.at,
  });

  final String uid;

  /// Google Play で使う Gmail
  final String email;
  final String name;
  final DateTime? at;

  /// Gmail の形か
  static bool validEmail(String s) =>
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
          .hasMatch(s.trim());
}

/// アプリへのフィードバック（意見・不具合の報告）
class AppFeedback {
  const AppFeedback({
    required this.school,
    required this.className,
    required this.nickname,
    required this.body,
    this.uid = '',
    this.platform = '',
    this.at,
  });

  /// 高校名（「湘南」か、その他で入れた名前）
  final String school;

  /// クラス（「1-1」〜「1-9」か、その他で入れたもの）
  final String className;
  final String nickname;
  final String body;

  /// 送った人（ログインしていなければ空）
  final String uid;

  /// web・android など
  final String platform;
  final DateTime? at;

  /// 選べる高校（小中学生版は「その他」だけ）
  static List<String> get schools => juniorEdition ? const [] : const ['湘南'];
  static const classes = [
    '1-1', '1-2', '1-3', '1-4', '1-5', '1-6', '1-7', '1-8', '1-9', //
  ];
  static const maxSchool = 40;
  static const maxClass = 20;
  static const maxNickname = 20;
  static const maxBody = 1000;

  Map<String, Object> toMap() => {
    'school': school,
    'class': className,
    'nickname': nickname,
    'body': body,
    'uid': uid,
    'platform': platform,
  };
}

/// お知らせとテスターの申しこみの保存先。
///
/// お知らせはだれでも読めて、書けるのは管理者だけ。
/// 申しこみは本人が自分の分だけ書けて、一覧を読めるのは管理者だけ
abstract class NoticeBackend {
  String? get userId;
  String? get email;

  bool get isAdmin => ContestRules.isAdmin(email);

  /// 今のお知らせ（なければ null）
  Future<AppNotice?> load();

  /// お知らせを保存する（管理者だけ）
  Future<void> save(AppNotice notice);

  /// 自分の申しこみ（まだなら null）
  Future<TesterSignup?> mySignup();

  /// テスターに申しこむ（ログインが必要。もう一度送ると書きかわる）
  Future<void> signup(String email, String name);

  /// 申しこみの一覧（管理者だけ。新しい順）
  Future<List<TesterSignup>> signups();

  /// フィードバックを送る（ログインしていなくても送れる）
  Future<void> sendFeedback(AppFeedback feedback);

  /// フィードバックの一覧（管理者だけ。新しい順）
  Future<List<AppFeedback>> feedbacks();
}

/// テストとサーバーのない版の、端末の中だけの保存先
class MemoryNoticeBackend extends NoticeBackend {
  MemoryNoticeBackend({this.userId, this.email, this.notice});

  @override
  String? userId;
  @override
  String? email;
  AppNotice? notice;
  final Map<String, TesterSignup> entries = {};

  @override
  Future<AppNotice?> load() async => notice;

  @override
  Future<void> save(AppNotice n) async {
    if (!isAdmin) throw StateError('お知らせを書けるのは管理者だけです');
    notice = n;
  }

  @override
  Future<TesterSignup?> mySignup() async =>
      userId == null ? null : entries[userId];

  @override
  Future<void> signup(String email, String name) async {
    final uid = userId;
    if (uid == null) throw StateError('ログインが必要です');
    entries[uid] = TesterSignup(
      uid: uid,
      email: email.trim(),
      name: name,
      at: DateTime.now(),
    );
  }

  final List<AppFeedback> sent = [];

  @override
  Future<void> sendFeedback(AppFeedback f) async => sent.add(
    AppFeedback(
      school: f.school,
      className: f.className,
      nickname: f.nickname,
      body: f.body,
      uid: userId ?? '',
      platform: f.platform,
      at: DateTime.now(),
    ),
  );

  @override
  Future<List<AppFeedback>> feedbacks() async {
    if (!isAdmin) throw StateError('一覧を見られるのは管理者だけです');
    return sent.reversed.toList();
  }

  @override
  Future<List<TesterSignup>> signups() async {
    if (!isAdmin) throw StateError('一覧を見られるのは管理者だけです');
    return entries.values.toList()
      ..sort((a, b) => (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0)));
  }
}
