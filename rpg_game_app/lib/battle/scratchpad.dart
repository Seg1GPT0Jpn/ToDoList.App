import 'package:flutter/material.dart';

import '../app/theme.dart';

/// 計算用の手書きメモ。問題の上に半透明で重ね、指やペンで書ける。
///
/// 書いた線は [strokes] に入れる（呼び出し側が問題ごとに空にする）。
class ScratchpadOverlay extends StatefulWidget {
  const ScratchpadOverlay({
    super.key,
    required this.strokes,
    required this.onClose,
  });

  final List<List<Offset>> strokes;
  final VoidCallback onClose;

  @override
  State<ScratchpadOverlay> createState() => _ScratchpadOverlayState();
}

class _ScratchpadOverlayState extends State<ScratchpadOverlay> {
  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('scratchpad'),
      color: TsuzuriColors.tint(0xFFFFFDF7).withValues(alpha: 0.82),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) =>
                    setState(() => widget.strokes.add([d.localPosition])),
                onPanUpdate: (d) =>
                    setState(() => widget.strokes.last.add(d.localPosition)),
                child: CustomPaint(painter: _StrokePainter(widget.strokes)),
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              child: Text(
                '計算メモ（答えるときは「とじる」）',
                style: TextStyle(fontSize: 12, color: TsuzuriColors.inkSoft),
              ),
            ),
            Positioned(
              top: 0,
              right: 4,
              child: Row(
                children: [
                  TextButton.icon(
                    key: const ValueKey('scratchpad-clear'),
                    onPressed: () => setState(widget.strokes.clear),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('消す'),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('scratchpad-close'),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('とじる'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TsuzuriColors.ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 1.3, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  // 線は同じリストに足していくので、毎回描きなおす
  @override
  bool shouldRepaint(_StrokePainter old) => true;
}
