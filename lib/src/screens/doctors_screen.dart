import 'package:flutter/material.dart';

import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  bool showHistory = false;
  String activeSpecialty = 'All';

  final specialties = const [
    'All',
    'General',
    'Dermatology',
    'Neurology',
    'Cardiology',
  ];

  final availableDoctors = const [
    _Doctor(
      name: 'Dr. Priya Sharma',
      specialty: 'Internal Medicine',
      rating: '4.9',
      status: 'Free now',
      about: 'Specialist in long-term preventive care and medication planning.',
      price: '\$28 / 20 min',
    ),
    _Doctor(
      name: 'Dr. Omar Malik',
      specialty: 'Dermatology',
      rating: '4.8',
      status: 'Available 2:00 PM',
      about: 'Helps with visual skin checks and inflammation management.',
      price: '\$35 / 20 min',
    ),
  ];

  final doctorHistory = const [
    _Doctor(
      name: 'Dr. Kavya Menon',
      specialty: 'Neurology',
      rating: '4.7',
      status: 'Last session: Oct 12',
      about: 'Migraine and stress-related care plans.',
      price: '\$30 / 20 min',
    ),
    _Doctor(
      name: 'Dr. Arjun Mehta',
      specialty: 'General Physician',
      rating: '4.8',
      status: 'Last session: Sep 29',
      about: 'Holistic checkups and daily health routines.',
      price: '\$26 / 20 min',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final doctors = showHistory ? doctorHistory : availableDoctors;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuraPageHeader(
              title: 'Good morning, Health Sanctuary',
              subtitle: 'Doctor matching and history',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _TabToggle(
                  label: 'My doctors',
                  selected: showHistory,
                  onTap: () => setState(() => showHistory = true),
                ),
                const SizedBox(width: 8),
                _TabToggle(
                  label: 'Available now',
                  selected: !showHistory,
                  onTap: () => setState(() => showHistory = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: specialties.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = specialties[index];
                  final selected = item == activeSpecialty;
                  return ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) => setState(() => activeSpecialty = item),
                    selectedColor: AuraColors.primary,
                    labelStyle: textTheme.labelSmall?.copyWith(
                      color: selected ? Colors.white : AuraColors.onSurfaceVariant,
                    ),
                    side: BorderSide(
                      color: AuraColors.outlineVariant.withValues(alpha: 0.25),
                    ),
                    backgroundColor: AuraColors.surfaceHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            ...doctors.map(
              (doctor) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AuraEditorialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AuraColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              doctor.initials,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AuraColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctor.name, style: textTheme.titleLarge?.copyWith(fontSize: 18)),
                                const SizedBox(height: 2),
                                Text(doctor.specialty, style: textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AuraColors.surfaceLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: AuraColors.warning),
                                const SizedBox(width: 4),
                                Text(doctor.rating, style: textTheme.labelSmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AuraStatusChip(
                        label: doctor.status,
                        color: showHistory ? AuraColors.onSurfaceVariant : AuraColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(doctor.about, style: textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showProfileSheet(context, doctor),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                  color: AuraColors.outlineVariant.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text('View profile'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AuraPrimaryButton(
                              label: showHistory ? 'Call again' : 'Consult now',
                              icon: Icons.video_call_rounded,
                              onPressed: () => Navigator.of(context).pushNamed('/live-consultation'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfileSheet(BuildContext context, _Doctor doctor) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;

        return Container(
          decoration: const BoxDecoration(
            color: AuraColors.surfaceLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AuraColors.outlineVariant,
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(doctor.name, style: textTheme.titleLarge),
                Text(doctor.specialty, style: textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(doctor.price, style: textTheme.bodyMedium?.copyWith(color: AuraColors.primary)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _InfoChip(icon: Icons.school_rounded, label: 'MBBS, MD'),
                    _InfoChip(icon: Icons.translate_rounded, label: 'English, Hindi'),
                    _InfoChip(icon: Icons.verified_rounded, label: '124 reviews'),
                    _InfoChip(icon: Icons.workspace_premium_rounded, label: '10+ years'),
                  ],
                ),
                const SizedBox(height: 16),
                AuraPrimaryButton(
                  label: 'Start consultation',
                  icon: Icons.video_call_rounded,
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/live-consultation');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Doctor {
  const _Doctor({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.status,
    required this.about,
    required this.price,
  });

  final String name;
  final String specialty;
  final String rating;
  final String status;
  final String about;
  final String price;

  String get initials {
    final words = name.split(' ');
    if (words.length < 2) return name.characters.take(2).toString();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AuraColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected ? AuraColors.primary : AuraColors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AuraColors.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
