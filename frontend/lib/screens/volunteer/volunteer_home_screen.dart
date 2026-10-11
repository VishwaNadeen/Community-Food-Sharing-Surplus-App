import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

import 'availability_screen.dart';
import 'deliveries_screen.dart';
import 'optimized_route_screen.dart';

class VolunteerHomeScreen
    extends StatefulWidget {
  const VolunteerHomeScreen({
    super.key,
  });

  @override
  State<VolunteerHomeScreen>
      createState() =>
          _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState
    extends State<VolunteerHomeScreen> {
  bool _loading = true;

  String? _error;

  VolunteerAvailability?
      _availability;

  VolunteerDashboardStats?
      _stats;

  int _availableTaskCount = 0;

  AuthProvider get _auth =>
      context.read<AuthProvider>();

  String get _token =>
      _auth.token!;

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  Future<void>
      _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results =
          await Future.wait<dynamic>([
        VolunteerService
            .getAvailability(
          _token,
        ),

        VolunteerService
            .getDashboard(
          _token,
        ),

        VolunteerService
            .getDeliveries(
          token: _token,
          status:
              'PENDING_ASSIGNMENT',
          sortByExpiry: true,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _availability =
            results[0]
                as VolunteerAvailability;

        _stats =
            results[1]
                as VolunteerDashboardStats;

        _availableTaskCount =
            (results[2] as List)
                .length;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _auth.logout();

    if (!mounted) return;

    Navigator
        .pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }

  Future<void> _open(
    Widget screen,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );

    if (mounted) {
      _loadDashboard();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        context
            .watch<AuthProvider>()
            .user;

    return Scaffold(
      backgroundColor:
          AppTheme.fieldFill,

      appBar: AppBar(
        title: const Text(
          'Volunteer Dashboard',
          style: TextStyle(
            color:
                AppTheme.darkText,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        backgroundColor:
            Colors.white,

        elevation: 0,

        actions: [
          IconButton(
            onPressed:
                _loadDashboard,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
            ),
          ),

          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout_outlined,
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  _loadDashboard,

              child: ListView(
                padding:
                    const EdgeInsets
                        .all(16),

                children: [
                  _WelcomeCard(
                    email:
                        user?.email ??
                            'Volunteer',
                    availability:
                        _availability,
                  ),

                  if (_error !=
                      null) ...[
                    const SizedBox(
                      height: 12,
                    ),

                    Container(
                      padding:
                          const EdgeInsets
                              .all(12),

                      decoration:
                          BoxDecoration(
                        color: Colors
                            .red
                            .shade50,

                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),

                      child: Text(
                        _error!,
                        style:
                            const TextStyle(
                          color: Colors
                              .redAccent,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _StatsGrid(
                    stats: _stats,
                    availableTaskCount:
                        _availableTaskCount,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  const Text(
                    'Volunteer Actions',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _ActionTile(
                    icon: Icons
                        .toggle_on_outlined,

                    title:
                        'Availability',

                    subtitle:
                        'Set yourself available or unavailable',

                    onTap: () =>
                        _open(
                      const VolunteerAvailabilityScreen(),
                    ),
                  ),

                  _ActionTile(
                    icon: Icons
                        .assignment_outlined,

                    title:
                        'Available Delivery Tasks',

                    subtitle:
                        'Browse unassigned deliveries and accept a task',

                    badge:
                        _availableTaskCount,

                    onTap: () =>
                        _open(
                      const VolunteerDeliveriesScreen(
                        initialTab: 0,
                      ),
                    ),
                  ),

                  _ActionTile(
                    icon: Icons
                        .local_shipping_outlined,

                    title:
                        'My Deliveries',

                    subtitle:
                        'View assigned, active and completed deliveries',

                    onTap: () =>
                        _open(
                      const VolunteerDeliveriesScreen(
                        initialTab: 1,
                      ),
                    ),
                  ),

                  _ActionTile(
                    icon:
                        Icons.route_outlined,

                    title:
                        'Optimized Route',

                    subtitle:
                        'See the recommended order for active deliveries',

                    onTap: () =>
                        _open(
                      const VolunteerOptimizedRouteScreen(),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            ),
    );
  }
}

class _WelcomeCard
    extends StatelessWidget {
  final String email;

  final VolunteerAvailability?
      availability;

  const _WelcomeCard({
    required this.email,
    required this.availability,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final available =
        availability?.isAvailable ??
            false;

    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          22,
        ),

        border: Border.all(
          color: AppTheme.border,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,

            decoration:
                BoxDecoration(
              color:
                  AppTheme.lightGreen,

              borderRadius:
                  BorderRadius
                      .circular(
                18,
              ),
            ),

            child: const Icon(
              Icons
                  .volunteer_activism,
              color: AppTheme
                  .primaryGreenDark,
              size: 34,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: AppTheme
                        .greyText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  email,

                  maxLines: 1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,

                      decoration:
                          BoxDecoration(
                        shape:
                            BoxShape.circle,

                        color: available
                            ? AppTheme
                                .primaryGreen
                            : Colors
                                .grey,
                      ),
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      available
                          ? 'AVAILABLE'
                          : 'UNAVAILABLE',

                      style:
                          TextStyle(
                        color: available
                            ? AppTheme
                                .primaryGreenDark
                            : AppTheme
                                .greyText,

                        fontWeight:
                            FontWeight
                                .w700,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid
    extends StatelessWidget {
  final VolunteerDashboardStats?
      stats;

  final int availableTaskCount;

  const _StatsGrid({
    required this.stats,
    required this.availableTaskCount,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final items = [
      (
        'Available',
        '$availableTaskCount',
        Icons.assignment_outlined,
      ),
      (
        'Active',
        '${stats?.activeDeliveries ?? 0}',
        Icons.local_shipping_outlined,
      ),
      (
        'Completed',
        '${stats?.completedDeliveries ?? 0}',
        Icons.check_circle_outline,
      ),
      (
        'Impact',
        '${stats?.communityImpactScore ?? 0}',
        Icons.eco_outlined,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,

      physics:
          const NeverScrollableScrollPhysics(),

      itemCount:
          items.length,

      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),

      itemBuilder:
          (context, index) {
        final item =
            items[index];

        return Container(
          padding:
              const EdgeInsets.all(
            14,
          ),

          decoration:
              BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.circular(
              16,
            ),

            border: Border.all(
              color:
                  AppTheme.border,
            ),
          ),

          child: Row(
            children: [
              Icon(
                item.$3,
                color: AppTheme
                    .primaryGreen,
                size: 28,
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      item.$2,
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    Text(
                      item.$1,
                      style:
                          const TextStyle(
                        color:
                            AppTheme
                                .greyText,

                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  final int? badge;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      elevation: 0,

      color: Colors.white,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        side: const BorderSide(
          color: AppTheme.border,
        ),
      ),

      child: ListTile(
        onTap: onTap,

        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 14,
          vertical: 7,
        ),

        leading: Container(
          width: 46,
          height: 46,

          decoration:
              BoxDecoration(
            color:
                AppTheme.lightGreen,

            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),

          child: Icon(
            icon,
            color: AppTheme
                .primaryGreenDark,
          ),
        ),

        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        subtitle:
            Text(subtitle),

        trailing:
            badge != null &&
                    badge! > 0
                ? Badge(
                    label: Text(
                      '$badge',
                    ),
                    child:
                        const Icon(
                      Icons
                          .chevron_right,
                    ),
                  )
                : const Icon(
                    Icons
                        .chevron_right,
                  ),
      ),
    );
  }
}