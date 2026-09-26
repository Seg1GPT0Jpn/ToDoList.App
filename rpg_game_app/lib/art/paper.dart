import 'package:flutter/widgets.dart';

import '../app/theme.dart';

/// ノートの紙（罫線＋赤い余白線）の背景。
class NotebookPaper extends StatelessWidget {
  const NotebookPaper({super.key, this.child, this.lineGap = 28});

  final Widget? child;
  final double lineGap;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PaperPainter(lineGap), child: child);
}

class _PaperPainter extends CustomPainter {
  _PaperPainter(this.gap);
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = TsuzuriColors.paper);
    final line = Paint()
      ..color = TsuzuriColors.gridLine
      ..strokeWidth = 1;
    for (var y = gap * 2; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    canvas.drawLine(
      const Offset(28, 0),
      Offset(28, size.height),
      Paint()
        ..color = TsuzuriColors.marginLine
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PaperPainter old) => old.gap != gap;
}
