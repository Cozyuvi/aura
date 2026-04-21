import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';

class AuraPageHeader extends StatelessWidget {
  const AuraPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.showAvatar = true,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showAvatar)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AuraColors.surfaceLowest,
              shape: BoxShape.circle,
              border: Border.all(
                color: AuraColors.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'YS',
              style: textTheme.labelSmall?.copyWith(
                color: AuraColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (showAvatar) const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  color: AuraColors.primary,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        action ??
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AuraColors.surfaceLowest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AuraColors.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AuraColors.primary,
              ),
            ),
      ],
    );
  }
}

class AuraEditorialCard extends StatelessWidget {
  const AuraEditorialCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accentColor = AuraColors.primary,
    this.backgroundColor = AuraColors.surfaceLowest,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color accentColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AuraRadii.card),
        border: Border.all(
          color: AuraColors.outlineVariant.withValues(alpha: 0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AuraRadii.card),
                  bottomLeft: Radius.circular(AuraRadii.card),
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class AuraMetricTile extends StatelessWidget {
  const AuraMetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AuraRadii.card),
        border: Border.all(
          color: AuraColors.outlineVariant.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AuraColors.primary),
          const Spacer(),
          Text(
            '$value $unit',
            style: textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class AuraActionTile extends StatelessWidget {
  const AuraActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AuraRadii.card),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AuraColors.surfaceLow,
          borderRadius: BorderRadius.circular(AuraRadii.card),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AuraColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AuraColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuraPrimaryButton extends StatelessWidget {
  const AuraPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AuraColors.primary, AuraColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(AuraRadii.pill),
        boxShadow: [
          BoxShadow(
            color: AuraColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AuraRadii.pill),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuraStatusChip extends StatelessWidget {
  const AuraStatusChip({
    super.key,
    required this.label,
    this.color = AuraColors.primary,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class AuraGlassBottomNav extends StatelessWidget {
  const AuraGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label})>[
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.smart_toy_rounded, label: 'Assistant'),
      (icon: Icons.medical_services_rounded, label: 'Doctors'),
      (icon: Icons.monitor_heart_rounded, label: 'Tracker'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AuraColors.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: SafeArea(
            top: false,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final selected = index == currentIndex;
                final color = selected ? AuraColors.primary : AuraColors.onSurfaceVariant;

                return Expanded(
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, color: color, size: 22),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight:
                                      selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: selected ? 16 : 0,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AuraColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
