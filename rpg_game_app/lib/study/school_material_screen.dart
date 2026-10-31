import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/services.dart';
import '../app/theme.dart';
import 'school_exam_store.dart';
import '../app/asset_path.dart';

/// 学校の配布資料（要点まとめなど）を、ページごとにめくって見る。
/// ピンチで拡大できる。ページは開いたときに読み込む。
/// 鍵のかかった資料は、学校のパスワードで開く（一度入れれば、この端末では覚えておく）
class SchoolMaterialScreen extends StatefulWidget {
  const SchoolMaterialScreen({super.key, required this.material});

  final SchoolMaterial material;

  /// 同梱ファイルを読む（テストで差しかえる）
  static Future<List<int>> Function(String asset) loader = loadAppAssetBytes;

  @override
  State<SchoolMaterialScreen> createState() => _SchoolMaterialScreenState();
}

class _SchoolMaterialScreenState extends State<SchoolMaterialScreen> {
  final _controller = PageController();
  final _password = TextEditingController();
  final Map<int, Future<Uint8List?>> _pages = {};
  var _page = 1;

  /// 鍵のかかった資料の鍵（まだなければ null）
  List<int>? _key;
  bool _checking = false;
  String? _error;
  var _started = false;

  SchoolMaterial get _m => widget.material;
  bool get _ready => !_m.locked || _key != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final saved = SchoolExamStore.of(RpgServices.of(context).personalBooks)
        .secret;
    if (_m.locked && saved != null) _tryKey(saved, remember: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _password.dispose();
    super.dispose();
  }

  /// パスワードで1ページ目が開けるか確かめ、開ければ鍵として使う
  Future<void> _tryKey(String password, {required bool remember}) async {
    if (password.trim().isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final store = SchoolExamStore.of(RpgServices.of(context).personalBooks);
    // 鍵を作るのに少し時間がかかるので、くるくるを先に出す
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final key = SchoolMaterials.keyFor(password);
    var ok = false;
    try {
      final raw = await SchoolMaterialScreen.loader(_m.asset(1));
      final page = SchoolMaterials.open(raw, key: key);
      ok = page != null && SchoolMaterials.looksLikeImage(page);
    } catch (_) {}
    if (!mounted) return;
    if (ok && remember) await store.saveSecret(password);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (ok) {
        _key = key;
      } else if (remember) {
        _error = 'パスワードがちがいます';
      }
    });
  }

  Future<Uint8List?> _load(int page) => _pages[page] ??= () async {
    try {
      final bytes = SchoolMaterials.open(
        await SchoolMaterialScreen.loader(_m.asset(page)),
        key: _key,
      );
      return bytes != null && SchoolMaterials.looksLikeImage(bytes)
          ? bytes
          : null;
    } catch (_) {
      return null;
    }
  }();

  Future<void> _jump() async {
    final input = TextEditingController(text: '$_page');
    final n = await showDialog<int>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ページへ移動'),
        content: TextField(
          controller: input,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(suffixText: '/ ${_m.pages}'),
          onSubmitted: (v) => Navigator.pop(c, int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('やめる'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, int.tryParse(input.text)),
            child: const Text('移動'),
          ),
        ],
      ),
    );
    input.dispose();
    if (n == null || !mounted) return;
    _controller.jumpToPage(n.clamp(1, _m.pages) - 1);
  }

  Widget _lockedBody() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('この資料にはパスワードが必要です', style: serif(16)),
              const SizedBox(height: 6),
              Text(
                '教科書や問題集の文章をふくむ資料なので、学校のパスワードで開きます。'
                '一度開けば、この端末では次から入れなくても開けます。',
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('material-password'),
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'パスワード'),
                onSubmitted: (v) => _tryKey(v, remember: true),
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
                  key: const ValueKey('material-unlock'),
                  onPressed: _checking
                      ? null
                      : () => _tryKey(_password.text, remember: true),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _m;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.title, style: serif(15), maxLines: 2),
        actions: [
          if (_ready)
            TextButton(
              key: const ValueKey('material-page'),
              onPressed: _jump,
              child: Text('$_page / ${m.pages}'),
            ),
        ],
      ),
      backgroundColor: const Color(0xFF5A5148),
      body: !_ready
          ? (_checking && _password.text.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _lockedBody())
          : PageView.builder(
              controller: _controller,
              itemCount: m.pages,
              onPageChanged: (i) => setState(() => _page = i + 1),
              itemBuilder: (context, i) => FutureBuilder<Uint8List?>(
                future: _load(i + 1),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final bytes = snap.data;
                  if (bytes == null) {
                    return const Center(
                      child: Text(
                        'このページを読めませんでした',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return InteractiveViewer(
                    maxScale: 5,
                    child: Center(
                      child: Image.memory(
                        bytes,
                        key: ValueKey('material-image-${i + 1}'),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
