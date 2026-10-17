/// Web 以外：ホーム画面に追加する案内はいらない
PwaInfo pwaInfo() => const PwaInfo(ios: false, standalone: true);

class PwaInfo {
  const PwaInfo({required this.ios, required this.standalone});

  /// iPhone・iPad の Safari など
  final bool ios;

  /// ホーム画面から開いている（アプリのように全画面）
  final bool standalone;
}
