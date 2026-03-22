import 'package:flutter/material.dart';
import 'package:todoapp/theme/app_theme.dart';

/// Minimal status indicator — thin orange ring only (no glow / pulse).
class LuxuryStatusDot extends StatelessWidget {
  const LuxuryStatusDot({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceContainerHighest,
        border: Border.all(
          color: LuxuryAppTheme.orange.withValues(alpha: 0.85),
          width: 1.5,
        ),
      ),
    );
  }
}
