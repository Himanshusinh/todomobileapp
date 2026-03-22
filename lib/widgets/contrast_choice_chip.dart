import 'package:flutter/material.dart';

/// Single-select chip with readable label colors (fixes white-on-pastel theme bugs).
class ContrastChoiceChip extends StatelessWidget {
  const ContrastChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.accentColor,
    this.compact = true,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  /// When set, selected state uses a tinted background and dark label for contrast.
  final Color? accentColor;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color effectiveSelectedBg = accentColor != null
        ? accentColor!.withValues(alpha: 0.24)
        : cs.primary;

    final Color labelColor = selected
        ? (accentColor != null ? cs.onSurface : cs.onPrimary)
        : cs.onSurface;

    final Color borderColor = selected
        ? (accentColor ?? cs.primary)
        : cs.outline.withValues(alpha: 0.45);

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          fontSize: compact ? 13 : 14,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: effectiveSelectedBg,
      backgroundColor: cs.surfaceContainerLow,
      disabledColor: cs.surfaceContainerHighest,
      side: BorderSide(
        color: borderColor,
        width: selected ? 1.5 : 1,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 0 : 2,
      ),
      labelPadding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 0 : 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
    );
  }
}
