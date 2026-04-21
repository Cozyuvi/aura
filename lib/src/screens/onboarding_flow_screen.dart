import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AuraColors.surface,
      appBar: AppBar(
        title: const Text('Onboarding flow'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: List.generate(3, (index) {
                  final active = index <= _page;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AuraColors.primary
                            : AuraColors.outlineVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  children: const [
                    _WelcomeStep(),
                    _AboutStep(),
                    _WatchStep(),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AuraPrimaryButton(
                label: _page == 2 ? 'Finish setup' : 'Continue',
                icon: _page == 2 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_page == 2) {
                    Navigator.of(context).pop();
                    return;
                  }
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  _page == 2 ? 'Skip for now' : 'Setup later',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AuraColors.primary.withValues(alpha: 0.16), AuraColors.surface],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: AuraColors.surfaceLowest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AuraColors.outlineVariant.withValues(alpha: 0.28),
                ),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 84,
                color: AuraColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Your personal AI health assistant', style: textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            'Precision insights and calming guidance for your daily health decisions.',
            style: textTheme.bodyMedium?.copyWith(color: AuraColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AboutStep extends StatelessWidget {
  const _AboutStep();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        children: [
          AuraEditorialCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About you', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                const _Field(label: 'Full name', value: 'Yuvi Sharma'),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Expanded(child: _Field(label: 'Age', value: '26')),
                    SizedBox(width: 10),
                    Expanded(child: _Field(label: 'Sex', value: 'M / F / O')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Expanded(child: _Field(label: 'Weight', value: '69 kg')),
                    SizedBox(width: 10),
                    Expanded(child: _Field(label: 'Height', value: '175 cm')),
                    SizedBox(width: 10),
                    Expanded(child: _Field(label: 'Blood', value: 'B+')),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _ConditionChip(label: 'None'),
                    _ConditionChip(label: 'Hypertension', selected: true),
                    _ConditionChip(label: 'Diabetes'),
                    _ConditionChip(label: 'Asthma'),
                  ],
                ),
                const SizedBox(height: 10),
                const _Field(
                  label: 'Current medications',
                  value: 'Type here...',
                  multiLine: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchStep extends StatelessWidget {
  const _WatchStep();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AuraColors.primary.withValues(alpha: 0.24),
              width: 12,
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AuraColors.primary.withValues(alpha: 0.18),
                width: 10,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.watch_rounded, size: 80, color: AuraColors.primary),
          ),
        ),
        const SizedBox(height: 24),
        Text('Connect smartwatch', style: textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Pair your watch to sync heart rate, sleep, and activity in real time.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AuraColors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        AuraPrimaryButton(
          label: 'Connect now',
          icon: Icons.bluetooth_rounded,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  final String label;
  final String value;
  final bool multiLine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AuraColors.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelSmall),
          const SizedBox(height: 4),
          SizedBox(
            height: multiLine ? 50 : null,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: textTheme.bodyMedium?.copyWith(color: AuraColors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AuraColors.primary.withValues(alpha: 0.16) : AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? AuraColors.primary : AuraColors.onSurfaceVariant,
            ),
      ),
    );
  }
}
