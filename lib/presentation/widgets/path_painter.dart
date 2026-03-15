import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/path_state_model.dart';

class PathPainter extends CustomPainter {
  final PathStateModel state;
  final List<Offset> Function() geometryService;

  PathPainter({required this.state, required this.geometryService});

  @override
  void paint(Canvas canvas, Size size) {
    final pathPoints = geometryService();

    if (pathPoints.length >= 2) {
      _drawPath(canvas, pathPoints);

      if (state.showCirclePacking) {
        _drawCirclePacking(canvas, pathPoints);
      }
    }

    if (state.showProjectionOverlay) {
      _drawProjectionOverlay(canvas);
    }

    _drawPoints(canvas);
  }

  void _drawPath(Canvas canvas, List<Offset> points) {
    final path = _generateSmoothPath(points);
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(path, paint);

    if (state.showClippingBoundary && points.isNotEmpty) {
      _drawEndpointMarker(canvas, points.last);
    }
  }

  void _drawCirclePacking(Canvas canvas, List<Offset> points) {
    final path = _generateSmoothPath(points);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final circleDiameter = AppConstants.circleRadius * 2;

    final circlePaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Start at radius distance so first circle edge touches path start
    double currentDistance = AppConstants.circleRadius;

    while (currentDistance <= totalLength) {
      final position = _getPointAtDistance(metrics, currentDistance);
      if (position != null) {
        // Handle animation if enabled
        final shouldDraw = !state.animateCircles || (currentDistance / totalLength) <= state.animationProgress;

        if (shouldDraw) {
          // Check if this is the last circle that needs clipping
          if (currentDistance + AppConstants.circleRadius > totalLength) {
            _drawClippedCircle(canvas, position, points.last, circlePaint, borderPaint);
          } else {
            canvas.drawCircle(position, AppConstants.circleRadius, circlePaint);
            canvas.drawCircle(position, AppConstants.circleRadius, borderPaint);
          }
        }
      }
      // Move to next circle position (edge-to-edge spacing)
      currentDistance += circleDiameter;
    }
  }

  // Clip the final circle at the path endpoint
  // This took some trial and error to get the clipping geometry right
  void _drawClippedCircle(Canvas canvas, Offset center, Offset pathEnd, Paint fillPaint, Paint borderPaint) {
    canvas.save();

    final clipPath = Path();
    final distanceToEnd = (pathEnd - center).distance;

    if (distanceToEnd < AppConstants.circleRadius) {
      // Calculate perpendicular line at endpoint
      final angle = (pathEnd - center).direction;
      final perpAngle1 = angle + 1.5708; // 90 degrees in radians
      final perpAngle2 = angle - 1.5708;

      final clipRadius = AppConstants.circleRadius * 2;
      final p1 = pathEnd + Offset(clipRadius * math.cos(perpAngle1), clipRadius * math.sin(perpAngle1));
      final p2 = pathEnd + Offset(clipRadius * math.cos(perpAngle2), clipRadius * math.sin(perpAngle2));

      // Create clip region: everything before the endpoint line
      clipPath.moveTo(center.dx - AppConstants.circleRadius * 2, center.dy - AppConstants.circleRadius * 2);
      clipPath.lineTo(center.dx + AppConstants.circleRadius * 2, center.dy - AppConstants.circleRadius * 2);
      clipPath.lineTo(center.dx + AppConstants.circleRadius * 2, center.dy + AppConstants.circleRadius * 2);
      clipPath.lineTo(center.dx - AppConstants.circleRadius * 2, center.dy + AppConstants.circleRadius * 2);
      clipPath.close();

      // Subtract the region beyond the endpoint
      clipPath.moveTo(p1.dx, p1.dy);
      clipPath.lineTo(pathEnd.dx, pathEnd.dy);
      clipPath.lineTo(p2.dx, p2.dy);
      clipPath.lineTo(p1.dx, p1.dy);
      clipPath.close();

      canvas.clipPath(clipPath, doAntiAlias: true);
    }

    // Draw the circle (will be clipped by the path)
    canvas.drawCircle(center, AppConstants.circleRadius, fillPaint);
    canvas.drawCircle(center, AppConstants.circleRadius, borderPaint);

    canvas.restore();
  }

  void _drawProjectionOverlay(Canvas canvas) {
    if (state.candidatePoints.isEmpty) return;

    final candidatePositions = state.candidatePoints.map((p) => p.position).toList();
    final bestFit = _computeBestFitLine(candidatePositions);

    // Draw the best-fit line extending across the canvas
    final linePaint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final lineExtension = 500.0;
    final lineStart = bestFit.origin - bestFit.direction * lineExtension;
    final lineEnd = bestFit.origin + bestFit.direction * lineExtension;
    canvas.drawLine(lineStart, lineEnd, linePaint);

    // Draw projection lines from each candidate to the best-fit line
    final projectionPaint = Paint()
      ..color = Colors.purple.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var point in candidatePositions) {
      final projected = _projectPointOntoLine(point, bestFit.origin, bestFit.direction);
      canvas.drawLine(point, projected, projectionPaint);

      // Mark the projected point on the line
      final projectedPointPaint = Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.fill;
      canvas.drawCircle(projected, 4, projectedPointPaint);
    }

    // Highlight the selected reduced point with a circle
    if (state.reducedPoint != null) {
      final highlightPaint = Paint()
        ..color = Colors.purple.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(state.reducedPoint!.position, 20, highlightPaint);
    }
  }

  void _drawPoints(Canvas canvas) {
    // Draw candidate points
    for (var point in state.candidatePoints) {
      _drawPoint(canvas, point.position, Colors.amber, AppConstants.candidatePointRadius);
    }

    // Draw reduced point
    if (state.reducedPoint != null) {
      _drawPoint(canvas, state.reducedPoint!.position, Colors.purple, AppConstants.pointRadius);
    }

    // Draw regular points
    for (var point in state.regularPoints) {
      _drawPoint(canvas, point.position, Colors.green, AppConstants.pointRadius);
    }
  }

  void _drawPoint(Canvas canvas, Offset position, Color color, double radius) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(position, radius, paint);
    canvas.drawCircle(position, radius, borderPaint);
  }

  void _drawEndpointMarker(Canvas canvas, Offset endpoint) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(endpoint, 8, paint);
    canvas.drawCircle(endpoint, 12, paint);
  }

  Path _generateSmoothPath(List<Offset> points) {
    if (points.isEmpty) return Path();
    if (points.length == 1) {
      return Path()..addOval(Rect.fromCircle(center: points[0], radius: 2));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      for (int j = 0; j <= AppConstants.pathSmoothness; j++) {
        final t = j / AppConstants.pathSmoothness;
        final point = _catmullRomPoint(p0, p1, p2, p3, t);
        path.lineTo(point.dx, point.dy);
      }
    }

    return path;
  }

  Offset _catmullRomPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    final x =
        0.5 * ((2 * p1.dx) + (-p0.dx + p2.dx) * t + (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 + (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    final y =
        0.5 * ((2 * p1.dy) + (-p0.dy + p2.dy) * t + (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 + (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }

  ({Offset origin, Offset direction}) _computeBestFitLine(List<Offset> points) {
    if (points.isEmpty) return (origin: Offset.zero, direction: const Offset(1, 0));
    if (points.length == 1) return (origin: points[0], direction: const Offset(1, 0));

    double sumX = 0, sumY = 0;
    for (var p in points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    final centroid = Offset(sumX / points.length, sumY / points.length);

    double sxx = 0, sxy = 0, syy = 0;
    for (var p in points) {
      final dx = p.dx - centroid.dx;
      final dy = p.dy - centroid.dy;
      sxx += dx * dx;
      sxy += dx * dy;
      syy += dy * dy;
    }

    final trace = sxx + syy;
    final det = sxx * syy - sxy * sxy;
    final lambda = trace / 2 + math.sqrt((trace * trace / 4 - det).abs());

    Offset direction;
    if (sxy.abs() > 1e-10) {
      direction = Offset(lambda - syy, sxy);
    } else if ((sxx - syy).abs() > 1e-10) {
      direction = sxx > syy ? const Offset(1, 0) : const Offset(0, 1);
    } else {
      direction = const Offset(1, 0);
    }

    final length = math.sqrt(direction.dx * direction.dx + direction.dy * direction.dy);
    direction = Offset(direction.dx / length, direction.dy / length);

    return (origin: centroid, direction: direction);
  }

  Offset _projectPointOntoLine(Offset point, Offset lineOrigin, Offset lineDirection) {
    final toPoint = point - lineOrigin;
    final projection = toPoint.dx * lineDirection.dx + toPoint.dy * lineDirection.dy;
    return lineOrigin + lineDirection * projection;
  }

  Offset? _getPointAtDistance(List<ui.PathMetric> metrics, double distance) {
    double accumulated = 0;
    for (var metric in metrics) {
      if (accumulated + metric.length >= distance) {
        final tangent = metric.getTangentForOffset(distance - accumulated);
        return tangent?.position;
      }
      accumulated += metric.length;
    }
    return null;
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => true;
}
