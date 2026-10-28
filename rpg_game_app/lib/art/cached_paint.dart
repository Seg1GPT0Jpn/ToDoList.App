import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 動かない絵（ぼかし・影の多い絵）を、1度だけ画像にして表示する。
///
/// CustomPaint のままだと、まわりに動くものがあるたびに描き直されて重くなるため。
/// [cacheKey] が変わったとき（ロックが外れたなど）だけ描き直す。
class CachedPaint extends StatefulWidget {
  const CachedPaint({super.key, required this.painter, required this.cacheKey});

  final CustomPainter painter;
  final Object cacheKey;

  @override
  State<CachedPaint> createState() => _CachedPaintState();
}

class _CachedPaintState extends State<CachedPaint> {
  ui.Image? _image;
  Size? _size;
  Object? _key;
  double _dpr = 0;
  int _serial = 0;

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _render(Size size, double dpr) async {
    final serial = ++_serial;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec)..scale(dpr);
    widget.painter.paint(c, size);
    final img = await rec.endRecording().toImage(
      (size.width * dpr).ceil(),
      (size.height * dpr).ceil(),
    );
    if (!mounted || serial != _serial) {
      img.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = img;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        if (size != _size || widget.cacheKey != _key || dpr != _dpr) {
          _size = size;
          _key = widget.cacheKey;
          _dpr = dpr;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _render(size, dpr);
          });
        }
        final img = _image;
        if (img == null) {
          return CustomPaint(size: size, painter: widget.painter);
        }
        return RawImage(
          image: img,
          width: size.width,
          height: size.height,
          fit: BoxFit.fill,
        );
      },
    );
  }
}
