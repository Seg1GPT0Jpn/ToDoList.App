/// プレイヤーのプロフィール（ユーザー名と、連携した Google アカウント）。
///
/// school_planner へ移植するときは users/{uid}/rpg_profile/main に保存する。
/// Google アカウントの連携は Firebase Authentication（GoogleAuthProvider）で行い、
/// ここには表示用の情報だけを持つ（トークンなどの秘密情報は保存しない）。
class PlayerProfile {
  const PlayerProfile({
    this.userName = '',
    this.googleEmail,
    this.googleDisplayName,
    this.linkedAt,
  });

  static const empty = PlayerProfile();

  /// ユーザー名の最大文字数
  static const maxNameLength = 12;

  final String userName;

  /// 連携した Google アカウント（未連携なら null）
  final String? googleEmail;
  final String? googleDisplayName;
  final DateTime? linkedAt;

  bool get hasName => userName.isNotEmpty;
  bool get isGoogleLinked => googleEmail != null;

  /// 画面に出す名前
  String get displayName => hasName ? userName : '名無しの冒険者';

  /// ユーザー名の入力チェック。問題なければ null、だめなら理由を返す。
  static String? validateName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return '名前を入力してください';
    if (name.runes.length > maxNameLength) {
      return '$maxNameLength文字以内にしてください';
    }
    if (name.runes.any((r) => r < 0x20 || r == 0x7F)) {
      return '使えない文字が入っています';
    }
    if (RegExp(r'^[\s　]+$').hasMatch(name)) return '空白だけの名前は使えません';
    return null;
  }

  PlayerProfile copyWith({
    String? userName,
    String? googleEmail,
    String? googleDisplayName,
    DateTime? linkedAt,
    bool unlinkGoogle = false,
  }) =>
      PlayerProfile(
        userName: userName ?? this.userName,
        googleEmail: unlinkGoogle ? null : (googleEmail ?? this.googleEmail),
        googleDisplayName:
            unlinkGoogle ? null : (googleDisplayName ?? this.googleDisplayName),
        linkedAt: unlinkGoogle ? null : (linkedAt ?? this.linkedAt),
      );

  Map<String, dynamic> toMap() => {
        'userName': userName,
        if (googleEmail != null) 'googleEmail': googleEmail,
        if (googleDisplayName != null) 'googleDisplayName': googleDisplayName,
        if (linkedAt != null) 'linkedAt': linkedAt!.toIso8601String(),
      };

  factory PlayerProfile.fromMap(Map<String, dynamic> map) => PlayerProfile(
        userName: (map['userName'] as String?) ?? '',
        googleEmail: map['googleEmail'] as String?,
        googleDisplayName: map['googleDisplayName'] as String?,
        linkedAt: map['linkedAt'] == null
            ? null
            : DateTime.tryParse(map['linkedAt'] as String),
      );
}
