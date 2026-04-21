import 'dart:async';

import 'package:flutter/material.dart';

import '../models/client_dashboard_data.dart';
import '../services/auth_service.dart';
import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class DiagnosisAssessmentScreen extends StatefulWidget {
  const DiagnosisAssessmentScreen({super.key});

  @override
  State<DiagnosisAssessmentScreen> createState() => _DiagnosisAssessmentScreenState();
}

class _DiagnosisAssessmentScreenState extends State<DiagnosisAssessmentScreen> {
  ClientDashboardData? _dashboard;
  Timer? _refreshTimer;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDashboard());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_loadDashboard(silent: true)),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final dashboard = await AuthService.instance.fetchDashboard();
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboard = dashboard;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final latest = _dashboard?.latestRecord;

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
                    title: 'Live assessment feed',
                    subtitle: 'Auto-refresh every few seconds',
                    showAvatar: false,
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: textTheme.bodySmall?.copyWith(color: AuraColors.error),
                      ),
                    ),
                  if (latest == null)
                    AuraEditorialCard(
                      child: Text(
                        'No live assessment data yet. Start talking with Dr. Sophia to generate your first assessment.',
                        style: textTheme.bodyMedium,
                      ),
                    )
                  else ...[
                    _SeverityBanner(record: latest),
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
                            latest.diagnosisSummary.isNotEmpty
                                ? latest.diagnosisSummary
                                : latest.spokenResponse,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          AuraStatusChip(
                            label:
                                '${latest.targetSpecialty.isNotEmpty ? latest.targetSpecialty : 'General medicine'} • ${latest.urgency.isNotEmpty ? latest.urgency : 'unknown'}',
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
                              const Icon(Icons.list_alt_rounded, color: AuraColors.primary),
                              const SizedBox(width: 8),
                              Text('Likely conditions', style: textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (latest.likelyConditions.isEmpty)
                            Text('No conditions listed yet.', style: textTheme.bodySmall)
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: latest.likelyConditions
                                  .map((condition) => _SymptomChip(label: condition))
                                  .toList(growable: false),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (latest.redFlags.isNotEmpty)
                      AuraEditorialCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AuraColors.warning),
                                const SizedBox(width: 8),
                                Text('Red flags', style: textTheme.bodyMedium),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...latest.redFlags.map(
                              (flag) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('• $flag', style: textTheme.bodySmall),
                              ),
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
                              Text('Next step', style: textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            latest.recommendedNextStep.isNotEmpty
                                ? latest.recommendedNextStep
                                : 'Continue monitoring symptoms and consult a specialist if they worsen.',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text('Recent updates', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...(_dashboard?.recentRecords ?? const <DiagnosisFeedItem>[])
                      .map(
                        (record) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AuraEditorialCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.targetSpecialty.isNotEmpty
                                      ? record.targetSpecialty
                                      : 'General medicine',
                                  style: textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  record.diagnosisSummary.isNotEmpty
                                      ? record.diagnosisSummary
                                      : record.spokenResponse,
                                  style: textTheme.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  record.createdAt?.toLocal().toString() ?? 'Unknown time',
                                  style: textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
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

class _SeverityBanner extends StatelessWidget {
  const _SeverityBanner({required this.record});

  final DiagnosisFeedItem record;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final urgency = record.urgency.toLowerCase();

    final (String label, Color color, String subtitle) = switch (urgency) {
      'emergency' => ('EMERGENCY', AuraColors.error, 'Seek immediate medical care'),
      'urgent' => ('URGENT', AuraColors.error, 'Doctor follow-up is needed soon'),
      'soon' => ('SOON', AuraColors.warning, 'Schedule a consultation shortly'),
      'routine' => ('ROUTINE', AuraColors.primary, 'Monitor and continue routine care'),
      _ => ('UNKNOWN', AuraColors.onSurfaceVariant, 'Awaiting clearer urgency classification'),
    };

    return Container(
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: textTheme.bodyMedium),
              ],
            ),
          ),
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
