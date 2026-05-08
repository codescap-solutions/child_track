import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/app/social_apps/view_model/bloc/app_lock_bloc.dart';
import 'package:child_track/app/social_apps/view_model/bloc/app_lock_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Google Play mandatory Prominent Disclosure dialog for Accessibility Service.
///
/// Must be shown BEFORE directing the user to Android Accessibility Settings.
/// Explains:
///   1. WHAT the service accesses (foreground app name)
///   2. WHY it's needed (enforce app locks on the child's device)
///   3. HOW it works (blocks restricted apps when detected in foreground)
///   4. DATA assurance (no personal data stored or transmitted)
///
/// Usage:
///   AccessibilityDisclosureDialog.show(context);
class AccessibilityDisclosureDialog extends StatelessWidget {
  const AccessibilityDisclosureDialog({super.key});

  /// Show the dialog. On "Enable" taps → triggers [OpenAccessibilitySettings].
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<AppLockBloc>(),
        child: const AccessibilityDisclosureDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.accessibility_new_rounded,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Accessibility Permission Required',
                    style: AppTextStyles.headline6.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 20),

            // ── Disclosure body ──────────────────────────────────
            Text(
              'To enable App Lock, NaviQ requires Android\'s Accessibility Service. '
              'Here is exactly what it does and does not do:',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            _BulletPoint(
              icon: Icons.visibility_outlined,
              color: AppColors.primaryColor,
              title: 'What it accesses',
              body:
                  'The service reads only the name of the app currently open on the child\'s screen.',
            ),
            const SizedBox(height: 12),
            _BulletPoint(
              icon: Icons.shield_outlined,
              color: const Color(0xFF2E7D32),
              title: 'Why it\'s needed',
              body:
                  'NaviQ uses this to detect when a restricted app is opened and immediately block it, enforcing the limits you set as a parent.',
            ),
            const SizedBox(height: 12),
            _BulletPoint(
              icon: Icons.lock_outline_rounded,
              color: const Color(0xFF1565C0),
              title: 'Your data is safe',
              body:
                  'No personal data, messages, or content is ever read, stored, or transmitted. The service only checks the app name against a local blocklist.',
            ),

            const SizedBox(height: 20),

            // ── Privacy note ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can disable this permission at any time in Android '
                      'Settings → Accessibility → NaviQ App Lock.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context
                          .read<AppLockBloc>()
                          .add(OpenAccessibilitySettings());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Enable',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ─────────────────────────────────────────────────────────

class _BulletPoint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _BulletPoint({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.subtitle2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
