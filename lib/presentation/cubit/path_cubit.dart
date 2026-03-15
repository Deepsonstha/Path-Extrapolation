import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/models/path_state_model.dart';
import '../../domain/models/point_model.dart';
import '../../domain/services/geometry_service.dart';

@injectable
class PathCubit extends Cubit<PathStateModel> {
  final GeometryService _geometryService;

  PathCubit(this._geometryService) : super(const PathStateModel());

  void initializePoints(Size canvasSize) {
    // Setup the 3 candidate points for the reduction algorithm
    // Positioned on the left side of the canvas
    final candidatePoints = [
      PointModel(position: Offset(canvasSize.width * 0.2, canvasSize.height * 0.3), type: PointType.candidate),
      PointModel(position: Offset(canvasSize.width * 0.25, canvasSize.height * 0.35), type: PointType.candidate),
      PointModel(position: Offset(canvasSize.width * 0.3, canvasSize.height * 0.32), type: PointType.candidate),
    ];

    // The 4 regular points that complete the 5-point path
    final regularPoints = [
      PointModel(position: Offset(canvasSize.width * 0.4, canvasSize.height * 0.5), type: PointType.regular),
      PointModel(position: Offset(canvasSize.width * 0.6, canvasSize.height * 0.4), type: PointType.regular),
      PointModel(position: Offset(canvasSize.width * 0.75, canvasSize.height * 0.6), type: PointType.regular),
      PointModel(position: Offset(canvasSize.width * 0.85, canvasSize.height * 0.5), type: PointType.regular),
    ];

    emit(state.copyWith(candidatePoints: candidatePoints, regularPoints: regularPoints));

    // Calculate the reduced point from candidates
    _computeReducedPoint();
  }

  // This runs the reduction algorithm to compute the purple point
  void _computeReducedPoint() {
    if (state.candidatePoints.isEmpty || state.regularPoints.isEmpty) return;

    // Extract positions from candidate points
    final candidatePositions = state.candidatePoints.map((p) => p.position).toList();

    // Use first regular point as reference (P2 in the spec)
    final referencePoint = state.regularPoints.first.position;

    // Run the reduction: project candidates, select farthest from P2
    final reducedPosition = _geometryService.selectReducedPoint(candidatePositions, referencePoint);

    emit(
      state.copyWith(
        reducedPoint: PointModel(position: reducedPosition, type: PointType.reduced),
      ),
    );
  }

  // Handle point dragging - updates happen in real-time
  void updatePointPosition(int index, Offset newPosition, PointType type) {
    switch (type) {
      case PointType.candidate:
        if (index >= 0 && index < state.candidatePoints.length) {
          final updatedPoints = List<PointModel>.from(state.candidatePoints);
          updatedPoints[index] = updatedPoints[index].copyWith(position: newPosition);
          emit(state.copyWith(candidatePoints: updatedPoints));
          // Recalculate reduced point when candidates move
          _computeReducedPoint();
        }
        break;
      case PointType.regular:
        if (index >= 0 && index < state.regularPoints.length) {
          final updatedPoints = List<PointModel>.from(state.regularPoints);
          updatedPoints[index] = updatedPoints[index].copyWith(position: newPosition);
          emit(state.copyWith(regularPoints: updatedPoints));
          // Reduced point depends on first regular point (P2)
          _computeReducedPoint();
        }
        break;
      case PointType.reduced:
        // Reduced point is computed, not draggable
        break;
    }
  }

  void setPointDragging(int index, bool isDragging, PointType type) {
    switch (type) {
      case PointType.candidate:
        if (index >= 0 && index < state.candidatePoints.length) {
          final updatedPoints = List<PointModel>.from(state.candidatePoints);
          updatedPoints[index] = updatedPoints[index].copyWith(isDragging: isDragging);
          emit(state.copyWith(candidatePoints: updatedPoints));
        }
        break;
      case PointType.regular:
        if (index >= 0 && index < state.regularPoints.length) {
          final updatedPoints = List<PointModel>.from(state.regularPoints);
          updatedPoints[index] = updatedPoints[index].copyWith(isDragging: isDragging);
          emit(state.copyWith(regularPoints: updatedPoints));
        }
        break;
      case PointType.reduced:
        break;
    }
  }

  void toggleProjectionOverlay() {
    emit(state.copyWith(showProjectionOverlay: !state.showProjectionOverlay));
  }

  void toggleCirclePacking() {
    emit(state.copyWith(showCirclePacking: !state.showCirclePacking));
  }

  void toggleClippingBoundary() {
    emit(state.copyWith(showClippingBoundary: !state.showClippingBoundary));
  }

  void toggleAnimation() {
    emit(state.copyWith(animateCircles: !state.animateCircles, animationProgress: 0.0));
  }

  void updateAnimationProgress(double progress) {
    emit(state.copyWith(animationProgress: progress));
  }

  // Returns the 5 points for path generation: 1 reduced + 4 regular
  List<Offset> getPathPoints() {
    if (state.reducedPoint == null) return [];
    return [
      state.reducedPoint!.position, // The computed reduced point (purple)
      ...state.regularPoints.map((p) => p.position), // The 4 regular points (green)
    ];
  }
}
