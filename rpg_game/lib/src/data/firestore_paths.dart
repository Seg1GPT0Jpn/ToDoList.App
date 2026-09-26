/// Firestore のパス定義（school_planner へ移植するときに使う）。
///
/// ここには Firebase の依存を入れず、文字列だけを持つ。
class RpgFirestorePaths {
  const RpgFirestorePaths._();

  /// 進行状況: users/{uid}/rpg_progress/main
  static const progressCollection = 'rpg_progress';
  static const progressDocId = 'main';

  /// 購入済みワールド: users/{uid}/rpg_purchases/{worldId}
  static const purchasesCollection = 'rpg_purchases';

  /// バトル履歴（任意・直近のみ）: users/{uid}/rpg_battle_logs/{autoId}
  static const battleLogsCollection = 'rpg_battle_logs';

  /// アカウント削除・バックアップ（account_deletion.dart / data_backup.dart）に
  /// 追加する users/{uid} 配下のサブコレクション。
  static const userSubcollections = [
    progressCollection,
    purchasesCollection,
    battleLogsCollection,
  ];

  /// 問題セットを Firestore から配信する場合（任意。初期はアプリ同梱の JSON）:
  /// rpg_worlds/{worldId}/question_sets/{setId}
  /// 全ユーザー共通の読み取り専用データなので、アカウント削除・バックアップの対象外。
  static const worldsCollection = 'rpg_worlds';
  static const questionSetsSubcollection = 'question_sets';

  static String progressDoc(String uid) =>
      'users/$uid/$progressCollection/$progressDocId';
  static String purchaseDoc(String uid, String worldId) =>
      'users/$uid/$purchasesCollection/$worldId';
  static String questionSetDoc(String worldId, String setId) =>
      '$worldsCollection/$worldId/$questionSetsSubcollection/$setId';
}
