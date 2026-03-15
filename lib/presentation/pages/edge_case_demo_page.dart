import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../domain/models/point_model.dart';
import '../cubit/path_cubit.dart';
import '../widgets/control_panel.dart';
import '../widgets/path_canvas.dart';

class EdgeCaseDemoPage extends StatelessWidget {
  const EdgeCaseDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PathCubit>(),
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(title: const Text('Edge Case Demonstrations'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: const PathCanvas()),
              ),
            ),
            const EdgeCaseControls(),
            const ControlPanel(),
          ],
        ),
      ),
    );
  }
}

class EdgeCaseControls extends StatelessWidget {
  const EdgeCaseControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          const Text('Test Edge Cases', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetButton(context, 'Horizontal', _setHorizontal),
              _buildPresetButton(context, 'Vertical', _setVertical),
              _buildPresetButton(context, 'Diagonal', _setDiagonal),
              _buildPresetButton(context, 'Inclined', _setInclined),
              _buildPresetButton(context, 'Sharp Bend', _setSharpBend),
              _buildPresetButton(context, 'S-Curve', _setSCurve),
              _buildPresetButton(context, 'Reset', _reset),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, String label, Function(BuildContext, Size) onPressed) {
    return ElevatedButton(
      onPressed: () {
        final size = MediaQuery.of(context).size;
        onPressed(context, size);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // Edge case: Horizontal straight line
  void _setHorizontal(BuildContext context, Size size) {
    final cubit = context.read<PathCubit>();
    final y = size.height * 0.5;

    // Set all points in a horizontal line
    cubit.updatePointPosition(0, Offset(size.width * 0.15, y), PointType.candidate);
    cubit.updatePointPosition(1, Offset(size.width * 0.20, y), PointType.candidate);
    cubit.updatePointPosition(2, Offset(size.width * 0.25, y), PointType.candidate);

    cubit.updatePointPosition(0, Offset(size.width * 0.35, y), PointType.regular);
    cubit.updatePointPosition(1, Offset(size.width * 0.50, y), PointType.regular);
    cubit.updatePointPosition(2, Offset(size.width * 0.65, y), PointType.regular);
    cubit.updatePointPosition(3, Offset(size.width * 0.80, y), PointType.regular);
  }

  // Edge case: Vertical straight line
  void _setVertical(BuildContext context, Size size) {
    final cubit = context.read<PathCubit>();
    final x = size.width * 0.5;

    cubit.updatePointPosition(0, Offset(x, size.height * 0.15), PointType.candidate);
    cubit.updatePointPosition(1, Offset(x, size.height * 0.20), PointType.candidate);
    cubit.updatePointPosition(2, Offset(x, size.height * 0.25), PointType.candidate);

    cubit.updatePointPosition(0, Offset(x, size.height * 0.35), PointType.regular);
    cubit.updatePointPosition(1, Offset(x, size.height * 0.50), PointType.regular);
    cubit.updatePointPosition(2, Offset(x, size.height * 0.65), PointType.regular);
    cubit.updatePointPosition(3, Offset(x, size.height * 0.80), PointType.regular);
  }

  // Edge case: Diagonal line (45 degrees)
  void _setDiagonal(BuildContext context, Size size) {
    final cubit = context.read<PathCubit>();

    cubit.updatePointPosition(0, Offset(size.width * 0.15, size.height * 0.15), PointType.candidate);
    cubit.updatePointPosition(1, Offset(size.width * 0.20, size.height * 0.20), PointType.candidate);
    cubit.updatePointPosition(2, Offset(size.width * 0.25, size.height * 0.25), PointType.candidate);

    cubit.updatePointPosition(0, Offset(size.width * 0.35, size.height * 0.35), PointType.regular);
    cubit.updatePointPosition(1, Offset(size.width * 0.50, size.height * 0.50), PointType.regular);
    cubit.updatePointPosition(2, Offset(size.width * 0.65, size.height * 0.65), PointType.regular);
    cubit.updatePointPosition(3, Offset(size.width * 0.80, size.height * 0.80), PointType.regular);
  }

  // Edge case: Inclined line (30 degrees)
  void _setInclined(BuildContext context, Size size) {
    final cubit = context.read<PathCubit>();

    cubit.updatePointPosition(0, Offset(size.width * 0.15, size.height * 0.30), PointType.candidate);
    cubit.updatePointPosition(1, Offset(size.width * 0.20, size.height * 0.35), PointType.candidate);
    cubit.updatePointPosition(2, Offset(size.width * 0.25, size.height * 0.40), PointType.candidate);

    cubit.updatePointPosition(0, Offset(size.width * 0.35, size.height * 0.50), PointType.regular);
    cubit.updatePointPosition(1, Offset(size.width * 0.50, size.height * 0.60), PointType.regular);
    cubit.updatePointPosition(2, Offset(size.width * 0.65, size.height * 0.70), PointType.regular);
    cubit.updatePointPosition(3, Offset(size.width * 0.80, size.height * 0.80), PointType.regular);
  }

  // Edge case: Sharp bend (L-shape)
  void _setSharpBend(BuildContext context, Size size) {
    final cubit = context.read<PathCubit>();

    cubit.updatePointPosition(0, Offset(size.width * 0.20, size.height * 0.30), PointType.candidate);
    cubit.updatePointPosition(1, Offset(size.width * 0.25, size.height * 0.32), PointType.candidate);
    cubit.updatePointPosition(2, Offset(size.width * 0.30, size.height * 0.34), PointType.candidate);

    cubit.updatePointPosition(0, Offset(size.width * 0.40, size.height * 0.40), PointType.regular);
    cubit.updatePointPosition(1, Offset(size.width * 0.50, size.height * 0.40), PointType.regular);
    cubit.updatePointPosition(2, Offset(size.width * 0.50, size.height * 0.60), PointType.regular);
    cubit.updatePointPosition(3, Offset(size.width * 0.50, size.height * 0.75), PointType.regular);
  }

  // Edge case: S-curve
  void _setSCurve(BuildContext context, Size size) {
    final cubit = context.read<PathCubit>();

    cubit.updatePointPosition(0, Offset(size.width * 0.20, size.height * 0.30), PointType.candidate);
    cubit.updatePointPosition(1, Offset(size.width * 0.25, size.height * 0.35), PointType.candidate);
    cubit.updatePointPosition(2, Offset(size.width * 0.30, size.height * 0.32), PointType.candidate);

    cubit.updatePointPosition(0, Offset(size.width * 0.40, size.height * 0.50), PointType.regular);
    cubit.updatePointPosition(1, Offset(size.width * 0.50, size.height * 0.30), PointType.regular);
    cubit.updatePointPosition(2, Offset(size.width * 0.65, size.height * 0.70), PointType.regular);
    cubit.updatePointPosition(3, Offset(size.width * 0.80, size.height * 0.50), PointType.regular);
  }

  // Reset to default
  void _reset(BuildContext context, Size size) {
    context.read<PathCubit>().initializePoints(size);
  }
}
