import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/volunteer/delivery_card.dart';

import 'delivery_details_screen.dart';
import 'volunteer_profile_setup_screen.dart';

class VolunteerDeliveriesScreen extends StatefulWidget {
  final int initialTab;

  const VolunteerDeliveriesScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<VolunteerDeliveriesScreen> createState() =>
      VolunteerDeliveriesScreenState();
}

class VolunteerDeliveriesScreenState extends State<VolunteerDeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  void selectTab(int index) {
    if (mounted && index >= 0 && index < 2) {
      _tabController.animateTo(index);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Volunteer Deliveries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.greyText,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              text: 'Available Tasks',
            ),
            Tab(
              text: 'My Deliveries',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DeliveryList(availablePool: true),
          _DeliveryList(availablePool: false),
        ],
      ),
    );
  }
}

class _DeliveryList extends StatefulWidget {
  final bool availablePool;

  const _DeliveryList({required this.availablePool});

  @override
  State<_DeliveryList> createState() => _DeliveryListState();
}

class _DeliveryListState extends State<_DeliveryList> {
  bool _loading = true;
  String? _error;
  List<VolunteerDelivery> _items = [];

  String get _token => context.read<AuthProvider>().token!;

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
      final data = await VolunteerService.getDeliveries(
        token: _token,
        status: widget.availablePool ? 'PENDING_ASSIGNMENT' : null,
        sortByExpiry: widget.availablePool,
      );

      if (!mounted) return;

      setState(() {
        _items = data;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(VolunteerDelivery delivery) async {
    final auth = context.read<AuthProvider>();
    if (!auth.profileCompleted) {
      final shouldSetup = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Account Setup Required',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You cannot process or accept deliveries without creating your volunteer profile (name, address, phone number, vehicle details).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.greyText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreenDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        builder: (_) => VolunteerDeliveryDetailScreen(deliveryId: delivery.id),
      ),
    );

    if (mounted) {
      _load();
    }
  }

  Widget _buildIncompleteBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber.shade900,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Setup Required',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Complete your account profile before accepting deliveries.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreenDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
  Widget build(BuildContext context) {
    final isProfileComplete = context.watch<AuthProvider>().profileCompleted;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Unable to Load Deliveries',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyText,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 140,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Retry',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.availablePool
                    ? Icons.inbox_outlined
                    : Icons.local_shipping_outlined,
                size: 64,
                color: AppTheme.primaryGreenDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.availablePool
                  ? 'No delivery tasks are available right now.'
                  : 'You do not have any assigned deliveries yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to refresh',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.greyText,
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
          separatorBuilder: (_, _) => const SizedBox(height: 14),
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