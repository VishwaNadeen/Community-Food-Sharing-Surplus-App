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
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of your volunteer account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
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
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: const Text(
          'Volunteer Profile',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isTab,
        actions: [
          IconButton(
            onPressed: _loadProfileData,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppTheme.darkText),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
          ),
        ],
      ),
      body: _loading && _availability == null && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _profile == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: AppTheme.greyText,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _loadProfileData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.volunteer_activism,
                            color: AppTheme.primaryGreenDark,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_profile?.fullName.isNotEmpty == true &&
                            user?.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            user!.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.greyText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Volunteer Delivery Partner',
                            style: TextStyle(
                              color: AppTheme.primaryGreenDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAvailable
                                    ? AppTheme.primaryGreenDark
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAvailable
                                  ? 'AVAILABLE FOR TASKS'
                                  : 'CURRENTLY UNAVAILABLE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isAvailable
                                    ? AppTheme.primaryGreenDark
                                    : Colors.orange.shade800,
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
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade900,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Profile Incomplete',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You cannot accept or process food deliveries until you create your volunteer account with your contact, address, and vehicle details.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openInitialSetup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreenDark,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                              ),
                              icon: const Icon(Icons.person_add_outlined,
                                  size: 18),
                              label: const Text(
                                'Complete Account Setup Now',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                            icon: Icons.check_circle_outline,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryBox(
                            label: 'Total Tasks',
                            value: '${_stats!.totalDeliveries}',
                            icon: Icons.local_shipping_outlined,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryBox(
                            label: 'Active',
                            value: '${_stats!.activeDeliveries}',
                            icon: Icons.timelapse_outlined,
                            color: Colors.orange.shade800,
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openEditProfile,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreenDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _DetailTile(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _profile?.fullName.isNotEmpty == true
                              ? _profile!.fullName
                              : 'Not provided',
                        ),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: _profile?.phoneNumber.isNotEmpty == true
                              ? _profile!.phoneNumber
                              : 'Not provided',
                        ),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                          icon: Icons.location_on_outlined,
                          label: 'Delivery Address',
                          value: _profile?.fullAddress.isNotEmpty == true
                              ? _profile!.fullAddress
                              : 'Not provided',
                        ),
                        if (_profile?.nic != null &&
                            _profile!.nic!.isNotEmpty) ...[
                          const Divider(height: 1, indent: 56),
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
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
                        const Divider(height: 1, indent: 56),
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _DetailTile(
                          icon: Icons.email_outlined,
                          label: 'Login Email',
                          value: user?.email ?? 'Not available',
                        ),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                          icon: Icons.badge_outlined,
                          label: 'Volunteer User ID',
                          value: user?.customUserId.isNotEmpty == true
                              ? user!.customUserId
                              : 'V-User',
                        ),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                          icon: Icons.category_outlined,
                          label: 'Role Code',
                          value:
                              '${user?.roleCode ?? 'V'} (Delivery Partner)',
                        ),
                        const Divider(height: 1, indent: 56),
                        _DetailTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Account Status',
                          value: isProfileComplete
                              ? 'Active & Verified'
                              : 'Profile Pending',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Security & Preferences
                  const Text(
                    'Security & Settings',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        // Edit Profile Tile
                        _ActionOptionTile(
                          icon: Icons.manage_accounts_outlined,
                          iconColor: AppTheme.primaryGreenDark,
                          iconBgColor: AppTheme.lightGreen,
                          title: 'Edit Profile Information',
                          subtitle:
                              'Update name, phone number, address, and vehicle',
                          onTap: _openEditProfile,
                        ),
                        const Divider(height: 1, indent: 56),
                        // Change Password Tile
                        _ActionOptionTile(
                          icon: Icons.lock_reset_rounded,
                          iconColor: Colors.blue.shade700,
                          iconBgColor: Colors.blue.shade50,
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
                        const Divider(height: 1, indent: 56),
                        // Delivery Availability Tile
                        _ActionOptionTile(
                          icon: Icons.toggle_on_outlined,
                          iconColor: Colors.teal.shade700,
                          iconBgColor: Colors.teal.shade50,
                          title: 'Delivery Availability',
                          subtitle: 'Set yourself available or unavailable',
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const VolunteerAvailabilityScreen(),
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
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: _ActionOptionTile(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.redAccent,
                      iconBgColor: Colors.red.shade50,
                      title: 'Log Out',
                      subtitle: 'Sign out of your volunteer account',
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
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: AppTheme.greyText, size: 22),
          ),
          const SizedBox(width: 14),
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
    return InkWell(
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
                      fontSize: 15,
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
              Icons.chevron_right,
              color: AppTheme.greyText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
