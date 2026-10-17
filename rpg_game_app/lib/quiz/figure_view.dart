import 'dart:math';

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// 問題の図・グラフを描く（形式は rpg_game の FigureSpec）。
class FigureView extends StatelessWidget {
  const FigureView(this.spec, {super.key, this.height = 150});

  final Map<String, dynamic> spec;
  final double height;

  @override
  Widget build(BuildContext context) {
    final chart = spec['chart'];
    final double aspect = chart != null
        ? 1.8
        : (spec['w'] as num).toDouble() / (spec['h'] as num).toDouble();
    return SizedBox(
      height: height,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: CustomPaint(
            painter: chart == null
                ? _ShapePainter(spec, TsuzuriColors.ink)
                : _ChartPainter(spec, TsuzuriColors.ink),
          ),
        ),
      ),
    );
  }
}

List<double> _nums(Object? v) => [
  for (final e in v as List) (e as num).toDouble(),
];

void _label(
  Canvas c,
  String s,
  Offset at,
  Color color,
  double size, {
  bool center = true,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(fontSize: size, color: color, height: 1.1),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center ? at - Offset(tp.width / 2, tp.height / 2) : at);
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.spec, this.color);
  final Map<String, dynamic> spec;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = (spec['w'] as num).toDouble();
    final k = size.width / w;
    Offset p(double x, double y) => Offset(x * k, y * k);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final fill = Paint()..color = color.withValues(alpha: 0.12);
    for (final raw in spec['items'] as List) {
      final it = raw as Map<String, dynamic>;
      if (it.containsKey('text')) {
        final a = _nums(it['at']);
        _label(canvas, it['text'] as String, p(a[0], a[1]), color, 13);
        continue;
      }
      if (it['line'] != null) {
        final v = _nums(it['line']);
        final a = p(v[0], v[1]), b = p(v[2], v[3]);
        if (it['dash'] == true) {
          final d = (b - a).distance, dir = (b - a) / d;
          for (var s = 0.0; s < d; s += 8) {
            canvas.drawLine(a + dir * s, a + dir * min(s + 4, d), stroke);
          }
        } else {
          canvas.drawLine(a, b, stroke);
        }
      } else if (it['path'] != null || it['poly'] != null) {
        final v = _nums(it['path'] ?? it['poly']);
        final path = Path()..moveTo(p(v[0], v[1]).dx, p(v[0], v[1]).dy);
        for (var i = 2; i + 1 < v.length; i += 2) {
          final q = p(v[i], v[i + 1]);
          path.lineTo(q.dx, q.dy);
        }
        if (it['poly'] != null) {
          path.close();
          if (it['fill'] == true) canvas.drawPath(path, fill);
        }
        canvas.drawPath(path, stroke);
      } else if (it['circle'] != null) {
        final v = _nums(it['circle']);
        canvas.drawCircle(p(v[0], v[1]), v[2] * k, stroke);
      } else if (it['arc'] != null) {
        final v = _nums(it['arc']);
        canvas.drawArc(
          Rect.fromCircle(center: p(v[0], v[1]), radius: v[2] * k),
          v[3] * pi / 180,
          v[4] * pi / 180,
          false,
          stroke,
        );
      } else if (it['dot'] != null) {
        final v = _nums(it['dot']);
        canvas.drawCircle(p(v[0], v[1]), 3, Paint()..color = color);
      } else if (it['arrow'] != null) {
        final v = _nums(it['arrow']);
        final a = p(v[0], v[1]), b = p(v[2], v[3]);
        canvas.drawLine(a, b, stroke);
        final ang = atan2(b.dy - a.dy, b.dx - a.dx);
        for (final s in [-1, 1]) {
          canvas.drawLine(
            b,
            b - Offset.fromDirection(ang + s * 0.45, 8),
            stroke,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => old.spec != spec;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.spec, this.color);
  final Map<String, dynamic> spec;
  final Color color;

  static const _palette = [
    Color(0xFF3F7CAC),
    Color(0xFFD9822B),
    Color(0xFF3E9E6B),
    Color(0xFFB0413E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final labels = [for (final l in spec['labels'] as List) '$l'];
    final bar = spec['chart'] == 'bar';
    final series = bar
        ? [
            {'name': '', 'values': spec['values']},
          ]
        : [for (final s in spec['series'] as List) s as Map<String, dynamic>];
    final all = [for (final s in series) ..._nums(s['values'])];
    var lo = all.reduce(min), hi = all.reduce(max);
    if (bar || lo > 0) lo = min(0, lo);
    if (hi == lo) hi = lo + 1;
    final step = _niceStep((hi - lo) / 4);
    lo = (lo / step).floorToDouble() * step;
    hi = (hi / step).ceilToDouble() * step;

    const left = 40.0, bottom = 20.0, top = 16.0;
    final right = series.length > 1 ? 70.0 : 8.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    double y(double v) => plot.bottom - (v - lo) / (hi - lo) * plot.height;
    final axis = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    final grid = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var v = lo; v <= hi + step / 2; v += step) {
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), grid);
      _label(canvas, _fmt(v), Offset(plot.left - 4 - 14, y(v)), color, 10);
    }
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axis);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axis);
    final unit = spec['unit'] as String?;
    if (unit != null && unit.isNotEmpty) {
      _label(
        canvas,
        '($unit)',
        Offset(plot.left - 30, 0),
        color,
        10,
        center: false,
      );
    }
    final n = labels.length;
    final slot = plot.width / n;
    for (var i = 0; i < n; i++) {
      _label(
        canvas,
        labels[i],
        Offset(plot.left + slot * (i + 0.5), plot.bottom + 10),
        color,
        10,
      );
    }
    for (final (si, s) in series.indexed) {
      final vals = _nums(s['values']);
      final c = _palette[si % _palette.length];
      if (bar) {
        for (var i = 0; i < n; i++) {
          final x = plot.left + slot * (i + 0.2);
          canvas.drawRect(
            Rect.fromLTRB(x, y(vals[i]), x + slot * 0.6, y(0)),
            Paint()..color = c,
          );
        }
      } else {
        final path = Path();
        for (var i = 0; i < n; i++) {
          final pt = Offset(plot.left + slot * (i + 0.5), y(vals[i]));
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
          canvas.drawCircle(pt, 2.5, Paint()..color = c);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = c
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        if (series.length > 1) {
          final ly = plot.top + 14.0 * si;
          canvas.drawLine(
            Offset(plot.right + 6, ly),
            Offset(plot.right + 18, ly),
            Paint()
              ..color = c
              ..strokeWidth = 2,
          );
          _label(
            canvas,
            '${s['name']}',
            Offset(plot.right + 21, ly - 6),
            color,
            10,
            center: false,
          );
        }
      }
    }
  }

  static double _niceStep(double raw) {
    final mag = pow(10, (log(raw) / ln10).floor()).toDouble();
    for (final m in [1, 2, 5, 10]) {
      if (raw <= m * mag) return m * mag;
    }
    return 10 * mag;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.spec != spec;
}
