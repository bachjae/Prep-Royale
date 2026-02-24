import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/local_stats_service.dart';

// Sample questions for seeding
final _sampleQuestions = [
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Linear Equations',
    'difficulty': 1,
    'questionText': 'Solve for x: 2x + 6 = 14',
    'choices': ['x = 4', 'x = 5', 'x = 3', 'x = 8'],
    'correctAnswer': 0,
    'explanation': 'Subtract 6 from both sides: 2x = 8. Divide by 2: x = 4.',
    'contentHash': 'sat_math_linear_001'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Linear Equations',
    'difficulty': 2,
    'questionText': 'If 3(x - 2) = 15, what is the value of x?',
    'choices': ['x = 7', 'x = 5', 'x = 9', 'x = 3'],
    'correctAnswer': 0,
    'explanation':
        'Distribute: 3x - 6 = 15. Add 6: 3x = 21. Divide by 3: x = 7.',
    'contentHash': 'sat_math_linear_002'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Quadratic Equations',
    'difficulty': 3,
    'questionText': 'What are the solutions to x² - 5x + 6 = 0?',
    'choices': [
      'x = 2 and x = 3',
      'x = 1 and x = 6',
      'x = -2 and x = -3',
      'x = 2 and x = -3'
    ],
    'correctAnswer': 0,
    'explanation': 'Factor: (x - 2)(x - 3) = 0. So x = 2 or x = 3.',
    'contentHash': 'sat_math_quad_001'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Percentages',
    'difficulty': 2,
    'questionText':
        'A shirt originally costs \$40. It is on sale for 25% off. What is the sale price?',
    'choices': ['\$30', '\$35', '\$25', '\$32'],
    'correctAnswer': 0,
    'explanation': '25% of \$40 = \$10. Sale price = \$40 - \$10 = \$30.',
    'contentHash': 'sat_math_percent_001'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Geometry',
    'difficulty': 2,
    'questionText':
        'What is the area of a rectangle with length 8 and width 5?',
    'choices': ['40', '26', '13', '45'],
    'correctAnswer': 0,
    'explanation': 'Area = length × width = 8 × 5 = 40.',
    'contentHash': 'sat_math_geo_001'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Statistics',
    'difficulty': 2,
    'questionText': 'Find the mean of: 4, 8, 6, 10, 7',
    'choices': ['7', '6', '8', '35'],
    'correctAnswer': 0,
    'explanation': 'Mean = (4 + 8 + 6 + 10 + 7) / 5 = 35 / 5 = 7.',
    'contentHash': 'sat_math_stat_001'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Ratios',
    'difficulty': 2,
    'questionText':
        'If the ratio of boys to girls is 3:4 and there are 28 students total, how many boys are there?',
    'choices': ['12', '16', '14', '21'],
    'correctAnswer': 0,
    'explanation':
        '3 + 4 = 7 parts. 28/7 = 4 students per part. Boys = 3 × 4 = 12.',
    'contentHash': 'sat_math_ratio_001'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Exponents',
    'difficulty': 2,
    'questionText': 'Simplify: 2³ × 2⁴',
    'choices': ['128', '64', '32', '256'],
    'correctAnswer': 0,
    'explanation':
        'When multiplying same bases, add exponents: 2^(3+4) = 2^7 = 128.',
    'contentHash': 'sat_math_exp_001'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Functions',
    'difficulty': 3,
    'questionText': 'If f(x) = 2x + 3, what is f(5)?',
    'choices': ['13', '10', '8', '25'],
    'correctAnswer': 0,
    'explanation': 'f(5) = 2(5) + 3 = 10 + 3 = 13.',
    'contentHash': 'sat_math_func_001'
  },
  {
    'examType': 'SAT',
    'section': 'Math',
    'skill': 'Probability',
    'difficulty': 2,
    'questionText':
        'A bag has 3 red and 5 blue marbles. What is the probability of picking a red marble?',
    'choices': ['3/8', '5/8', '3/5', '1/2'],
    'correctAnswer': 0,
    'explanation':
        'Probability = favorable outcomes / total outcomes = 3 / (3+5) = 3/8.',
    'contentHash': 'sat_math_prob_001'
  },
  {
    'examType': 'SAT',
    'section': 'Reading',
    'skill': 'Main Idea',
    'difficulty': 2,
    'questionText':
        'A passage discusses how climate change affects polar bears. What is the main idea?',
    'choices': [
      'Climate change threatens polar bear habitats',
      'Polar bears are the largest land predators',
      'Arctic ice is beautiful',
      'Scientists study animals'
    ],
    'correctAnswer': 0,
    'explanation':
        'The main idea focuses on the relationship between climate change and polar bear survival.',
    'contentHash': 'sat_read_main_001'
  },
  {
    'examType': 'SAT',
    'section': 'Reading',
    'skill': 'Vocabulary in Context',
    'difficulty': 2,
    'questionText':
        'In the sentence "The musician\'s virtuosity amazed the audience," what does "virtuosity" mean?',
    'choices': [
      'Exceptional skill',
      'Loud volume',
      'Stage presence',
      'Musical instrument'
    ],
    'correctAnswer': 0,
    'explanation':
        'Virtuosity refers to exceptional technical skill in music or another art.',
    'contentHash': 'sat_read_vocab_001'
  },
  {
    'examType': 'SAT',
    'section': 'Writing',
    'skill': 'Grammar',
    'difficulty': 1,
    'questionText': 'Choose the correct sentence:',
    'choices': [
      'She and I went to the store.',
      'Her and me went to the store.',
      'Her and I went to the store.',
      'She and me went to the store.'
    ],
    'correctAnswer': 0,
    'explanation':
        'Use subject pronouns (she, I) as the subject of a sentence.',
    'contentHash': 'sat_write_gram_001'
  },
  {
    'examType': 'SAT',
    'section': 'Writing',
    'skill': 'Punctuation',
    'difficulty': 2,
    'questionText': 'Which sentence uses commas correctly?',
    'choices': [
      'After the rain stopped, we went outside.',
      'After the rain stopped we went outside.',
      'After, the rain stopped we went outside.',
      'After the rain, stopped we went outside.'
    ],
    'correctAnswer': 0,
    'explanation': 'Use a comma after an introductory clause.',
    'contentHash': 'sat_write_punct_001'
  },
  {
    'examType': 'ACT',
    'section': 'Math',
    'skill': 'Algebra',
    'difficulty': 2,
    'questionText': 'Simplify: 3x + 2y - x + 4y',
    'choices': ['2x + 6y', '4x + 6y', '2x + 2y', '3x + 6y'],
    'correctAnswer': 0,
    'explanation': 'Combine like terms: (3x - x) + (2y + 4y) = 2x + 6y.',
    'contentHash': 'act_math_alg_001'
  },
  {
    'examType': 'ACT',
    'section': 'Math',
    'skill': 'Trigonometry',
    'difficulty': 3,
    'questionText':
        'In a right triangle, if the opposite side is 3 and the hypotenuse is 5, what is sin(θ)?',
    'choices': ['3/5', '4/5', '3/4', '5/3'],
    'correctAnswer': 0,
    'explanation': 'sin(θ) = opposite/hypotenuse = 3/5.',
    'contentHash': 'act_math_trig_001'
  },
  {
    'examType': 'ACT',
    'section': 'Reading',
    'skill': 'Inference',
    'difficulty': 2,
    'questionText':
        'Based on the passage, what can be inferred about the author\'s attitude toward technology?',
    'choices': [
      'Cautiously optimistic',
      'Completely negative',
      'Indifferent',
      'Unreservedly positive'
    ],
    'correctAnswer': 0,
    'explanation':
        'The author acknowledges both benefits and risks of technology.',
    'contentHash': 'act_read_inf_001'
  },
  {
    'examType': 'ACT',
    'section': 'English',
    'skill': 'Sentence Structure',
    'difficulty': 2,
    'questionText':
        'Which revision corrects the run-on sentence? "I love pizza it is my favorite food."',
    'choices': [
      'I love pizza; it is my favorite food.',
      'I love pizza it, is my favorite food.',
      'I love, pizza it is my favorite food.',
      'I love pizza is my favorite food.'
    ],
    'correctAnswer': 0,
    'explanation':
        'Use a semicolon to connect two related independent clauses.',
    'contentHash': 'act_eng_sent_001'
  },
  {
    'examType': 'ACT',
    'section': 'Science',
    'skill': 'Data Interpretation',
    'difficulty': 2,
    'questionText':
        'According to the graph, as temperature increases, what happens to the reaction rate?',
    'choices': [
      'It increases',
      'It decreases',
      'It stays the same',
      'It fluctuates randomly'
    ],
    'correctAnswer': 0,
    'explanation':
        'Higher temperatures generally increase reaction rates due to more molecular collisions.',
    'contentHash': 'act_sci_data_001'
  },
  {
    'examType': 'ACT',
    'section': 'Science',
    'skill': 'Scientific Method',
    'difficulty': 2,
    'questionText': 'What is the purpose of a control group in an experiment?',
    'choices': [
      'To provide a baseline for comparison',
      'To increase sample size',
      'To eliminate all variables',
      'To speed up the experiment'
    ],
    'correctAnswer': 0,
    'explanation':
        'A control group provides a baseline to compare against the experimental group.',
    'contentHash': 'act_sci_method_001'
  },
];

Future<void> _seedQuestions(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    for (final q in _sampleQuestions) {
      final docRef = db.collection('questions').doc();
      batch.set(docRef, {
        ...q,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seeded ${_sampleQuestions.length} questions!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Guest Mode Banner ────────────────────────────
          if (isGuest) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "You're in Guest Mode",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your progress is saved locally on this device only. Create an account to sync across devices and access all features.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.amber.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Account section ──────────────────────────────
          _SectionHeader(title: isGuest ? 'Guest Account' : 'Account'),
          if (!isGuest) ...[
            _SettingsTile(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () => context.push(Routes.editProfile),
            ),
            _SettingsTile(
              icon: Icons.photo_camera_outlined,
              label: 'Change Profile Picture',
              onTap: () => context.push(Routes.profilePicture),
            ),
          ],

          // Guest-specific options
          if (isGuest) ...[
            _SettingsTile(
              icon: Icons.person_add_outlined,
              label: 'Create Account',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Recommended',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              onTap: () async {
                await ref.read(userSessionProvider.notifier).exitGuestMode();
                if (context.mounted) context.go(Routes.signup);
              },
            ),
            _SettingsTile(
              icon: Icons.login,
              label: 'Sign In to Existing Account',
              onTap: () async {
                await ref.read(userSessionProvider.notifier).exitGuestMode();
                if (context.mounted) context.go(Routes.login);
              },
            ),
            _SettingsTile(
              icon: Icons.delete_outline,
              label: 'Clear Local Data',
              onTap: () => _showClearDataDialog(context, ref),
            ),
          ],

          const SizedBox(height: 8),

          // ── About section ────────────────────────────────
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'App Version',
            trailing: Text(
              '1.0.0',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textTertiary,
              ),
            ),
            onTap: null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Not affiliated with College Board, SAT, ACT, Inc., or any official testing organization.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textTertiary,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Developer section (temporary) ─────────────────
          _SectionHeader(title: 'Developer'),
          _SettingsTile(
            icon: Icons.add_circle_outline,
            label: 'Seed Sample Questions',
            onTap: () => _seedQuestions(context),
          ),

          const SizedBox(height: 24),

          // ── Sign Out / Exit Guest Mode button ───────────────────────────────
          if (!isGuest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SignOutButton(
                onSignOut: () async {
                  await ref.read(authControllerProvider).signOut();
                  if (context.mounted) {
                    context.go(Routes.welcome);
                  }
                },
              ),
            ),

          if (isGuest)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ExitGuestButton(
                onExit: () async {
                  await ref.read(userSessionProvider.notifier).exitGuestMode();
                  if (context.mounted) {
                    context.go(Routes.welcome);
                  }
                },
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will delete all your local progress, stats, and battle history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final localStatsService = ref.read(localStatsServiceProvider);
      await localStatsService.clearGuestStats();
      ref.invalidate(guestStatsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local data cleared')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textTertiary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Settings list tile
// ─────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textTertiary,
                    size: 20,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sign out button
// ─────────────────────────────────────────────
class _SignOutButton extends StatefulWidget {
  final Future<void> Function() onSignOut;

  const _SignOutButton({required this.onSignOut});

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.onSignOut();
                if (mounted) {
                  setState(() => _loading = false);
                }
              },
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.errorColor,
                ),
              )
            : const Icon(Icons.logout, size: 20, color: AppTheme.errorColor),
        label: Text(
          'Sign Out',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.errorColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Exit guest mode button
// ─────────────────────────────────────────────
class _ExitGuestButton extends StatefulWidget {
  final Future<void> Function() onExit;

  const _ExitGuestButton({required this.onExit});

  @override
  State<_ExitGuestButton> createState() => _ExitGuestButtonState();
}

class _ExitGuestButtonState extends State<_ExitGuestButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);
                await widget.onExit();
                if (mounted) {
                  setState(() => _loading = false);
                }
              },
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.textSecondary,
                ),
              )
            : Icon(Icons.exit_to_app, size: 20, color: AppTheme.textSecondary),
        label: Text(
          'Exit Guest Mode',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textSecondary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: AppTheme.textTertiary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
