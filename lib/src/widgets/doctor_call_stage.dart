import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';

class DoctorCallStage extends StatefulWidget {
  const DoctorCallStage({
    super.key,
    required this.doctorName,
    required this.subtitle,
    required this.status,
    required this.isListening,
    required this.isThinking,
    required this.isSpeaking,
  });

  final String doctorName;
  final String subtitle;
  final String status;
  final bool isListening;
  final bool isThinking;
  final bool isSpeaking;

  @override
  State<DoctorCallStage> createState() => _DoctorCallStageState();
}

class _DoctorCallStageState extends State<DoctorCallStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    if (widget.isListening) {
      return const Color(0xFF3ED19A);
    }
    if (widget.isThinking) {
      return const Color(0xFF8CA9FF);
    }
    if (widget.isSpeaking) {
      return const Color(0xFFF2C46D);
    }
    return AuraColors.primary;
  }

  String get _modeLabel {
    if (widget.isThinking) {
      return 'Analyzing';
    }
    if (widget.isListening) {
      return 'Listening';
    }
    if (widget.isSpeaking) {
      return 'Speaking';
    }
    return 'Live';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final double t = _pulseController.value;
        final bool active = widget.isListening || widget.isThinking || widget.isSpeaking;
        final double pulse = active ? (1.0 + math.sin(t * math.pi * 2) * 0.02) : 1.0;
        final double glow = active ? 0.22 + (math.sin((t + 0.2) * math.pi * 2) + 1) * 0.06 : 0.12;

        return Container(
          height: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B2E2D), Color(0xFF0B1413), Color(0xFF060B0A)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DoctorBackdropPainter(
                      accentColor: _accentColor,
                      pulse: t,
                      glow: glow,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: _CallBadge(
                    label: 'LIVE',
                    color: _accentColor,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: _CallBadge(
                    label: _modeLabel,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: pulse,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DoctorPortrait(
                          accentColor: _accentColor,
                          isListening: widget.isListening,
                          isThinking: widget.isThinking,
                          isSpeaking: widget.isSpeaking,
                          pulse: t,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.doctorName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                        const SizedBox(height: 14),
                        _VoiceBars(
                          accentColor: _accentColor,
                          intensity: widget.isSpeaking
                              ? 1.0
                              : widget.isListening
                                  ? 0.82
                                  : widget.isThinking
                                      ? 0.56
                                      : 0.28,
                          phase: t,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withValues(alpha: 0.45),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.status,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
      },
    );
  }
}

class _CallBadge extends StatelessWidget {
  const _CallBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
          ),
        ],
      ),
    );
  }
}

class _DoctorBackdropPainter extends CustomPainter {
  const _DoctorBackdropPainter({
    required this.accentColor,
    required this.pulse,
    required this.glow,
  });

  final Color accentColor;
  final double pulse;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF152927), Color(0xFF081010), Color(0xFF050807)],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final center = size.center(Offset.zero);
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.18 + glow),
          accentColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.48));
    canvas.drawCircle(center.translate(0, -size.height * 0.05), size.shortestSide * (0.45 + pulse * 0.02), highlightPaint);

    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.32),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center.translate(0, size.height * 0.18), radius: size.shortestSide * 0.55));
    canvas.drawCircle(center.translate(0, size.height * 0.18), size.shortestSide * 0.55, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _DoctorBackdropPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.pulse != pulse ||
        oldDelegate.glow != glow;
  }
}

class _DoctorPortrait extends StatelessWidget {
  const _DoctorPortrait({
    required this.accentColor,
    required this.isListening,
    required this.isThinking,
    required this.isSpeaking,
    required this.pulse,
  });

  final Color accentColor;
  final bool isListening;
  final bool isThinking;
  final bool isSpeaking;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final bool active = isListening || isThinking || isSpeaking;
    final double ringOpacity = active ? 0.35 : 0.18;

    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 184,
            height: 184,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.26),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0E1817),
              border: Border.all(
                color: Colors.white.withValues(alpha: ringOpacity),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.28),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.15, -0.2),
                radius: 0.9,
                colors: [
                  const Color(0xFFF4CBA7),
                  const Color(0xFFE1AB7F),
                  const Color(0xFFC98A64),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Positioned(
            top: 26,
            child: Container(
              width: 132,
              height: 86,
              decoration: BoxDecoration(
                color: const Color(0xFF2A1512),
                borderRadius: BorderRadius.circular(58),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 44,
            child: Container(
              width: 116,
              height: 114,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF7D3B7), Color(0xFFE0A77D)],
                ),
                borderRadius: BorderRadius.circular(54),
              ),
            ),
          ),
          Positioned(
            top: 56,
            left: 56,
            child: _PortraitEye(isLeft: true),
          ),
          Positioned(
            top: 56,
            right: 56,
            child: _PortraitEye(isLeft: false),
          ),
          Positioned(
            top: 90,
            child: Container(
              width: 7,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFC98968),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            top: 118,
            child: Container(
              width: 34,
              height: 12,
              decoration: BoxDecoration(
                color: isSpeaking ? const Color(0xFFB64C50) : const Color(0xFFA74746),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            child: Container(
              width: 140,
              height: 74,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF9FCFE), Color(0xFFE2EBF2)],
                ),
                borderRadius: BorderRadius.circular(48),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 38,
            child: Container(
              width: 114,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0F5),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned(
            bottom: 52,
            left: 56,
            child: Container(
              width: 22,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC8D4DC),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 52,
            right: 56,
            child: Container(
              width: 22,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC8D4DC),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0.72,
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: 126,
                height: 16,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.0),
                      accentColor.withValues(alpha: 0.46),
                      accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortraitEye extends StatelessWidget {
  const _PortraitEye({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F2),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2020),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _VoiceBars extends StatelessWidget {
  const _VoiceBars({
    required this.accentColor,
    required this.intensity,
    required this.phase,
  });

  final Color accentColor;
  final double intensity;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(8, (index) {
          final double wave = math.sin((phase * math.pi * 2) + (index * 0.55));
          final double height = 8 + ((wave + 1) * 0.5) * (12 + intensity * 12);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.42 + intensity * 0.36),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}
