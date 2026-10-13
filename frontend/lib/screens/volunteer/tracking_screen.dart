import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

class VolunteerTrackingScreen
    extends StatefulWidget {
  final String deliveryId;

  const VolunteerTrackingScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<VolunteerTrackingScreen>
      createState() =>
          _VolunteerTrackingScreenState();
}

class _VolunteerTrackingScreenState
    extends State<
        VolunteerTrackingScreen> {
  bool _loading = true;

  String? _error;

  List<DeliveryTrackingEntry>
      _entries = [];

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
      final entries =
          await VolunteerService
              .getTracking(
        token: _token,
        deliveryId:
            widget.deliveryId,
      );

      if (!mounted) return;

      setState(() {
        _entries = entries;
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

  String _date(
    DateTime? value,
  ) {
    if (value == null) {
      return '';
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
          'Delivery Tracking',
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
              : RefreshIndicator(
                  onRefresh:
                      _load,

                  child: _entries
                          .isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),

                          children:
                              const [
                            SizedBox(
                              height:
                                  180,
                            ),

                            Icon(
                              Icons
                                  .timeline_outlined,
                              size:
                                  60,
                              color:
                                  AppTheme
                                      .greyText,
                            ),

                            SizedBox(
                              height:
                                  12,
                            ),

                            Text(
                              'No tracking history yet.',
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  TextStyle(
                                color:
                                    AppTheme
                                        .greyText,
                              ),
                            ),
                          ],
                        )
                      : ListView
                          .builder(
                          padding:
                              const EdgeInsets
                                  .all(
                            16,
                          ),

                          itemCount:
                              _entries
                                  .length,

                          itemBuilder:
                              (
                            context,
                            index,
                          ) {
                            final entry =
                                _entries[
                                    index];

                            return Card(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom:
                                    10,
                              ),

                              child:
                                  ListTile(
                                leading:
                                    CircleAvatar(
                                  backgroundColor:
                                      AppTheme
                                          .lightGreen,

                                  child:
                                      const Icon(
                                    Icons
                                        .location_history,
                                    color:
                                        AppTheme
                                            .primaryGreenDark,
                                  ),
                                ),

                                title:
                                    Text(
                                  entry
                                      .status
                                      .replaceAll(
                                    '_',
                                    ' ',
                                  ),

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
                                    if (entry
                                            .message !=
                                        null)
                                      Text(
                                        entry
                                            .message!,
                                      ),

                                    if (entry.latitude !=
                                            null &&
                                        entry.longitude !=
                                            null)
                                      Text(
                                        '${entry.latitude}, ${entry.longitude}',
                                      ),

                                    Text(
                                      _date(
                                        entry
                                            .createdAt,
                                      ),

                                      style:
                                          const TextStyle(
                                        color:
                                            AppTheme
                                                .greyText,
                                        fontSize:
                                            12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}