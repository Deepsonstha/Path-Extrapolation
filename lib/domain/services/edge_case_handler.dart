import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

/// Helper service to detect and handle edge cases in path configurations
@injectable
class EdgeCaseHandler {
  /// Detects if points form a straight line (horizontal, vertical, or inclined)
  PathType detectPathType(List<Offset> points) {
    if (points.length < 2) return PathType.single;
    if (points.length == 2) return PathType.straight;

    // Check if all points are collinear
    if (_arePointsCollinear(points)) {
      // Determine orientation
      final dx = (points.last.dx - points.first.dx).abs();
      final dy = (points.last.dy - points.first.dy).abs();

      if (dx < 1e-6) return PathType.vertical;
      if (dy < 1e-6) return PathType.horizontal;

      // Check if it's a perfect diagonal (45 degrees)
      if ((dx - dy).abs() < 1e-6) return PathType.diagonal;

      return PathType.inclined;
    }

    // Check for sharp bends
    if (_hasSharpBends(points)) return PathType.bent;

    return PathType.curved;
  }

  /// Check if points are collinear (lie on the same line)
  bool _arePointsCollinear(List<Offset> points) {
    if (points.length < 3) return true;

    // Use cross product to check collinearity
    // If all cross products are near zero, points are collinear
    final p0 = points[0];
    final p1 = points[1];

    for (int i = 2; i < points.length; i++) {
      final p2 = points[i];

      // Cross product: (p1 - p0) × (p2 - p0)
      final crossProduct = (p1.dx - p0.dx) * (p2.dy - p0.dy) - (p1.dy - p0.dy) * (p2.dx - p0.dx);

      // If cross product is not near zero, points are not collinear
      if (crossProduct.abs() > 1e-3) {
        return false;
      }
    }

    return true;
  }

  /// Check if path has sharp bends (angle > 90 degrees)
  bool _hasSharpBends(List<Offset> points) {
    if (points.length < 3) return false;

    for (int i = 1; i < points.length - 1; i++) {
      final v1 = points[i] - points[i - 1];
      final v2 = points[i + 1] - points[i];

      // Calculate angle using dot product
      final dotProduct = v1.dx * v2.dx + v1.dy * v2.dy;
      final mag1 = math.sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
      final mag2 = math.sqrt(v2.dx * v2.dx + v2.dy * v2.dy);

      if (mag1 > 0 && mag2 > 0) {
        final cosAngle = dotProduct / (mag1 * mag2);
        final angle = math.acos(cosAngle.clamp(-1.0, 1.0));

        // If angle is greater than 90 degrees (pi/2 radians)
        if (angle > math.pi / 2) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get angle of inclined line in degrees
  double getInclinationAngle(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    return math.atan2(dy, dx) * 180 / math.pi;
  }

  /// Check if path is too short for circle packing
  bool isPathTooShort(double pathLength, double circleRadius) {
    return pathLength < circleRadius * 2;
  }

  /// Validate that points are not all at the same location
  bool arePointsValid(List<Offset> points) {
    if (points.length < 2) return true;

    final first = points.first;
    for (var point in points.skip(1)) {
      if ((point - first).distance > 1e-6) {
        return true; // At least one point is different
      }
    }

    return false; // All points are at the same location
  }
}

enum PathType {
  single, // Single point
  straight, // Two points (straight line)
  horizontal, // Horizontal line
  vertical, // Vertical line
  diagonal, // 45-degree diagonal
  inclined, // Any other straight line
  bent, // Sharp bends
  curved, // Smooth curves
}
