import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/path_state_model.dart';
import '../cubit/path_cubit.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PathCubit, PathStateModel>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Path Extrapolation Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildToggleButton(
                    context,
                    label: 'Projection Overlay',
                    isActive: state.showProjectionOverlay,
                    onPressed: () => context.read<PathCubit>().toggleProjectionOverlay(),
                    icon: Icons.grid_on,
                  ),
                  _buildToggleButton(
                    context,
                    label: 'Circle Packing',
                    isActive: state.showCirclePacking,
                    onPressed: () => context.read<PathCubit>().toggleCirclePacking(),
                    icon: Icons.circle_outlined,
                  ),
                  _buildToggleButton(
                    context,
                    label: 'Clipping Boundary',
                    isActive: state.showClippingBoundary,
                    onPressed: () => context.read<PathCubit>().toggleClippingBoundary(),
                    icon: Icons.crop,
                  ),
                  _buildToggleButton(
                    context,
                    label: 'Animate Circles',
                    isActive: state.animateCircles,
                    onPressed: () => context.read<PathCubit>().toggleAnimation(),
                    icon: Icons.play_arrow,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLegend(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(Colors.amber, 'Candidate Points'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.purple, 'Reduced Point'),
          const SizedBox(width: 16),
          _buildLegendItem(Colors.green, 'Regular Points'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
