import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/recipient_model.dart';
import '../../services/recipient_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import 'recipient_edit_profile_screen.dart';

// ====================== SCREEN ENTRY POINT ======================
//
// Pass [token] always.
// Pass [existingProfile] when the user already has a profile
//   → starts in View mode.
// Leave [existingProfile] null for a fresh create.

class RecipientProfileScreen extends StatefulWidget {
  final String token;
  final RecipientModel? existingProfile;

  const RecipientProfileScreen({
    super.key,
    required this.token,
    this.existingProfile,
  });

  @override
  State<RecipientProfileScreen> createState() =>
      _RecipientProfileScreenState();
}

// ====================== SCREEN MODES ======================

enum _ScreenMode { create, view, edit }

class _RecipientProfileScreenState
    extends State<RecipientProfileScreen> {
  // -------------------- state --------------------
  late _ScreenMode _mode;
  RecipientModel? _profile;
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _profileLoadError;

  // -------------------- form --------------------
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _timeZoneController = TextEditingController();
  final _languageController = TextEditingController();

  // ====================== LIFECYCLE ======================

  
  @override
  void initState() {
    super.initState();

    if (widget.existingProfile != null) {
      _profile = widget.existingProfile;
      _mode = _ScreenMode.view;
      _populateControllers(widget.existingProfile!);
      _isLoadingProfile = false;
    } else {
      _mode = _ScreenMode.create;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingProfile();
      });
    }
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

  // ====================== HELPERS ======================

  void _populateControllers(RecipientModel p) {
    _firstNameController.text = p.firstName;
    _lastNameController.text = p.lastName;
    _nicController.text = p.nic;
    _phoneController.text = p.phoneNumber;
    _addressLine1Controller.text = p.addressLine1;
    _addressLine2Controller.text = p.addressLine2 ?? '';
    _cityController.text = p.city;
    _districtController.text = p.district;
    _timeZoneController.text = p.timeZone;
    _languageController.text = p.language;
  }

  void _clearControllers() {
    _firstNameController.clear();
    _lastNameController.clear();
    _nicController.clear();
    _phoneController.clear();
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _districtController.clear();
    _timeZoneController.clear();
    _languageController.clear();
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

    final addr2 = _addressLine2Controller.text.trim();
    if (addr2.isNotEmpty) payload['addressLine2'] = addr2;

    return payload;
  }

  // ====================== NIC CLIENT VALIDATION ======================

  String? _validateNic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIC is required';
    }
    final v = value.trim().toUpperCase();
    final oldFormat = RegExp(r'^\d{9}[VX]$');
    final newFormat = RegExp(r'^\d{12}$');
    if (!oldFormat.hasMatch(v) && !newFormat.hasMatch(v)) {
      return 'Enter a valid NIC (e.g. 123456789V or 200012345678)';
    }
    return null;
  }

  // ====================== ACTIONS ======================

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = await RecipientService.createProfile(
        token: widget.token,
        data: _buildPayload(),
      );

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _mode = _ScreenMode.view;
      });

      // Mark profile as completed in AuthProvider
      Provider.of<AuthProvider>(context, listen: false)
          .setProfileCompleted(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile created successfully'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );

      // Navigate to recipient home
      Navigator.pushReplacementNamed(context, '/recipient-home');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = await RecipientService.updateProfile(
        token: widget.token,
        data: _buildPayload(),
      );

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _mode = _ScreenMode.view;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Logout'),
      content: const Text(
        'Are you sure you want to logout?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (shouldLogout != true || !mounted) return;

  await Provider.of<AuthProvider>(
    context,
    listen: false,
  ).logout();

  if (!mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/login',
    (_) => false,
  );
 }
  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text(
          'Are you sure you want to delete your recipient profile? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await RecipientService.deleteProfile(token: widget.token);

      if (!mounted) return;

      setState(() {
        _profile = null;
        _mode = _ScreenMode.create;
        _clearControllers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile deleted'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 
  Future<void> _enterEditMode() async {
    if (_profile == null) return;

    final updatedProfile = await Navigator.push<RecipientModel>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipientEditProfileScreen(
          token: widget.token,
          profile: _profile!,
        ),
      ),
    );

    if (updatedProfile != null && mounted) {
      setState(() {
        _profile = updatedProfile;
      });
    }
  }

  void _cancelEdit() {
    _clearControllers();
    setState(() => _mode = _ScreenMode.view);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }


Future<void> _loadExistingProfile() async {
  if (!mounted) return;

  setState(() {
    _isLoadingProfile = true;
    _profileLoadError = null;
  });

  try {
    final profile = await RecipientService.getProfile(
      token: widget.token,
    );

    if (!mounted) return;

    setState(() {
      _profile = profile;
      _mode = _ScreenMode.view;
      _isLoadingProfile = false;
    });

    _populateControllers(profile);
  } catch (e) {
    if (!mounted) return;

    final message = e
        .toString()
        .replaceFirst('Exception: ', '');

    final lowerMessage = message.toLowerCase();

    final profileDoesNotExist =
        lowerMessage.contains('not found') ||
        lowerMessage.contains('does not exist') ||
        lowerMessage.contains('no recipient profile');

    setState(() {
      _isLoadingProfile = false;

      if (profileDoesNotExist) {
        _profile = null;
        _mode = _ScreenMode.create;
      } else {
        _profileLoadError = message;
      }
    });
  }
}

  // ====================== BUILD ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _mode == _ScreenMode.edit
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.darkText,
                ),
                onPressed: _cancelEdit,
              )
            : null,
        title: Text(
          _mode == _ScreenMode.create
              ? 'Complete Profile'
              : _mode == _ScreenMode.edit
                  ? 'Edit Profile'
                  : 'My Profile',
          style: const TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              )
            : _profileLoadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _profileLoadError!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadExistingProfile,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _mode == _ScreenMode.view && _profile != null
                    ? _buildViewMode()
                    : _buildFormMode(),
      ),
    );
  }

  // ====================== VIEW MODE ======================

  
  Widget _buildViewMode() {
    final p = _profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.primaryGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${p.firstName} ${p.lastName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FoodLink Recipient',
                    style: TextStyle(
                      color: AppTheme.primaryGreenDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Edit profile action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _enterEditMode,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),

          _infoSection('Contact Details', [
            _infoRow(Icons.badge_outlined, 'NIC', p.nic),
            _infoRow(Icons.phone_outlined, 'Phone Number', p.phoneNumber),
          ]),

          const SizedBox(height: 16),

          _infoSection('Address Information', [
            _infoRow(
              Icons.home_outlined,
              'Address Line 1',
              p.addressLine1,
            ),
            if (p.addressLine2 != null &&
                p.addressLine2!.isNotEmpty)
              _infoRow(
                Icons.home_work_outlined,
                'Address Line 2',
                p.addressLine2!,
              ),
            _infoRow(Icons.location_city_outlined, 'City', p.city),
            _infoRow(Icons.map_outlined, 'District', p.district),
            if (p.latitude != null && p.longitude != null)
              _infoRow(
                Icons.my_location_outlined,
                'GPS Coordinates',
                '${p.latitude!.toStringAsFixed(5)}, '
                    '${p.longitude!.toStringAsFixed(5)}',
              ),
          ]),

          const SizedBox(height: 16),

          _infoSection('Preferences', [
            _infoRow(
              Icons.schedule_outlined,
              'Time Zone',
              p.timeZone,
            ),
            _infoRow(
              Icons.language_outlined,
              'Language',
              p.language,
            ),
          ]),

          const SizedBox(height: 28),

          // Delete profile action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteProfile,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(
                  color: Colors.red.shade200,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Text(
              'Manage your FoodLink recipient information.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.greyText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreenDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================== FORM MODE (CREATE / EDIT) ======================

  Widget _buildFormMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header ----
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.primaryGreenDark,
                size: 28,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              _mode == _ScreenMode.create
                  ? 'Complete Your Profile'
                  : 'Update Your Profile',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _mode == _ScreenMode.create
                  ? 'Fill in the details to set up your recipient profile.'
                  : 'Edit the fields you want to update.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // ==================== FIRST NAME ====================

            _sectionLabel('Personal Information'),
            const SizedBox(height: 10),

            CustomTextField(
              controller: _firstNameController,
              hint: 'First Name',
              prefixIcon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // ==================== LAST NAME ====================

            CustomTextField(
              controller: _lastNameController,
              hint: 'Last Name',
              prefixIcon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            // ==================== NIC ====================

            CustomTextField(
              controller: _nicController,
              hint: 'NIC  (e.g. 123456789V or 200012345678)',
              prefixIcon: Icons.badge_outlined,
              validator: _validateNic,
            ),

            const SizedBox(height: 14),

            // ==================== PHONE ====================

            CustomTextField(
              controller: _phoneController,
              hint: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ==================== ADDRESS ====================

            _sectionLabel('Address'),
            const SizedBox(height: 10),

            CustomTextField(
              controller: _addressLine1Controller,
              hint: 'Address Line 1',
              prefixIcon: Icons.home_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Address Line 1 is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            CustomTextField(
              controller: _addressLine2Controller,
              hint: 'Address Line 2 (optional)',
              prefixIcon: Icons.home_outlined,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              controller: _cityController,
              hint: 'City',
              prefixIcon: Icons.location_city_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'City is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            CustomTextField(
              controller: _districtController,
              hint: 'District',
              prefixIcon: Icons.map_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'District is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ==================== PREFERENCES ====================

            _sectionLabel('Preferences'),
            const SizedBox(height: 10),

            CustomTextField(
              controller: _timeZoneController,
              hint: 'Time Zone  (e.g. Asia/Colombo)',
              prefixIcon: Icons.schedule_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Time zone is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            CustomTextField(
              controller: _languageController,
              hint: 'Language  (e.g. English)',
              prefixIcon: Icons.language_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Language is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // ==================== SUBMIT ====================

            PrimaryButton(
              text: _mode == _ScreenMode.create
                  ? 'Create Profile'
                  : 'Save Changes',
              isLoading: _isLoading,
              onPressed: _mode == _ScreenMode.create
                  ? _createProfile
                  : _updateProfile,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.greyText,
        letterSpacing: 0.8,
      ),
    );
  }
}
