/// つづりクエスト 小中学生版としてビルドしているか（`--dart-define=TSUZURI_JUNIOR=true`）。
///
/// 小中学生版は、仕組みは高校生版と共通で、中身（ワールド・問題・学習体系・授業・物語）を
/// editions/junior/ のものに入れかえて作る。高校向けの機能（共通テスト・予想問題・LEAP など）は出さない。
/// const なので、使わない画面のプログラムはビルドに入らない
const bool juniorEdition = bool.fromEnvironment('TSUZURI_JUNIOR');
