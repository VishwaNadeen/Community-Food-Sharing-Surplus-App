import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

import 'report_problem_screen.dart';
import 'tracking_screen.dart';
import 'volunteer_profile_setup_screen.dart';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class VolunteerDeliveryDetailScreen extends StatefulWidget {
  final String deliveryId;

  const VolunteerDeliveryDetailScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<VolunteerDeliveryDetailScreen> createState() =>
      _VolunteerDeliveryDetailScreenState();
}
class _VolunteerDeliveryDetailScreenState
    extends State<VolunteerDeliveryDetailScreen> {
  VolunteerDelivery? _delivery;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  String get _token => context.read<AuthProvider>().token!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _cleanError(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final delivery = await VolunteerService.getDelivery(
        token: _token,
        deliveryId: widget.deliveryId,
      );

      if (!mounted) return;
      setState(() => _delivery = delivery);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _actionLoading = true);

    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(e))),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  // =====================================================
  // ACCEPT DELIVERY
  // =====================================================

  Future<void> _accept() async {
    final auth = context.read<AuthProvider>();
    if (!auth.profileCompleted) {
      final shouldSetup = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Account Profile Required'),
          content: const Text(
            'You cannot accept deliveries without creating your volunteer profile (name, phone number, address, and vehicle details).',
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
              child: const Text('Complete Profile'),
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
      }
      return;
    }

    await _runAction(() async {
      await VolunteerService.acceptDelivery(
        token: _token,
        deliveryId: widget.deliveryId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery accepted successfully.')),
      );
    });
  }

  // =====================================================
  // REJECT DELIVERY
  // =====================================================

  Future<void> _reject() async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Delivery'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason == null || reason.isEmpty) return;

    await _runAction(() async {
      await VolunteerService.rejectDelivery(
        token: _token,
        deliveryId: widget.deliveryId,
        rejectionReason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery rejected.')),
      );
    });
  }

  // =====================================================
  // STATUS WORKFLOW
  // =====================================================

  String? _nextStatus(String status) {
    switch (status) {
      case 'ACCEPTED':
        return 'PICKED_UP';
      case 'PICKED_UP':
        return 'IN_TRANSIT';
      case 'IN_TRANSIT':
        return 'DELIVERED';
      default:
        return null;
    }
  }

  String _statusButtonLabel(String status) {
    switch (status) {
      case 'PICKED_UP':
        return 'Mark as Picked Up';
      case 'IN_TRANSIT':
        return 'Start Delivery';
      case 'DELIVERED':
        return 'Mark as Delivered';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Future<void> _advanceStatus() async {
    final current = _delivery;
    if (current == null) return;

    final next = _nextStatus(current.status);
    if (next == null) return;

    await _runAction(() async {
      await VolunteerService.updateDeliveryStatus(
        token: _token,
        deliveryId: widget.deliveryId,
        status: next,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status changed to ${next.replaceAll('_', ' ')}.'),
        ),
      );
    });
  }

  // =====================================================
  // GPS LOCATION
  // =====================================================

  Future<void> _updateCurrentLocation() async {
    await _runAction(() async {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please turn on device location services.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await VolunteerService.updateLocation(
        token: _token,
        deliveryId: widget.deliveryId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location updated.')),
      );
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Not specified';
    final d = value.toLocal();
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Delivery Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(_delivery!),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(VolunteerDelivery delivery) {
    final canAccept = delivery.status == 'PENDING_ASSIGNMENT' ||
        delivery.status == 'ASSIGNED';
    final nextStatus = _nextStatus(delivery.status);

    return Stack(
      children: [
        // ── Scrollable content ──────────────────────────────────────────
        ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            canAccept || nextStatus != null ? 100 : 24,
          ),
          children: [
            // Full-width map
            _DeliveryMapCard(delivery: delivery),

            // Content padding
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Status + Food header
                  _HeaderCard(delivery: delivery),

                  const SizedBox(height: 14),

                  // Pickup
                  _SectionCard(
                    title: 'Pickup',
                    icon: Icons.store_mall_directory_outlined,
                    children: [
                      _DetailRow(
                        label: 'Address',
                        value: delivery.pickupAddress ?? 'Not provided',
                      ),
                      _DetailRow(
                        label: 'Coordinates',
                        value: delivery.pickupLatitude != null &&
                                delivery.pickupLongitude != null
                            ? '${delivery.pickupLatitude}, ${delivery.pickupLongitude}'
                            : 'Not provided',
                      ),
                      _DetailRow(
                        label: 'Donor email',
                        value: delivery.donor?.email.isNotEmpty == true
                            ? delivery.donor!.email
                            : 'Not available',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Drop-off
                  _SectionCard(
                    title: 'Drop-off',
                    icon: Icons.location_on_outlined,
                    children: [
                      _DetailRow(
                        label: 'Address',
                        value: delivery.recipient?.deliveryAddress.isNotEmpty ==
                                true
                            ? delivery.recipient!.deliveryAddress
                            : delivery.dropoffAddress ?? 'Not provided',
                      ),
                      _DetailRow(
                        label: 'Recipient',
                        value: delivery.recipient?.name.isNotEmpty == true
                            ? delivery.recipient!.name
                            : 'Not available',
                      ),
                      _DetailRow(
                        label: 'Phone',
                        value:
                            delivery.recipient?.phoneNumber.isNotEmpty == true
                                ? delivery.recipient!.phoneNumber
                                : 'Not available',
                      ),
                      _DetailRow(
                        label: 'Distance',
                        value: delivery.distanceKm == null
                            ? 'Not available'
                            : '${delivery.distanceKm!.toStringAsFixed(2)} km',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Food & Timeline
                  _SectionCard(
                    title: 'Food & Timeline',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      _DetailRow(
                        label: delivery.foodItem.isEmpty
                            ? 'Food details unavailable'
                            : 'Item',
                        value: delivery.foodItem,
                      ),
                      _DetailRow(
                        label: 'Quantity',
                        value:
                            '${delivery.foodQuantityKg.toStringAsFixed(1)} kg',
                      ),
                      _DetailRow(
                        label: 'Expiry',
                        value: _formatDate(delivery.foodExpiryDate),
                      ),
                      _DetailRow(
                        label: 'Accepted',
                        value: _formatDate(delivery.acceptedAt),
                      ),
                      _DetailRow(
                        label: 'Picked up',
                        value: _formatDate(delivery.pickedUpAt),
                      ),
                      _DetailRow(
                        label: 'Delivered',
                        value: _formatDate(delivery.deliveredAt),
                      ),
                    ],
                  ),

                  if (delivery.rejectionReason != null) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Rejection',
                      icon: Icons.cancel_outlined,
                      children: [
                        _DetailRow(
                          label: 'Reason',
                          value: delivery.rejectionReason!,
                        ),
                      ],
                    ),
                  ],

                  // Secondary actions (only after accepting)
                  if (!canAccept) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _actionLoading ? null : _updateCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 18),
                            label: const Text('Update Location'),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VolunteerTrackingScreen(
                                    deliveryId: widget.deliveryId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.route_outlined, size: 18),
                            label: const Text('Tracking'),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VolunteerReportProblemScreen(
                                deliveryId: widget.deliveryId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.report_problem_outlined,
                            size: 18),
                        label: const Text('Report a Problem'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),

        // ── Loading overlay ─────────────────────────────────────────────
        if (_actionLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // ── Bottom sticky action bar ────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: canAccept
                ? FilledButton(
                    onPressed: _actionLoading ? null : _accept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreenDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept Delivery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : nextStatus != null
                    ? FilledButton.icon(
                        onPressed: _actionLoading ? null : _advanceStatus,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreenDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          _statusButtonLabel(nextStatus),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header card (food name + status chip)
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final VolunteerDelivery delivery;

  const _HeaderCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7ED),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          delivery.foodItem.isEmpty ? 'Food item' : delivery.foodItem,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF202124),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail row
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.greyText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-width map card
// ─────────────────────────────────────────────────────────────────────────────


class _DeliveryMapCard extends StatefulWidget {
  final VolunteerDelivery delivery;

  const _DeliveryMapCard({
    required this.delivery,
  });

  @override
  State<_DeliveryMapCard> createState() =>
      _DeliveryMapCardState();
}

class _DeliveryMapCardState extends State<_DeliveryMapCard> {
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  bool _locating = false;

  VolunteerDelivery get delivery => widget.delivery;

  bool get _hasPickup =>
      delivery.pickupLatitude != null &&
      delivery.pickupLongitude != null &&
      delivery.pickupLatitude! >= -90 &&
      delivery.pickupLatitude! <= 90 &&
      delivery.pickupLongitude! >= -180 &&
      delivery.pickupLongitude! <= 180;

  bool get _hasDropoff =>
      delivery.dropoffLatitude != null &&
      delivery.dropoffLongitude != null &&
      delivery.dropoffLatitude! >= -90 &&
      delivery.dropoffLatitude! <= 90 &&
      delivery.dropoffLongitude! >= -180 &&
      delivery.dropoffLongitude! <= 180;

  Future<void> _goToCurrentLocation() async {
    if (_locating) return;

    setState(() => _locating = true);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Please enable GPS/location services on your device.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Enable it in your device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() => _currentLocation = location);

      _mapController.move(location, 16);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _hasPickup
        ? LatLng(
            delivery.pickupLatitude!,
            delivery.pickupLongitude!,
          )
        : null;

    final dropoff = _hasDropoff
        ? LatLng(
            delivery.dropoffLatitude!,
            delivery.dropoffLongitude!,
          )
        : null;

    final locations = <LatLng>[
      if (pickup != null) pickup,
      if (dropoff != null) dropoff,
    ];

    final initialCenter = locations.isEmpty
        ? const LatLng(7.8731, 80.7718)
        : locations.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E5E9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'Pickup & Drop-off Map',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.50,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: locations.length > 1 ? 12 : 14,
                    initialCameraFit: locations.length > 1
                        ? CameraFit.coordinates(
                            coordinates: locations,
                            padding: const EdgeInsets.all(45),
                            maxZoom: 15,
                          )
                        : null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.foodlink.app',
                    ),

                    if (pickup != null && dropoff != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [pickup, dropoff],
                            strokeWidth: 4,
                            color: const Color(0xFF159653),
                          ),
                        ],
                      ),

                    MarkerLayer(
                      markers: [
                        if (pickup != null)
                          Marker(
                            point: pickup,
                            width: 75,
                            height: 55,
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.store,
                                  color: Colors.green,
                                  size: 30,
                                ),
                                Text(
                                  'Pickup',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (dropoff != null)
                          Marker(
                            point: dropoff,
                            width: 75,
                            height: 55,
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                Text(
                                  'Drop-off',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 48,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SimpleAttributionWidget(
                      source: Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),

                Positioned(
                  right: 12,
                  bottom: 45,
                  child: Material(
                    elevation: 4,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      tooltip: 'My current location',
                      onPressed: _locating
                          ? null
                          : _goToCurrentLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pickup != null)
                  Text(
                    'Pickup: ${delivery.pickupAddress ?? 'Address not provided'}',
                  ),
                if (pickup != null && dropoff != null)
                  const SizedBox(height: 8),
                if (dropoff != null)
                  Text(
                    'Drop-off: ${delivery.dropoffAddress ?? delivery.recipient?.deliveryAddress ?? 'Address not provided'}',
                  ),
                if (pickup == null || dropoff == null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Some delivery coordinates are not available.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
