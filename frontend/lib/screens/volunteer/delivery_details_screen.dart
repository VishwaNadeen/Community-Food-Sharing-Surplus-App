import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

import 'report_problem_screen.dart';
import 'tracking_screen.dart';

class VolunteerDeliveryDetailScreen
    extends StatefulWidget {
  final String deliveryId;

  const VolunteerDeliveryDetailScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<VolunteerDeliveryDetailScreen>
      createState() =>
          _VolunteerDeliveryDetailScreenState();
}

class _VolunteerDeliveryDetailScreenState
    extends State<
        VolunteerDeliveryDetailScreen> {
  VolunteerDelivery? _delivery;

  bool _loading = true;

  bool _actionLoading = false;

  String? _error;

  String get _token =>
      context
          .read<AuthProvider>()
          .token!;

  @override
  void initState() {
    super.initState();

    _load();
  }

  String _cleanError(
    Object e,
  ) {
    return e
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final delivery =
          await VolunteerService
              .getDelivery(
        token: _token,
        deliveryId:
            widget.deliveryId,
      );

      if (!mounted) return;

      setState(() {
        _delivery = delivery;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _runAction(
    Future<void> Function()
        action,
  ) async {
    setState(() {
      _actionLoading = true;
    });

    try {
      await action();

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(e),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading =
              false;
        });
      }
    }
  }

  // =====================================================
  // ACCEPT DELIVERY
  // =====================================================

  Future<void> _accept() async {
    await _runAction(
      () async {
        await VolunteerService
            .acceptDelivery(
          token: _token,

          deliveryId:
              widget.deliveryId,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery accepted successfully.',
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // REJECT DELIVERY
  // =====================================================

  Future<void> _reject() async {
    final controller =
        TextEditingController();

    final reason =
        await showDialog<String>(
      context: context,

      builder:
          (dialogContext) =>
              AlertDialog(
        title: const Text(
          'Reject Delivery',
        ),

        content: TextField(
          controller:
              controller,

          autofocus: true,

          maxLines: 3,

          decoration:
              const InputDecoration(
            hintText:
                'Enter rejection reason',
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
              );
            },
            child:
                const Text(
              'Cancel',
            ),
          ),

          FilledButton(
            onPressed: () {
              final value =
                  controller
                      .text
                      .trim();

              if (value.isNotEmpty) {
                Navigator.pop(
                  dialogContext,
                  value,
                );
              }
            },
            child:
                const Text(
              'Reject',
            ),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason == null ||
        reason.isEmpty) {
      return;
    }

    await _runAction(
      () async {
        await VolunteerService
            .rejectDelivery(
          token: _token,

          deliveryId:
              widget.deliveryId,

          rejectionReason:
              reason,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery rejected.',
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // STATUS WORKFLOW
  // ACCEPTED -> PICKED_UP -> IN_TRANSIT -> DELIVERED
  // =====================================================

  String? _nextStatus(
    String status,
  ) {
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

  String _statusButtonLabel(
    String status,
  ) {
    switch (status) {
      case 'PICKED_UP':
        return 'Mark as Picked Up';

      case 'IN_TRANSIT':
        return 'Start Delivery';

      case 'DELIVERED':
        return 'Mark as Delivered';

      default:
        return status.replaceAll(
          '_',
          ' ',
        );
    }
  }

  Future<void>
      _advanceStatus() async {
    final current =
        _delivery;

    if (current == null) {
      return;
    }

    final next =
        _nextStatus(
      current.status,
    );

    if (next == null) {
      return;
    }

    await _runAction(
      () async {
        await VolunteerService
            .updateDeliveryStatus(
          token: _token,

          deliveryId:
              widget.deliveryId,

          status: next,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Status changed to ${next.replaceAll('_', ' ')}.',
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // GPS LOCATION
  // =====================================================

  Future<void>
      _updateCurrentLocation() async {
    await _runAction(
      () async {
        final serviceEnabled =
            await Geolocator
                .isLocationServiceEnabled();

        if (!serviceEnabled) {
          throw Exception(
            'Please turn on device location services.',
          );
        }

        var permission =
            await Geolocator
                .checkPermission();

        if (permission ==
            LocationPermission.denied) {
          permission =
              await Geolocator
                  .requestPermission();
        }

        if (permission ==
                LocationPermission
                    .denied ||
            permission ==
                LocationPermission
                    .deniedForever) {
          throw Exception(
            'Location permission is required.',
          );
        }

        final position =
            await Geolocator
                .getCurrentPosition(
          locationSettings:
              const LocationSettings(
            accuracy:
                LocationAccuracy
                    .high,
          ),
        );

        await VolunteerService
            .updateLocation(
          token: _token,

          deliveryId:
              widget.deliveryId,

          latitude:
              position.latitude,

          longitude:
              position.longitude,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Current location updated.',
            ),
          ),
        );
      },
    );
  }

  String _formatDate(
    DateTime? value,
  ) {
    if (value == null) {
      return 'Not specified';
    }

    final d =
        value.toLocal();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery Details',
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _error != null
              ? _buildError()
              : _buildContent(
                  _delivery!,
                ),
    );
  }

  Widget _buildError() {
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
              size: 52,
              color:
                  Colors.redAccent,
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

  Widget _buildContent(
    VolunteerDelivery delivery,
  ) {
    final canAccept =
        delivery.status ==
                'PENDING_ASSIGNMENT' ||
            delivery.status ==
                'ASSIGNED';

    final nextStatus =
        _nextStatus(
      delivery.status,
    );

    return Stack(
      children: [
        ListView(
          padding:
              const EdgeInsets
                  .fromLTRB(
            16,
            16,
            16,
            120,
          ),

          children: [
            _HeaderCard(
              delivery: delivery,
            ),

            const SizedBox(
              height: 16,
            ),

            // PICKUP INFORMATION
            _SectionCard(
              title: 'Pickup',

              icon: Icons
                  .store_mall_directory_outlined,

              children: [
                _DetailRow(
                  label: 'Address',

                  value: delivery
                          .pickupAddress ??
                      'Not provided',
                ),

                _DetailRow(
                  label:
                      'Coordinates',

                  value: delivery
                                  .pickupLatitude !=
                              null &&
                          delivery
                                  .pickupLongitude !=
                              null
                      ? '${delivery.pickupLatitude}, ${delivery.pickupLongitude}'
                      : 'Not provided',
                ),

                _DetailRow(
                  label:
                      'Donor email',

                  value: delivery
                              .donor
                              ?.email
                              .isNotEmpty ==
                          true
                      ? delivery
                          .donor!
                          .email
                      : 'Not available',
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            // DROP-OFF INFORMATION
            _SectionCard(
              title: 'Drop-off',

              icon: Icons
                  .location_on_outlined,

              children: [
                _DetailRow(
                  label: 'Address',

                  value: delivery
                              .recipient
                              ?.deliveryAddress
                              .isNotEmpty ==
                          true
                      ? delivery
                          .recipient!
                          .deliveryAddress
                      : delivery
                              .dropoffAddress ??
                          'Not provided',
                ),

                _DetailRow(
                  label:
                      'Recipient',

                  value: delivery
                              .recipient
                              ?.name
                              .isNotEmpty ==
                          true
                      ? delivery
                          .recipient!
                          .name
                      : 'Not available',
                ),

                _DetailRow(
                  label: 'Phone',

                  value: delivery
                              .recipient
                              ?.phoneNumber
                              .isNotEmpty ==
                          true
                      ? delivery
                          .recipient!
                          .phoneNumber
                      : 'Not available',
                ),

                _DetailRow(
                  label: 'Distance',

                  value: delivery
                              .distanceKm ==
                          null
                      ? 'Not available'
                      : '${delivery.distanceKm!.toStringAsFixed(2)} km',
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            // FOOD INFORMATION
            _SectionCard(
              title:
                  'Food & Timeline',

              icon: Icons
                  .inventory_2_outlined,

              children: [
                _DetailRow(
                  label:
                      'Food item',

                  value:
                      delivery.foodItem,
                ),

                _DetailRow(
                  label:
                      'Quantity',

                  value:
                      '${delivery.foodQuantityKg.toStringAsFixed(1)} kg',
                ),

                _DetailRow(
                  label: 'Expiry',

                  value: _formatDate(
                    delivery
                        .foodExpiryDate,
                  ),
                ),

                _DetailRow(
                  label:
                      'Accepted',

                  value: _formatDate(
                    delivery
                        .acceptedAt,
                  ),
                ),

                _DetailRow(
                  label:
                      'Picked up',

                  value: _formatDate(
                    delivery
                        .pickedUpAt,
                  ),
                ),

                _DetailRow(
                  label:
                      'Delivered',

                  value: _formatDate(
                    delivery
                        .deliveredAt,
                  ),
                ),
              ],
            ),

            if (delivery
                    .rejectionReason !=
                null) ...[
              const SizedBox(
                height: 16,
              ),

              _SectionCard(
                title:
                    'Rejection',

                icon: Icons
                    .cancel_outlined,

                children: [
                  _DetailRow(
                    label: 'Reason',

                    value: delivery
                        .rejectionReason!,
                  ),
                ],
              ),
            ],

            // ACTIONS AFTER ACCEPTING
            if (!canAccept) ...[
              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton
                            .icon(
                      onPressed:
                          _actionLoading
                              ? null
                              : _updateCurrentLocation,

                      icon:
                          const Icon(
                        Icons
                            .my_location,
                      ),

                      label:
                          const Text(
                        'Update Location',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                        OutlinedButton
                            .icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    VolunteerTrackingScreen(
                              deliveryId:
                                  widget.deliveryId,
                            ),
                          ),
                        );
                      },

                      icon:
                          const Icon(
                        Icons
                            .route_outlined,
                      ),

                      label:
                          const Text(
                        'Tracking',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          VolunteerReportProblemScreen(
                        deliveryId:
                            widget.deliveryId,
                      ),
                    ),
                  );
                },

                icon:
                    const Icon(
                  Icons
                      .report_problem_outlined,
                ),

                label:
                    const Text(
                  'Report a Problem',
                ),
              ),
            ],
          ],
        ),

        if (_actionLoading)
          const Positioned.fill(
            child: ColoredBox(
              color:
                  Color(0x33000000),
              child: Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),
          ),

        // BOTTOM ACTION BUTTONS
        if (canAccept ||
            nextStatus != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,

            child: SafeArea(
              child: canAccept
                  ? Row(
                      children: [
                        Expanded(
                          child:
                              OutlinedButton(
                            onPressed:
                                _actionLoading
                                    ? null
                                    : _reject,

                            style:
                                OutlinedButton
                                    .styleFrom(
                              minimumSize:
                                  const Size
                                      .fromHeight(
                                52,
                              ),
                              foregroundColor:
                                  Colors
                                      .redAccent,
                            ),

                            child:
                                const Text(
                              'Reject',
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child:
                              FilledButton(
                            onPressed:
                                _actionLoading
                                    ? null
                                    : _accept,

                            style:
                                FilledButton
                                    .styleFrom(
                              minimumSize:
                                  const Size
                                      .fromHeight(
                                52,
                              ),
                            ),

                            child:
                                const Text(
                              'Accept',
                            ),
                          ),
                        ),
                      ],
                    )
                  : FilledButton
                      .icon(
                      onPressed:
                          _actionLoading
                              ? null
                              : _advanceStatus,

                      style:
                          FilledButton
                              .styleFrom(
                        minimumSize:
                            const Size
                                .fromHeight(
                          54,
                        ),
                      ),

                      icon:
                          const Icon(
                        Icons
                            .arrow_forward,
                      ),

                      label: Text(
                        _statusButtonLabel(
                          nextStatus!,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _HeaderCard
    extends StatelessWidget {
  final VolunteerDelivery delivery;

  const _HeaderCard({
    required this.delivery,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration: BoxDecoration(
        color:
            AppTheme.lightGreen,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          Text(
            delivery.foodItem,

            style:
                const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppTheme.darkText,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            delivery.status
                .replaceAll(
              '_',
              ' ',
            ),

            style:
                const TextStyle(
              color: AppTheme
                  .primaryGreenDark,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard
    extends StatelessWidget {
  final String title;

  final IconData icon;

  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color:
              AppTheme.border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme
                    .primaryGreen,
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                title,

                style:
                    const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
            ],
          ),

          const Divider(
            height: 24,
          ),

          ...children,
        ],
      ),
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  final String label;

  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          SizedBox(
            width: 90,

            child: Text(
              label,

              style:
                  const TextStyle(
                color:
                    AppTheme.greyText,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}