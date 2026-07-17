import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smittenbrot_app/core/theme/app_colors.dart';
import 'package:smittenbrot_app/core/services/supabase_service.dart';

/// Profile and notification preferences screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedLocationId;
  List<Map<String, dynamic>> _locations = [];
  bool _reminderEmail = true;
  bool _reminderPush = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Profil', [
            _buildTextField(Icons.person, 'Name', _nameController),
            _buildTextField(Icons.phone, 'Telefon (optional)', _phoneController),
          ]),
          const SizedBox(height: 20),
          _buildSection('Abholort', [
            DropdownButtonFormField<String>(
              value: _selectedLocationId,
              decoration: _decoration(Icons.location_on, 'Bevorzugter Abholort'),
              items: _locations.map((loc) => DropdownMenuItem(
                value: loc['id'] as String,
                child: Text(loc['name'] as String ?? ''),
              )).toList(),
              onChanged: (v) => setState(() => _selectedLocationId = v),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('Benachrichtigungen', [
            SwitchListTile(
              title: const Text('E-Mail Erinnerungen'),
              subtitle: const Text('Vor Bestellschluss per E-Mail erinnern'),
              value: _reminderEmail,
              onChanged: (v) => setState(() => _reminderEmail = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Push-Benachrichtigungen'),
              subtitle: const Text('Abholbereit- und Erinnerungs-Push'),
              value: _reminderPush,
              onChanged: (v) => setState(() => _reminderPush = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Speichern', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await SupabaseService().signOut();
                if (mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Abmelden', style: TextStyle(color: AppColors.error)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.surfaceDark),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: _decoration(icon, label),
      ),
    );
  }

  InputDecoration _decoration(IconData icon, String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final supabase = SupabaseService().client;
      final user = SupabaseService().currentUser;
      if (user == null) return;

      await supabase.from('customers').update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'preferred_pickup_location_id': _selectedLocationId,
        'reminder_email': _reminderEmail,
        'reminder_push': _reminderPush,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Einstellungen gespeichert'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final supabase = SupabaseService().client;
    final user = SupabaseService().currentUser;

    if (user == null) return;

    final [custRes, locRes] = await Future.wait([
      supabase.from('customers').select('name, phone, preferred_pickup_location_id, reminder_email, reminder_push').eq('id', user.id).maybeSingle(),
      supabase.from('pickup_locations').select('id, name').eq('active', true).order('sort_order', ascending: true),
    ]);

    if (custRes != null) {
      _nameController.text = (custRes as Map)['name'] as String? ?? '';
      _phoneController.text = custRes['phone'] as String? ?? '';
      _selectedLocationId = custRes['preferred_pickup_location_id'] as String?;
      _reminderEmail = custRes['reminder_email'] as bool? ?? true;
      _reminderPush = custRes['reminder_push'] as bool? ?? true;
    }

    if (locRes != null) {
      _locations = (locRes as List).cast<Map<String, dynamic>>();
    }

    setState(() => _loading = false);
  }
}
