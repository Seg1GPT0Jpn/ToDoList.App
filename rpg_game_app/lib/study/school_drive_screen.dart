import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/services.dart';
import '../app/theme.dart';
import '../art/paper.dart';
import 'school_exam_store.dart';

/// 学校の Google ドライブ（予想問題・授業ノートなど）のフォルダを教科ごとに並べ、
/// タップでドライブを開く。中身はドライブのものをそのまま見るので、ファイルが
/// 増えればアプリを更新しなくても見られる。
/// リンクは学校のパスワードで開く（一度入れれば、この端末では覚えておく）
class SchoolDriveScreen extends StatefulWidget {
  const SchoolDriveScreen({super.key});

  /// リンクを開く（テストで差しかえる）
  static Future<bool> Function(Uri url) opener = (url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  /// 暗号化したリンク（テストで差しかえる）
  static String data = SchoolDrive.sealed;

  @override
  State<SchoolDriveScreen> createState() => _SchoolDriveScreenState();
}

class _SchoolDriveScreenState extends State<SchoolDriveScreen> {
  final _password = TextEditingController();
  List<SchoolDriveLink>? _links;
  bool _checking = false;
  String? _error;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final saved = _store.secret;
    if (saved != null) _try(saved, remember: false);
  }

  SchoolExamStore get _store =>
      SchoolExamStore.of(RpgServices.of(context).personalBooks);

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _try(String password, {required bool remember}) async {
    if (password.trim().isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final store = _store;
    // 鍵を作るのに少し時間がかかるので、くるくるを先に出す
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final links = SchoolDrive.open(
      SchoolMaterials.keyFor(password),
      data: SchoolDriveScreen.data,
    );
    if (links != null && remember) await store.saveSecret(password);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _links = links;
      if (links == null && remember) _error = 'パスワードがちがいます';
    });
  }

  Future<void> _open(SchoolDriveLink l) async {
    var ok = false;
    try {
      ok = await SchoolDriveScreen.opener(Uri.parse(l.url));
    } catch (_) {}
    if (ok || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('ドライブを開けませんでした')));
  }

  Widget _locked() => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('学校のパスワードで開きます', style: serif(16)),
          const SizedBox(height: 6),
          Text(
            '一度開けば、この端末では次から入れなくても開けます。',
            style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('drive-password'),
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'パスワード'),
            onSubmitted: (v) => _try(v, remember: true),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 12, color: TsuzuriColors.wrong),
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey('drive-unlock'),
              onPressed: _checking
                  ? null
                  : () => _try(_password.text, remember: true),
              child: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('開く'),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _list(List<SchoolDriveLink> links) {
    final out = <Widget>[];
    String? group;
    for (final l in links) {
      if (l.group.isNotEmpty && l.group != group) {
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
            child: Text(l.group, style: serif(15)),
          ),
        );
      }
      group = l.group;
      out.add(
        Card(
          child: ListTile(
            key: ValueKey('drive-link-${l.title}'),
            leading: const Icon(Icons.folder_shared_outlined),
            title: Text(l.title),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _open(l),
          ),
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final links = _links;
    return Scaffold(
      appBar: AppBar(title: Text('ドライブの資料', style: serif(17))),
      body: NotebookPaper(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              '予想問題・授業ノートなどを置いている Google ドライブのフォルダです。'
              'タップするとドライブが開きます（ファイルが増えても、ここからそのまま見られます）。',
              style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
            ),
            const SizedBox(height: 12),
            if (links == null)
              _checking && _store.secret != null
                  ? const Center(child: CircularProgressIndicator())
                  : _locked()
            else
              ..._list(links),
          ],
        ),
      ),
    );
  }
}
