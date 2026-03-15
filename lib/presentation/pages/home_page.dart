import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../cubit/path_cubit.dart';
import '../widgets/control_panel.dart';
import '../widgets/path_canvas.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PathCubit>(),
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(title: const Text('Path Extrapolation'), backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 2),
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
            const ControlPanel(),
          ],
        ),
      ),
    );
  }
}
