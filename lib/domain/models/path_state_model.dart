import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'point_model.dart';

part 'path_state_model.freezed.dart';

@freezed
class PathStateModel with _$PathStateModel {
  const factory PathStateModel({
    @Default([]) List<PointModel> candidatePoints,
    PointModel? reducedPoint,
    @Default([]) List<PointModel> regularPoints,
    @Default(true) bool showProjectionOverlay,
    @Default(true) bool showCirclePacking,
    @Default(true) bool showClippingBoundary,
    @Default(false) bool animateCircles,
    @Default(0.0) double animationProgress,
  }) = _PathStateModel;
}
