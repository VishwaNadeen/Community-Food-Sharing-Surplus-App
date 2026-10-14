import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class VolunteerProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;
  final VolunteerProfileModel? existingProfile;

  const VolunteerProfileSetupScreen({
    super.key,
    this.isEditMode = false,
    this.existingProfile,
  });

  @override
  State<VolunteerProfileSetupScreen> createState() =>
      _VolunteerProfileSetupScreenState();
}

class _VolunteerProfileSetupScreenState
    extends State<VolunteerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _nicController;

  String _vehicleType = 'Motorcycle';
  bool _isLoading = false;

  final List<String> _vehicleTypes = [
    'Motorcycle',
    'Scooter',
    'Car',
    'Van',
    'Bicycle',
    'Three-Wheeler',
    'Walker / On Foot'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _firstNameController = TextEditingController(text: p?.firstName ?? '');
    _lastNameController = TextEditingController(text: p?.lastName ?? '');
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _addressLine1Controller = TextEditingController(text: p?.addressLine1 ?? '');
    _addressLine2Controller = TextEditingController(text: p?.addressLine2 ?? '');
    _cityController = TextEditingController(text: p?.city ?? '');
    _districtController = TextEditingController(text: p?.district ?? '');
    _vehicleNumberController =
        TextEditingController(text: p?.vehicleNumber ?? '');
    _nicController = TextEditingController(text: p?.nic ?? '');

    if (p?.vehicleType != null && _vehicleTypes.contains(p!.vehicleType)) {
      _vehicleType = p.vehicleType!;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _vehicleNumberController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (widget.isEditMode) {
      Navigator.pop(context);
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Setup?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'You need to complete your volunteer profile before you can access deliveries. Do you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Setup', style: TextStyle(color: AppTheme.greyText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim().isEmpty
            ? null
            : _addressLine2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'vehicleType': _vehicleType,
        'vehicleNumber': _vehicleNumberController.text.trim().isEmpty
            ? null
            : _vehicleNumberController.text.trim(),
        'nic': _nicController.text.trim().isEmpty
            ? null
            : _nicController.text.trim(),
      };

      final updatedProfile = await VolunteerService.updateProfile(
        token: token,
        data: payload,
      );

      auth.setProfileCompleted(true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Profile updated successfully!'
                : 'Welcome, ${updatedProfile.fullName}! Your volunteer account is ready.',
          ),
          backgroundColor: AppTheme.primaryGreenDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (widget.isEditMode) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacementNamed(context, '/volunteer-home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            widget.isEditMode
                ? 'Edit Volunteer Profile'
                : 'Complete Volunteer Account',
            style: const TextStyle(
              color: AppTheme.darkText,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.darkText,
              size: 20,
            ),
            onPressed: _handleBack,
          ),
          actions: [
            if (!widget.isEditMode)
              TextButton(
                onPressed: _handleBack,
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFE2E8F0)),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isEditMode) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delivery_dining_rounded,
                              color: AppTheme.primaryGreenDark,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Almost Ready to Deliver!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Please provide contact and vehicle details so coordinators can assign surplus pickups near you.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Personal Information Card ──
                  _formSectionCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('First Name'),
                                CustomTextField(
                                  hint: 'e.g. Nimal',
                                  prefixIcon: Icons.person_outline_rounded,
                                  controller: _firstNameController,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('Last Name'),
                                CustomTextField(
                                  hint: 'e.g. Perera',
                                  prefixIcon: Icons.badge_outlined,
                                  controller: _lastNameController,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Phone Number'),
                      CustomTextField(
                        hint: '077 123 4567',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Phone number is required';
                          if (v.trim().replaceAll(RegExp(r'\D'), '').length < 9) {
                            return 'Enter a valid phone number (at least 9 digits)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('National ID / NIC (Optional)'),
                      CustomTextField(
                        hint: '200012345678 or 991234567V',
                        prefixIcon: Icons.credit_card_outlined,
                        controller: _nicController,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Address Information Card ──
                  _formSectionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Home Base & Address',
                    children: [
                      _fieldLabel('Street Address (Line 1)'),
                      CustomTextField(
                        hint: '123 Main Street',
                        prefixIcon: Icons.home_outlined,
                        controller: _addressLine1Controller,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Street address is required' : null,
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Address Line 2 (Optional)'),
                      CustomTextField(
                        hint: 'Apartment, Suite, Unit',
                        prefixIcon: Icons.location_city_outlined,
                        controller: _addressLine2Controller,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('City'),
                                CustomTextField(
                                  hint: 'Colombo',
                                  prefixIcon: Icons.location_on_outlined,
                                  controller: _cityController,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fieldLabel('District'),
                                CustomTextField(
                                  hint: 'Western',
                                  prefixIcon: Icons.map_outlined,
                                  controller: _districtController,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Vehicle & Delivery Info Card ──
                  _formSectionCard(
                    icon: Icons.two_wheeler_outlined,
                    title: 'Vehicle & Transportation',
                    children: [
                      _fieldLabel('Vehicle Type'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.fieldFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _vehicleType,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.greyText,
                            ),
                            items: _vehicleTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: AppTheme.darkText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _vehicleType = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel('Vehicle Plate / Registration Number (Optional)'),
                      CustomTextField(
                        hint: 'WP BCD-1234',
                        prefixIcon: Icons.pin_outlined,
                        controller: _vehicleNumberController,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Submit Button ──
                  PrimaryButton(
                    text: widget.isEditMode
                        ? 'Save Profile Changes'
                        : 'Complete Profile & Continue',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primaryGreenDark),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFE2E8F0)),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
