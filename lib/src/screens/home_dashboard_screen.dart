import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

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
              title: 'Good morning, Yuvi',
              subtitle: 'Health Sanctuary',
            ),
            const SizedBox(height: 20),
            Text(
              'Clinical sanctuary',
              style: textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Live vitals and guidance for your day.',
              style: textTheme.bodyMedium?.copyWith(
                color: AuraColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                AuraMetricTile(
                  icon: Icons.favorite_rounded,
                  value: '96',
                  unit: 'BPM',
                  label: 'Heart rate',
                ),
                AuraMetricTile(
                  icon: Icons.water_drop_rounded,
                  value: '98',
                  unit: '%',
                  label: 'SpO2',
                ),
                AuraMetricTile(
                  icon: Icons.psychology_alt_rounded,
                  value: '4',
                  unit: '/10',
                  label: 'Stress level',
                ),
                AuraMetricTile(
                  icon: Icons.directions_walk_rounded,
                  value: '7.2k',
                  unit: '',
                  label: 'Steps today',
                ),
              ],
            ),
            const SizedBox(height: 16),
            AuraEditorialCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s health status',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Everything looks stable. Start a quick AI check if you want personalized recommendations.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AuraColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuraPrimaryButton(
                    label: 'Start AI check',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () => Navigator.of(context).pushNamed('/human-ai-assistant'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionHeading(
              title: 'Quick actions',
              actionText: 'View all',
              onTap: () => Navigator.of(context).pushNamed('/onboarding'),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AuraActionTile(
                  icon: Icons.smart_toy_rounded,
                  title: 'Talk to AI',
                  onTap: () => Navigator.of(context).pushNamed('/human-ai-assistant'),
                ),
                AuraActionTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Camera check',
                  onTap: () => Navigator.of(context).pushNamed('/visual-scan'),
                ),
                AuraActionTile(
                  icon: Icons.medical_services_rounded,
                  title: 'Find doctors',
                  onTap: () => Navigator.of(context).pushNamed('/doctor-matching'),
                ),
                AuraActionTile(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Assessment',
                  onTap: () => Navigator.of(context).pushNamed('/diagnosis'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionHeading(title: 'Recent activity'),
            const SizedBox(height: 10),
            const _ActivityTile(
              icon: Icons.water_drop_rounded,
              title: 'Hydration reminder completed',
              subtitle: '2 minutes ago',
            ),
            const SizedBox(height: 8),
            const _ActivityTile(
              icon: Icons.video_call_rounded,
              title: 'Consultation summary ready',
              subtitle: 'Today, 09:14 AM',
            ),
            const SizedBox(height: 8),
            const _ActivityTile(
              icon: Icons.medication_rounded,
              title: 'Morning dose logged',
              subtitle: 'Today, 08:02 AM',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.actionText,
    this.onTap,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onTap,
            child: Text(actionText!),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AuraColors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AuraColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AuraColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
