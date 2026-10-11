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
          content: Text(
            isNowAvailable
                ? 'You are now marked AVAILABLE for deliveries!'
                : 'You are now marked OFFLINE / UNAVAILABLE.',
          ),
          backgroundColor: isNowAvailable
              ? AppTheme.primaryGreenDark
              : Colors.grey.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update availability: $e'),
          backgroundColor: Colors.redAccent,
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
        backgroundColor: AppTheme.fieldFill,
        appBar: _currentIndex == 0
            ? AppBar(
                title: const Text(
                  'Volunteer Dashboard',
                  style: TextStyle(
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                actions: [
                  IconButton(
                    onPressed: _loadDashboard,
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh, color: AppTheme.darkText),
                  ),
                  IconButton(
                    onPressed: _logout,
                    tooltip: 'Logout',
                    icon: const Icon(
                      Icons.logout_outlined,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 0) {
              _loadDashboard();
            }
          },
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.greyText,
          backgroundColor: Colors.white,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Deliveries',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.route_outlined),
              activeIcon: Icon(Icons.route),
              label: 'Route',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardBody(dynamic user) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Welcome Card with In-place Availability Toggle ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: AppTheme.primaryGreenDark,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: AppTheme.greyText,
                                fontSize: 12.5,
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
                                color: AppTheme.darkText,
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
                                    color: AppTheme.greyText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _profile!.vehicleType!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppTheme.greyText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // Instant Availability Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAvailable
                                ? AppTheme.primaryGreenDark
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAvailable
                              ? 'AVAILABLE FOR TASKS'
                              : 'CURRENTLY OFFLINE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isAvailable
                                ? AppTheme.primaryGreenDark
                                : AppTheme.greyText,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    _togglingAvailability
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch.adaptive(
                            value: isAvailable,
                            activeTrackColor: AppTheme.primaryGreen,
                            onChanged: _toggleAvailability,
                          ),
                  ],
                ),
              ],
            ),
          ),

          // ── Incomplete Profile Notice (if setup not done) ──
          if (!isProfileComplete) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade900,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Setup Incomplete',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Add your contact, address & vehicle info to accept tasks.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreenDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _open(
                      const VolunteerProfileSetupScreen(isEditMode: false),
                    ),
                    child: const Text('Set Up'),
                  ),
                ],
              ),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Overview Summary Metrics (Interactive 2x2 Grid) ──
          const Text(
            'Delivery Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
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
                  color: Colors.blue.shade700,
                  onTap: () => _navigateToDeliveriesTab(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Active Deliveries',
                  value: '$activeCount',
                  subtitle: 'Assigned to you',
                  icon: Icons.local_shipping_outlined,
                  color: Colors.orange.shade800,
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
                  color: AppTheme.primaryGreenDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Impact Score',
                  value: '${_stats?.communityImpactScore ?? 0} pts',
                  subtitle: 'Meals rescued',
                  icon: Icons.eco_outlined,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),

          // ── Active Delivery in Progress (If active delivery exists) ──
          if (activeDelivery != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.timelapse_outlined,
                  size: 18,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Active Delivery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
              const Text(
                'Available Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              if (_availableDeliveries.isNotEmpty)
                TextButton(
                  onPressed: () => _navigateToDeliveriesTab(0),
                  child: Text(
                    'View All (${_availableDeliveries.length})',
                    style: const TextStyle(
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: AppTheme.greyText,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No available tasks',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.greyText),
                  ),
                ],
              ),
            )
          else ...[
            ..._availableDeliveries.take(2).map((delivery) {
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: AppTheme.primaryGreenDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Food Safety Guidelines',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood & Agree'),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.support_agent_outlined,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Volunteer Dispatch Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Need urgent assistance with donor pickup, recipient contact, or vehicle breakdown?',
              style: TextStyle(fontSize: 14, color: AppTheme.darkText),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.phone_in_talk_outlined,
                    color: AppTheme.primaryGreenDark,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Coordinator Hotline',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
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
                color: AppTheme.fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mail_outline, color: AppTheme.primaryGreenDark),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Volunteer Helpdesk Email',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
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
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppTheme.greyText,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
              ),
            ],
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
            const Icon(Icons.chevron_right, color: AppTheme.greyText, size: 20),
          ],
        ),
      ),
    );
  }
}
