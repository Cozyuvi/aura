import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class AssistantChatScreen extends StatelessWidget {
  const AssistantChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: const AuraPageHeader(
              title: 'Good morning, Health Sanctuary',
              subtitle: 'Aura Assistant is listening',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                AuraEditorialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Live Vitals'),
                          AuraStatusChip(label: 'Syncing'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Expanded(
                            child: _VitalsColumn(label: 'Heart', value: '96 BPM'),
                          ),
                          Expanded(
                            child: _VitalsColumn(label: 'SpO2', value: '98%'),
                          ),
                          Expanded(
                            child: _VitalsColumn(label: 'Stress', value: 'Medium'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _AssistantBubble(
                  text:
                      'Hi Yuvi, I noticed mild stress elevation. Would you like a quick breathing protocol or a visual check?',
                ),
                const SizedBox(height: 10),
                const _UserBubble(
                  text: 'I feel eye strain. Can you check if it looks concerning?',
                ),
                const SizedBox(height: 10),
                _AssistantBubble(
                  text: 'I can run a visual scan now. Hold your phone 20-30 cm away in soft lighting.',
                  cardChild: _MiniRequestCard(
                    icon: Icons.photo_camera_rounded,
                    title: 'Camera Check Requested',
                    subtitle: 'Eyes focus mode is prepared.',
                    onTap: () => Navigator.of(context).pushNamed('/visual-scan'),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SuggestionChip(label: 'Eyes', onTap: () {}),
                    _SuggestionChip(label: 'Mouth', onTap: () {}),
                    _SuggestionChip(label: 'Face', onTap: () {}),
                    _SuggestionChip(label: 'Body', onTap: () {}),
                    _SuggestionChip(
                      label: 'Live consultation',
                      onTap: () => Navigator.of(context).pushNamed('/live-consultation'),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AuraColors.surface.withValues(alpha: 0),
                  AuraColors.surface,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AuraColors.surfaceLowest,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AuraColors.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pushNamed('/visual-scan'),
                    icon: const Icon(Icons.camera_alt_rounded),
                    color: AuraColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      'Reply or describe...',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AuraColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AuraColors.primary, AuraColors.primaryContainer],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalsColumn extends StatelessWidget {
  const _VitalsColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text, this.cardChild});

  final String text;
  final Widget? cardChild;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: AuraColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AuraColors.surfaceLow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: AuraColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: textTheme.bodyMedium),
                if (cardChild != null) ...[
                  const SizedBox(height: 10),
                  cardChild!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AuraColors.surfaceLowest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(
            color: AuraColors.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

class _MiniRequestCard extends StatelessWidget {
  const _MiniRequestCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AuraColors.surfaceLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AuraColors.primary.withValues(alpha: 0.15),
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
                  Text(subtitle, style: textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: AuraColors.surfaceLowest,
      shape: StadiumBorder(
        side: BorderSide(
          color: AuraColors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
