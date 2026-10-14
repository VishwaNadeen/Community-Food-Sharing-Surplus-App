import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/volunteer/status_chip.dart';

import 'delivery_route_map.dart';
import 'report_problem_screen.dart';
import 'tracking_screen.dart';
import 'volunteer_profile_setup_screen.dart';

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
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Account Profile Required', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'You cannot accept deliveries without creating your volunteer profile (name, phone number, address, and vehicle details).',
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
        SnackBar(
          content: const Text('Delivery task accepted successfully!'),
          backgroundColor: AppTheme.primaryGreenDark,
          behavior: SnackBarBehavior.floating,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline Delivery Task', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a brief reason for declining this delivery assignment:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Vehicle breakdown, outside coverage area, unavailable...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.greyText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Decline Task'),
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
        const SnackBar(
          content: Text('Delivery declined and returned to pool.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  // =====================================================
  // STATUS WORKFLOW
  // =====================================================

  String? _nextStatus(String status) {
    switch (status.toUpperCase()) {
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
        return 'Confirm Food Picked Up';
      case 'IN_TRANSIT':
        return 'Start Trip to Recipient';
      case 'DELIVERED':
        return 'Confirm Food Delivered';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  IconData _statusButtonIcon(String status) {
    switch (status) {
      case 'PICKED_UP':
        return Icons.inventory_2_rounded;
      case 'IN_TRANSIT':
        return Icons.local_shipping_rounded;
      case 'DELIVERED':
        return Icons.check_circle_rounded;
      default:
        return Icons.arrow_forward_rounded;
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
          content: Text('Delivery progressed to ${next.replaceAll('_', ' ')}.'),
          backgroundColor: AppTheme.primaryGreenDark,
          behavior: SnackBarBehavior.floating,
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
        SnackBar(
          content: const Text('Live GPS location transmitted to dispatch.'),
          backgroundColor: AppTheme.primaryGreenDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    final d = value.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[d.month - 1];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} $month ${d.year}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Delivery Details',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _error != null
              ? _buildError()
              : _buildContent(_delivery!),
    );
  }

  Widget _buildError() {
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
                child: const Icon(Icons.error_outline_rounded, size: 30, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 14),
              const Text(
                'Failed to Load Details',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppTheme.darkText),
              ),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 18),
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
            canAccept || nextStatus != null ? 120 : 32,
          ),
          children: [
            // Live route map: volunteer location, donor and route to follow
            _DeliveryMapCard(delivery: delivery),

            // Content padding
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Status + Food header
                  _HeaderCard(delivery: delivery),

                  const SizedBox(height: 14),

                  // Interactive Stage Stepper
                  _DeliveryProgressStepper(status: delivery.status),

                  const SizedBox(height: 14),

                  // Pickup
                  _SectionCard(
                    title: 'Pickup Location',
                    icon: Icons.storefront_rounded,
                    iconColor: AppTheme.primaryGreenDark,
                    children: [
                      _DetailRow(
                        label: 'Address',
                        value: delivery.pickupAddress?.trim().isNotEmpty == true
                            ? delivery.pickupAddress!
                            : 'Donor pickup address not specified',
                      ),
                      if (delivery.pickupLatitude != null && delivery.pickupLongitude != null)
                        _DetailRow(
                          label: 'Coordinates',
                          value: '${delivery.pickupLatitude!.toStringAsFixed(4)}, ${delivery.pickupLongitude!.toStringAsFixed(4)}',
                        ),
                      _DetailRow(
                        label: 'Donor Email',
                        value: delivery.donor?.email.isNotEmpty == true
                            ? delivery.donor!.email
                            : 'Not available',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Drop-off
                  _SectionCard(
                    title: 'Drop-off Destination',
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFFDC2626),
                    children: [
                      _DetailRow(
                        label: 'Address',
                        value: delivery.recipient?.deliveryAddress.isNotEmpty == true
                            ? delivery.recipient!.deliveryAddress
                            : delivery.dropoffAddress?.trim().isNotEmpty == true
                                ? delivery.dropoffAddress!
                                : 'Recipient address not specified',
                      ),
                      _DetailRow(
                        label: 'Recipient',
                        value: delivery.recipient?.name.isNotEmpty == true
                            ? delivery.recipient!.name
                            : 'Not available',
                      ),
                      _DetailRow(
                        label: 'Phone Contact',
                        value: delivery.recipient?.phoneNumber.isNotEmpty == true
                            ? delivery.recipient!.phoneNumber
                            : 'Not available',
                      ),
                      if (delivery.distanceKm != null)
                        _DetailRow(
                          label: 'Distance',
                          value: '${delivery.distanceKm!.toStringAsFixed(2)} km',
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Food & Timeline
                  _SectionCard(
                    title: 'Item & Milestones',
                    icon: Icons.inventory_2_rounded,
                    iconColor: const Color(0xFF2563EB),
                    children: [
                      _DetailRow(
                        label: 'Food Item',
                        value: delivery.foodItem.isNotEmpty
                            ? delivery.foodItem
                            : 'Surplus food parcel',
                      ),
                      _DetailRow(
                        label: 'Quantity',
                        value: '${delivery.foodQuantityKg.toStringAsFixed(1)} kg',
                      ),
                      _DetailRow(
                        label: 'Food Expiry',
                        value: _formatDate(delivery.foodExpiryDate),
                      ),
                      _DetailRow(
                        label: 'Accepted At',
                        value: _formatDate(delivery.acceptedAt),
                      ),
                      _DetailRow(
                        label: 'Picked Up At',
                        value: _formatDate(delivery.pickedUpAt),
                      ),
                      _DetailRow(
                        label: 'Delivered At',
                        value: _formatDate(delivery.deliveredAt),
                      ),
                    ],
                  ),

                  if (delivery.rejectionReason != null) ...[
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Decline Notice',
                      icon: Icons.cancel_rounded,
                      iconColor: const Color(0xFFDC2626),
                      children: [
                        _DetailRow(
                          label: 'Reason',
                          value: delivery.rejectionReason!,
                        ),
                      ],
                    ),
                  ],

                  // Secondary actions (only after accepting)
                  if (!canAccept && delivery.status != 'REJECTED' && delivery.status != 'DELIVERED') ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _actionLoading ? null : _updateCurrentLocation,
                            icon: const Icon(Icons.my_location_rounded, size: 18),
                            label: const Text('Update GPS'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: AppTheme.primaryGreenDark,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                            icon: const Icon(Icons.timeline_rounded, size: 18),
                            label: const Text('Timeline'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                        icon: const Icon(Icons.report_problem_outlined, size: 18),
                        label: const Text('Report an Issue'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: const Color(0xFFEA580C),
                          side: const BorderSide(color: Color(0xFFFED7AA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
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
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                ),
              ],
              border: const Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: canAccept
                ? Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: _actionLoading ? null : _reject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _actionLoading ? null : _accept,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreenDark,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_task_rounded, size: 20),
                          label: const Text(
                            'Accept Delivery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : nextStatus != null
                    ? FilledButton.icon(
                        onPressed: _actionLoading ? null : _advanceStatus,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreenDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(_statusButtonIcon(nextStatus)),
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
// Header card (food name + status chip + quantity)
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lunch_dining_rounded,
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
                  delivery.foodItem.isEmpty ? 'Food item' : delivery.foodItem,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${delivery.foodQuantityKg.toStringAsFixed(1)} kg surplus package',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(status: delivery.status),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delivery Progress Stepper
// ─────────────────────────────────────────────────────────────────────────────
class _DeliveryProgressStepper extends StatelessWidget {
  final String status;

  const _DeliveryProgressStepper({required this.status});

  int get _stepIndex {
    switch (status.toUpperCase()) {
      case 'PENDING_ASSIGNMENT':
      case 'ASSIGNED':
        return 0;
      case 'ACCEPTED':
        return 1;
      case 'PICKED_UP':
        return 2;
      case 'IN_TRANSIT':
        return 3;
      case 'DELIVERED':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _stepIndex;
    final steps = ['Assigned', 'Accepted', 'Picked Up', 'In Transit', 'Delivered'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Progression',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final lineIndex = i ~/ 2;
                final isDone = lineIndex < current;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    color: isDone ? AppTheme.primaryGreenDark : const Color(0xFFE2E8F0),
                  ),
                );
              } else {
                final nodeIndex = i ~/ 2;
                final isPassed = nodeIndex <= current;
                final isCurrent = nodeIndex == current;
                return Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPassed ? AppTheme.primaryGreenDark : const Color(0xFFF1F5F9),
                    border: Border.all(
                      color: isCurrent
                          ? AppTheme.primaryGreen
                          : isPassed
                              ? AppTheme.primaryGreenDark
                              : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isPassed
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : Text(
                            '${nodeIndex + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pickup',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: current >= 1 ? AppTheme.primaryGreenDark : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                'Transit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: current >= 3 ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                'Completed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: current >= 4 ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
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
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor = AppTheme.primaryGreen,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFE2E8F0)),
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
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppTheme.darkText,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map card: live route map with full-screen option
// ─────────────────────────────────────────────────────────────────────────────

class _DeliveryMapCard extends StatelessWidget {
  final VolunteerDelivery delivery;

  const _DeliveryMapCard({required this.delivery});

  bool get _headingToDonor => delivery.status == 'ACCEPTED';

  @override
  Widget build(BuildContext context) {
    final destinationAddress = _headingToDonor
        ? delivery.pickupAddress
        : delivery.recipient?.deliveryAddress.isNotEmpty == true
            ? delivery.recipient!.deliveryAddress
            : delivery.dropoffAddress;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        _headingToDonor ? Icons.storefront_rounded : Icons.navigation_rounded,
                        size: 18,
                        color: _headingToDonor ? AppTheme.primaryGreenDark : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _headingToDonor ? 'Route to Donor (Pickup)' : 'Route to Destination (Drop-off)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Live GPS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          DeliveryRouteMap(
            delivery: delivery,
            height: MediaQuery.sizeOf(context).height * 0.42,
            onOpenFullScreen: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryNavigationScreen(delivery: delivery),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _headingToDonor ? Icons.storefront_rounded : Icons.location_on_rounded,
                  color: _headingToDonor ? AppTheme.primaryGreenDark : const Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_headingToDonor ? 'Pickup' : 'Drop-off'}: '
                    '${destinationAddress?.trim().isNotEmpty == true ? destinationAddress! : 'Address not specified'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.darkText,
                    ),
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
