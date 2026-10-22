import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rpg_game/rpg_game.dart';

import '../app/theme.dart';

/// 学校の配布資料（要点まとめなど）を、ページごとにめくって見る。
/// ピンチで拡大できる。ページは開いたときに読み込む
class SchoolMaterialScreen extends StatefulWidget {
  const SchoolMaterialScreen({super.key, required this.material});

  final SchoolMaterial material;

  /// 同梱ファイルを読む（テストで差しかえる）
  static Future<List<int>> Function(String asset) loader = (asset) async =>
      (await rootBundle.load(asset)).buffer.asUint8List();

  @override
  State<SchoolMaterialScreen> createState() => _SchoolMaterialScreenState();
}

class _SchoolMaterialScreenState extends State<SchoolMaterialScreen> {
  final _controller = PageController();
  final Map<int, Future<Uint8List?>> _pages = {};
  var _page = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Uint8List?> _load(int page) => _pages[page] ??= () async {
    try {
      return SchoolMaterials.open(
        await SchoolMaterialScreen.loader(widget.material.asset(page)),
      );
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
          decoration: InputDecoration(suffixText: '/ ${widget.material.pages}'),
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
    _controller.jumpToPage(n.clamp(1, widget.material.pages) - 1);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.material;
    return Scaffold(
      appBar: AppBar(
        title: Text(m.title, style: serif(15), maxLines: 2),
        actions: [
          TextButton(
            key: const ValueKey('material-page'),
            onPressed: _jump,
            child: Text('$_page / ${m.pages}'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF5A5148),
      body: PageView.builder(
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
