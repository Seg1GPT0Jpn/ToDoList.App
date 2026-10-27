import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';
import '../art/paper.dart';
import 'drive_page_io.dart' if (dart.library.js_interop) 'drive_page_web.dart';
import 'school_drive_screen.dart';

/// ドライブのフォルダの中身（ファイル一覧）をアプリの中で見る。
/// スマホ版は一覧を読んで並べ、フォルダはこの画面の中で開く。ファイルはドライブで開く。
/// Web 版はドライブの一覧のページを埋め込んで見せる
class SchoolDriveFolderScreen extends StatefulWidget {
  const SchoolDriveFolderScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;

  /// フォルダのリンク
  final String url;

  /// 一覧のページを読む（テストで差しかえる。null なら読めなかった）
  static Future<String?> Function(Uri url) fetcher = fetchDrivePage;

  /// 埋め込みで見せる（テストで差しかえる。null なら一覧を読む）
  static Widget? Function(Uri url) embed = driveEmbed;

  @override
  State<SchoolDriveFolderScreen> createState() =>
      _SchoolDriveFolderScreenState();
}

class _SchoolDriveFolderScreenState extends State<SchoolDriveFolderScreen> {
  late Future<List<DriveEntry>?> _entries = _load();

  String? get _id => DriveFolder.idOf(widget.url);

  Future<List<DriveEntry>?> _load() async {
    final id = _id;
    if (id == null) return null;
    try {
      final html = await SchoolDriveFolderScreen.fetcher(
        DriveFolder.embedUrl(id),
      );
      return html == null ? null : DriveFolder.parse(html);
    } catch (_) {
      return null;
    }
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() => _entries = f);
    await f;
  }

  void _openInDrive(String url) => openDriveUrl(context, url);

  void _tap(DriveEntry e) {
    if (e.isFolder) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SchoolDriveFolderScreen(title: e.title, url: e.url),
        ),
      );
    } else {
      _openInDrive(e.url);
    }
  }

  static IconData _icon(DriveEntry e) {
    if (e.isFolder) return Icons.folder_outlined;
    return switch (e.extension) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'png' || 'jpg' || 'jpeg' || 'heic' || 'webp' => Icons.image_outlined,
      'doc' || 'docx' || 'txt' => Icons.description_outlined,
      'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
      'ppt' || 'pptx' => Icons.slideshow_outlined,
      'mp3' || 'm4a' || 'wav' => Icons.audiotrack_outlined,
      'mp4' || 'mov' => Icons.movie_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  Widget _message(String text) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(text, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Center(
        child: OutlinedButton.icon(
          key: const ValueKey('drive-folder-open'),
          onPressed: () => _openInDrive(widget.url),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('ドライブで開く'),
        ),
      ),
    ],
  );

  Widget _list() => FutureBuilder<List<DriveEntry>?>(
    future: _entries,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final list = snap.data;
      return RefreshIndicator(
        onRefresh: _reload,
        child: list == null
            ? _message(
                '一覧を読みこめませんでした。\nインターネットにつながっているか確かめて、下に引っぱって読みなおしてください。',
              )
            : list.isEmpty
            ? _message('このフォルダは空です')
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  for (final e in list)
                    Card(
                      child: ListTile(
                        key: ValueKey('drive-entry-${e.id}'),
                        leading: Icon(_icon(e)),
                        title: Text(e.title),
                        subtitle: e.modified.isEmpty
                            ? null
                            : Text(
                                '更新 ${e.modified}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: TsuzuriColors.inkSoft,
                                ),
                              ),
                        trailing: Icon(
                          e.isFolder ? Icons.chevron_right : Icons.open_in_new,
                          size: e.isFolder ? null : 18,
                        ),
                        onTap: () => _tap(e),
                      ),
                    ),
                ],
              ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final id = _id;
    final embedded = id == null
        ? null
        : SchoolDriveFolderScreen.embed(DriveFolder.embedUrl(id));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: serif(17)),
        actions: [
          IconButton(
            key: const ValueKey('drive-folder-external'),
            tooltip: 'ドライブで開く',
            onPressed: () => _openInDrive(widget.url),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: embedded != null
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Text(
                    'ファイルをタップすると、新しいタブでドライブが開きます',
                    style: TextStyle(
                      fontSize: 11,
                      color: TsuzuriColors.inkSoft,
                    ),
                  ),
                ),
                Expanded(
                  child: ColoredBox(color: Colors.white, child: embedded),
                ),
              ],
            )
          : NotebookPaper(child: _list()),
    );
  }
}
