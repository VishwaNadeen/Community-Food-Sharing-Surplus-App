import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

import 'delivery_details_screen.dart';

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
          _VolunteerDeliveriesScreenState();
}

class _VolunteerDeliveriesScreenState
    extends State<
        VolunteerDeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController
      _tabController;

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

  @override
  Widget build(
    BuildContext context,
  ) {
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

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children: [
            const SizedBox(
              height: 150,
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
    }

    return RefreshIndicator(
      onRefresh: _load,

      child:
          ListView.separated(
        padding:
            const EdgeInsets.all(
          16,
        ),

        itemCount:
            _items.length,

        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 12,
        ),

        itemBuilder:
            (context, index) {
          final delivery =
              _items[index];

          return _DeliveryCard(
            delivery: delivery,

            onTap: () =>
                _open(
              delivery,
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryCard
    extends StatelessWidget {
  final VolunteerDelivery delivery;

  final VoidCallback onTap;

  const _DeliveryCard({
    required this.delivery,
    required this.onTap,
  });

  String _date(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Not specified';
    }

    final d =
        date.toLocal();

    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(
        18,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          18,
        ),

        onTap: onTap,

        child: Container(
          padding:
              const EdgeInsets.all(
            16,
          ),

          decoration:
              BoxDecoration(
            border: Border.all(
              color:
                  AppTheme.border,
            ),

            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      delivery.foodItem,

                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ),

                  _StatusChip(
                    status:
                        delivery.status,
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              _InfoLine(
                icon:
                    Icons.scale_outlined,

                text:
                    '${delivery.foodQuantityKg.toStringAsFixed(1)} kg',
              ),

              const SizedBox(
                height: 8,
              ),

              _InfoLine(
                icon: Icons
                    .schedule_outlined,

                text:
                    'Expiry: ${_date(delivery.foodExpiryDate)}',
              ),

              const SizedBox(
                height: 8,
              ),

              _InfoLine(
                icon: Icons
                    .store_mall_directory_outlined,

                text: delivery
                        .pickupAddress ??
                    'Pickup address not provided',
              ),

              const SizedBox(
                height: 8,
              ),

              _InfoLine(
                icon: Icons
                    .location_on_outlined,

                text: delivery
                        .dropoffAddress ??
                    'Drop-off address not provided',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine
    extends StatelessWidget {
  final IconData icon;

  final String text;

  const _InfoLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 18,
          color:
              AppTheme.greyText,
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Text(
            text,

            style:
                const TextStyle(
              color:
                  AppTheme.greyText,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip
    extends StatelessWidget {
  final String status;

  const _StatusChip({
    required this.status,
  });

  Color get _color {
    switch (status) {
      case 'DELIVERED':
        return AppTheme
            .primaryGreen;

      case 'REJECTED':
      case 'CANCELLED':
        return Colors
            .redAccent;

      case 'IN_TRANSIT':
        return Colors.blue;

      case 'PICKED_UP':
        return Colors.orange;

      default:
        return Colors
            .blueGrey;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final color = _color;

    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Text(
        status.replaceAll(
          '_',
          ' ',
        ),

        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}