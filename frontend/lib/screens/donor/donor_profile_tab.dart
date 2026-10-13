import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import 'donor_ui.dart';

class DonorProfileTab extends StatefulWidget {
  const DonorProfileTab({super.key});

  @override
  State<DonorProfileTab> createState() => _DonorProfileTabState();
}

class _DonorProfileTabState extends State<DonorProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _notesController = TextEditingController();

  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  // Stored donor type codes and the names shown to the donor.
  static const Map<String, String> _donorTypeNames = {
    'INDIVIDUAL': 'Individual',
    'ORGANIZATION': 'Organization',
  };

  String? _donorType;
  String? _province;
  String? _district;
  String? _city;
  LatLng? _selectedLocation;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasProfile = false;
  bool _submitAttempted = false;
  String? _loadError;

  final Map<String, List<String>> _districtsByProvince = {
    'Western': ['Colombo', 'Gampaha', 'Kalutara'],
    'Central': ['Kandy', 'Matale', 'Nuwara Eliya'],
    'Southern': ['Galle', 'Matara', 'Hambantota'],
    'Northern': ['Jaffna', 'Kilinochchi', 'Mannar', 'Mullaitivu', 'Vavuniya'],
    'Eastern': ['Ampara', 'Batticaloa', 'Trincomalee'],
    'North Western': ['Kurunegala', 'Puttalam'],
    'North Central': ['Anuradhapura', 'Polonnaruwa'],
    'Uva': ['Badulla', 'Monaragala'],
    'Sabaragamuwa': ['Ratnapura', 'Kegalle'],
  };

  // Starter city lists. These can be expanded as needed.
  final Map<String, List<String>> _citiesByDistrict = {
    'Colombo': ['Colombo', 'Dehiwala', 'Moratuwa', 'Maharagama', 'Kotte'],
    'Gampaha': ['Gampaha', 'Negombo', 'Ja-Ela', 'Wattala', 'Kadawatha'],
    'Kalutara': ['Kalutara', 'Panadura', 'Horana', 'Beruwala'],
    'Kandy': ['Kandy', 'Peradeniya', 'Katugastota'],
    'Matale': ['Matale', 'Dambulla', 'Sigiriya'],
    'Nuwara Eliya': ['Nuwara Eliya', 'Hatton', 'Talawakele'],
    'Galle': ['Galle', 'Hikkaduwa', 'Ambalangoda'],
    'Matara': ['Matara', 'Weligama', 'Akuressa'],
    'Hambantota': ['Hambantota', 'Tangalle', 'Tissamaharama'],
    'Jaffna': ['Jaffna', 'Nallur', 'Chavakachcheri'],
    'Kilinochchi': ['Kilinochchi'],
    'Mannar': ['Mannar'],
    'Mullaitivu': ['Mullaitivu'],
    'Vavuniya': ['Vavuniya'],
    'Ampara': ['Ampara', 'Kalmunai', 'Akkaraipattu'],
    'Batticaloa': ['Batticaloa', 'Eravur'],
    'Trincomalee': ['Trincomalee', 'Kinniya'],
    'Kurunegala': ['Kurunegala', 'Kuliyapitiya', 'Narammala'],
    'Puttalam': ['Puttalam', 'Chilaw', 'Wennappuwa'],
    'Anuradhapura': ['Anuradhapura', 'Kekirawa'],
    'Polonnaruwa': ['Polonnaruwa', 'Kaduruwela'],
    'Badulla': ['Badulla', 'Bandarawela', 'Haputale'],
    'Monaragala': ['Monaragala', 'Wellawaya'],
    'Ratnapura': ['Ratnapura', 'Embilipitiya', 'Balangoda'],
    'Kegalle': ['Kegalle', 'Mawanella'],
  };

  // Approximate coordinates used to focus the map when a district changes.
  final Map<String, LatLng> _districtCoordinates = {
    'Colombo': LatLng(6.9271, 79.8612),
    'Gampaha': LatLng(7.0917, 79.9990),
    'Kalutara': LatLng(6.5854, 79.9607),
    'Kandy': LatLng(7.2906, 80.6337),
    'Matale': LatLng(7.4675, 80.6234),
    'Nuwara Eliya': LatLng(6.9497, 80.7891),
    'Galle': LatLng(6.0535, 80.2210),
    'Matara': LatLng(5.9549, 80.5550),
    'Hambantota': LatLng(6.1429, 81.1212),
    'Jaffna': LatLng(9.6615, 80.0255),
    'Kilinochchi': LatLng(9.3803, 80.3770),
    'Mannar': LatLng(8.9810, 79.9044),
    'Mullaitivu': LatLng(9.2671, 80.8142),
    'Vavuniya': LatLng(8.7542, 80.4982),
    'Ampara': LatLng(7.2975, 81.6820),
    'Batticaloa': LatLng(7.7310, 81.6747),
    'Trincomalee': LatLng(8.5874, 81.2152),
    'Kurunegala': LatLng(7.4863, 80.3623),
    'Puttalam': LatLng(8.0362, 79.8283),
    'Anuradhapura': LatLng(8.3114, 80.4037),
    'Polonnaruwa': LatLng(7.9403, 81.0188),
    'Badulla': LatLng(6.9934, 81.0550),
    'Monaragala': LatLng(6.8728, 81.3507),
    'Ratnapura': LatLng(6.7056, 80.3847),
    'Kegalle': LatLng(7.2513, 80.3464),
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _notesController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final token = context.read<AuthProvider>().token;

    if (token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await AuthService.getDonorProfile(token);

      // Accept either a direct profile response or a wrapped response.
      final dynamic rawProfile = response['donor'] ??
          response['profile'] ??
          response['data'] ??
          response;

      if (rawProfile is Map) {
        final profile = Map<String, dynamic>.from(rawProfile);

        _firstNameController.text = profile['firstName']?.toString() ?? '';
        _lastNameController.text = profile['lastName']?.toString() ?? '';
        _phoneController.text = profile['phoneNumber']?.toString() ?? '';
        _organizationController.text =
            profile['organizationName']?.toString() ?? '';
        _addressLine1Controller.text =
            profile['addressLine1']?.toString() ?? '';
        _addressLine2Controller.text =
            profile['addressLine2']?.toString() ?? '';
        _notesController.text = profile['notes']?.toString() ?? '';

        final type = profile['donorType']?.toString();
        _donorType = _donorTypeNames.containsKey(type) ? type : null;

        final province = profile['province']?.toString();
        if (province != null && _districtsByProvince.containsKey(province)) {
          _province = province;
        }

        final district = profile['district']?.toString();
        if (_province != null &&
            _districtsByProvince[_province]!.contains(district)) {
          _district = district;
        }

        final city = profile['city']?.toString();
        if (_district != null &&
            (_citiesByDistrict[_district] ?? []).contains(city)) {
          _city = city;
        }

        final latitude = profile['latitude'];
        final longitude = profile['longitude'];

        if (latitude != null && longitude != null) {
          final lat = double.tryParse(latitude.toString());
          final lng = double.tryParse(longitude.toString());

          if (lat != null && lng != null) {
            _selectedLocation = LatLng(lat, lng);
          }
        }

        _hasProfile = profile['customUserId'] != null ||
            profile['firstName'] != null;
      }
    } catch (error) {
      // A missing profile is expected for a new donor, so the empty
      // form is shown. Any other problem is shown with a retry button,
      // so the donor does not fill in a form that cannot be saved.
      final isMissingProfile =
          error.toString().toLowerCase().contains('not found');

      if (!isMissingProfile) {
        debugPrint('Donor profile loading: $error');
        _loadError = friendlyErrorMessage(error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _focusMap() {
    final center = _district != null
        ? _districtCoordinates[_district] ?? _sriLankaCenter
        : _sriLankaCenter;

    _mapController.move(center, _district != null ? 12 : 7);
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitAttempted = true);

    if (!_formKey.currentState!.validate()) {
      showDonorError(
        context,
        'Some details need fixing. Check the fields marked in red.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final token = auth.token;

    if (token == null) {
      showDonorError(context, kSessionErrorMessage);
      return;
    }

    final profileData = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'donorType': _donorType,
      'organizationName': _donorType == 'ORGANIZATION'
          ? _organizationController.text.trim()
          : null,
      'addressLine1': _addressLine1Controller.text.trim(),
      'addressLine2': _addressLine2Controller.text.trim().isEmpty
          ? null
          : _addressLine2Controller.text.trim(),
      'province': _province,
      'district': _district,
      'city': _city,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'latitude': _selectedLocation?.latitude,
      'longitude': _selectedLocation?.longitude,
    };

    setState(() => _isSaving = true);

    try {
      if (_hasProfile) {
        await AuthService.updateDonorProfile(
          token: token,
          profileData: profileData,
        );
      } else {
        await AuthService.createDonorProfile(
          token: token,
          profileData: profileData,
        );
      }

      if (!mounted) return;

      await auth.refreshDonorProfileStatus();

      if (!mounted) return;

      setState(() => _hasProfile = true);
      showDonorSuccess(context, 'Your profile has been saved.');
    } catch (error) {
      if (mounted) {
        showDonorError(
          context,
          'Your profile was not saved. ${friendlyErrorMessage(error)}',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await confirmDonorAction(
      context,
      title: 'Log out?',
      message: 'You will need to log in again to manage your donations.',
      confirmLabel: 'Log out',
      cancelLabel: 'Stay logged in',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    await context.read<AuthProvider>().logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  // ---------- Validation ----------

  String? Function(String?) _required(String message) {
    return (value) =>
        value == null || value.trim().isEmpty ? message : null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'[\s-]'), '') ?? '';

    if (phone.isEmpty) {
      return 'Enter your phone number so volunteers can reach you.';
    }

    // Sri Lankan numbers: 0771234567 or +94771234567.
    if (!RegExp(r'^(?:\+94|0)\d{9}$').hasMatch(phone)) {
      return 'Enter a 10-digit number, for example 0771234567.';
    }

    return null;
  }

  // ---------- UI ----------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.words,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      maxLines: maxLines,
      style: kDonorFieldTextStyle,
      validator: validator,
      decoration: donorInputDecoration(label, hint: hint, icon: icon),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required String requiredMessage,
    required ValueChanged<String?> onChanged,
    IconData? icon,
    String? hint,
    String Function(String)? itemLabel,
  }) {
    return DropdownButtonFormField<String>(
      // initialValue is only read once, so the key rebuilds the field
      // when the value is reset (for example, district after a new
      // province is chosen).
      key: ValueKey('$label-$value-${items.length}'),
      initialValue: value,
      isExpanded: true,
      style: kDonorFieldTextStyle,
      decoration: donorInputDecoration(label, icon: icon, hint: hint),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                itemLabel?.call(item) ?? item,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: (selected) => selected == null ? requiredMessage : null,
      // Disabled until there is something to choose from.
      onChanged: items.isEmpty ? null : onChanged,
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: DonorTextSize.section,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 300,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD5DAD8)),
          ),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation ?? _sriLankaCenter,
                  initialZoom: _selectedLocation != null ? 14 : 7,
                  onTap: (tapPosition, point) {
                    setState(() => _selectedLocation = point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.foodlink',
                    maxZoom: 19,
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            color: AppTheme.danger,
                            size: 46,
                          ),
                        ),
                      ],
                    ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Tap the map to place your pin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: DonorTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 24,
                child: FloatingActionButton(
                  heroTag: 'donorMapSriLanka',
                  tooltip: 'Show all of Sri Lanka',
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryGreen,
                  onPressed: () {
                    _mapController.move(_sriLankaCenter, 7);
                  },
                  child: const Icon(Icons.zoom_out_map),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedLocation != null)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.primaryGreenDark,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pin placed on the map',
                    style: TextStyle(
                      fontSize: DonorTextSize.body,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedLocation = null),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, kDonorTapHeight),
                    foregroundColor: AppTheme.danger,
                    textStyle: const TextStyle(
                      fontSize: DonorTextSize.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Remove pin'),
                ),
              ],
            ),
          )
        else
          const Text(
            'Optional. A pin helps volunteers find you faster.',
            style: TextStyle(
              fontSize: DonorTextSize.body,
              color: AppTheme.mutedText,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ColoredBox(
        color: AppTheme.fieldFill,
        child: DonorLoadingView(message: 'Loading your profile...'),
      );
    }

    if (_loadError != null) {
      return ColoredBox(
        color: AppTheme.fieldFill,
        child: SafeArea(
          child: DonorMessageView.error(
            title: 'Could not load your profile',
            message: _loadError!,
            onAction: _loadProfile,
          ),
        ),
      );
    }

    final districts = _province == null
        ? <String>[]
        : _districtsByProvince[_province] ?? <String>[];

    final cities =
        _district == null ? <String>[] : _citiesByDistrict[_district] ?? [];

    return Container(
      color: AppTheme.fieldFill,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                autovalidateMode: _submitAttempted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: AppTheme.lightGreen,
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 48,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'My Donor Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasProfile
                          ? 'Keep your details up to date so volunteers '
                              'can collect your donations.'
                          : 'Add your details so volunteers know where to '
                              'collect your donations.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: DonorTextSize.body,
                        color: AppTheme.mutedText,
                        height: 1.5,
                      ),
                    ),

                    _sectionTitle('Personal Information', Icons.person_outline),
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'First name',
                      icon: Icons.badge_outlined,
                      validator: _required('Enter your first name.'),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Last name',
                      icon: Icons.badge_outlined,
                      validator: _required('Enter your last name.'),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone number',
                      hint: 'e.g. 0771234567',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      capitalization: TextCapitalization.none,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'I am donating as',
                      icon: Icons.groups_outlined,
                      value: _donorType,
                      items: _donorTypeNames.keys.toList(),
                      itemLabel: (type) => _donorTypeNames[type] ?? type,
                      requiredMessage:
                          'Choose whether you are an individual or an '
                          'organization.',
                      onChanged: (value) {
                        setState(() => _donorType = value);
                      },
                    ),
                    if (_donorType == 'ORGANIZATION') ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _organizationController,
                        label: 'Organization name',
                        icon: Icons.business_outlined,
                        validator:
                            _required('Enter the name of your organization.'),
                      ),
                    ],

                    _sectionTitle('Address', Icons.home_outlined),
                    _buildDropdown(
                      label: 'Province',
                      icon: Icons.map_outlined,
                      value: _province,
                      items: _districtsByProvince.keys.toList(),
                      requiredMessage: 'Choose your province.',
                      onChanged: (value) {
                        setState(() {
                          _province = value;
                          _district = null;
                          _city = null;
                        });
                        _focusMap();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'District',
                      icon: Icons.location_city_outlined,
                      hint: _province == null ? 'Choose a province first' : null,
                      value: _district,
                      items: districts,
                      requiredMessage: _province == null
                          ? 'Choose your province first, then your district.'
                          : 'Choose your district.',
                      onChanged: (value) {
                        setState(() {
                          _district = value;
                          _city = null;
                        });
                        _focusMap();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'City',
                      icon: Icons.place_outlined,
                      hint: _district == null ? 'Choose a district first' : null,
                      value: _city,
                      items: cities,
                      requiredMessage: _district == null
                          ? 'Choose your district first, then your city.'
                          : 'Choose your city.',
                      onChanged: (value) {
                        setState(() => _city = value);
                        _focusMap();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressLine1Controller,
                      label: 'Address line 1',
                      hint: 'House number and street',
                      icon: Icons.location_on_outlined,
                      validator:
                          _required('Enter your house number and street.'),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressLine2Controller,
                      label: 'Address line 2 (optional)',
                      icon: Icons.add_location_alt_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _notesController,
                      label: 'Notes for volunteers (optional)',
                      hint: 'e.g. Gate is next to the bakery',
                      icon: Icons.notes_outlined,
                      capitalization: TextCapitalization.sentences,
                      maxLines: 3,
                    ),

                    _sectionTitle('Map Location', Icons.map_outlined),
                    const Text(
                      'Place a pin where volunteers should collect your '
                      'donations. Choosing a district moves the map there.',
                      style: TextStyle(
                        fontSize: DonorTextSize.body,
                        color: AppTheme.mutedText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLocationPicker(),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: donorFilledButtonStyle(),
                        icon: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : _hasProfile
                                  ? 'Save Changes'
                                  : 'Save Profile',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _logout,
                      style: donorOutlinedButtonStyle(color: AppTheme.danger),
                      icon: const Icon(Icons.logout_outlined),
                      label: const Text('Log out'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
