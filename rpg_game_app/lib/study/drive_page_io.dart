import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

/// スマホ版：ドライブの埋め込み用ページを読んで、アプリの中に一覧を出す
Future<String?> fetchDrivePage(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(url);
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    return await res.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

/// スマホ版では埋め込まない（読んだ一覧を出す）
Widget? driveEmbed(Uri url) => null;
