import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';

import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';

import '../../providers/auth_provider.dart';

import '../../services/auth_service.dart';

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

  String? _donorType;

  String? _province;

  String? _district;

  String? _city;

  LatLng? _selectedLocation;

  bool _isLoading = true;

  bool _isSaving = false;

  bool _hasProfile = false;

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

        _donorType = type == 'INDIVIDUAL' || type == 'ORGANIZATION'

            ? type

            : null;

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

      // A missing profile is expected for a new donor.

      debugPrint('Donor profile loading: $error');

    } finally {

      if (mounted) setState(() => _isLoading = false);

    }

  }

  void _focusMap() {

    LatLng? center;

    if (_city != null && _district != null) {

      center = _districtCoordinates[_district];

    } else if (_district != null) {

      center = _districtCoordinates[_district];

    }

    center ??= _sriLankaCenter;

    _mapController.move(center, 12);

  }

  Future<void> _saveProfile() async {

    if (!_formKey.currentState!.validate()) return;

    if (_province == null || _district == null || _city == null) {

      _showMessage('Please select your province, district, and city.');

      return;

    }

    if (_donorType == null) {

      _showMessage('Please select your donor type.');

      return;

    }

    if (_donorType == 'ORGANIZATION' &&

        _organizationController.text.trim().isEmpty) {

      _showMessage('Please enter your organization name.');

      return;

    }

    final auth = context.read<AuthProvider>();

    final token = auth.token;

    if (token == null) {

      _showMessage('Your session has expired. Please log in again.');

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

      _showMessage('Donor profile saved successfully.');

    } catch (error) {

      if (mounted) {

        _showMessage('Could not save profile: $error');

      }

    } finally {

      if (mounted) setState(() => _isSaving = false);

    }

  }

  void _showMessage(String message) {

    ScaffoldMessenger.of(context)

      ..hideCurrentSnackBar()

      ..showSnackBar(SnackBar(content: Text(message)));

  }

  InputDecoration _inputDecoration(

    String label, {

    String? hint,

    IconData? icon,

  }) {

    return InputDecoration(

      labelText: label,

      hintText: hint,

      prefixIcon: icon == null ? null : Icon(icon),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(

        borderRadius: BorderRadius.circular(12),

      ),

      enabledBorder: OutlineInputBorder(

        borderRadius: BorderRadius.circular(12),

        borderSide: BorderSide(color: Colors.grey.shade300),

      ),

      focusedBorder: OutlineInputBorder(

        borderRadius: BorderRadius.circular(12),

        borderSide: const BorderSide(

          color: AppTheme.primaryGreen,

          width: 1.5,

        ),

      ),

    );

  }

  Widget _buildTextField({

    required TextEditingController controller,

    required String label,

    required IconData icon,

    String? hint,

    TextInputType keyboardType = TextInputType.text,

    int maxLines = 1,

    String? Function(String?)? validator,

  }) {

    return TextFormField(

      controller: controller,

      keyboardType: keyboardType,

      maxLines: maxLines,

      validator: validator ??

          (value) {

            if (value == null || value.trim().isEmpty) {

              return '$label is required.';

            }

            return null;

          },

      decoration: _inputDecoration(label, hint: hint, icon: icon),

    );

  }

  Widget _buildDropdown({

    required String label,

    required String? value,

    required List<String> items,

    required ValueChanged<String?> onChanged,

  }) {

    return DropdownButtonFormField<String>(

      value: value,

      isExpanded: true,

      decoration: _inputDecoration(label),

      items: items

          .map(

            (item) => DropdownMenuItem<String>(

              value: item,

              child: Text(item, overflow: TextOverflow.ellipsis),

            ),

          )

          .toList(),

      validator: (selected) =>

          selected == null ? 'Please select $label.' : null,

      onChanged: onChanged,

    );

  }

  Widget _sectionTitle(String title, IconData icon) {

    return Padding(

      padding: const EdgeInsets.only(top: 24, bottom: 14),

      child: Row(

        children: [

          Icon(icon, color: AppTheme.primaryGreen, size: 23),

          const SizedBox(width: 10),

          Expanded(

            child: Text(

              title,

              style: const TextStyle(

                fontSize: 18,

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

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Container(

          height: 300,

          clipBehavior: Clip.antiAlias,

          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: Colors.grey.shade300),

          ),

          child: Stack(

            children: [

              FlutterMap(

                mapController: _mapController,

                options: MapOptions(

                  initialCenter: _sriLankaCenter,

                  initialZoom: 7,

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

                            color: Colors.red,

                            size: 46,

                          ),

                        ),

                      ],

                    ),

                  RichAttributionWidget(

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

                      color: Colors.white.withValues(alpha: 0.94),

                      borderRadius: BorderRadius.circular(10),

                    ),

                    child: const Text(

                      'Tap the map to select your location',

                      textAlign: TextAlign.center,

                      style: TextStyle(fontWeight: FontWeight.w600),

                    ),

                  ),

                ),

              ),

              Positioned(

                right: 12,

                bottom: 12,

                child: FloatingActionButton.small(

                  heroTag: 'donorMapSriLanka',

                  backgroundColor: Colors.white,

                  foregroundColor: AppTheme.primaryGreen,

                  onPressed: () {

                    _mapController.move(_sriLankaCenter, 7);

                  },

                  child: const Icon(Icons.public),

                ),

              ),

            ],

          ),

        ),

        const SizedBox(height: 10),

        if (_selectedLocation != null)

          Container(

            width: double.infinity,

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(

              color: AppTheme.primaryGreen.withValues(alpha: 0.08),

              borderRadius: BorderRadius.circular(10),

            ),

            child: Text(

              'Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}\n'

              'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',

              style: const TextStyle(

                fontSize: 13,

                height: 1.6,

              ),

            ),

          )

        else

          Text(

            'Location is optional. Tap the map to select a point.',

            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),

          ),

      ],

    );

  }

  @override

  Widget build(BuildContext context) {

    if (_isLoading) {

      return const Center(

        child: CircularProgressIndicator(color: AppTheme.primaryGreen),

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

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Center(

                      child: CircleAvatar(

                        radius: 42,

                        backgroundColor: Color(0xFFE3F2E8),

                        child: Icon(

                          Icons.person_outline_rounded,

                          size: 48,

                          color: AppTheme.primaryGreen,

                        ),

                      ),

                    ),

                    const SizedBox(height: 16),

                    const Center(

                      child: Text(

                        'My Donor Profile',

                        style: TextStyle(

                          fontSize: 25,

                          fontWeight: FontWeight.bold,

                          color: AppTheme.darkText,

                        ),

                      ),

                    ),

                    const SizedBox(height: 8),

                    Center(

                      child: Text(

                        'Manage your personal details and donation location.',

                        textAlign: TextAlign.center,

                        style: TextStyle(

                          color: Colors.grey.shade700,

                          height: 1.5,

                        ),

                      ),

                    ),

                    _sectionTitle('Personal Information', Icons.person_outline),

                    _buildTextField(

                      controller: _firstNameController,

                      label: 'First name',

                      icon: Icons.badge_outlined,

                    ),

                    const SizedBox(height: 14),

                    _buildTextField(

                      controller: _lastNameController,

                      label: 'Last name',

                      icon: Icons.badge_outlined,

                    ),

                    const SizedBox(height: 14),

                    _buildTextField(

                      controller: _phoneController,

                      label: 'Phone number',

                      icon: Icons.phone_outlined,

                      keyboardType: TextInputType.phone,

                      validator: (value) {

                        if (value == null || value.trim().isEmpty) {

                          return 'Phone number is required.';

                        }

                        if (value.trim().length < 9) {

                          return 'Please enter a valid phone number.';

                        }

                        return null;

                      },

                    ),

                    const SizedBox(height: 14),

                    _buildDropdown(

                      label: 'Donor type',

                      value: _donorType,

                      items: const ['INDIVIDUAL', 'ORGANIZATION'],

                      onChanged: (value) {

                        setState(() => _donorType = value);

                      },

                    ),

                    if (_donorType == 'ORGANIZATION') ...[

                      const SizedBox(height: 14),

                      _buildTextField(

                        controller: _organizationController,

                        label: 'Organization name',

                        icon: Icons.business_outlined,

                      ),

                    ],

                    _sectionTitle('Address', Icons.home_outlined),

                    _buildDropdown(

                      label: 'Province',

                      value: _province,

                      items: _districtsByProvince.keys.toList(),

                      onChanged: (value) {

                        setState(() {

                          _province = value;

                          _district = null;

                          _city = null;

                        });

                        _focusMap();

                      },

                    ),

                    const SizedBox(height: 14),

                    _buildDropdown(

                      label: 'District',

                      value: _district,

                      items: districts,

                      onChanged: (value) {

                        setState(() {

                          _district = value;

                          _city = null;

                        });

                        _focusMap();

                      },

                    ),

                    const SizedBox(height: 14),

                    _buildDropdown(

                      label: 'City',

                      value: _city,

                      items: cities,

                      onChanged: (value) {

                        setState(() => _city = value);

                        _focusMap();

                      },

                    ),

                    const SizedBox(height: 14),

                    _buildTextField(

                      controller: _addressLine1Controller,

                      label: 'Address line 1',

                      icon: Icons.location_on_outlined,

                    ),

                    const SizedBox(height: 14),

                    _buildTextField(

                      controller: _addressLine2Controller,

                      label: 'Address line 2 (optional)',

                      icon: Icons.add_location_alt_outlined,

                      validator: (_) => null,

                    ),

                    const SizedBox(height: 14),

                    _buildTextField(

                      controller: _notesController,

                      label: 'Additional notes (optional)',

                      icon: Icons.notes_outlined,

                      maxLines: 3,

                      validator: (_) => null,

                    ),

                    _sectionTitle('Map Location', Icons.map_outlined),

                    const Text(

                      'Choose your donor or pickup location on the map. '

                      'Selecting a province or district also focuses the map.',

                      style: TextStyle(height: 1.5),

                    ),

                    const SizedBox(height: 12),

                    _buildLocationPicker(),

                    const SizedBox(height: 28),

                    SizedBox(

                      width: double.infinity,

                      height: 52,

                      child: ElevatedButton.icon(

                        onPressed: _isSaving ? null : _saveProfile,

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

                              ? 'Saving profile...'

                              : _hasProfile

                                  ? 'Update Profile'

                                  : 'Save Profile',

                        ),

                        style: ElevatedButton.styleFrom(

                          backgroundColor: AppTheme.primaryGreen,

                          foregroundColor: Colors.white,

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(12),

                          ),

                        ),

                      ),

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
