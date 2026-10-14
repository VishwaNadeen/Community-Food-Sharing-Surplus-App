import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';

class VolunteerReportProblemScreen extends StatefulWidget {
  final String deliveryId;

  const VolunteerReportProblemScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<VolunteerReportProblemScreen> createState() =>
      _VolunteerReportProblemScreenState();
}

class _VolunteerReportProblemScreenState
    extends State<VolunteerReportProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _problemType = 'Unable to contact donor';
  bool _submitting = false;
  bool _loadingProblems = true;
  List<DeliveryProblem> _problems = [];

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

  String get _token => context.read<AuthProvider>().token!;

  @override
  void initState() {
    super.initState();
    _loadProblems();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProblems() async {
    try {
      final problems = await VolunteerService.getProblems(
        token: _token,
        deliveryId: widget.deliveryId,
      );

      if (!mounted) return;

      setState(() {
        _problems = problems;
      });
    } catch (_) {
      // Still allow user to report new problem.
    } finally {
      if (mounted) {
        setState(() {
          _loadingProblems = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await VolunteerService.reportProblem(
        token: _token,
        deliveryId: widget.deliveryId,
        problemType: _problemType,
        description: _descriptionController.text.trim(),
      );

      _descriptionController.clear();
      await _loadProblems();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Problem report submitted to dispatch coordinators.'),
          backgroundColor: AppTheme.primaryGreenDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Report an Issue',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Guidance banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEDD5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFEA580C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Our volunteer coordinator team monitors reported issues in real-time to assist with rerouting or resolving discrepancies.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF9A3412),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Report Form Card
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Issue Category',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _problemType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _types
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(fontSize: 14, color: AppTheme.darkText),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _problemType = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Problem Details',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: 'Describe what happened, location roadblocks, donor notes, etc.',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.greyText),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a brief description of the issue.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _submitting ? 'Transmitting to Dispatch...' : 'Submit Issue Report',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Previously reported problems
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Incident History',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              if (_problems.isNotEmpty)
                Text(
                  '${_problems.length} reported',
                  style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (_loadingProblems)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            )
          else if (_problems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: const [
                    Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF16A34A)),
                    SizedBox(height: 10),
                    Text(
                      'No Issues Logged',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Everything is proceeding normally on this delivery.',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.greyText),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._problems.map((problem) {
              final isResolved = problem.status.toUpperCase() == 'RESOLVED';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isResolved
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isResolved
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: isResolved
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              problem.problemType,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              problem.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isResolved
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isResolved
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Text(
                          problem.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isResolved
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}