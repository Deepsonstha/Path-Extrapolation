import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/path_state_model.dart';
import '../../domain/models/point_model.dart';
import '../cubit/path_cubit.dart';
import 'path_painter.dart';

class PathCanvas extends StatefulWidget {
  const PathCanvas({super.key});

  @override
  State<PathCanvas> createState() => _PathCanvasState();
}

class _PathCanvasState extends State<PathCanvas> with SingleTickerProviderStateMixin {
  int? _draggedPointIndex;
  PointType? _draggedPointType;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addListener(() {
        context.read<PathCubit>().updateAnimationProgress(_animationController.value);
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      context.read<PathCubit>().initializePoints(size);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PathCubit, PathStateModel>(
      listenWhen: (previous, current) => previous.animateCircles != current.animateCircles,
      listener: (context, state) {
        if (state.animateCircles) {
          _animationController.repeat();
        } else {
          _animationController.stop();
          _animationController.reset();
        }
      },
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: BlocBuilder<PathCubit, PathStateModel>(
          builder: (context, state) {
            return CustomPaint(
              painter: PathPainter(state: state, geometryService: context.read<PathCubit>().getPathPoints),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final cubit = context.read<PathCubit>();
    final state = cubit.state;
    final position = details.localPosition;

    // Check candidate points
    for (int i = 0; i < state.candidatePoints.length; i++) {
      if (_isNearPoint(position, state.candidatePoints[i].position)) {
        setState(() {
          _draggedPointIndex = i;
          _draggedPointType = PointType.candidate;
        });
        cubit.setPointDragging(i, true, PointType.candidate);
        return;
      }
    }

    // Check regular points
    for (int i = 0; i < state.regularPoints.length; i++) {
      if (_isNearPoint(position, state.regularPoints[i].position)) {
        setState(() {
          _draggedPointIndex = i;
          _draggedPointType = PointType.regular;
        });
        cubit.setPointDragging(i, true, PointType.regular);
        return;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggedPointIndex != null && _draggedPointType != null) {
      context.read<PathCubit>().updatePointPosition(_draggedPointIndex!, details.localPosition, _draggedPointType!);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_draggedPointIndex != null && _draggedPointType != null) {
      context.read<PathCubit>().setPointDragging(_draggedPointIndex!, false, _draggedPointType!);
      setState(() {
        _draggedPointIndex = null;
        _draggedPointType = null;
      });
    }
  }

  bool _isNearPoint(Offset touch, Offset point) {
    return (touch - point).distance < AppConstants.hitTestRadius;
  }
}
