/// 公開された Google ドライブのフォルダの中身（ファイル一覧）。
///
/// API キーを使わず、ドライブの埋め込み用ページ（embeddedfolderview）の HTML から読む。
class DriveEntry {
  const DriveEntry({
    required this.id,
    required this.title,
    required this.url,
    required this.isFolder,
    this.modified = '',
  });

  final String id;
  final String title;

  /// ドライブで開くリンク
  final String url;
  final bool isFolder;

  /// 更新日時（ドライブの表示のまま。「11:29 pm」「Oct 22」など）
  final String modified;

  /// 拡張子（小文字。なければ空）
  String get extension {
    final i = title.lastIndexOf('.');
    return isFolder || i < 0 ? '' : title.substring(i + 1).toLowerCase();
  }
}

abstract final class DriveFolder {
  /// フォルダのリンクから id を取り出す（フォルダのリンクでなければ null）
  static String? idOf(String url) =>
      RegExp(r'/folders/([\w-]+)').firstMatch(url)?.group(1);

  /// 一覧を読むページ
  static Uri embedUrl(String folderId) => Uri.parse(
        'https://drive.google.com/embeddedfolderview?id=$folderId#list',
      );

  static final _entry = RegExp(
    r'<div class="flip-entry" id="entry-([\w-]+)"(.*?)(?=<div class="flip-entry" id="entry-|$)',
    dotAll: true,
  );
  static final _href = RegExp(r'<a href="([^"]+)"');
  static final _title = RegExp(r'<div class="flip-entry-title">(.*?)</div>');
  static final _modified = RegExp(
    r'<div class="flip-entry-last-modified">\s*<div>(.*?)</div>',
    dotAll: true,
  );

  /// 埋め込み用ページの HTML から一覧を作る（フォルダを先、名前の順）
  static List<DriveEntry> parse(String html) {
    final out = <DriveEntry>[];
    for (final m in _entry.allMatches(html)) {
      final id = m.group(1)!, body = m.group(2)!;
      final title = _title.firstMatch(body)?.group(1);
      if (title == null) continue;
      final href = _unescape(_href.firstMatch(body)?.group(1) ?? '');
      final isFolder = href.contains('/folders/');
      out.add(
        DriveEntry(
          id: id,
          title: _unescape(title.trim()),
          url: href.startsWith('https://')
              ? href
              : isFolder
                  ? 'https://drive.google.com/drive/folders/$id'
                  : 'https://drive.google.com/file/d/$id/view',
          isFolder: isFolder,
          modified:
              _unescape(_modified.firstMatch(body)?.group(1)?.trim() ?? ''),
        ),
      );
    }
    out.sort((a, b) {
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      return a.title.compareTo(b.title);
    });
    return out;
  }

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (m) => String.fromCharCode(int.parse(m.group(1)!)),
      );
}
