import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class DiagnosisAssessmentScreen extends StatelessWidget {
  const DiagnosisAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnosis assessment')),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuraPageHeader(
                    title: 'Your assessment',
                    subtitle: 'Completed just now',
                    showAvatar: false,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AuraColors.surfaceLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AuraColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MODERATE',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AuraColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Worth keeping an eye on',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuraEditorialCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AuraColors.primary.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AuraColors.primary,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('AI Assessment', style: textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mild inflammatory response likely linked to visual strain. No immediate critical markers detected from current signals.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallCard(
                          icon: Icons.photo_camera_rounded,
                          title: 'Observation',
                          value: 'Mild redness',
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: AuraColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: _SmallCard(
                          icon: Icons.watch_rounded,
                          title: 'Watch data',
                          value: '96 BPM',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AuraEditorialCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.list_alt_rounded, color: AuraColors.primary),
                            const SizedBox(width: 8),
                            Text('Symptoms', style: textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _SymptomChip(label: 'Itching'),
                            _SymptomChip(label: 'Warm to touch'),
                            _SymptomChip(label: 'Started yesterday'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  AuraEditorialCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.route_rounded, color: AuraColors.primary),
                            const SizedBox(width: 8),
                            Text('Next steps', style: textTheme.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AuraColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Book a doctor appointment within the next 24 hours for a guided follow-up.',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: AuraPrimaryButton(
                label: 'Find available doctor',
                icon: Icons.calendar_month_rounded,
                onPressed: () => Navigator.of(context).pushNamed('/doctor-matching'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.icon,
    required this.title,
    required this.value,
    this.child,
  });

  final IconData icon;
  final String title;
  final String value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuraColors.outlineVariant.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AuraColors.primary),
          const SizedBox(height: 8),
          Text(title, style: textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: textTheme.bodyMedium),
          if (child != null) ...[
            const SizedBox(height: 8),
            child!,
          ],
        ],
      ),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  const _SymptomChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
