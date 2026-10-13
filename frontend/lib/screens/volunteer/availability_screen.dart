import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

class VolunteerAvailabilityScreen
    extends StatefulWidget {
  const VolunteerAvailabilityScreen({
    super.key,
  });

  @override
  State<VolunteerAvailabilityScreen>
      createState() =>
          _VolunteerAvailabilityScreenState();
}

class _VolunteerAvailabilityScreenState
    extends State<
        VolunteerAvailabilityScreen> {
  final _notesController =
      TextEditingController();

  bool _loading = true;

  bool _saving = false;

  bool _available = false;

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

  @override
  void dispose() {
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final VolunteerAvailability
          availability =
          await VolunteerService
              .getAvailability(
        _token,
      );

      if (!mounted) return;

      setState(() {
        _available =
            availability
                .isAvailable;

        _notesController.text =
            availability.notes ?? '';
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

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    try {
      final updated =
          await VolunteerService
              .updateAvailability(
        token: _token,

        status: _available
            ? 'AVAILABLE'
            : 'UNAVAILABLE',

        notes:
            _notesController.text,
      );

      if (!mounted) return;

      setState(() {
        _available =
            updated.isAvailable;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Availability updated successfully.',
          ),
        ),
      );
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
          _saving = false;
        });
      }
    }
  }

  String _cleanError(
    Object e,
  ) =>
      e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Volunteer Availability',
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _error != null
              ? _ErrorState(
                  message:
                      _error!,
                  onRetry:
                      _load,
                )
              : ListView(
                  padding:
                      const EdgeInsets
                          .all(20),

                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .all(20),

                      decoration:
                          BoxDecoration(
                        color: _available
                            ? AppTheme
                                .lightGreen
                            : Colors
                                .grey
                                .shade100,

                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),

                        border:
                            Border.all(
                          color:
                              AppTheme
                                  .border,
                        ),
                      ),

                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,

                            decoration:
                                BoxDecoration(
                              color: _available
                                  ? AppTheme
                                      .primaryGreen
                                  : Colors
                                      .grey
                                      .shade400,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),

                            child:
                                const Icon(
                              Icons
                                  .volunteer_activism_outlined,
                              color:
                                  Colors.white,
                            ),
                          ),

                          const SizedBox(
                            width: 16,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Text(
                                  _available
                                      ? 'Available'
                                      : 'Unavailable',

                                  style:
                                      const TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  _available
                                      ? 'You can receive delivery tasks.'
                                      : 'You will not receive delivery tasks.',

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

                          Switch(
                            value:
                                _available,

                            activeThumbColor:
                                AppTheme
                                    .primaryGreen,

                            onChanged:
                                _saving
                                    ? null
                                    : (value) {
                                        setState(
                                          () {
                                            _available =
                                                value;
                                          },
                                        );
                                      },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    TextField(
                      controller:
                          _notesController,

                      maxLines: 4,

                      decoration:
                          const InputDecoration(
                        hintText:
                            'Example: Available until 6 PM, Colombo area only',
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    SizedBox(
                      height: 52,

                      child:
                          FilledButton(
                        onPressed:
                            _saving
                                ? null
                                : _save,

                        child:
                            _saving
                                ? const SizedBox(
                                    width:
                                        22,
                                    height:
                                        22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Availability',
                                  ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final String message;

  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
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
              message,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 16,
            ),

            OutlinedButton(
              onPressed: onRetry,
              child:
                  const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }
}