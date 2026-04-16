import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Horizontally scrollable destinations so icons/labels stay full size on phones.
class NavDestinationData {
  const NavDestinationData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class ScrollableBottomNav extends StatefulWidget {
  const ScrollableBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.floating = false,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestinationData> destinations;
  final bool floating;

  @override
  State<ScrollableBottomNav> createState() => _ScrollableBottomNavState();
}

class _ScrollableBottomNavState extends State<ScrollableBottomNav> {
  final ScrollController _scroll = ScrollController();
  static const double _itemWidth = 78;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant ScrollableBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final i = widget.currentIndex.clamp(0, widget.destinations.length - 1);
      final target =
          (i * _itemWidth) -
          (_scroll.position.viewportDimension / 2) +
          (_itemWidth / 2);
      _scroll.animateTo(
        target.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = cs.primary;
    final unselectedColor = cs.onSurfaceVariant;
    final radius = widget.floating ? 28.0 : 18.0;

    return Material(
      elevation: widget.floating ? 14 : 12,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      cs.surfaceContainerHigh,
                      cs.surfaceContainerHighest,
                    ]
                  : [
                      cs.surface,
                      cs.surfaceContainerLow,
                    ],
            ),
            // No hard border; rely on elevation/shadow for separation.
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: widget.floating ? 70 : 74,
              child: ListView.builder(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                itemCount: widget.destinations.length,
                itemBuilder: (context, index) {
                  final d = widget.destinations[index];
                  final selected = index == widget.currentIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onDestinationSelected(index);
                        },
                        borderRadius: BorderRadius.circular(22),
                        splashColor: selectedColor.withValues(alpha: 0.12),
                        highlightColor: selectedColor.withValues(alpha: 0.06),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          width: _itemWidth - 8,
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: null,
                            color: selected
                                ? selectedColor.withValues(
                                    alpha: isDark ? 0.22 : 0.09,
                                  )
                                : Colors.transparent,
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: selectedColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: selected ? 1.04 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                child: Icon(
                                  selected ? d.selectedIcon : d.icon,
                                  size: 23.5,
                                  color: selected
                                      ? selectedColor
                                      : unselectedColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    d.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 9.75,
                                      color: selected
                                          ? selectedColor
                                          : unselectedColor,
                                      letterSpacing: 0.15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
