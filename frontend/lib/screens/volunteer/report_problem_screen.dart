import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

class VolunteerReportProblemScreen
    extends StatefulWidget {
  final String deliveryId;

  const VolunteerReportProblemScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<VolunteerReportProblemScreen>
      createState() =>
          _VolunteerReportProblemScreenState();
}

class _VolunteerReportProblemScreenState
    extends State<
        VolunteerReportProblemScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _descriptionController =
      TextEditingController();

  String _problemType =
      'Unable to contact donor';

  bool _submitting = false;

  bool _loadingProblems =
      true;

  List<DeliveryProblem>
      _problems = [];

  static const _types = [
    'Unable to contact donor',
    'Unable to contact recipient',
    'Incorrect pickup address',
    'Incorrect drop-off address',
    'Food item issue',
    'Vehicle issue',
    'Safety concern',
    'Other',
  ];

  String get _token =>
      context
          .read<AuthProvider>()
          .token!;

  @override
  void initState() {
    super.initState();

    _loadProblems();
  }

  @override
  void dispose() {
    _descriptionController
        .dispose();

    super.dispose();
  }

  Future<void>
      _loadProblems() async {
    try {
      final problems =
          await VolunteerService
              .getProblems(
        token: _token,

        deliveryId:
            widget.deliveryId,
      );

      if (!mounted) return;

      setState(() {
        _problems =
            problems;
      });
    } catch (_) {
      // Still allow user to
      // report new problem.
    } finally {
      if (mounted) {
        setState(() {
          _loadingProblems =
              false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey
        .currentState!
        .validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await VolunteerService
          .reportProblem(
        token: _token,

        deliveryId:
            widget.deliveryId,

        problemType:
            _problemType,

        description:
            _descriptionController
                .text,
      );

      _descriptionController
          .clear();

      await _loadProblems();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Problem reported successfully.',
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
            e
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
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
          'Report a Problem',
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(
          16,
        ),

        children: [
          Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,

              children: [
                DropdownButtonFormField<
                    String>(
                  initialValue:
                      _problemType,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Problem type',
                  ),

                  items: _types
                      .map(
                        (type) =>
                            DropdownMenuItem(
                          value: type,
                          child:
                              Text(
                            type,
                          ),
                        ),
                      )
                      .toList(),

                  onChanged:
                      (value) {
                    if (value !=
                        null) {
                      setState(() {
                        _problemType =
                            value;
                      });
                    }
                  },
                ),

                const SizedBox(
                  height: 14,
                ),

                TextFormField(
                  controller:
                      _descriptionController,

                  maxLines: 5,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Description',

                    hintText:
                        'Explain what happened...',

                    alignLabelWithHint:
                        true,
                  ),

                  validator:
                      (value) {
                    if (value ==
                            null ||
                        value
                            .trim()
                            .isEmpty) {
                      return 'Please enter a problem description.';
                    }

                    return null;
                  },
                ),

                const SizedBox(
                  height: 16,
                ),

                FilledButton.icon(
                  onPressed:
                      _submitting
                          ? null
                          : _submit,

                  icon:
                      const Icon(
                    Icons
                        .send_outlined,
                  ),

                  label: Text(
                    _submitting
                        ? 'Submitting...'
                        : 'Submit Problem',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          const Text(
            'Previously Reported Problems',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          if (_loadingProblems)
            const Center(
              child:
                  CircularProgressIndicator(),
            )
          else if (_problems
              .isEmpty)
            const Text(
              'No problems reported for this delivery.',
              style: TextStyle(
                color:
                    AppTheme.greyText,
              ),
            )
          else
            ..._problems.map(
              (problem) =>
                  Card(
                margin:
                    const EdgeInsets
                        .only(
                  bottom: 10,
                ),

                child:
                    ListTile(
                  leading:
                      const Icon(
                    Icons
                        .report_problem_outlined,
                    color:
                        Colors.orange,
                  ),

                  title: Text(
                    problem
                        .problemType,
                  ),

                  subtitle: Text(
                    problem
                        .description,
                  ),

                  trailing: Text(
                    problem.status,

                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}