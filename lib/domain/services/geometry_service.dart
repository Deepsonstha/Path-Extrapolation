import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/app_constants.dart';

@injectable
class GeometryService {
  /// Computes the best fit line through a set of points
  /// Using PCA approach - took me a while to get this right!
  /// Handles all edge cases: vertical, horizontal, inclined, collinear points
  ({Offset origin, Offset direction}) computeBestFitLine(List<Offset> points) {
    // Edge case: empty list
    if (points.isEmpty) {
      return (origin: Offset.zero, direction: const Offset(1, 0));
    }

    // Edge case: single point
    if (points.length == 1) {
      return (origin: points[0], direction: const Offset(1, 0));
    }

    // Edge case: two points - just use the direction between them
    if (points.length == 2) {
      final dir = points[1] - points[0];
      final len = math.sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
      if (len < 1e-10) {
        // Points are at same location
        return (origin: points[0], direction: const Offset(1, 0));
      }
      return (origin: Offset((points[0].dx + points[1].dx) / 2, (points[0].dy + points[1].dy) / 2), direction: Offset(dir.dx / len, dir.dy / len));
    }

    // First, find the center point (centroid)
    double sumX = 0;
    double sumY = 0;
    for (var p in points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    final centroid = Offset(sumX / points.length, sumY / points.length);

    // Now calculate covariance matrix components
    // This is basically measuring how the points spread out
    double sxx = 0;
    double sxy = 0;
    double syy = 0;

    for (var p in points) {
      final dx = p.dx - centroid.dx;
      final dy = p.dy - centroid.dy;
      sxx += dx * dx;
      sxy += dx * dy;
      syy += dy * dy;
    }

    // Edge case: all points at same location
    if (sxx < 1e-10 && syy < 1e-10) {
      return (origin: centroid, direction: const Offset(1, 0));
    }

    // Get the principal direction using eigenvalue calculation
    // Had to look this up - it's been a while since linear algebra class
    final trace = sxx + syy;
    final det = sxx * syy - sxy * sxy;

    // Edge case: handle numerical instability
    final discriminant = trace * trace / 4 - det;
    if (discriminant < 0) {
      // Shouldn't happen mathematically, but handle it anyway
      return (origin: centroid, direction: const Offset(1, 0));
    }

    final lambda = trace / 2 + math.sqrt(discriminant);

    Offset direction;

    // Handle different cases for finding the direction vector
    if (sxy.abs() > 1e-10) {
      // General case - inclined line
      direction = Offset(lambda - syy, sxy);
    } else if ((sxx - syy).abs() > 1e-10) {
      // Edge case: horizontal or vertical line
      direction = sxx > syy ? const Offset(1, 0) : const Offset(0, 1);
    } else {
      // Edge case: points form a circle or are collinear at 45 degrees
      direction = const Offset(1, 0);
    }

    // Normalize the direction vector to unit length
    final len = math.sqrt(direction.dx * direction.dx + direction.dy * direction.dy);

    // Edge case: zero-length direction vector
    if (len < 1e-10) {
      direction = const Offset(1, 0);
    } else {
      direction = Offset(direction.dx / len, direction.dy / len);
    }

    return (origin: centroid, direction: direction);
  }

  /// Projects a point onto a line (perpendicular projection)
  Offset projectPointOntoLine(Offset point, Offset lineOrigin, Offset lineDirection) {
    // Vector from line origin to the point
    final toPoint = point - lineOrigin;

    // Dot product gives us the scalar projection
    final projectionLength = toPoint.dx * lineDirection.dx + toPoint.dy * lineDirection.dy;

    // Scale the direction vector and add to origin
    return lineOrigin + lineDirection * projectionLength;
  }

  /// This is the reduction step - picks the point farthest from reference
  Offset selectReducedPoint(List<Offset> candidatePoints, Offset referencePoint) {
    if (candidatePoints.isEmpty) {
      return referencePoint; // fallback
    }

    // Get the best fit line through candidates
    final bestFit = computeBestFitLine(candidatePoints);

    // Project all candidates onto this line
    final projectedPoints = candidatePoints.map((p) => projectPointOntoLine(p, bestFit.origin, bestFit.direction)).toList();

    // Now find which projected point is farthest from the reference
    int maxIdx = 0;
    double maxDist = 0.0;

    for (int i = 0; i < projectedPoints.length; i++) {
      final dist = (projectedPoints[i] - referencePoint).distance;
      if (dist > maxDist) {
        maxDist = dist;
        maxIdx = i;
      }
    }

    return projectedPoints[maxIdx];
  }

  /// Generate smooth path using Catmull-Rom spline
  /// This creates a nice smooth curve through all the points
  /// Handles edge cases: straight lines (horizontal, vertical, inclined), bent paths
  Path generateSmoothPath(List<Offset> points) {
    // Edge case: no points
    if (points.isEmpty) return Path();

    // Edge case: single point
    if (points.length == 1) {
      return Path()..addOval(Rect.fromCircle(center: points[0], radius: 2));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // Edge case: two points - straight line (works for any orientation)
    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    // Check if points are collinear (straight, vertical, horizontal, inclined)
    if (_arePointsCollinear(points)) {
      // For straight lines, just connect with line segments
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }

    // Catmull-Rom spline for smooth curves
    for (int i = 0; i < points.length - 1; i++) {
      // Get control points (with boundary handling)
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      // Interpolate between p1 and p2
      for (int j = 0; j <= AppConstants.pathSmoothness; j++) {
        final t = j / AppConstants.pathSmoothness;
        final point = _catmullRom(p0, p1, p2, p3, t);
        path.lineTo(point.dx, point.dy);
      }
    }

    return path;
  }

  // Helper for Catmull-Rom interpolation
  Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    // The magic formula - don't ask me to derive this again
    final x =
        0.5 * ((2 * p1.dx) + (-p0.dx + p2.dx) * t + (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 + (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);

    final y =
        0.5 * ((2 * p1.dy) + (-p0.dy + p2.dy) * t + (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 + (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);

    return Offset(x, y);
  }

  /// Check if points are collinear (for detecting straight lines)
  /// This handles horizontal, vertical, and inclined straight paths
  bool _arePointsCollinear(List<Offset> points) {
    if (points.length < 3) return true;

    final p0 = points[0];
    final p1 = points[1];

    // Check each subsequent point
    for (int i = 2; i < points.length; i++) {
      final p2 = points[i];

      // Cross product: (p1 - p0) × (p2 - p0)
      // If zero, points are collinear
      final crossProduct = (p1.dx - p0.dx) * (p2.dy - p0.dy) - (p1.dy - p0.dy) * (p2.dx - p0.dx);

      // Allow small tolerance for floating point errors
      if (crossProduct.abs() > 1e-3) {
        return false;
      }
    }

    return true;
  }

  /// Calculate where to place circles along the path
  /// They need to be edge-to-edge with no gaps
  List<Offset> calculateCirclePositions(Path path, double circleRadius) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return [];

    // Get total path length
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final circleDiameter = circleRadius * 2;

    final positions = <Offset>[];

    // Start with the first circle at radius distance (so edge touches start)
    double currentDistance = circleRadius;

    while (currentDistance <= totalLength) {
      // Find the point at this distance along the path
      for (var metric in metrics) {
        if (currentDistance <= metric.length) {
          final tangent = metric.getTangentForOffset(currentDistance);
          if (tangent != null) {
            positions.add(tangent.position);
          }
          break;
        }
        currentDistance -= metric.length;
      }

      // Move to next circle position (edge-to-edge)
      currentDistance += circleDiameter;
    }

    return positions;
  }

  /// Get the total length of a path
  double getPathLength(Path path) {
    return path.computeMetrics().fold<double>(0, (sum, m) => sum + m.length);
  }

  /// Get a point at a specific distance along the path
  Offset? getPointAtDistance(Path path, double distance) {
    final metrics = path.computeMetrics().toList();
    double accumulated = 0;

    for (var metric in metrics) {
      if (accumulated + metric.length >= distance) {
        final tangent = metric.getTangentForOffset(distance - accumulated);
        return tangent?.position;
      }
      accumulated += metric.length;
    }

    return null; // Distance beyond path end
  }
}
