import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/streak_display.dart';
import '../../widgets/common/xp_progress_bar.dart';
import '../../widgets/guest_mode_prompt.dart';

// SVG icons for mode cards
const String _shieldSvg = '''
<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <path d="M40 8 L68 20 L68 44 C68 58 55 70 40 74 C25 70 12 58 12 44 L12 20 Z"
    fill="#38BDF8" fill-opacity="0.20" stroke="#38BDF8" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M40 18 L58 27 L58 44 C58 54 50 63 40 66 C30 63 22 54 22 44 L22 27 Z"
    fill="#38BDF8" fill-opacity="0.30"/>
  <line x1="40" y1="28" x2="40" y2="52" stroke="#38BDF8" stroke-width="3" stroke-linecap="round"/>
  <line x1="28" y1="40" x2="52" y2="40" stroke="#38BDF8" stroke-width="3" stroke-linecap="round"/>
</svg>
''';

const String _bookSvg = '''
<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <rect x="10" y="16" width="28" height="48" rx="3"
    fill="#14B8A6" fill-opacity="0.20" stroke="#14B8A6" stroke-width="2.5"/>
  <rect x="42" y="16" width="28" height="48" rx="3"
    fill="#14B8A6" fill-opacity="0.20" stroke="#14B8A6" stroke-width="2.5"/>
  <line x1="38" y1="16" x2="38" y2="64" stroke="#14B8A6" stroke-width="2" stroke-linecap="round"/>
  <line x1="17" y1="28" x2="31" y2="28" stroke="#14B8A6" stroke-width="2" stroke-linecap="round"/>
  <line x1="17" y1="36" x2="31" y2="36" stroke="#14B8A6" stroke-width="2" stroke-linecap="round"/>
  <line x1="17" y1="44" x2="31" y2="44" stroke="#14B8A6" stroke-width="2" stroke-linecap="round"/>
  <line x1="49" y1="28" x2="63" y2="28" stroke="#14B8A6" stroke-width="2" stroke-linecap="round"/>
  <line x1="49" y1="36" x2="63" y2="36" stroke="#14B8A6" stroke-width="2" stroke-linecap="round"/>
  <line x1="49" y1="44" x2="63" y2="44" stroke="#14B8A6" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    final effectiveUser = ref.watch(effectiveUserDataProvider);
    final userAsync = ref.watch(currentUserProvider);

    // For guests, use the effective user data directly
    if (isGuest) {
      return _buildHomeContent(context, ref, effectiveUser, isGuest: true);
    }

    // For authenticated users, wait for Firestore data
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorDisplay(
            message: 'Failed to load user data',
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
          data: (user) {
            if (user == null) {
              return ErrorDisplay(
                message: 'User profile not found. Please sign out and create a new account.',
                onRetry: () async {
                  await ref.read(authControllerProvider).signOut();
                  if (context.mounted) {
                    context.go(Routes.welcome);
                  }
                },
                actionLabel: 'Sign Out',
                actionIcon: Icons.logout,
              );
            }

            return _buildHomeContent(context, ref, effectiveUser, isGuest: false);
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, WidgetRef ref, EffectiveUserData? userData, {required bool isGuest}) {
    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar: avatar + name + level | settings
              _TopBar(
                username: userData.username,
                profilePictureUrl: userData.profilePictureUrl,
                level: userData.level,
                isGuest: isGuest,
                onProfileTap: () {
                  if (isGuest) {
                    GuestFeaturePrompt.show(
                      context,
                      featureName: 'Profile',
                      description: 'Create an account to customize your profile and track your progress across devices.',
                      icon: Icons.person_outline,
                    );
                  } else {
                    context.push(Routes.profile);
                  }
                },
                onSettingsTap: () => context.push(Routes.settings),
              ),
              const SizedBox(height: 16),

              // Guest mode banner
              if (isGuest) ...[
                const GuestModeBanner(),
                const SizedBox(height: 8),
              ],

              // XP Progress bar
              XpProgressBar(
                level: userData.level,
                progress: _calculateProgress(userData.totalXp, userData.level),
                xpToNextLevel: _xpToNextLevel(userData.totalXp, userData.level),
              ),
              const SizedBox(height: 20),

              // Streak row
              StreakRow(
                dailyStreak: userData.dailyStreak,
                accuracyStreak: 0, // Guest mode doesn't track accuracy streak in real-time
                dailyBest: userData.dailyStreak,
                accuracyBest: 0,
              ),
              const SizedBox(height: 28),

              // Section label
              Text(
                'Choose Your Mode',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Mode cards row
              Row(
                children: [
                  Expanded(
                    child: _ModeCard(
                      label: 'Battle',
                      subtitle: 'Challenge others',
                      svgString: _shieldSvg,
                      accentColor: AppTheme.primaryColor,
                      backgroundGradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE0F5FE),
                          Color(0xFFBAEAFD),
                        ],
                      ),
                      onTap: () {
                        // Show battle mode selection for all users
                        _showBattleModeSelector(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ModeCard(
                      label: 'Zen',
                      subtitle: 'Study at your pace',
                      svgString: _bookSvg,
                      accentColor: const Color(0xFF14B8A6),
                      backgroundGradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE0FAF7),
                          Color(0xFFB2F0EA),
                        ],
                      ),
                      onTap: () => context.push(Routes.studySelector),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Quick stats (tappable to see detailed stats)
              GestureDetector(
                onTap: () => context.push(Routes.stats),
                child: _QuickStats(
                  totalQuestions: userData.totalQuestionsAnswered,
                  accuracy: (userData.overallAccuracy * 100).round(),
                  battlesWon: userData.battlesWon,
                ),
              ),
              const SizedBox(height: 16),

              // Leaderboard link (disabled for guests)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    if (isGuest) {
                      GuestFeaturePrompt.show(
                        context,
                        featureName: 'Leaderboard',
                        description: 'Sign up to see your global ranking and compete with other players!',
                        icon: Icons.leaderboard_outlined,
                      );
                    } else {
                      context.push(Routes.leaderboard);
                    }
                  },
                  icon: Icon(
                    Icons.leaderboard_outlined,
                    size: 18,
                    color: isGuest ? AppTheme.textTertiary : AppTheme.textSecondary,
                  ),
                  label: Text(
                    'View Leaderboard',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isGuest ? AppTheme.textTertiary : AppTheme.textSecondary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showBattleModeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Choose Battle Mode',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select how you want to battle',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Live Battle Option
            _BattleModeOption(
              icon: Icons.people,
              title: 'Live Battle',
              description: 'Challenge real players online',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.battleLobby);
              },
            ),
            const SizedBox(height: 12),

            // Bot Battle Option
            _BattleModeOption(
              icon: Icons.smart_toy,
              title: 'Practice vs Bot',
              description: 'Practice against AI opponent',
              color: AppTheme.secondaryColor,
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.guestBattle);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  double _calculateProgress(int totalXp, int level) {
    final currentLevelXp = 100 * level * level;
    final nextLevelXp = 100 * (level + 1) * (level + 1);
    final xpInLevel = totalXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    return xpInLevel / xpNeeded;
  }

  int _xpToNextLevel(int totalXp, int level) {
    final nextLevelXp = 100 * (level + 1) * (level + 1);
    return nextLevelXp - totalXp;
  }
}

// ─────────────────────────────────────────────
// Top bar widget
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String username;
  final String? profilePictureUrl;
  final int level;
  final bool isGuest;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;

  const _TopBar({
    required this.username,
    this.profilePictureUrl,
    required this.level,
    required this.isGuest,
    required this.onProfileTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile avatar (tappable)
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isGuest ? AppTheme.textTertiary : AppTheme.primaryColor,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: profilePictureUrl != null
                  ? CachedNetworkImage(
                      imageUrl: profilePictureUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.backgroundColor,
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.textTertiary,
                          size: 26,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.backgroundColor,
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.textTertiary,
                          size: 26,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.backgroundColor,
                      child: const Icon(
                        Icons.person,
                        size: 26,
                        color: AppTheme.textTertiary,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Username + level badge + guest indicator
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      username,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isGuest) ...[
                    const SizedBox(width: 8),
                    const GuestModeBanner(compact: true),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level $level',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Settings icon
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: AppTheme.textSecondary,
          ),
          onPressed: onSettingsTap,
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Mode card widget
// ─────────────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String svgString;
  final Color accentColor;
  final Gradient backgroundGradient;
  final VoidCallback onTap;

  const _ModeCard({
    required this.label,
    required this.subtitle,
    required this.svgString,
    required this.accentColor,
    required this.backgroundGradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SVG icon
                SvgPicture.string(
                  svgString,
                  width: 64,
                  height: 64,
                ),
                const SizedBox(height: 16),

                // Label
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: accentColor.withValues(alpha: 0.75),
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

// ─────────────────────────────────────────────
// Quick stats widget
// ─────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final int totalQuestions;
  final int accuracy;
  final int battlesWon;

  const _QuickStats({
    required this.totalQuestions,
    required this.accuracy,
    required this.battlesWon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                value: '$totalQuestions',
                label: 'Questions',
                icon: Icons.quiz_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE2E8F0),
              ),
              _StatItem(
                value: '$accuracy%',
                label: 'Accuracy',
                icon: Icons.check_circle_outline,
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE2E8F0),
              ),
              _StatItem(
                value: '$battlesWon',
                label: 'Wins',
                icon: Icons.military_tech_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tap for detailed stats',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Battle mode option widget
// ─────────────────────────────────────────────
class _BattleModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _BattleModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
