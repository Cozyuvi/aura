import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class MedicationTrackerScreen extends StatelessWidget {
  const MedicationTrackerScreen({super.key});

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
              subtitle: 'Medication tracker',
            ),
            const SizedBox(height: 20),
            Text('My prescriptions', style: textTheme.headlineLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.medical_services_rounded, size: 16, color: AuraColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Dr. Priya Sharma · Today', style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 14),
            AuraEditorialCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Migraine protocol', style: textTheme.titleLarge),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE7E7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Active flare',
                                style: textTheme.labelSmall?.copyWith(color: AuraColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 96,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Progress', style: textTheme.bodySmall),
                            Text('3 of 6 doses', style: textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: const LinearProgressIndicator(
                                value: 0.5,
                                minHeight: 6,
                                color: AuraColors.primary,
                                backgroundColor: AuraColors.surfaceHigh,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AuraColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medication_rounded, color: AuraColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ibuprofen 400mg', style: textTheme.bodyMedium),
                            Text('Take with food', style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Expanded(
                        child: _DoseButton(
                          title: 'Morning',
                          done: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _DoseButton(
                          title: 'Afternoon',
                          done: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _DoseButton(
                          title: 'Night',
                          done: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AuraColors.surfaceLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: AuraColors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Past prescriptions', style: textTheme.bodyMedium),
                  ),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AuraPrimaryButton(
              label: 'Set medicine reminder',
              icon: Icons.alarm_add_rounded,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _DoseButton extends StatelessWidget {
  const _DoseButton({required this.title, required this.done});

  final String title;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: done
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AuraColors.primary, AuraColors.primaryContainer],
              )
            : null,
        color: done ? null : AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: done
            ? null
            : Border.all(
                color: AuraColors.outlineVariant.withValues(alpha: 0.4),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 17,
            color: done ? Colors.white : AuraColors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: done ? Colors.white : AuraColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
