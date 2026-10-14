import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';
import '../change_password_screen.dart';
import 'availability_screen.dart';
import 'volunteer_profile_setup_screen.dart';

class VolunteerProfileScreen extends StatefulWidget {
  final bool isTab;

  const VolunteerProfileScreen({
    super.key,
    this.isTab = false,
  });

  @override
  State<VolunteerProfileScreen> createState() => _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  bool _loading = false;
  VolunteerAvailability? _availability;
  VolunteerDashboardStats? _stats;
  VolunteerProfileModel? _profile;
  String? _error;

  AuthProvider get _auth => context.read<AuthProvider>();
  String get _token => _auth.token ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_token.isEmpty) {
      if (mounted) {
        setState(() {
          _error = 'Your session has expired. Please sign in again.';
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final availability = await VolunteerService.getAvailability(_token);
      final stats = await VolunteerService.getDashboard(_token);
      final profile = await VolunteerService.getProfile(_token);

      if (!mounted) return;

      setState(() {
        _availability = availability;
        _stats = stats;
        _profile = profile;
        if (profile.isCompleted) {
          _auth.setProfileCompleted(true);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VolunteerProfileSetupScreen(
          isEditMode: true,
          existingProfile: _profile,
        ),
      ),
    );

    if (updated == true) {
      _loadProfileData();
    }
  }

  Future<void> _openInitialSetup() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VolunteerProfileSetupScreen(
          isEditMode: false,
          existingProfile: _profile,
        ),
      ),
    );

    if (completed == true) {
      _loadProfileData();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to log out of your volunteer delivery account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.greyText)),
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

    if (confirmed != true || !mounted) return;

    await _auth.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAvailable = _availability?.isAvailable ?? false;
    final isProfileComplete = _profile?.isCompleted ?? false;
    final displayName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : (user?.email ?? 'Volunteer Driver');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Volunteer Profile',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: !widget.isTab,
        actions: [
          IconButton(
            onPressed: _loadProfileData,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.darkText),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _loading && _availability == null && _profile == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _error != null && _profile == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF2F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_off_rounded,
                              size: 28,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Unable to Load Profile',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _loadProfileData,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreenDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryGreen,
                  onRefresh: _loadProfileData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Profile Hero Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGreen,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.volunteer_activism_rounded,
                                    color: AppTheme.primaryGreenDark,
                                    size: 38,
                                  ),
                                ),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAvailable
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF94A3B8),
                                    border: Border.all(color: Colors.white, width: 2.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_profile?.fullName.isNotEmpty == true &&
                                user?.email != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                user!.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 13,
                                        color: AppTheme.primaryGreenDark,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified Volunteer Driver',
                                        style: TextStyle(
                                          color: AppTheme.primaryGreenDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? const Color(0xFFF0FDF4)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isAvailable ? 'AVAILABLE' : 'OFFLINE',
                                    style: TextStyle(
                                      color: isAvailable
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Profile Incomplete Banner
                      if (!isProfileComplete) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFD97706),
                                    size: 22,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Profile Setup Incomplete',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'You cannot accept or process food deliveries until you create your volunteer account with contact, address, and vehicle details.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFFB45309),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: _openInitialSetup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD97706),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.person_add_rounded, size: 18),
                                  label: const Text(
                                    'Complete Account Setup',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Quick Performance / Overview Stats
                      if (_stats != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryBox(
                                label: 'Completed',
                                value: '${_stats!.completedDeliveries}',
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryBox(
                                label: 'Total Tasks',
                                value: '${_stats!.totalDeliveries}',
                                icon: Icons.local_shipping_rounded,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SummaryBox(
                                label: 'Active Tasks',
                                value: '${_stats!.activeDeliveries}',
                                icon: Icons.timelapse_rounded,
                                color: const Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Section: Volunteer Personal Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Personal & Contact Details',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openEditProfile,
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text(
                              'Edit',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreenDark,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _DetailTile(
                              icon: Icons.person_outline_rounded,
                              label: 'Full Name',
                              value: _profile?.fullName.isNotEmpty == true
                                  ? _profile!.fullName
                                  : 'Not provided',
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _DetailTile(
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: _profile?.phoneNumber.isNotEmpty == true
                                  ? _profile!.phoneNumber
                                  : 'Not provided',
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _DetailTile(
                              icon: Icons.location_on_outlined,
                              label: 'Delivery Address',
                              value: _profile?.fullAddress.isNotEmpty == true
                                  ? _profile!.fullAddress
                                  : 'Not provided',
                            ),
                            if (_profile?.nic != null &&
                                _profile!.nic!.isNotEmpty) ...[
                              const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                              _DetailTile(
                                icon: Icons.badge_outlined,
                                label: 'NIC / Identity Number',
                                value: _profile!.nic!,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section: Vehicle & Transportation Details
                      const Text(
                        'Vehicle & Transportation',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _DetailTile(
                              icon: Icons.directions_car_outlined,
                              label: 'Vehicle Type',
                              value: _profile?.vehicleType?.isNotEmpty == true
                                  ? _profile!.vehicleType!
                                  : 'Not specified',
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _DetailTile(
                              icon: Icons.pin_outlined,
                              label: 'Vehicle Plate / Registration',
                              value: _profile?.vehicleNumber?.isNotEmpty == true
                                  ? _profile!.vehicleNumber!
                                  : 'Not specified',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section: Account Details
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _DetailTile(
                              icon: Icons.email_outlined,
                              label: 'Login Email',
                              value: user?.email ?? 'Not available',
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _DetailTile(
                              icon: Icons.badge_outlined,
                              label: 'Volunteer User ID',
                              value: user?.customUserId.isNotEmpty == true
                                  ? user!.customUserId
                                  : 'V-User',
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _DetailTile(
                              icon: Icons.category_outlined,
                              label: 'Role Code',
                              value: '${user?.roleCode ?? 'V'} (Delivery Partner)',
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _DetailTile(
                              icon: Icons.verified_user_outlined,
                              label: 'Account Status',
                              value: isProfileComplete
                                  ? 'Active & Ready for Tasks'
                                  : 'Profile Incomplete',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section: Security & Preferences
                      const Text(
                        'Preferences & Security',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            _ActionOptionTile(
                              icon: Icons.manage_accounts_outlined,
                              iconColor: AppTheme.primaryGreenDark,
                              iconBgColor: AppTheme.lightGreen,
                              title: 'Edit Profile Information',
                              subtitle: 'Update contact details, address & vehicle',
                              onTap: _openEditProfile,
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _ActionOptionTile(
                              icon: Icons.lock_reset_rounded,
                              iconColor: const Color(0xFF2563EB),
                              iconBgColor: const Color(0xFFEFF6FF),
                              title: 'Change Password',
                              subtitle: 'Update your account login password',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChangePasswordScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                            _ActionOptionTile(
                              icon: Icons.toggle_on_outlined,
                              iconColor: const Color(0xFF0D9488),
                              iconBgColor: const Color(0xFFF0FDFA),
                              title: 'Delivery Availability',
                              subtitle: 'Set availability status and service notes',
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VolunteerAvailabilityScreen(),
                                  ),
                                );
                                _loadProfileData();
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section: Account Actions (Logout)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: _ActionOptionTile(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFDC2626),
                          iconBgColor: const Color(0xFFFEF2F2),
                          title: 'Log Out',
                          subtitle: 'Sign out of your volunteer delivery account',
                          onTap: _logout,
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.greyText,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: const Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionOptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.greyText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
