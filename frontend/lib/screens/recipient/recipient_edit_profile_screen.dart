import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/recipient_model.dart';
import '../../services/recipient_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'location_picker_screen.dart';

// ====================== STATIC DATA / API ======================

/// Options currently supported by the app.
const _supportedLanguages = ['English'];
const _supportedTimeZones = ['Asia/Colombo'];

// ---------- countries (REST Countries API) ----------

class _Country {
  final String name;
  final String iso; // ISO 3166-1 alpha-2
  final String dial; // e.g. +94

  const _Country(this.name, this.iso, this.dial);

  String get flagUrl => 'https://flagcdn.com/w40/${iso.toLowerCase()}.png';

  String get emoji => iso
      .toUpperCase()
      .codeUnits
      .map((c) => String.fromCharCode(0x1F1E6 + c - 65))
      .join();
}

const _lk = _Country('Sri Lanka', 'LK', '+94');

/// Used instantly and as an offline fallback if the API cannot be reached.
const _fallbackCountries = <_Country>[
  _lk,
  _Country('India', 'IN', '+91'),
  _Country('Maldives', 'MV', '+960'),
  _Country('Pakistan', 'PK', '+92'),
  _Country('Bangladesh', 'BD', '+880'),
  _Country('United Kingdom', 'GB', '+44'),
  _Country('United States', 'US', '+1'),
  _Country('Canada', 'CA', '+1'),
  _Country('Australia', 'AU', '+61'),
  _Country('United Arab Emirates', 'AE', '+971'),
  _Country('Saudi Arabia', 'SA', '+966'),
  _Country('Qatar', 'QA', '+974'),
  _Country('Kuwait', 'KW', '+965'),
  _Country('Singapore', 'SG', '+65'),
  _Country('Malaysia', 'MY', '+60'),
  _Country('Japan', 'JP', '+81'),
  _Country('Germany', 'DE', '+49'),
  _Country('France', 'FR', '+33'),
  _Country('Italy', 'IT', '+39'),
];

List<_Country>? _countryCache;

Future<List<_Country>> _fetchCountries() async {
  if (_countryCache != null) return _countryCache!;

  final res = await http
      .get(Uri.parse(
          'https://restcountries.com/v3.1/all?fields=name,cca2,idd'))
      .timeout(const Duration(seconds: 12));
  if (res.statusCode != 200) {
    throw Exception('Countries request failed (${res.statusCode})');
  }

  final list = jsonDecode(res.body) as List;
  final result = <_Country>[];

  for (final raw in list) {
    final e = raw as Map<String, dynamic>;
    final iso = e['cca2'] as String?;
    final name = (e['name'] as Map?)?['common'] as String?;
    final idd = e['idd'] as Map?;
    final root = (idd?['root'] as String?) ?? '';
    final suffixes = (idd?['suffixes'] as List?) ?? const [];

    if (iso == null || name == null || root.isEmpty) continue;

    // Countries sharing a root (e.g. +1 with many area codes) use the root only.
    final dial = suffixes.length == 1 ? '$root${suffixes.first}' : root;
    result.add(_Country(name, iso, dial));
  }

  if (result.isEmpty) throw Exception('No countries returned');

  result.sort((a, b) => a.name.compareTo(b.name));
  _countryCache = result;
  return result;
}

// ---------- Sri Lankan districts ----------

const _fallbackDistricts = <String>[
  'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle',
  'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle',
  'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala',
  'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura',
  'Trincomalee', 'Vavuniya',
];

List<String>? _districtCache;

/// Sri Lanka has 25 districts. If the API returns something that does not
/// look like that, the built-in list above is used.
Future<List<String>> _fetchDistricts() async {
  if (_districtCache != null) return _districtCache!;

  final res = await http
      .post(
        Uri.parse('https://countriesnow.space/api/v0.1/countries/states'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'country': 'Sri Lanka'}),
      )
      .timeout(const Duration(seconds: 12));
  if (res.statusCode != 200) {
    throw Exception('Districts request failed (${res.statusCode})');
  }

  final data = jsonDecode(res.body) as Map<String, dynamic>;
  final states = (data['data']?['states'] as List?) ?? const [];

  final names = states
      .map((s) => ((s as Map)['name'] as String?) ?? '')
      .where((n) => n.isNotEmpty && !n.toLowerCase().endsWith('province'))
      .map((n) => n.replaceAll(RegExp(r'\s+District$', caseSensitive: false), ''))
      .toSet()
      .toList()
    ..sort();

  if (names.length < 20 || names.length > 30) {
    throw Exception('Unexpected districts response');
  }

  _districtCache = names;
  return names;
}

// ====================== SCREEN ======================

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
  late final TextEditingController _phoneController; // national number only
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;

  late final List<TextEditingController> _allControllers;

  // picker values
  String? _district;
  late String _language;
  late String _timeZone;
  bool _tzAuto = false;

  // phone
  _Country _country = _lk;
  List<_Country> _countries = _fallbackCountries;
  bool _phoneTouched = false;

  // districts
  List<String> _districts = _fallbackDistricts;
  bool _districtsLoading = true;

  // location
  double? _lat;
  double? _lng;
  String? _locationLabel;
  bool _locating = false;

  // state
  bool _isLoading = false;
  bool _allowPop = false;
  late Map<String, dynamic> _initial;

  // ====================== LIFECYCLE ======================

  @override
  void initState() {
    super.initState();

    final p = widget.profile;

    _firstNameController = TextEditingController(text: p.firstName);
    _lastNameController = TextEditingController(text: p.lastName);
    _nicController = TextEditingController(text: p.nic);
    _phoneController = TextEditingController();
    _addressLine1Controller = TextEditingController(text: p.addressLine1);
    _addressLine2Controller = TextEditingController(text: p.addressLine2 ?? '');
    _cityController = TextEditingController(text: p.city);

    _district = p.district.isEmpty ? null : p.district;
    _language = p.language.isEmpty ? _supportedLanguages.first : p.language;
    _timeZone = p.timeZone.isEmpty ? _supportedTimeZones.first : p.timeZone;
    _lat = p.latitude;
    _lng = p.longitude;

    _parsePhone(p.phoneNumber);

    _allControllers = [
      _firstNameController,
      _lastNameController,
      _nicController,
      _phoneController,
      _addressLine1Controller,
      _addressLine2Controller,
      _cityController,
    ];
    for (final c in _allControllers) {
      c.addListener(_onChanged);
    }

    _initial = _buildPayload();

    _loadCountries();
    _loadDistricts();
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  // ====================== DATA LOADING ======================

  Future<void> _loadCountries() async {
    try {
      final list = await _fetchCountries();
      if (!mounted) return;

      setState(() {
        _countries = list;
        _country = list.firstWhere(
          (c) => c.iso == _country.iso,
          orElse: () => _country,
        );
      });

      // Re-parse the stored number with the full list (e.g. +880...) if the
      // user has not touched the phone field yet.
      if (!_phoneTouched) {
        _parsePhone(widget.profile.phoneNumber);
        _initial['phoneNumber'] = _buildPayload()['phoneNumber'];
        setState(() {});
      }
    } catch (_) {
      // keep the fallback list
    }
  }

  Future<void> _loadDistricts() async {
    try {
      final list = await _fetchDistricts();
      if (!mounted) return;
      setState(() {
        _districts = list;
        _districtsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _districtsLoading = false);
    }
  }

  // ====================== PHONE HELPERS ======================

  void _parsePhone(String raw) {
    final v = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');

    if (v.startsWith('+')) {
      _Country? best;
      for (final c in _countries) {
        if (v.startsWith(c.dial) &&
            (best == null || c.dial.length > best.dial.length)) {
          best = c;
        }
      }
      if (best != null) {
        _country = best;
        _phoneController.text = v.substring(best.dial.length);
      } else {
        _phoneController.text = v.substring(1);
      }
    } else {
      // local format, e.g. 0771234567 -> Sri Lanka by default
      _country = _countries.firstWhere(
        (c) => c.iso == 'LK',
        orElse: () => _lk,
      );
      _phoneController.text = v.replaceFirst(RegExp(r'^0+'), '');
    }
  }

  String _nationalDigits() => _phoneController.text
      .replaceAll(RegExp(r'\D'), '')
      .replaceFirst(RegExp(r'^0+'), '');

  String? _validatePhone(String? _) {
    final n = _nationalDigits();
    if (n.isEmpty) return 'Phone number is required';
    if (_country.iso == 'LK') {
      if (n.length != 9) return 'Enter 9 digits, e.g. 77 123 4567';
      return null;
    }
    if (n.length < 6 || n.length > 14) return 'Enter a valid phone number';
    return null;
  }

  // ====================== VALIDATION / PAYLOAD ======================

  String? _validateNic(String? value) {
    if (value == null || value.trim().isEmpty) return 'NIC is required';

    final nic = value.trim().toUpperCase();
    final oldFormat = RegExp(r'^\d{9}[VX]$');
    final newFormat = RegExp(r'^\d{12}$');

    if (!oldFormat.hasMatch(nic) && !newFormat.hasMatch(nic)) {
      return 'Use 123456789V or 200012345678';
    }
    return null;
  }

  String? Function(String?) _required(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) return '$label is required';
      return null;
    };
  }

  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'nic': _nicController.text.trim(),
      'phoneNumber': '${_country.dial}${_nationalDigits()}',
      'addressLine1': _addressLine1Controller.text.trim(),
      'city': _cityController.text.trim(),
      'district': (_district ?? '').trim(),
      'timeZone': _timeZone,
      'language': _language,
    };

    final addressLine2 = _addressLine2Controller.text.trim();
    if (addressLine2.isNotEmpty) payload['addressLine2'] = addressLine2;

    if (_lat != null && _lng != null) {
      payload['latitude'] = _lat;
      payload['longitude'] = _lng;
    }

    return payload;
  }

  bool get _isDirty => !mapEquals(_initial, _buildPayload());

  // ====================== LOCATION ======================

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null,
        ),
      ),
    );

    if (result != null && mounted) {
      await _applyLocation(
        result.point,
        label: result.label,
        city: result.city,
        district: result.district,
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      final point = await LocationService.current();
      final addr = await GeoService.reverse(point);
      if (!mounted) return;
      await _applyLocation(
        point,
        label: addr?.label,
        city: addr?.city,
        district: addr?.district,
      );
    } on LocationException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Could not get your location. Please try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _applyLocation(
    LatLng point, {
    String? label,
    String? city,
    String? district,
  }) async {
    setState(() {
      _lat = point.latitude;
      _lng = point.longitude;
      _locationLabel = label;
    });

    // Auto time zone from the location (only if it is a supported option).
    final tz = await GeoService.timeZoneFor(point);
    if (!mounted) return;
    if (tz != null && _supportedTimeZones.contains(tz)) {
      setState(() {
        _timeZone = tz;
        _tzAuto = true;
      });
    }

    final canFill = (city != null && city.isNotEmpty) ||
        (district != null && district.isNotEmpty);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Location set'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryGreenDark,
          action: canFill
              ? SnackBarAction(
                  label: 'Fill address',
                  textColor: Colors.white,
                  onPressed: () => _fillAddressFrom(city, district),
                )
              : null,
        ),
      );
  }

  void _fillAddressFrom(String? city, String? district) {
    setState(() {
      if (city != null && city.isNotEmpty) _cityController.text = city;
      if (district != null && district.isNotEmpty) {
        final match = _districts.where(
          (d) => d.toLowerCase() == district.toLowerCase(),
        );
        if (match.isNotEmpty) _district = match.first;
      }
    });
  }

  void _removeLocation() {
    setState(() {
      _lat = null;
      _lng = null;
      _locationLabel = null;
      _tzAuto = false;
    });
  }

  // ====================== PICKERS ======================

  Future<void> _pickCountry() async {
    final pinned = _countries.where((c) => c.iso == 'LK').toList();
    final others = _countries.where((c) => c.iso != 'LK').toList();

    final result = await _showOptionSheet<_Country>(
      context: context,
      title: 'Select country code',
      items: [...pinned, ...others],
      selected: _country,
      isSame: (a, b) => a.iso == b.iso,
      label: (c) => c.name,
      trailing: (c) => c.dial,
      leading: (c) => _flag(c),
      searchable: true,
      searchHint: 'Search country or code',
      searchText: (c) => '${c.name} ${c.dial} ${c.iso}',
    );

    if (result != null) {
      setState(() {
        _country = result;
        _phoneTouched = true;
      });
    }
  }

  Future<void> _pickDistrict() async {
    final result = await _showOptionSheet<String>(
      context: context,
      title: 'Select district',
      items: _districts,
      selected: _district,
      isSame: (a, b) => a.toLowerCase() == b.toLowerCase(),
      label: (d) => d,
      leading: (_) => const Icon(Icons.map_outlined,
          size: 22, color: AppTheme.primaryGreenDark),
      searchable: true,
      searchHint: 'Search district',
    );
    if (result != null) setState(() => _district = result);
  }

  Future<void> _pickLanguage() async {
    final result = await _showOptionSheet<String>(
      context: context,
      title: 'Select language',
      items: _supportedLanguages,
      selected: _language,
      label: (l) => l,
      leading: (_) => const Icon(Icons.language_outlined,
          size: 22, color: AppTheme.primaryGreenDark),
      footer: 'More languages are coming soon.',
    );
    if (result != null) setState(() => _language = result);
  }

  Future<void> _pickTimeZone() async {
    final result = await _showOptionSheet<String>(
      context: context,
      title: 'Select time zone',
      items: _supportedTimeZones,
      selected: _timeZone,
      label: (t) => t,
      leading: (_) => const Icon(Icons.schedule_outlined,
          size: 22, color: AppTheme.primaryGreenDark),
      footer: 'More time zones are coming soon.',
    );
    if (result != null) {
      setState(() {
        _timeZone = result;
        _tzAuto = false;
      });
    }
  }

  // ====================== ACTIONS ======================

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _showError('Please fix the highlighted fields.');
      return;
    }

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
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );

      setState(() => _allowPop = true);
      Navigator.pop(context, updatedProfile);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.edit_off_outlined,
            color: Colors.orange.shade700, size: 32),
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. If you leave now they will be lost.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
  }

  // ====================== BUILD ======================

  @override
  Widget build(BuildContext context) {
    final dirty = _isDirty;

    return PopScope(
      canPop: _allowPop || (!dirty && !_isLoading),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isLoading) return;
        _confirmDiscard();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F8F6),
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildPersonalCard(),
                      const SizedBox(height: 16),
                      _buildAddressCard(),
                      const SizedBox(height: 16),
                      _buildLocationCard(),
                      const SizedBox(height: 16),
                      _buildPreferencesCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(dirty),
        ),
      ),
    );
  }

  // ---------- header ----------

  String get _initials {
    final f = _firstNameController.text.trim();
    final l = _lastNameController.text.trim();
    final s = '${f.isNotEmpty ? f[0] : ''}${l.isNotEmpty ? l[0] : ''}'
        .toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  Widget _buildHeader() {
    final name =
        '${_firstNameController.text} ${_lastNameController.text}'.trim();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withAlpha(40),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isLoading
                          ? null
                          : () => Navigator.maybePop(context),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(60),
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreenDark,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name.isEmpty ? 'Your name' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Keep your recipient information accurate',
                style: TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- bottom bar ----------

  Widget _buildBottomBar(bool dirty) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dirty && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'You have unsaved changes',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.greyText),
                    ),
                  ],
                ),
              ),
            PrimaryButton(
              text: 'Save changes',
              isLoading: _isLoading,
              onPressed: (dirty && !_isLoading) ? _saveChanges : null,
            ),
          ],
        ),
      ),
    );
  }

  // ====================== SECTIONS ======================

  Widget _buildPersonalCard() {
    return _SectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Personal information',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _labeled(
                'First name',
                CustomTextField(
                  controller: _firstNameController,
                  hint: 'First name',
                  prefixIcon: Icons.person_outline,
                  validator: _required('First name'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _labeled(
                'Last name',
                CustomTextField(
                  controller: _lastNameController,
                  hint: 'Last name',
                  prefixIcon: Icons.person_outline,
                  validator: _required('Last name'),
                ),
              ),
            ),
          ],
        ),
        _labeled(
          'NIC number',
          CustomTextField(
            controller: _nicController,
            hint: '123456789V or 200012345678',
            prefixIcon: Icons.badge_outlined,
            validator: _validateNic,
          ),
        ),
        _labeled('Phone number', _buildPhoneRow()),
      ],
    );
  }

  Widget _buildPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppTheme.fieldFill,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickCountry,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _flag(_country),
                  const SizedBox(width: 8),
                  Text(
                    _country.dial,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.greyText),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 14,
            onChanged: (_) => _phoneTouched = true,
            validator: _validatePhone,
            style: const TextStyle(fontSize: 15, color: AppTheme.darkText),
            decoration: _inputDecoration('77 123 4567'),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.greyText.withAlpha(170)),
      counterText: '',
      filled: true,
      fillColor: AppTheme.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(AppTheme.primaryGreen, 1.5),
      errorBorder: border(Colors.red.shade300),
      focusedErrorBorder: border(Colors.red.shade400, 1.5),
    );
  }

  Widget _buildAddressCard() {
    return _SectionCard(
      icon: Icons.home_outlined,
      title: 'Delivery address',
      children: [
        _labeled(
          'Address line 1',
          CustomTextField(
            controller: _addressLine1Controller,
            hint: 'House no, street',
            prefixIcon: Icons.home_outlined,
            validator: _required('Address line 1'),
          ),
        ),
        _labeled(
          'Address line 2',
          CustomTextField(
            controller: _addressLine2Controller,
            hint: 'Apartment, landmark',
            prefixIcon: Icons.home_work_outlined,
          ),
          optional: true,
        ),
        _labeled(
          'City',
          CustomTextField(
            controller: _cityController,
            hint: 'City',
            prefixIcon: Icons.location_city_outlined,
            validator: _required('City'),
          ),
        ),
        _labeled(
          'District',
          _PickerField(
            value: _district,
            icon: Icons.map_outlined,
            hint: 'Select district',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'District is required' : null,
            loading: _districtsLoading,
            onTap: _pickDistrict,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    final hasLocation = _lat != null && _lng != null;

    return _SectionCard(
      icon: Icons.my_location_rounded,
      title: 'Location',
      subtitle: 'Pin your exact spot so deliveries can find you.',
      trailing: hasLocation
          ? TextButton(
              onPressed: _removeLocation,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Remove'),
            )
          : null,
      children: [
        if (hasLocation) ...[
          _buildMapPreview(LatLng(_lat!, _lng!)),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: AppTheme.primaryGreenDark),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locationLabel ?? 'Pinned location',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkText,
                      ),
                    ),
                    Text(
                      '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.fieldFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 34, color: AppTheme.greyText),
                SizedBox(height: 8),
                Text(
                  'No location set yet',
                  style: TextStyle(color: AppTheme.greyText, fontSize: 13.5),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(hasLocation ? 'Change on map' : 'Choose on map'),
                style: _outlinedStyle(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      )
                    : const Icon(Icons.gps_fixed_rounded, size: 18),
                label: const Text('Use current'),
                style: _outlinedStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryGreenDark,
        side: const BorderSide(color: AppTheme.primaryGreen),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  Widget _buildMapPreview(LatLng point) {
    return SizedBox(
      height: 150,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            IgnorePointer(
              child: FlutterMap(
                key: ValueKey('${point.latitude}_${point.longitude}'),
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.tileUrl,
                    userAgentPackageName: MapConfig.userAgent,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          size: 44,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: _openMapPicker),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_location_alt_outlined,
                        size: 14, color: AppTheme.primaryGreenDark),
                    SizedBox(width: 4),
                    Text(
                      'Tap to change',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreenDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return _SectionCard(
      icon: Icons.tune_rounded,
      title: 'Preferences',
      children: [
        _labeled(
          'Language',
          _PickerField(
            value: _language,
            icon: Icons.language_outlined,
            hint: 'Select language',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Language is required' : null,
            onTap: _pickLanguage,
          ),
        ),
        _labeled(
          'Time zone',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PickerField(
                value: _timeZone,
                icon: Icons.schedule_outlined,
                hint: 'Select time zone',
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Time zone is required' : null,
                onTap: _pickTimeZone,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Row(
                  children: [
                    Icon(
                      _tzAuto
                          ? Icons.auto_awesome_rounded
                          : Icons.info_outline_rounded,
                      size: 14,
                      color: _tzAuto
                          ? AppTheme.primaryGreenDark
                          : AppTheme.greyText,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _tzAuto
                            ? 'Set automatically from your location'
                            : 'Set a location to detect this automatically',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _tzAuto
                              ? AppTheme.primaryGreenDark
                              : AppTheme.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ====================== SMALL HELPERS ======================

  Widget _labeled(String label, Widget child, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text.rich(
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
                children: [
                  if (optional)
                    const TextSpan(
                      text: '  (optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppTheme.greyText,
                      ),
                    ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ====================== REUSABLE WIDGETS ======================

Widget _flag(_Country c, {double width = 28}) {
  final height = width * 0.72;
  return ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: Image.network(
      c.flagUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : SizedBox(width: width, height: height),
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: FittedBox(child: Text(c.emoji)),
      ),
    ),
  );
}

/// White rounded card with an icon header, used for each form section.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      // fields already add their own bottom padding; add gaps for non-fields
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(11),
                ),
                child:
                    Icon(icon, size: 20, color: AppTheme.primaryGreenDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          ..._withGaps(spaced),
        ],
      ),
    );
  }

  /// Adds a gap between non-labeled children (e.g. map preview + buttons).
  List<Widget> _withGaps(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1 && items[i] is! Padding) {
        out.add(const SizedBox(height: 12));
      }
    }
    return out;
  }
}

/// A dropdown-style field that opens a bottom sheet; supports form validation.
class _PickerField extends FormField<String> {
  _PickerField({
    super.key,
    required String? value,
    required IconData icon,
    required String hint,
    required VoidCallback onTap,
    String? Function(String?)? validator,
    bool loading = false,
  }) : super(
          initialValue: value,
          validator: (_) => validator?.call(value),
          builder: (state) {
            final hasValue = value != null && value.isNotEmpty;
            final hasError = state.hasError;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: AppTheme.fieldFill,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onTap,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasError
                              ? Colors.red.shade300
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: AppTheme.greyText),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              hasValue ? value! : hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                color: hasValue
                                    ? AppTheme.darkText
                                    : AppTheme.greyText.withAlpha(170),
                              ),
                            ),
                          ),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.greyText),
                        ],
                      ),
                    ),
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 14),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}

// ====================== OPTION SHEET (custom dropdown) ======================

Future<T?> _showOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required T? selected,
  required String Function(T) label,
  Widget Function(T)? leading,
  String Function(T)? trailing,
  String Function(T)? searchText,
  bool Function(T, T)? isSame,
  bool searchable = false,
  String searchHint = 'Search',
  String? footer,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _OptionSheet<T>(
      title: title,
      items: items,
      selected: selected,
      label: label,
      leading: leading,
      trailing: trailing,
      searchText: searchText,
      isSame: isSame,
      searchable: searchable,
      searchHint: searchHint,
      footer: footer,
    ),
  );
}

class _OptionSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selected;
  final String Function(T) label;
  final Widget Function(T)? leading;
  final String Function(T)? trailing;
  final String Function(T)? searchText;
  final bool Function(T, T)? isSame;
  final bool searchable;
  final String searchHint;
  final String? footer;

  const _OptionSheet({
    required this.title,
    required this.items,
    required this.selected,
    required this.label,
    required this.searchable,
    required this.searchHint,
    this.leading,
    this.trailing,
    this.searchText,
    this.isSame,
    this.footer,
  });

  @override
  State<_OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<_OptionSheet<T>> {
  String _query = '';

  bool _same(T a, T b) => widget.isSame != null ? widget.isSame!(a, b) : a == b;

  List<T> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) {
      final text = (widget.searchText ?? widget.label)(item).toLowerCase();
      return text.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.greyText),
                    filled: true,
                    fillColor: AppTheme.fieldFill,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            Flexible(
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No results found',
                        style: TextStyle(color: AppTheme.greyText),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        final isSelected = widget.selected != null &&
                            _same(widget.selected as T, item);

                        return InkWell(
                          onTap: () => Navigator.pop(context, item),
                          child: Container(
                            color: isSelected
                                ? AppTheme.lightGreen.withAlpha(140)
                                : null,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 13),
                            child: Row(
                              children: [
                                if (widget.leading != null) ...[
                                  SizedBox(
                                    width: 32,
                                    child: Center(child: widget.leading!(item)),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    widget.label(item),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: AppTheme.darkText,
                                    ),
                                  ),
                                ),
                                if (widget.trailing != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      widget.trailing!(item),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.greyText,
                                      ),
                                    ),
                                  ),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.primaryGreen,
                                      size: 22,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (widget.footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppTheme.greyText),
                    const SizedBox(width: 6),
                    Text(
                      widget.footer!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}