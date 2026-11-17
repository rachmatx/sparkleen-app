import '../theme/app_icons.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_card.dart';

/// Root tabs keep their scroll/filter state while tapping or swiping.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int? _dragIndex;
  double _pageDrag = 0;

  void _goBranch(int index, {bool resetIfCurrent = false}) {
    widget.navigationShell.goBranch(
      index,
      initialLocation:
          resetIfCurrent && index == widget.navigationShell.currentIndex,
    );
  }

  void _finishPageSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_pageDrag.abs() >= 60 ||
        (_pageDrag.abs() >= 24 && velocity.abs() >= 350)) {
      final direction = _pageDrag < 0 ? 1 : -1;
      final target = (widget.navigationShell.currentIndex + direction).clamp(
        0,
        2,
      );
      if (target != widget.navigationShell.currentIndex) _goBranch(target);
    }
    _pageDrag = 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _dragIndex ?? widget.navigationShell.currentIndex;
    final largeText = MediaQuery.textScalerOf(context).scale(13) > 18;
    return AppBackdrop(
      child: Scaffold(
        extendBody: true,
        body: GestureDetector(
          key: const ValueKey('tab-swipe-area'),
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) => _pageDrag = 0,
          onHorizontalDragUpdate: (details) =>
              _pageDrag += details.primaryDelta ?? 0,
          onHorizontalDragEnd: _finishPageSwipe,
          onHorizontalDragCancel: () => _pageDrag = 0,
          child: widget.navigationShell,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: BackdropGroup(
            child: AppCard(
              radius: 999,
              blur: 24,
              padding: const EdgeInsets.all(4),
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  key: const ValueKey('tab-slide-bar'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (details) => setState(() {
                    _dragIndex =
                        (details.localPosition.dx / (constraints.maxWidth / 3))
                            .floor()
                            .clamp(0, 2);
                  }),
                  onHorizontalDragEnd: (_) {
                    final target = _dragIndex;
                    setState(() => _dragIndex = null);
                    if (target != null &&
                        target != widget.navigationShell.currentIndex) {
                      _goBranch(target);
                    }
                  },
                  onHorizontalDragCancel: () =>
                      setState(() => _dragIndex = null),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedAlign(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment(-1 + selected.toDouble(), 0),
                          child: FractionallySizedBox(
                            widthFactor: 1 / 3,
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      NavigationBar(
                        height: largeText ? 80 : 60,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        selectedIndex: widget.navigationShell.currentIndex,
                        onDestinationSelected: (index) =>
                            _goBranch(index, resetIfCurrent: true),
                        destinations: [
                          for (final (index, label, icon, selectedIcon) in [
                            (
                              0,
                              'Beranda',
                              AppIcons.home_outlined,
                              AppIcons.home_rounded,
                            ),
                            (
                              1,
                              'Pesanan',
                              AppIcons.receipt_long_outlined,
                              AppIcons.receipt_long_rounded,
                            ),
                            (
                              2,
                              'Profil',
                              AppIcons.person_outline_rounded,
                              AppIcons.person_rounded,
                            ),
                          ])
                            _CapsuleDestination(
                              label: label,
                              icon: icon,
                              selectedIcon: selectedIcon,
                              selected: selected == index,
                              onTap: () =>
                                  _goBranch(index, resetIfCurrent: true),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CapsuleDestination extends StatelessWidget {
  const _CapsuleDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon, selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: MediaQuery.textScalerOf(context).scale(13) > 18
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? selectedIcon : icon,
                          size: 22,
                          color: color,
                        ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? selectedIcon : icon,
                          size: 22,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
