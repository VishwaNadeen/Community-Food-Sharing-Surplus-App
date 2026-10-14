import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/volunteer/status_chip.dart';

import 'delivery_details_screen.dart';

class VolunteerOptimizedRouteScreen extends StatefulWidget {
  const VolunteerOptimizedRouteScreen({super.key});

  @override
  State<VolunteerOptimizedRouteScreen> createState() =>
      _VolunteerOptimizedRouteScreenState();
}

class _VolunteerOptimizedRouteScreenState
    extends State<VolunteerOptimizedRouteScreen> {
  bool _loading = true;
  String? _error;
  OptimizedVolunteerRoute? _route;

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
      final result = await VolunteerService.getOptimizedRoute(_token);

      if (!mounted) return;

      setState(() {
        _route = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Optimized Route',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: 'Refresh Route',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.darkText),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _error != null
              ? _buildErrorState()
              : _buildRoute(),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
                  Icons.error_outline_rounded,
                  size: 28,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Unable to Load Route',
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
                onPressed: _load,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreenDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoute() {
    final route = _route!;

    if (route.deliveries.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 36,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Deliveries to Optimize',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Accept tasks from the Deliveries tab first. Once accepted, our optimization algorithm calculates the most fuel-efficient sequence for your vehicle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: OutlinedButton.icon(
                onPressed: _load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreenDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Check for Active Tasks'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Route Summary Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
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
                    Icons.alt_route_rounded,
                    color: AppTheme.primaryGreenDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${route.deliveries.length} Optimized Stops',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Total Distance: ${route.totalDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Efficient',
                    style: TextStyle(
                      color: AppTheme.primaryGreenDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Header for stops
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Recommended Stop Sequence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                'Sequential Order',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.greyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // List of stops
          ...route.deliveries.asMap().entries.map((entry) {
            final index = entry.key;
            final delivery = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VolunteerDeliveryDetailScreen(
                          deliveryId: delivery.id,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreenDark,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                delivery.foodItem.isNotEmpty
                                    ? delivery.foodItem
                                    : 'Surplus Food Parcel',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkText,
                                ),
                              ),
                            ),
                            StatusChip(status: delivery.status),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Route pickup & dropoff
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.storefront_rounded,
                                    size: 16,
                                    color: AppTheme.primaryGreenDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pickup: ${delivery.pickupAddress?.trim().isNotEmpty == true ? delivery.pickupAddress! : "Donor location"}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.darkText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Drop-off: ${delivery.dropoffAddress?.trim().isNotEmpty == true ? delivery.dropoffAddress! : "Recipient location"}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.darkText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text(
                              'View Details & Navigation',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryGreenDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppTheme.primaryGreenDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          if (route.googleMapsUrl != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The system generated an optimized multi-stop route to reduce total transit time and minimize food spoilage.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}