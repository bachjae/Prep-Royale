import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Breakpoints for responsive layouts
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Returns true when running on web AND the viewport is desktop-sized.
bool isDesktopWeb(BuildContext context) {
  if (!kIsWeb) return false;
  return MediaQuery.of(context).size.width >= Breakpoints.tablet;
}

/// Constrains content to a max width and centers it.
/// Use this on any screen that should not stretch across a large monitor.
class WebMaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = 860,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A Scaffold wrapper that adds a left sidebar on desktop web.
/// On mobile / non-web it renders the child scaffold as-is.
class WebScaffold extends StatelessWidget {
  final Widget child;
  final List<WebNavItem> navItems;
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final String title;

  const WebScaffold({
    super.key,
    required this.child,
    required this.navItems,
    required this.currentIndex,
    required this.onNavTap,
    this.title = 'Prep Royale',
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWeb(context)) return child;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _DesktopSidebar(
            items: navItems,
            currentIndex: currentIndex,
            onTap: onNavTap,
            title: title,
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class WebNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const WebNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _DesktopSidebar extends StatelessWidget {
  final List<WebNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String title;

  const _DesktopSidebar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo area
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Nav items
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final selected = i == currentIndex;
            return _SidebarNavItem(
              icon: selected ? item.activeIcon : item.icon,
              label: item.label,
              selected: selected,
              onTap: () => onTap(i),
            );
          }),
        ],
      ),
    );
  }
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
        color: selected ? const Color(0xFF38BDF8).withValues(alpha: 0.1) : Colors.transparent,
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
                  color: selected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
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

/// Two-panel web layout for auth screens (login / signup).
/// On desktop web: left = branded gradient panel, right = white form panel.
/// On mobile/non-web: renders [child] directly.
class WebAuthLayout extends StatelessWidget {
  /// The form content to show on the right panel (or full screen on mobile).
  final Widget child;

  /// Optional label shown below the tagline on the brand panel (e.g. 'Sign In' / 'Create Account').
  final String? pageLabel;

  const WebAuthLayout({super.key, required this.child, this.pageLabel});

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWeb(context)) return child;

    return Scaffold(
      body: Row(
        children: [
          // ── Left: brand panel ──────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Prep Royale',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Study Smarter.\nBattle Harder.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Practice thousands of SAT & ACT questions and '
                    'compete in live 1-on-1 battles.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 40),
                  // Feature list
                  ...[
                    (Icons.bolt, 'Live real-time battles'),
                    (Icons.bar_chart, 'Skill-by-skill accuracy tracking'),
                    (Icons.emoji_events, 'Global & friends leaderboard'),
                  ].map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(f.$1, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              f.$2,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),

          // ── Right: form panel ──────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: TextButton.icon(
                      onPressed: () => context.go('/landing'),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a screen body in a centered card on desktop web (e.g. for auth screens).
class WebCenteredCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebCenteredCard({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDesktopWeb(context)) return child;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
