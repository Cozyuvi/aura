import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class DoctorMatchingScreen extends StatelessWidget {
  const DoctorMatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor matching')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AuraColors.primary.withValues(alpha: 0.14),
                      AuraColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const AuraStatusChip(label: 'Match confirmed'),
                    const SizedBox(height: 12),
                    Text(
                      'Finding you a doctor',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We connected you with a highly-rated specialist available right now.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: AuraColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AuraEditorialCard(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: AuraColors.primary.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'PS',
                            style: textTheme.titleLarge?.copyWith(color: AuraColors.primary),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AuraColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Dr. Priya Sharma', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('Internal Medicine', style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: AuraColors.warning, size: 18),
                        const SizedBox(width: 4),
                        Text('4.8', style: textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        Text('(124 reviews)', style: textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AuraStatusChip(label: 'Available now'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _Tag('10+ Years Exp.'),
                        _Tag('English, Hindi'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AuraPrimaryButton(
                      label: 'Start consultation',
                      icon: Icons.video_call_rounded,
                      onPressed: () => Navigator.of(context).pushNamed('/live-consultation'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Find another'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 16, color: AuraColors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'End-to-end encrypted consultation',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(value, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
