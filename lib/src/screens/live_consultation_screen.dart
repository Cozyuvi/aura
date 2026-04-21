import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class LiveConsultationScreen extends StatelessWidget {
  const LiveConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1412),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 55,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF253238), Color(0xFF0C151A)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _GlassLabel(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dr. Sharma · 12:31',
                              style: textTheme.bodySmall?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(
                        Icons.signal_cellular_4_bar_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        width: 78,
                        height: 116,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF67747B), Color(0xFF2D3940)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 45,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: const BoxDecoration(
                  color: AuraColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 28,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AuraColors.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.visibility_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text('Your file visible to Dr. Sharma', style: textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AuraEditorialCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Migraine Assessment', style: textTheme.titleLarge),
                              ),
                              const AuraStatusChip(
                                label: 'Moderate-High',
                                color: AuraColors.tertiary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Submitted 12 minutes ago', style: textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: const [
                              _MiniTag('Light sensitivity'),
                              _MiniTag('Nausea'),
                              _MiniTag('One-sided pain'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded, size: 16, color: AuraColors.primary),
                              const SizedBox(width: 6),
                              Text('Resting HR 92 BPM', style: textTheme.bodySmall),
                              const SizedBox(width: 10),
                              const Icon(Icons.trending_up_rounded, size: 16, color: AuraColors.warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: Colors.white.withValues(alpha: 0.78),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              _ControlButton(icon: Icons.mic_rounded),
                              _ControlButton(icon: Icons.videocam_rounded),
                              _ControlButton(icon: Icons.chat_bubble_outline_rounded, dot: true),
                              _ControlButton(icon: Icons.call_end_rounded, danger: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassLabel extends StatelessWidget {
  const _GlassLabel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(value, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, this.dot = false, this.danger = false});

  final IconData icon;
  final bool dot;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final background = danger ? AuraColors.error : AuraColors.surfaceLowest;
    final iconColor = danger ? Colors.white : AuraColors.onSurface;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        if (dot)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AuraColors.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
