import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web 版：ブラウザからはドライブのページを読めない（ほかのサイトの中身は読めない決まり）
Future<String?> fetchDrivePage(Uri url) async => null;

/// Web 版：ドライブの一覧のページを、アプリの中にそのまま埋め込んで見せる
Widget? driveEmbed(Uri url) => HtmlElementView.fromTagName(
  tagName: 'iframe',
  onElementCreated: (e) {
    final f = e as web.HTMLIFrameElement;
    f.src = url.toString();
    f.style.border = 'none';
    f.style.width = '100%';
    f.style.height = '100%';
  },
);
