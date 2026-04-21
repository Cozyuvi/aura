import 'package:flutter/material.dart';

import 'screens/diagnosis_assessment_screen.dart';
import 'screens/doctor_matching_screen.dart';
import 'screens/doctors_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/human_ai_assistant_screen.dart';
import 'screens/live_consultation_screen.dart';
import 'screens/medication_tracker_screen.dart';
import 'screens/onboarding_flow_screen.dart';
import 'screens/profile_records_screen.dart';
import 'screens/visual_health_scan_screen.dart';
import 'theme/aura_theme.dart';
import 'widgets/aura_ui.dart';

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura Health Assistant',
      debugShowCheckedModeBanner: false,
      theme: AuraTheme.light(),
      home: const AuraShell(),
      routes: {
        '/onboarding': (_) => const OnboardingFlowScreen(),
        '/diagnosis': (_) => const DiagnosisAssessmentScreen(),
        '/live-consultation': (_) => const LiveConsultationScreen(),
        '/visual-scan': (_) => const VisualHealthScanScreen(),
        '/human-ai-assistant': (_) => const HumanAiAssistantScreen(),
        '/doctor-matching': (_) => const DoctorMatchingScreen(),
      },
    );
  }
}

class AuraShell extends StatefulWidget {
  const AuraShell({super.key});

  @override
  State<AuraShell> createState() => _AuraShellState();
}

class _AuraShellState extends State<AuraShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = const [
    HomeDashboardScreen(),
    HumanAiAssistantScreen(),
    DoctorsScreen(),
    MedicationTrackerScreen(),
    ProfileRecordsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: AuraGlassBottomNav(
        currentIndex: _currentIndex,
        onTap: (value) => setState(() => _currentIndex = value),
      ),
    );
  }
}
