import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

import 'delivery_details_screen.dart';

class VolunteerOptimizedRouteScreen
    extends StatefulWidget {
  const VolunteerOptimizedRouteScreen({
    super.key,
  });

  @override
  State<VolunteerOptimizedRouteScreen>
      createState() =>
          _VolunteerOptimizedRouteScreenState();
}

class _VolunteerOptimizedRouteScreenState
    extends State<
        VolunteerOptimizedRouteScreen> {
  bool _loading = true;

  String? _error;

  OptimizedVolunteerRoute?
      _route;

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
      final result =
          await VolunteerService
              .getOptimizedRoute(
        _token,
      );

      if (!mounted) return;

      setState(() {
        _route = result;
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Optimized Delivery Route',
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets
                            .all(
                      24,
                    ),

                    child:
                        Column(
                      mainAxisSize:
                          MainAxisSize
                              .min,

                      children: [
                        Text(
                          _error!,
                          textAlign:
                              TextAlign
                                  .center,
                        ),

                        const SizedBox(
                          height:
                              12,
                        ),

                        OutlinedButton(
                          onPressed:
                              _load,

                          child:
                              const Text(
                            'Retry',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildRoute(),
    );
  }

  Widget _buildRoute() {
    final route =
        _route!;

    if (route.deliveries
        .isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,

        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          children: const [
            SizedBox(
              height: 180,
            ),

            Icon(
              Icons.route_outlined,
              size: 64,
              color:
                  AppTheme.greyText,
            ),

            SizedBox(
              height: 16,
            ),

            Text(
              'No active deliveries to optimize.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
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

      child: ListView(
        padding:
            const EdgeInsets.all(
          16,
        ),

        children: [
          Container(
            padding:
                const EdgeInsets.all(
              18,
            ),

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

            child: Row(
              children: [
                const Icon(
                  Icons.route,

                  color:
                      AppTheme
                          .primaryGreenDark,

                  size: 32,
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
                      Text(
                        '${route.deliveries.length} active deliveries',

                        style:
                            const TextStyle(
                          fontSize:
                              17,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'Estimated route: ${route.totalDistanceKm.toStringAsFixed(2)} km',

                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Recommended Order',

            style: TextStyle(
              fontSize: 18,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          ...route.deliveries
              .asMap()
              .entries
              .map(
            (entry) {
              final index =
                  entry.key;

              final delivery =
                  entry.value;

              return Card(
                margin:
                    const EdgeInsets
                        .only(
                  bottom: 10,
                ),

                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder:
                            (_) =>
                                VolunteerDeliveryDetailScreen(
                          deliveryId:
                              delivery.id,
                        ),
                      ),
                    );
                  },

                  leading:
                      CircleAvatar(
                    backgroundColor:
                        AppTheme
                            .primaryGreen,

                    foregroundColor:
                        Colors.white,

                    child: Text(
                      '${index + 1}',
                    ),
                  ),

                  title: Text(
                    delivery.foodItem,

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),

                  subtitle:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        'Pickup: ${delivery.pickupAddress ?? 'Not provided'}',
                      ),

                      Text(
                        'Drop-off: ${delivery.dropoffAddress ?? 'Not provided'}',
                      ),

                      Text(
                        'Status: ${delivery.status.replaceAll('_', ' ')}',
                      ),
                    ],
                  ),

                  trailing:
                      const Icon(
                    Icons
                        .chevron_right,
                  ),
                ),
              );
            },
          ),

          if (route.googleMapsUrl !=
              null) ...[
            const SizedBox(
              height: 8,
            ),

            Container(
              padding:
                  const EdgeInsets
                      .all(
                14,
              ),

              decoration:
                  BoxDecoration(
                color: Colors
                    .blue
                    .shade50,

                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),

              child:
                  const Text(
                'The backend generated an optimized Google Maps route. '
                'The recommended pickup and drop-off order is shown above.',
                style:
                    TextStyle(
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}