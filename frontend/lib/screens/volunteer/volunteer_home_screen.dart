import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_model.dart';
import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/volunteer/delivery_card.dart';

import 'deliveries_screen.dart';
import 'delivery_details_screen.dart';
import 'optimized_route_screen.dart';
import 'volunteer_profile_screen.dart';
import 'volunteer_profile_setup_screen.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> {
  int _currentIndex = 0;
  bool _loading = true;
  String? _error;

  VolunteerAvailability? _availability;
  VolunteerDashboardStats? _stats;
  VolunteerProfileModel? _profile;
  List<VolunteerDelivery> _availableDeliveries = [];
  List<VolunteerDelivery> _myDeliveries = [];
  bool _togglingAvailability = false;

  final GlobalKey<VolunteerDeliveriesScreenState> _deliveriesKey = GlobalKey();

  AuthProvider get _auth => context.read<AuthProvider>();
  String get _token => _auth.token ?? '';

  void _navigateToDeliveriesTab(int subTab) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deliveriesKey.currentState?.selectTab(subTab);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (_token.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
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
      final available = await VolunteerService.getDeliveries(
        token: _token,
        status: 'PENDING_ASSIGNMENT',
        sortByExpiry: true,
      );
      final myDeliveries = await VolunteerService.getDeliveries(token: _token);
      final profile = await VolunteerService.getProfile(_token);

      if (!mounted) return;

      setState(() {
        _availability = availability;
        _stats = stats;
        _availableDeliveries = available;
        _myDeliveries = myDeliveries;
        _profile = profile;
        if (profile.isCompleted) {
          _auth.setProfileCompleted(true);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability(bool isNowAvailable) async {
    if (_togglingAvailability) return;
    final newStatus = isNowAvailable ? 'AVAILABLE' : 'UNAVAILABLE';
    setState(() => _togglingAvailability = true);

    try {
      final updated = await VolunteerService.updateAvailability(
        token: _token,
        status: newStatus,
      );

      if (!mounted) return;

      setState(() {
        _availability = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isNowAvailable ? Icons.check_circle_rounded : Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isNowAvailable
                      ? 'You are now marked AVAILABLE for deliveries!'
                      : 'You are now marked OFFLINE / UNAVAILABLE.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isNowAvailable
              ? AppTheme.primaryGreenDark
              : const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update availability: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingAvailability = false);
    }
  }

  Future<void> _openDelivery(String deliveryId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VolunteerDeliveryDetailScreen(deliveryId: deliveryId),
      ),
    );
    if (mounted) _loadDashboard();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    if (mounted) {
      _loadDashboard();
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

    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _currentIndex == 0
            ? AppBar(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppTheme.primaryGreenDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Volunteer Hub',
                      style: TextStyle(
                        color: AppTheme.darkText,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 1,

                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              )
            : null,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardBody(user),
            VolunteerDeliveriesScreen(key: _deliveriesKey),
            const VolunteerOptimizedRouteScreen(),
            const VolunteerProfileScreen(isTab: true),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              if (index == 0) {
                _loadDashboard();
              }
            },
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.lightGreen,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryGreenDark),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping_rounded, color: AppTheme.primaryGreenDark),
                label: 'Deliveries',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined),
                selectedIcon: Icon(Icons.route_rounded, color: AppTheme.primaryGreenDark),
                label: 'Route',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryGreenDark),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(dynamic user) {
    if (_loading && _stats == null && _availableDeliveries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 14),
            Text(
              'Loading volunteer dashboard...',
              style: TextStyle(color: AppTheme.greyText, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final isAvailable = _availability?.isAvailable ?? false;
    final isProfileComplete = _profile?.isCompleted ?? false;
    final displayName = _profile?.fullName.isNotEmpty == true
        ? _profile!.fullName
        : (user?.email ?? 'Volunteer Driver');

    // Find any active delivery in progress
    VolunteerDelivery? activeDelivery;
    for (final d in _myDeliveries) {
      final s = d.status.toUpperCase();
      if (s == 'ACCEPTED' ||
          s == 'PICKED_UP' ||
          s == 'ASSIGNED' ||
          s == 'IN_TRANSIT') {
        activeDelivery = d;
        break;
      }
    }

    final activeCount = _myDeliveries.where((d) {
      final s = d.status.toUpperCase();
      return s == 'ACCEPTED' ||
          s == 'PICKED_UP' ||
          s == 'ASSIGNED' ||
          s == 'IN_TRANSIT';
    }).length;

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Welcome Card with In-place Availability Toggle ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _currentIndex = 3),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.volunteer_activism_rounded,
                          color: AppTheme.primaryGreenDark,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, welcome back',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_profile?.vehicleType != null &&
                                _profile!.vehicleType!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    _profile!.vehicleType!
                                            .toLowerCase()
                                            .contains('motor')
                                        ? Icons.two_wheeler_outlined
                                        : Icons.directions_car_outlined,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _profile!.vehicleType!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 12),

                // Instant Availability Banner & Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAvailable
                                    ? const Color(0xFF4ADE80)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAvailable
                                        ? 'READY FOR DELIVERIES'
                                        : 'CURRENTLY OFFLINE',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  Text(
                                    isAvailable
                                        ? 'Active and receiving nearby surplus food tasks'
                                        : 'Toggle switch when ready to take food tasks',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _togglingAvailability
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Switch.adaptive(
                              value: isAvailable,
                              activeTrackColor: Colors.white,
                              activeColor: AppTheme.primaryGreen,
                              activeThumbColor: AppTheme.primaryGreen,
                              inactiveThumbColor: Colors.white70,
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                              onChanged: _toggleAvailability,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Incomplete Profile Notice (if setup not done) ──
          if (!isProfileComplete) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Account Setup Incomplete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Add your contact, address & vehicle info to accept tasks.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _open(
                      const VolunteerProfileSetupScreen(isEditMode: false),
                    ),
                    child: const Text(
                      'Complete',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadDashboard,
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 22),

          // ── Overview Summary Metrics (Interactive 2x2 Grid) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Overview',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                'Live Activity',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? AppTheme.primaryGreenDark : AppTheme.greyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Available Tasks',
                  value: '${_availableDeliveries.length}',
                  subtitle: 'Ready for pickup',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF2563EB),
                  onTap: () => _navigateToDeliveriesTab(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Active Tasks',
                  value: '$activeCount',
                  subtitle: 'Assigned to you',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFEA580C),
                  onTap: () => _navigateToDeliveriesTab(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Completed',
                  value: '${_stats?.completedDeliveries ?? 0}',
                  subtitle: 'Delivered safely',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Impact Score',
                  value: '${_stats?.communityImpactScore ?? 0} pts',
                  subtitle: 'Meals rescued',
                  icon: Icons.eco_outlined,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ],
          ),

          // ── Active Delivery in Progress (If active delivery exists) ──
          if (activeDelivery != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timelapse_rounded,
                    size: 16,
                    color: Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ongoing Delivery in Progress',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _openDelivery(activeDelivery!.id),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Track Route',
                    style: TextStyle(
                      color: AppTheme.primaryGreenDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DeliveryCard(
              delivery: activeDelivery,
              onTap: () => _openDelivery(activeDelivery!.id),
              isAvailablePool: false,
            ),
          ],

          const SizedBox(height: 24),

          // ── Available Delivery Tasks Preview ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Available Tasks',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  if (_availableDeliveries.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_availableDeliveries.length}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_availableDeliveries.isNotEmpty)
                TextButton(
                  onPressed: () => _navigateToDeliveriesTab(0),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primaryGreenDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_availableDeliveries.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      size: 28,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Available Tasks Right Now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'New surplus donations will appear here automatically. Pull down to refresh anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.greyText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _loadDashboard,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: AppTheme.primaryGreenDark,
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh Feed'),
                  ),
                ],
              ),
            )
          else ...[
            ..._availableDeliveries.take(3).map((delivery) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeliveryCard(
                  delivery: delivery,
                  onTap: () => _openDelivery(delivery.id),
                  isAvailablePool: true,
                ),
              );
            }),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void showFoodSafetyGuidelines(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppTheme.primaryGreenDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Food Safety Guidelines',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        'Standards for safe surplus transport',
                        style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.greyText),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSafetyItem(
              icon: Icons.thermostat_outlined,
              title: 'Temperature Control',
              desc:
                  'Keep warm meals above 60°C and chilled items below 5°C. Use insulated delivery bags at all times.',
            ),
            const SizedBox(height: 14),
            _buildSafetyItem(
              icon: Icons.timelapse_outlined,
              title: 'Prompt Delivery',
              desc:
                  'Deliver within 60 minutes from pickup to keep meals fresh, wholesome, and safe for consumption.',
            ),
            const SizedBox(height: 14),
            _buildSafetyItem(
              icon: Icons.verified_user_outlined,
              title: 'Tamper & Seal Check',
              desc:
                  'Verify container seals upon donor pickup. Never open or alter sealed donor packaging.',
            ),
            const SizedBox(height: 14),
            _buildSafetyItem(
              icon: Icons.handshake_outlined,
              title: 'Courteous Recipient Handover',
              desc:
                  'Follow recipient delivery notes and verify destination code before completing handoff.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreenDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Understood & Agree',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void showCoordinatorSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch Support Hotline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      Text(
                        'Urgent coordinator dispatch assistance',
                        style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: AppTheme.greyText),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Need urgent assistance with donor pickup, recipient contact, or vehicle breakdown?',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.3),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.phone_in_talk_rounded,
                    color: AppTheme.primaryGreenDark,
                    size: 24,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Coordinator Hotline',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.greyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '+1 (800) 555-FOOD (3663)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.mail_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volunteer Helpdesk Email',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.greyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'support@communityfoodsharing.org',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryGreenDark, size: 20),
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
                desc,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.greyText,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    if (onTap != null)
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppTheme.greyText,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ToolTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ToolTile({
    super.key,
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
            const Icon(Icons.chevron_right_rounded, color: AppTheme.greyText, size: 22),
          ],
        ),
      ),
    );
  }
}
