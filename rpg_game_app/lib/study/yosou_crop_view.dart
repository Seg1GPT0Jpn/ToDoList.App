import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:rpg_game/rpg_game.dart';

import 'yosou_exam_store.dart';

/// 予想問題の原本のページ画像を開く鍵（学校のパスワードで予想問題を開いたときに入る）
abstract final class YosouImages {
  static List<int>? key;
  static final _files = <String, YosouExamFiles>{};
  static final _sizes = <String, Future<Size?>>{};

  static YosouExamFiles? files(String examId) {
    final k = key;
    final exam = YosouExams.byId(examId);
    if (k == null || exam == null) return null;
    final f = _files[examId];
    if (f != null && identical(f.key, k)) return f;
    return _files[examId] = YosouExamFiles(exam, k);
  }

  /// ページ画像と、その大きさ
  static Future<(Uint8List, Size)?> page(String examId, int page) async {
    final f = files(examId);
    if (f == null) return null;
    final bytes = await f.page(page);
    if (bytes == null) return null;
    final size = await (_sizes['$examId:$page'] ??= () async {
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final s = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        frame.image.dispose();
        return s;
      } catch (_) {
        return null;
      }
    }());
    return size == null ? null : (bytes, size);
  }
}

/// 原本の図・表・漢文などの切り抜き（タップで拡大）
class YosouCropView extends StatelessWidget {
  const YosouCropView(this.crop, {super.key, this.maxHeight});

  final YosouCrop crop;
  final double? maxHeight;

  Widget _clip(Uint8List bytes) => ClipRect(
    child: LayoutBuilder(
      builder: (context, bc) {
        final w = bc.maxWidth / (crop.right - crop.left);
        final h = bc.maxHeight / (crop.bottom - crop.top);
        return OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: w,
          maxWidth: w,
          minHeight: h,
          maxHeight: h,
          child: Transform.translate(
            offset: Offset(-crop.left * w, -crop.top * h),
            child: Image.memory(bytes, fit: BoxFit.fill, width: w, height: h),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(Uint8List, Size)?>(
      future: YosouImages.page(crop.examId, crop.page),
      builder: (context, snap) {
        final v = snap.data;
        if (v == null) {
          return SizedBox(
            height: 60,
            child: Center(
              child: snap.connectionState == ConnectionState.done
                  ? const Text('図を開けませんでした（学校のパスワードで予想問題を開いてください）')
                  : const CircularProgressIndicator(),
            ),
          );
        }
        final (bytes, size) = v;
        final aspect = crop.aspect(size.width / size.height);
        Widget box = AspectRatio(aspectRatio: aspect, child: _clip(bytes));
        if (maxHeight != null) {
          box = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight!),
            child: box,
          );
        }
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(title: const Text('拡大（ピンチで大きく）')),
                body: InteractiveViewer(
                  maxScale: 6,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: aspect,
                      child: _clip(bytes),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: Center(child: box),
        );
      },
    );
  }
}
