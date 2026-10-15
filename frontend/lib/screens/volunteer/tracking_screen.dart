import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/volunteer/status_chip.dart';

class VolunteerTrackingScreen extends StatefulWidget {
  final String deliveryId;

  const VolunteerTrackingScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<VolunteerTrackingScreen> createState() =>
      _VolunteerTrackingScreenState();
}

class _VolunteerTrackingScreenState extends State<VolunteerTrackingScreen> {
  bool _loading = true;
  String? _error;
  List<DeliveryTrackingEntry> _entries = [];

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
      final entries = await VolunteerService.getTracking(
        token: _token,
        deliveryId: widget.deliveryId,
      );

      if (!mounted) return;

      setState(() {
        _entries = entries;
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

  String _date(DateTime? value) {
    if (value == null) return '';
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
          'Tracking Timeline',
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
            tooltip: 'Refresh',
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
              : _buildTimeline(),
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
                'Unable to Load Tracking',
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

  Widget _buildTimeline() {
    if (_entries.isEmpty) {
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
                  Icons.timeline_rounded,
                  size: 36,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Tracking History Recorded Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'As you pick up food, advance stages, and transmit GPS updates, historical audit entries will be recorded chronologically here.',
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
                label: const Text('Refresh Feed'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final isFirst = index == 0;
          final isLast = index == _entries.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline line and indicator dot
                Column(
                  children: [
                    Container(
                      width: 2,
                      height: 10,
                      color: isFirst ? Colors.transparent : AppTheme.primaryGreenDark,
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryGreenDark,
                          width: 4,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast ? Colors.transparent : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Content card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusChip(status: entry.status),
                            Text(
                              _date(entry.createdAt),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.greyText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (entry.message != null && entry.message!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            entry.message!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppTheme.darkText,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (entry.latitude != null && entry.longitude != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Color(0xFF475569),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'GPS: ${entry.latitude!.toStringAsFixed(4)}, ${entry.longitude!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}