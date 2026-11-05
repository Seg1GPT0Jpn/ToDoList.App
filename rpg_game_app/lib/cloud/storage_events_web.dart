import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web 版：同じブラウザのほかのタブ（つづりクエスト／Light）が保存したら知らせる
void onOtherTabSaved(void Function() callback) {
  try {
    web.window.addEventListener('storage', ((web.Event _) => callback()).toJS);
  } catch (_) {
    // 使えないブラウザでは、アプリにもどったときだけ読みなおす
  }
}
