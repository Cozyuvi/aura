import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/client_dashboard_data.dart';
import '../services/auth_service.dart';
import '../theme/aura_theme.dart';
import '../widgets/aura_ui.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final _imagePicker = ImagePicker();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _sexController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bloodController = TextEditingController();
  final _cityController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _medicationsController = TextEditingController();

  Timer? _refreshTimer;
  Uint8List? _profilePhotoBytes;
  String _profilePhotoDataUrl = '';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  ClientDashboardData? _dashboard;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDashboard());
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_loadDashboard(silent: true)),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _sexController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _bloodController.dispose();
    _cityController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final dashboard = await AuthService.instance.fetchDashboard();
      if (!mounted) {
        return;
      }

      _fillControllers(dashboard.user);

      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _fillControllers(AppUser user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _ageController.text = user.profile.age?.toString() ?? '';
    _sexController.text = user.profile.sex;
    _weightController.text = user.profile.weightKg?.toString() ?? '';
    _heightController.text = user.profile.heightCm?.toString() ?? '';
    _bloodController.text = user.profile.bloodGroup;
    _cityController.text = user.profile.city;
    _conditionsController.text = user.profile.conditions.join(', ');
    _medicationsController.text = user.profile.medications.join(', ');
    _setProfilePhotoDataUrl(user.profile.photoDataUrl);
  }

  void _setProfilePhotoDataUrl(String value) {
    final trimmed = value.trim();
    _profilePhotoDataUrl = trimmed;
    _profilePhotoBytes = _decodeProfilePhotoBytes(trimmed);
  }

  Uint8List? _decodeProfilePhotoBytes(String dataUrl) {
    final trimmed = dataUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final commaIndex = trimmed.indexOf(',');
    if (commaIndex == -1) {
      return null;
    }

    final payload = trimmed.substring(commaIndex + 1).trim();
    if (payload.isEmpty) {
      return null;
    }

    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickProfilePhoto() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 768,
      maxHeight: 768,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    final mimeType = _imageMimeTypeForPath(image.path);

    if (!mounted) {
      return;
    }

    setState(() {
      _profilePhotoBytes = bytes;
      _profilePhotoDataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      _error = null;
    });
  }

  Future<void> _saveProfile() async {
    final existingUser = _dashboard?.user ?? AuthService.instance.currentUser;
    if (existingUser == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final profile = AppUserProfile(
      age: int.tryParse(_ageController.text.trim()),
      sex: _sexController.text.trim(),
      weightKg: double.tryParse(_weightController.text.trim()),
      heightCm: double.tryParse(_heightController.text.trim()),
      bloodGroup: _bloodController.text.trim(),
      city: _cityController.text.trim(),
      conditions: _splitComma(_conditionsController.text),
      medications: _splitComma(_medicationsController.text),
      photoDataUrl: _profilePhotoDataUrl.trim(),
    );

    try {
      await AuthService.instance.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profile: profile,
      );
      await _loadDashboard(silent: true);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<String> _splitComma(String value) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
  }

  String _imageMimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  Widget _buildProfilePhoto(AppUser? user) {
    final nameSeed = (user?.name.isNotEmpty ?? false)
        ? user!.name
        : _nameController.text.trim();
    final initials = nameSeed.isEmpty
        ? 'U'
        : nameSeed
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    final imageBytes = _profilePhotoBytes;
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;

    return GestureDetector(
      onTap: _pickProfilePhoto,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AuraColors.primary.withValues(alpha: 0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AuraColors.primary.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipOval(
                child: hasImage
                    ? Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AuraColors.surfaceLow,
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AuraColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AuraColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dashboard = _dashboard;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: AuraPageHeader(
                    title: 'Client dashboard',
                    subtitle: 'Profile and live health records',
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
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
            if (dashboard != null)
              AuraEditorialCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfilePhoto(dashboard.user),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dashboard.user.name,
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dashboard.user.email,
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap the photo to change it and save your profile.',
                            style: textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _pickProfilePhoto,
                      child: const Text('Change photo'),
                    ),
                  ],
                ),
              ),
            if (dashboard != null) const SizedBox(height: 14),
            if (dashboard != null)
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    label: 'Sessions',
                    value: dashboard.metrics.sessions.toString(),
                    icon: Icons.chat_rounded,
                  ),
                  _MetricCard(
                    label: 'Specialties',
                    value: dashboard.metrics.doctors.toString(),
                    icon: Icons.medical_services_rounded,
                  ),
                  _MetricCard(
                    label: 'Urgent cases',
                    value: dashboard.metrics.urgentCases.toString(),
                    icon: Icons.priority_high_rounded,
                  ),
                ],
              ),
            const SizedBox(height: 14),
            AuraEditorialCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile setup', style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: dashboard?.user.email ?? ''),
                    decoration: const InputDecoration(labelText: 'Email (registered)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _sexController,
                          decoration: const InputDecoration(labelText: 'Sex'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Weight (kg)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Height (cm)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bloodController,
                          decoration: const InputDecoration(labelText: 'Blood group'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _conditionsController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Medical conditions (comma separated)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _medicationsController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Current medications (comma separated)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  AuraPrimaryButton(
                    label: _isSaving ? 'Saving profile...' : 'Save profile',
                    icon: Icons.save_rounded,
                    onPressed: _isSaving ? () {} : _saveProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (dashboard?.latestRecord != null)
              AuraEditorialCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latest assessment', style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      dashboard!.latestRecord!.diagnosisSummary.isNotEmpty
                          ? dashboard.latestRecord!.diagnosisSummary
                          : dashboard.latestRecord!.spokenResponse,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    AuraStatusChip(
                      label:
                          '${dashboard.latestRecord!.targetSpecialty} • ${dashboard.latestRecord!.urgency}',
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Text('Recent assessments', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            if ((dashboard?.recentRecords.length ?? 0) == 0)
              Text(
                'No assessment records yet. Start a consultation to populate your dashboard.',
                style: textTheme.bodySmall,
              )
            else
              ...dashboard!.recentRecords.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AuraEditorialCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.targetSpecialty.isNotEmpty
                              ? record.targetSpecialty
                              : 'General Medicine',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.diagnosisSummary.isNotEmpty
                              ? record.diagnosisSummary
                              : record.spokenResponse,
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AuraColors.primary),
          const Spacer(),
          Text(value, style: textTheme.titleLarge?.copyWith(fontSize: 20)),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
