import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_model.freezed.dart';

@freezed
class PointModel with _$PointModel {
  const factory PointModel({required Offset position, required PointType type, @Default(false) bool isDragging}) = _PointModel;
}

enum PointType { candidate, reduced, regular }
