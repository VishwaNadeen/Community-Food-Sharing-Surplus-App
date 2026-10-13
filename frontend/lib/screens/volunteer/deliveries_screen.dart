import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/volunteer/delivery_card.dart';

import 'delivery_details_screen.dart';
import 'volunteer_profile_setup_screen.dart';

class VolunteerDeliveriesScreen
    extends StatefulWidget {
  final int initialTab;

  const VolunteerDeliveriesScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<VolunteerDeliveriesScreen>
      createState() =>
          VolunteerDeliveriesScreenState();
}

class VolunteerDeliveriesScreenState
    extends State<
        VolunteerDeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController
      _tabController;

  void selectTab(int index) {
    if (mounted && index >= 0 && index < 2) {
      _tabController.animateTo(index);
    }
  }

  @override
  void initState() {
    super.initState();

    _tabController =
        TabController(
      length: 2,

      vsync: this,

      initialIndex:
          widget.initialTab.clamp(
        0,
        1,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Volunteer Deliveries',
        ),

        bottom: TabBar(
          controller:
              _tabController,

          tabs: const [
            Tab(
              text:
                  'Available Tasks',
            ),
            Tab(
              text:
                  'My Deliveries',
            ),
          ],
        ),
      ),

      body: TabBarView(
        controller:
            _tabController,

        children: const [
          _DeliveryList(
            availablePool:
                true,
          ),

          _DeliveryList(
            availablePool:
                false,
          ),
        ],
      ),
    );
  }
}

class _DeliveryList
    extends StatefulWidget {
  final bool availablePool;

  const _DeliveryList({
    required this.availablePool,
  });

  @override
  State<_DeliveryList>
      createState() =>
          _DeliveryListState();
}

class _DeliveryListState
    extends State<_DeliveryList> {
  bool _loading = true;

  String? _error;

  List<VolunteerDelivery>
      _items = [];

  String get _token =>
      context
          .read<AuthProvider>()
          .token!;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await VolunteerService
              .getDeliveries(
        token: _token,

        status:
            widget.availablePool
                ? 'PENDING_ASSIGNMENT'
                : null,

        sortByExpiry:
            widget.availablePool,
      );

      if (!mounted) return;

      setState(() {
        _items = data;
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

  Future<void> _open(
    VolunteerDelivery delivery,
  ) async {
    final auth = context.read<AuthProvider>();
    if (!auth.profileCompleted) {
      final shouldSetup = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Account Setup Required'),
          content: const Text(
            'You cannot process or accept deliveries without creating your volunteer profile (name, address, phone number, vehicle details).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreenDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Set Up Account'),
            ),
          ],
        ),
      );

      if (shouldSetup == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VolunteerProfileSetupScreen(),
          ),
        );
        if (mounted) _load();
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VolunteerDeliveryDetailScreen(
          deliveryId:
              delivery.id,
        ),
      ),
    );

    if (mounted) {
      _load();
    }
  }

  Widget _buildIncompleteBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade900, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Setup Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Complete your account profile before accepting deliveries.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreenDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VolunteerProfileSetupScreen(),
                ),
              );
              if (mounted) _load();
            },
            child: const Text('Set Up'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final isProfileComplete = context.watch<AuthProvider>().profileCompleted;

    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _error!,
                textAlign:
                    TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              OutlinedButton(
                onPressed: _load,
                child:
                    const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget content;
    if (_items.isEmpty) {
      content = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(
              height: 120,
            ),
            Icon(
              widget.availablePool
                  ? Icons
                      .inbox_outlined
                  : Icons
                      .local_shipping_outlined,
              size: 64,
              color:
                  AppTheme.greyText,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              widget.availablePool
                  ? 'No delivery tasks are available right now.'
                  : 'You do not have any assigned deliveries yet.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    AppTheme.greyText,
              ),
            ),
          ],
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final delivery = _items[index];
            return DeliveryCard(
              delivery: delivery,
              onTap: () => _open(delivery),
              isAvailablePool: widget.availablePool,
            );
          },
        ),
      );
    }

    if (!isProfileComplete) {
      return Column(
        children: [
          _buildIncompleteBanner(),
          Expanded(child: content),
        ],
      );
    }

    return content;
  }
}