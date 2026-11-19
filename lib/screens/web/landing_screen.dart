import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/router.dart';
import '../../config/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NavBar(
              onSignIn: () => context.go(Routes.login),
              onSignUp: () => context.go(Routes.signup),
            ),
            const _HeroSection(),
            const _FeaturesSection(),
            const _HowItWorksSection(),
            _CtaSection(onSignUp: () => context.go(Routes.signup)),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Nav Bar
// ─────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const _NavBar({required this.onSignIn, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Prep Royale',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onSignIn,
            child: const Text('Sign In'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onSignUp,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w >= 900;

    return Container(
      color: AppTheme.surfaceColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 64 : 32,
              vertical: isWide ? 80 : 56,
            ),
            child: isWide
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 5, child: _HeroText()),
                      SizedBox(width: 64),
                      Expanded(flex: 4, child: _BattlePreview()),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HeroText(centered: true),
                      SizedBox(height: 48),
                      _BattlePreview(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final bool centered;
  const _HeroText({this.centered = false});

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    final cross = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final wrap = centered ? WrapAlignment.center : WrapAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      children: [
        // Pill label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'SAT & ACT Test Prep',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Study Smarter.\nBattle Harder.',
          textAlign: align,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'Practice thousands of SAT and ACT questions, then put your skills to the test '
          'in live 1-on-1 battles. Track your progress and climb the leaderboard.',
          textAlign: align,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: wrap,
          children: [
            Builder(builder: (ctx) => ElevatedButton.icon(
              onPressed: () => ctx.go(Routes.signup),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Create Free Account'),
            )),
            Builder(builder: (ctx) => OutlinedButton(
              onPressed: () => ctx.go(Routes.login),
              child: const Text('Sign In'),
            )),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Free to start • No credit card required',
          textAlign: align,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
        ),
      ],
    );
  }
}

/// Mock battle UI card — shows what the app looks like in action
class _BattlePreview extends StatelessWidget {
  const _BattlePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE BATTLE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.timer_outlined, size: 14, color: AppTheme.warningColor),
              const SizedBox(width: 4),
              Text(
                '0:22',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Health bars
          const _HealthRow(label: 'You', hp: 85, color: AppTheme.successColor),
          const SizedBox(height: 8),
          const _HealthRow(label: 'Opponent', hp: 55, color: AppTheme.errorColor),
          const SizedBox(height: 20),

          // Question card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAT Math · Algebra',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'If 3x + 7 = 22, what is x?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['A.  3', 'B.  5', 'C.  7', 'D.  9'].map((c) {
                    final correct = c.contains('5');
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: correct
                            ? AppTheme.successColor.withValues(alpha: 0.1)
                            : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: correct
                              ? AppTheme.successColor.withValues(alpha: 0.4)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        c,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: correct ? AppTheme.successColor : AppTheme.textSecondary,
                              fontWeight: correct ? FontWeight.w600 : FontWeight.w400,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final int hp;
  final Color color;

  const _HealthRow({required this.label, required this.hp, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary)),
            Text('$hp HP', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hp / 100,
            minHeight: 6,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Features
// ─────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _features = [
    (Icons.sports_kabaddi, AppTheme.primaryColor, 'Live Battles',
        '1-on-1 real-time matches. Answer correctly and faster to deal damage and win.'),
    (Icons.self_improvement, AppTheme.accentColor, 'Zen Practice',
        'Thousands of AI-generated questions across every SAT and ACT section.'),
    (Icons.bar_chart, Color(0xFF8B5CF6), 'Skill Tracking',
        'See your accuracy per skill and section. Know exactly where to focus.'),
    (Icons.emoji_events, AppTheme.warningColor, 'Leaderboard',
        'Compete with friends or rank globally as your score improves.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      color: AppTheme.backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 32, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'Everything you need to ace your test',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Built for students who want results, not just practice.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 48),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _features
                          .map((f) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: _FeatureCard(icon: f.$1, color: f.$2, title: f.$3, desc: f.$4),
                                ),
                              ))
                          .toList(),
                    )
                  : Column(
                      children: _features
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _FeatureCard(icon: f.$1, color: f.$2, title: f.$3, desc: f.$4),
                              ))
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _FeatureCard({required this.icon, required this.color, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// How It Works
// ─────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      color: AppTheme.surfaceColor,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 32, vertical: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text(
                'Up and running in minutes',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 48),
              isWide
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _StepCard(n: '1', title: 'Create your account', body: 'Sign up free, pick SAT or ACT, and set your target score.')),
                        SizedBox(width: 16),
                        Expanded(child: _StepCard(n: '2', title: 'Practice in Zen Mode', body: 'Work through questions at your own pace. The app adapts to your weaknesses.')),
                        SizedBox(width: 16),
                        Expanded(child: _StepCard(n: '3', title: 'Battle your way up', body: 'Challenge real students, earn XP, and watch your skills sharpen under pressure.')),
                      ],
                    )
                  : const Column(
                      children: [
                        _StepCard(n: '1', title: 'Create your account', body: 'Sign up free and pick your test.'),
                        SizedBox(height: 16),
                        _StepCard(n: '2', title: 'Practice in Zen Mode', body: 'Work through questions at your own pace.'),
                        SizedBox(height: 16),
                        _StepCard(n: '3', title: 'Battle your way up', body: 'Challenge real students and earn XP.'),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String n;
  final String title;
  final String body;

  const _StepCard({required this.n, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                n,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CTA
// ─────────────────────────────────────────────
class _CtaSection extends StatelessWidget {
  final VoidCallback onSignUp;
  const _CtaSection({required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              Text(
                'Ready to raise your score?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Join students already using Prep Royale to conquer the SAT and ACT.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Create Free Account',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'Prep Royale',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
              ),
            ],
          ),
          Text(
            'Independent app — not affiliated with College Board or ACT, Inc.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ],
      ),
    );
  }
}
