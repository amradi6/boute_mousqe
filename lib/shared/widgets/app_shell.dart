import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_typography.dart';

class StudentShell extends StatelessWidget {
  final Widget child;
  const StudentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: _AppBottomNav(
        items: const [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: AppStrings.home, path: '/student'),
          _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: AppStrings.attendance, path: '/student/attendance'),
          _NavItem(icon: Icons.star_outline_rounded, activeIcon: Icons.star_rounded, label: AppStrings.evaluation, path: '/student/evaluation'),
          _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: AppStrings.notifications, path: '/student/notifications'),
          _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: AppStrings.profile, path: '/student/profile'),
        ],
        currentLocation: location,
        onTap: (path) => context.go(path),
      ),
    );
  }
}

class TeacherShell extends StatelessWidget {
  final Widget child;
  const TeacherShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: _AppBottomNav(
        items: const [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: AppStrings.home, path: '/teacher'),
          _NavItem(icon: Icons.how_to_reg_outlined, activeIcon: Icons.how_to_reg_rounded, label: AppStrings.attendance, path: '/teacher/attendance'),
          _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: AppStrings.evaluation, path: '/teacher/evaluation'),
          _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: AppStrings.notifications, path: '/teacher/notifications'),
          _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: AppStrings.profile, path: '/teacher/profile'),
        ],
        currentLocation: location,
        onTap: (path) => context.go(path),
      ),
    );
  }
}

class ParentShell extends StatelessWidget {
  final Widget child;
  const ParentShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: _AppBottomNav(
        items: const [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: AppStrings.home, path: '/parent'),
          _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: AppStrings.notifications, path: '/parent/notifications'),
          _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: AppStrings.profile, path: '/parent/profile'),
        ],
        currentLocation: location,
        onTap: (path) => context.go(path),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

class _AppBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final String currentLocation;
  final ValueChanged<String> onTap;

  const _AppBottomNav({
    required this.items,
    required this.currentLocation,
    required this.onTap,
  });

  int get _currentIndex {
    // Pick the item whose path is the longest prefix of currentLocation.
    // This ensures '/student/attendance' wins over '/student' when both match.
    var bestIndex = 0;
    var bestLength = -1;
    for (var i = 0; i < items.length; i++) {
      final path = items[i].path;
      if (currentLocation == path || currentLocation.startsWith('$path/')) {
        if (path.length > bestLength) {
          bestIndex = i;
          bestLength = path.length;
        }
      }
    }
    return bestIndex;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == current;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(item.path),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withAlpha(20) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
