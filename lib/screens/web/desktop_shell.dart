import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/router.dart';
import '../../config/theme.dart';

/// Shell that wraps all authenticated main screens on desktop web.
/// Shows a left sidebar with navigation. On mobile/non-web, renders [child] directly.
class DesktopShell extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const DesktopShell({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || MediaQuery.of(context).size.width < 900) return child;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          _Sidebar(currentPath: currentPath),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentPath;
  const _Sidebar({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', route: Routes.home),
      const _NavItem(icon: Icons.quiz_outlined, activeIcon: Icons.quiz, label: 'Zen Mode', route: Routes.studySelector),
      const _NavItem(icon: Icons.shield_outlined, activeIcon: Icons.shield, label: 'Battle', route: Routes.battleLobby),
      const _NavItem(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: 'Leaderboard', route: Routes.leaderboard),
      const _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Friends', route: Routes.friends),
      const _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', route: Routes.profile),
    ];

    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Prep Royale',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          ...items.map((item) {
            // Check if current path starts with item route
            // (so /profile/edit still highlights Profile)
            final selected = currentPath == item.route ||
                (item.route != Routes.home && currentPath.startsWith(item.route));
            return _SidebarNavItem(
              icon: selected ? item.activeIcon : item.icon,
              label: item.label,
              selected: selected,
              onTap: () => context.go(item.route),
            );
          }),

          const Spacer(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

          // Settings at bottom
          _SidebarNavItem(
            icon: currentPath.startsWith(Routes.settings) ? Icons.settings : Icons.settings_outlined,
            label: 'Settings',
            selected: currentPath.startsWith(Routes.settings),
            onTap: () => context.push(Routes.settings),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
