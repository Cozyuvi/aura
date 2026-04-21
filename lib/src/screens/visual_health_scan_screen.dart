import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';

class VisualHealthScanScreen extends StatefulWidget {
  const VisualHealthScanScreen({super.key});

  @override
  State<VisualHealthScanScreen> createState() => _VisualHealthScanScreenState();
}

class _VisualHealthScanScreenState extends State<VisualHealthScanScreen> {
  final modes = const ['Eyes', 'Mouth', 'Body'];
  int activeMode = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF555A5D), Color(0xFF1C2224)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            'Visual health scan',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                      Text(
                        'Show me your ${modes[activeMode].toLowerCase()}',
                        style: textTheme.headlineLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hold 20-30 cm away',
                              style: textTheme.bodySmall?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(modes.length, (index) {
                          final selected = index == activeMode;
                          return Padding(
                            padding: EdgeInsets.only(right: index == modes.length - 1 ? 0 : 8),
                            child: GestureDetector(
                              onTap: () => setState(() => activeMode = index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  modes[index],
                                  style: textTheme.bodySmall?.copyWith(
                                    color: selected ? AuraColors.onSurface : Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.86,
                      height: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 72,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Container(
                                width: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white38),
                                ),
                                child: const Icon(Icons.add_rounded, color: Colors.white),
                              );
                            }
                            return Container(
                              width: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.12),
                                border: Border.all(color: Colors.white38),
                              ),
                            );
                          },
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemCount: 5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Spacer(),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white70, width: 4),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [AuraColors.primary, AuraColors.primaryContainer],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Done',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
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
        ],
      ),
    );
  }
}
