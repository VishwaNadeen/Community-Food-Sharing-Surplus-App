
import 'package:flutter/material.dart';

import '../../models/recipient_model.dart';
import '../../services/recipient_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class RecipientEditProfileScreen extends StatefulWidget {
  final String token;
  final RecipientModel profile;

  const RecipientEditProfileScreen({
    super.key,
    required this.token,
    required this.profile,
  });

  @override
  State<RecipientEditProfileScreen> createState() =>
      _RecipientEditProfileScreenState();
}

class _RecipientEditProfileScreenState
    extends State<RecipientEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nicController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _timeZoneController;
  late final TextEditingController _languageController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final p = widget.profile;

    _firstNameController = TextEditingController(text: p.firstName);
    _lastNameController = TextEditingController(text: p.lastName);
    _nicController = TextEditingController(text: p.nic);
    _phoneController = TextEditingController(text: p.phoneNumber);
    _addressLine1Controller =
        TextEditingController(text: p.addressLine1);
    _addressLine2Controller =
        TextEditingController(text: p.addressLine2 ?? '');
    _cityController = TextEditingController(text: p.city);
    _districtController = TextEditingController(text: p.district);
    _timeZoneController = TextEditingController(text: p.timeZone);
    _languageController = TextEditingController(text: p.language);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _timeZoneController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  String? _validateNic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIC is required';
    }

    final nic = value.trim().toUpperCase();
    final oldFormat = RegExp(r'^\d{9}[VX]$');
    final newFormat = RegExp(r'^\d{12}$');

    if (!oldFormat.hasMatch(nic) &&
        !newFormat.hasMatch(nic)) {
      return 'Enter a valid NIC';
    }

    return null;
  }

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'nic': _nicController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'addressLine1': _addressLine1Controller.text.trim(),
      'city': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'timeZone': _timeZoneController.text.trim(),
      'language': _languageController.text.trim(),
    };

    final addressLine2 = _addressLine2Controller.text.trim();

    if (addressLine2.isNotEmpty) {
      payload['addressLine2'] = addressLine2;
    }

    return payload;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = await RecipientService.updateProfile(
        token: widget.token,
        data: _buildPayload(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );

      Navigator.pop(context, updatedProfile);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
            color: AppTheme.darkText,
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppTheme.darkText,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_outline,
                        color: AppTheme.primaryGreen,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update your details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Keep your recipient information accurate.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              _sectionTitle('Personal Information'),
              const SizedBox(height: 12),

              _field(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
                validator: _required('First name'),
              ),
              _field(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
                validator: _required('Last name'),
              ),
              _field(
                controller: _nicController,
                label: 'NIC Number',
                icon: Icons.badge_outlined,
                validator: _validateNic,
              ),
              _field(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _required('Phone number'),
              ),

              const SizedBox(height: 18),

              _sectionTitle('Address'),
              const SizedBox(height: 12),

              _field(
                controller: _addressLine1Controller,
                label: 'Address Line 1',
                icon: Icons.home_outlined,
                validator: _required('Address line 1'),
              ),
              _field(
                controller: _addressLine2Controller,
                label: 'Address Line 2 (Optional)',
                icon: Icons.home_work_outlined,
              ),
              _field(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city_outlined,
                validator: _required('City'),
              ),
              _field(
                controller: _districtController,
                label: 'District',
                icon: Icons.map_outlined,
                validator: _required('District'),
              ),

              const SizedBox(height: 18),

              _sectionTitle('Preferences'),
              const SizedBox(height: 12),

              _field(
                controller: _timeZoneController,
                label: 'Time Zone',
                icon: Icons.schedule_outlined,
                validator: _required('Time zone'),
              ),
              _field(
                controller: _languageController,
                label: 'Language',
                icon: Icons.language_outlined,
                validator: _required('Language'),
              ),

              const SizedBox(height: 24),

              PrimaryButton(
                text: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _saveChanges,
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.greyText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String? Function(String?) _required(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required';
      }
      return null;
    };
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkText,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomTextField(
        controller: controller,
        hint: label,
        prefixIcon: icon,
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }
}
