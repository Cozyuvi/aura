import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class ProfileRecordsScreen extends StatelessWidget {
  const ProfileRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuraPageHeader(
              title: 'Health Sanctuary',
              subtitle: 'Profile and records',
            ),
            const SizedBox(height: 20),
            Text('Yuvi Sharma', style: textTheme.headlineLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _Badge(icon: Icons.cake_rounded, value: '26 yrs'),
                _Badge(icon: Icons.bloodtype_rounded, value: 'B+'),
                _Badge(icon: Icons.monitor_weight_rounded, value: '69 kg'),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit profile'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: AuraColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _ProfileMetric(icon: Icons.event_note_rounded, value: '42', label: 'Sessions'),
                _ProfileMetric(icon: Icons.medical_services_rounded, value: '3', label: 'Doctors'),
                _ProfileMetric(icon: Icons.medication_rounded, value: '2', label: 'Prescriptions'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AuraColors.primary, AuraColors.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.watch_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apple Watch Series 9',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Actively syncing vitals',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sync_rounded, color: Colors.white),
                    label: const Text('Sync', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Clinical timeline',
                    style: textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('View all')),
              ],
            ),
            const _TimelineCard(
              icon: Icons.auto_awesome_rounded,
              title: 'AI check completed',
              subtitle: 'Yesterday, 10:12 PM',
              status: 'Stable',
              color: AuraColors.primary,
            ),
            const SizedBox(height: 8),
            const _TimelineCard(
              icon: Icons.video_call_rounded,
              title: 'Doctor call summary',
              subtitle: 'Oct 12, 7:44 PM',
              status: 'Follow-up due',
              color: AuraColors.tertiary,
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AuraColors.surfaceLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: const [
                  _SettingsRow(icon: Icons.security_rounded, label: 'Privacy & security'),
                  _SettingsRow(icon: Icons.payments_rounded, label: 'Payments'),
                  _SettingsRow(icon: Icons.logout_rounded, label: 'Logout', danger: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AuraColors.primary),
          const SizedBox(width: 6),
          Text(value, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AuraColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: AuraColors.primary),
          ),
          const Spacer(),
          Text(value, style: textTheme.titleLarge?.copyWith(fontSize: 20)),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AuraEditorialCard(
      accentColor: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                AuraStatusChip(label: status, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AuraColors.error : AuraColors.onSurface;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: danger
                    ? AuraColors.error.withValues(alpha: 0.12)
                    : AuraColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: danger ? AuraColors.error : AuraColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
