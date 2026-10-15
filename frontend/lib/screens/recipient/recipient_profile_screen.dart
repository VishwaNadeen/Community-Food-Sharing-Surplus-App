import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
//   -> starts in View mode.
// Leave [existingProfile] null for a fresh create.
//
// Editing is handled by RecipientEditProfileScreen (pushed from view mode).

class RecipientProfileScreen extends StatefulWidget {
  final String token;
  final RecipientModel? existingProfile;

  const RecipientProfileScreen({
    super.key,
    required this.token,
    this.existingProfile,
  });

  @override
  State<RecipientProfileScreen> createState() => _RecipientProfileScreenState();
}

enum _ScreenMode { create, view }

class _RecipientProfileScreenState extends State<RecipientProfileScreen> {
  // -------------------- state --------------------
  late _ScreenMode _mode;
  RecipientModel? _profile;

  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _showNic = false;
  String? _profileLoadError;

  // -------------------- form (create mode) --------------------
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

  String _initials(RecipientModel p) {
    final f = p.firstName.trim();
    final l = p.lastName.trim();
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : '';
    final s = '$a$b'.toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  String _maskedNic(String nic) {
    if (nic.length <= 4) return nic;
    return '${'•' * (nic.length - 4)}${nic.substring(nic.length - 4)}';
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label copied'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ====================== NIC VALIDATION ======================

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

      Provider.of<AuthProvider>(context, listen: false)
          .setProfileCompleted(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile created successfully'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );

      Navigator.pushReplacementNamed(context, '/recipient-home');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 32),
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
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
              elevation: 0,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    await Provider.of<AuthProvider>(context, listen: false).logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.warning_amber_rounded,
            color: Colors.red.shade600, size: 34),
        title: const Text('Delete profile?'),
        content: const Text(
          'Your recipient profile will be permanently removed. '
          'This cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        _showNic = false;
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
      setState(() => _profile = updatedProfile);
      _populateControllers(updatedProfile);
    }
  }

  Future<void> _loadExistingProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProfile = true;
      _profileLoadError = null;
    });

    try {
      final profile = await RecipientService.getProfile(token: widget.token);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _mode = _ScreenMode.view;
        _isLoadingProfile = false;
      });

      _populateControllers(profile);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      final lower = message.toLowerCase();

      final profileDoesNotExist = lower.contains('not found') ||
          lower.contains('does not exist') ||
          lower.contains('no recipient profile');

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
    final isView = _mode == _ScreenMode.view &&
        _profile != null &&
        !_isLoadingProfile &&
        _profileLoadError == null;

    return Scaffold(
      backgroundColor: isView ? const Color(0xFFF6F8F6) : Colors.white,
      // View mode has its own header, so no AppBar there.
      appBar: isView
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppTheme.darkText),
              title: const Text(
                'Complete Profile',
                style: TextStyle(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _profileLoadError != null
              ? _buildErrorState()
              : isView
                  ? _buildViewMode()
                  : SafeArea(child: _buildFormMode()),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_off_rounded,
                    color: Colors.red.shade400, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Couldn\'t load your profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _profileLoadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadExistingProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== VIEW MODE ======================

  Widget _buildViewMode() {
    final p = _profile!;
    final hasAddr2 = p.addressLine2 != null && p.addressLine2!.isNotEmpty;

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadExistingProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(p),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- personal ----------
                  _sectionTitle('Personal'),
                  _card([
                    _tile(
                      icon: Icons.badge_outlined,
                      label: 'National ID (NIC)',
                      value: _showNic ? p.nic : _maskedNic(p.nic),
                      trailing: IconButton(
                        tooltip: _showNic ? 'Hide NIC' : 'Show NIC',
                        icon: Icon(
                          _showNic
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppTheme.greyText,
                        ),
                        onPressed: () => setState(() => _showNic = !_showNic),
                      ),
                    ),
                    _tile(
                      icon: Icons.phone_outlined,
                      label: 'Phone number',
                      value: p.phoneNumber,
                      onLongPress: () => _copy('Phone number', p.phoneNumber),
                      trailing: _copyButton(
                        () => _copy('Phone number', p.phoneNumber),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ---------- address ----------
                  _sectionTitle('Delivery address'),
                  _card([
                    _tile(
                      icon: Icons.home_outlined,
                      label: 'Street address',
                      value: hasAddr2
                          ? '${p.addressLine1}\n${p.addressLine2}'
                          : p.addressLine1,
                    ),
                    _tile(
                      icon: Icons.location_city_outlined,
                      label: 'City',
                      value: p.city,
                    ),
                    _tile(
                      icon: Icons.map_outlined,
                      label: 'District',
                      value: p.district,
                    ),
                    if (p.latitude != null && p.longitude != null)
                      _tile(
                        icon: Icons.my_location_outlined,
                        label: 'GPS location',
                        value: '${p.latitude!.toStringAsFixed(5)}, '
                            '${p.longitude!.toStringAsFixed(5)}',
                        onLongPress: () => _copy(
                          'Coordinates',
                          '${p.latitude}, ${p.longitude}',
                        ),
                      ),
                  ]),

                  const SizedBox(height: 20),

                  // ---------- preferences ----------
                  _sectionTitle('Preferences'),
                  _card([
                    _tile(
                      icon: Icons.schedule_outlined,
                      label: 'Time zone',
                      value: p.timeZone,
                    ),
                    _tile(
                      icon: Icons.language_outlined,
                      label: 'Language',
                      value: p.language,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ---------- account ----------
                  _sectionTitle('Account'),
                  _card([
                    _actionTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit profile',
                      subtitle: 'Update your personal details',
                      onTap: _isLoading ? null : _enterEditMode,
                    ),
                    _actionTile(
                      icon: Icons.logout_rounded,
                      title: 'Log out',
                      subtitle: 'Sign out of this device',
                      color: Colors.red.shade600,
                      onTap: _logout,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // ---------- danger zone ----------
                  Center(
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _deleteProfile,
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: Colors.red.shade400),
                      label: Text(
                        'Delete profile',
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Tip: long-press a phone number to copy it.\n'
                      'Pull down to refresh your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.grey.shade500,
                      ),
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

  // ---------- header ----------

  Widget _buildHeader(RecipientModel p) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              // top bar
              Row(
                children: [
                  if (Navigator.canPop(context))
                    _headerIconButton(
                      Icons.arrow_back_ios_new_rounded,
                      () => Navigator.maybePop(context),
                    )
                  else
                    const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'My Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _headerIconButton(
                    Icons.edit_outlined,
                    _isLoading ? null : _enterEditMode,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // avatar with edit badge
              Stack(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(60),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(p),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreenDark,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 14),

              Text(
                '${p.firstName} ${p.lastName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volunteer_activism_outlined,
                            size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'FoodLink Recipient',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${p.city}, ${p.district}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.white.withAlpha(40),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }

  // ---------- reusable building blocks ----------

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.greyText,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  /// A white rounded card that places dividers between its children.
  Widget _card(List<Widget> children) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(Divider(
          height: 1,
          indent: 68,
          endIndent: 16,
          color: Colors.grey.shade200,
        ));
      }
    }
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(children: items),
    );
  }

  Widget _iconBox(IconData icon, {Color? color}) {
    final c = color ?? AppTheme.primaryGreenDark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color == null ? AppTheme.lightGreen : c.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: c),
    );
  }

  Widget _tile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _iconBox(icon),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      color: AppTheme.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _copyButton(VoidCallback onTap) {
    return IconButton(
      tooltip: 'Copy',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.greyText),
      onPressed: onTap,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBox(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color ?? AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  // ====================== FORM MODE (CREATE) ======================

  Widget _buildFormMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Fill in the details to set up your recipient profile.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // ---- Personal ----
            _formSectionLabel(Icons.person_outline, 'Personal information'),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _firstNameController,
              hint: 'First Name',
              prefixIcon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'First name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _lastNameController,
              hint: 'Last Name',
              prefixIcon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Last name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _nicController,
              hint: 'NIC  (e.g. 123456789V or 200012345678)',
              prefixIcon: Icons.badge_outlined,
              validator: _validateNic,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _phoneController,
              hint: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Phone number is required'
                  : null,
            ),

            const SizedBox(height: 28),

            // ---- Address ----
            _formSectionLabel(Icons.location_on_outlined, 'Delivery address'),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _addressLine1Controller,
              hint: 'Address Line 1',
              prefixIcon: Icons.home_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Address Line 1 is required'
                  : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _addressLine2Controller,
              hint: 'Address Line 2 (optional)',
              prefixIcon: Icons.home_work_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _cityController,
              hint: 'City',
              prefixIcon: Icons.location_city_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'City is required' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _districtController,
              hint: 'District',
              prefixIcon: Icons.map_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'District is required'
                  : null,
            ),

            const SizedBox(height: 28),

            // ---- Preferences ----
            _formSectionLabel(Icons.tune_rounded, 'Preferences'),
            const SizedBox(height: 10),
            CustomTextField(
              controller: _timeZoneController,
              hint: 'Time Zone  (e.g. Asia/Colombo)',
              prefixIcon: Icons.schedule_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Time zone is required'
                  : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _languageController,
              hint: 'Language  (e.g. English)',
              prefixIcon: Icons.language_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Language is required'
                  : null,
            ),

            const SizedBox(height: 32),

            PrimaryButton(
              text: 'Create Profile',
              isLoading: _isLoading,
              onPressed: _createProfile,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _formSectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreenDark),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.greyText,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}