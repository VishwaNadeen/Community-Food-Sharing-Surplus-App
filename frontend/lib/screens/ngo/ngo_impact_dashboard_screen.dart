import 'package:flutter/material.dart';
import '../../models/ngo_impact_analytics_model.dart';
import '../../services/ngo_impact_service.dart';
import '../../services/ngo_report_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ngo_ui.dart';

const _blue = Color(0xFF3F6EDC);
const _teal = Color(0xFF008C82);
const _amber = Color(0xFFDB7A00);
const _purple = Color(0xFF9B6DCE);
const _red = Color(0xFFD85B5B);

String _fmt(num value) {
  final text = value % 1 == 0
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  final parts = text.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}

String _unitLabel(String unit) => switch (unit) {
  'KG' => 'Kilograms (kg)',
  'G' => 'Grams (g)',
  'LITRE' => 'Litres (L)',
  'ML' => 'Millilitres (ml)',
  _ => titleCase(unit),
};

String _percent(int part, int total) =>
    total == 0 ? '0%' : '${(part * 100 / total).round()}%';

class ImpactDashboardScreen extends StatefulWidget {
  final String token;
  const ImpactDashboardScreen({super.key, required this.token});

  @override
  State<ImpactDashboardScreen> createState() => _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState extends State<ImpactDashboardScreen> {
  late Future<ImpactAnalyticsModel> _impactFuture;
  late Future<VolunteerActivityModel> _volunteerFuture;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _impactFuture = ImpactService.getImpact(token: widget.token);
    _volunteerFuture = ImpactService.getVolunteerActivity(token: widget.token);
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await Future.wait([_impactFuture, _volunteerFuture]);
    } catch (_) {
      // Errors are shown by the FutureBuilders.
    }
  }

  Future<void> _export(ReportFormat format) async {
    if (_exporting) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    ReportFile? report;
    try {
      report = await ReportService.downloadImpactReport(
        token: widget.token,
        format: format,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
    if (report == null || !mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReportReadySheet(report: report!),
    );
    if (action == null) return;

    try {
      if (action == 'save') {
        final saved = await ReportService.saveToDevice(report);
        if (saved) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Report saved to your phone.'),
              backgroundColor: AppTheme.primaryGreenDark,
            ),
          );
        }
      } else {
        await ReportService.share(report);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.fieldFill,
    body: Column(
      children: [
        NgoHeader(
          title: 'Platform Impact',
          subtitle: 'Community results and reports',
          actions: [
            if (_exporting)
              const Padding(
                padding: EdgeInsets.only(left: 14, right: 12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Material(
                  color: AppTheme.fieldFill,
                  shape: const CircleBorder(),
                  child: PopupMenuButton<ReportFormat>(
                    icon: const Icon(
                      Icons.file_download_outlined,
                      color: AppTheme.darkText,
                    ),
                    tooltip: 'Export report',
                    onSelected: _export,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: ReportFormat.pdf,
                        child: ListTile(
                          leading: Icon(Icons.picture_as_pdf_outlined),
                          title: Text('Export as PDF'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: ReportFormat.csv,
                        child: ListTile(
                          leading: Icon(Icons.table_chart_outlined),
                          title: Text('Export as CSV'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: FutureBuilder<ImpactAnalyticsModel>(
            future: _impactFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                );
              }
              if (snapshot.hasError) {
                return ErrorState(
                  error: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }
              return _ImpactContent(
                impact: snapshot.data!,
                volunteerFuture: _volunteerFuture,
                onRefresh: _refresh,
                onExport: _export,
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _ReportReadySheet extends StatelessWidget {
  final ReportFile report;
  const _ReportReadySheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final isPdf = report.format == ReportFormat.pdf;
    final sizeKb = (report.bytes.length / 1024).toStringAsFixed(1);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your report is ready',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.fieldFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.table_chart_outlined,
                      color: AppTheme.primaryGreenDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${isPdf ? 'PDF' : 'CSV'} • $sizeKb KB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'share'),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreenDark,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, 'save'),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Save to phone'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactContent extends StatelessWidget {
  final ImpactAnalyticsModel impact;
  final Future<VolunteerActivityModel> volunteerFuture;
  final RefreshCallback onRefresh;
  final ValueChanged<ReportFormat> onExport;

  const _ImpactContent({
    required this.impact,
    required this.volunteerFuture,
    required this.onRefresh,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: TabBar(
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              labelColor: AppTheme.primaryGreenDark,
              unselectedLabelColor: AppTheme.greyText,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Donations'),
                Tab(text: 'Volunteers'),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        Expanded(
          child: TabBarView(
            children: [
              _OverviewTab(
                impact: impact,
                onRefresh: onRefresh,
                onExport: onExport,
              ),
              _DonationsTab(impact: impact, onRefresh: onRefresh),
              _VolunteerTab(future: volunteerFuture, onRefresh: onRefresh),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------- Overview

class _OverviewTab extends StatelessWidget {
  final ImpactAnalyticsModel impact;
  final RefreshCallback onRefresh;
  final ValueChanged<ReportFormat> onExport;

  const _OverviewTab({
    required this.impact,
    required this.onRefresh,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final s = impact.summary;
    final foodKg = s.foodWastePreventedByUnit['KG'] ?? 0;

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _HeroCard(
            meals: s.mealsDelivered ?? 0,
            foodKg: foodKg,
            deliveries: s.completedDeliveries,
            volunteers: s.activeVolunteers ?? 0,
          ),
          const _SectionHeader('Key figures'),
          _StatGrid(
            children: [
              _StatCard(
                icon: Icons.volunteer_activism_outlined,
                value: _fmt(s.totalDonations),
                label: 'Donations received',
                color: AppTheme.primaryGreenDark,
              ),
              _StatCard(
                icon: Icons.request_page_outlined,
                value: _fmt(s.totalRequests),
                label: 'Food requests',
                color: _blue,
              ),
              _StatCard(
                icon: Icons.hub_outlined,
                value: _fmt(s.suitableMatches),
                label: 'Matches identified',
                color: _purple,
              ),
              _StatCard(
                icon: Icons.groups_outlined,
                value: _fmt(s.activeVolunteers ?? 0),
                label: 'Active volunteers',
                color: _teal,
              ),
            ],
          ),
          const _SectionHeader('How the platform is performing'),
          _Panel(
            child: Column(
              children: [
                _ProgressRow(
                  label: 'Donations approved',
                  detail: '${s.approvedDonations} of ${s.totalDonations}',
                  fraction: s.totalDonations == 0
                      ? 0
                      : s.approvedDonations / s.totalDonations,
                  color: AppTheme.primaryGreen,
                ),
                _ProgressRow(
                  label: 'Requests approved',
                  detail: '${s.approvedRequests} of ${s.totalRequests}',
                  fraction: s.totalRequests == 0
                      ? 0
                      : s.approvedRequests / s.totalRequests,
                  color: _blue,
                ),
                _ProgressRow(
                  label: 'Matches accepted',
                  detail: '${s.acceptedMatches} of ${s.suitableMatches}',
                  fraction: s.suitableMatches == 0
                      ? 0
                      : s.acceptedMatches / s.suitableMatches,
                  color: _purple,
                  isLast: true,
                ),
              ],
            ),
          ),
          const _SectionHeader('Monthly activity', trailing: 'Last 6 months'),
          _TrendChart(data: impact.monthlyImpact),
          const _SectionHeader('Donations by category'),
          _CategoryList(categories: impact.donationsByCategory),
          const SizedBox(height: 18),
          _ExportCard(onExport: onExport),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int meals;
  final double foodKg;
  final int deliveries;
  final int volunteers;

  const _HeroCard({
    required this.meals,
    required this.foodKg,
    required this.deliveries,
    required this.volunteers,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF168A55), Color(0xFF2FAE60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x332FAE60),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.restaurant_outlined, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text(
              'MEALS DELIVERED (ESTIMATED)',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _fmt(meals),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            height: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'About 2 meals for every kg of food delivered',
          style: TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x40FFFFFF))),
          ),
          child: Row(
            children: [
              _HeroMetric(value: '${_fmt(foodKg)} kg', label: 'Food saved'),
              _HeroMetric(value: _fmt(deliveries), label: 'Deliveries'),
              _HeroMetric(value: _fmt(volunteers), label: 'Volunteers'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;
  const _HeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ExportCard extends StatelessWidget {
  final ValueChanged<ReportFormat> onExport;
  const _ExportCard({required this.onExport});

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.description_outlined, color: AppTheme.primaryGreenDark),
            SizedBox(width: 8),
            Text(
              'Community impact report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          "Download these figures to share the platform's results.",
          style: TextStyle(fontSize: 13, color: AppTheme.greyText),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => onExport(ReportFormat.pdf),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onExport(ReportFormat.csv),
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('CSV'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreenDark,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// --------------------------------------------------------------- Donations

class _DonationsTab extends StatelessWidget {
  final ImpactAnalyticsModel impact;
  final RefreshCallback onRefresh;
  const _DonationsTab({required this.impact, required this.onRefresh});

  static Color _statusColor(String status) => switch (status) {
    'APPROVED' => AppTheme.primaryGreen,
    'AVAILABLE' => _teal,
    'COLLECTED' => _blue,
    'REJECTED' => _red,
    'CANCELLED' => AppTheme.greyText,
    'EXPIRED' => const Color(0xFF6B7078),
    _ => _amber,
  };

  static String _statusLabel(String value) => switch (value) {
    'PENDING' => 'Pending review',
    _ => titleCase(value),
  };

  @override
  Widget build(BuildContext context) {
    final stats = impact.donationStatistics;
    final statuses = stats.byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _StatGrid(
            children: [
              _StatCard(
                icon: Icons.volunteer_activism_outlined,
                value: _fmt(stats.total),
                label: 'Total donations',
                color: AppTheme.primaryGreenDark,
              ),
              _StatCard(
                icon: Icons.verified_outlined,
                value: _fmt(stats.approved),
                label: 'Approved donations',
                color: _blue,
              ),
              _StatCard(
                icon: Icons.local_shipping_outlined,
                value: _fmt(stats.completedDeliveryRecords),
                label: 'Completed deliveries',
                color: _teal,
              ),
              _StatCard(
                icon: Icons.hourglass_top_outlined,
                value: _fmt(stats.byStatus['PENDING'] ?? 0),
                label: 'Awaiting review',
                color: _amber,
              ),
            ],
          ),
          const _SectionHeader('Donation status'),
          if (statuses.isEmpty)
            const _EmptyPanel('No donation data yet')
          else
            _Panel(
              child: Column(
                children: [
                  _StackedBar(
                    segments: statuses
                        .map((e) => _Segment(e.value, _statusColor(e.key)))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < statuses.length; i++)
                    _LegendRow(
                      color: _statusColor(statuses[i].key),
                      label: _statusLabel(statuses[i].key),
                      value: '${statuses[i].value}',
                      share: _percent(statuses[i].value, stats.total),
                    ),
                ],
              ),
            ),
          const _SectionHeader('Donated quantity'),
          _QuantityCard(values: stats.quantityByUnit),
        ],
      ),
    );
  }
}

class _QuantityCard extends StatelessWidget {
  final Map<String, double> values;
  const _QuantityCard({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const _EmptyPanel('No quantity data yet');
    final entries = values.entries.toList();
    return _Panel(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == entries.length - 1 ? 0 : 12,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.scale_outlined,
                      size: 18,
                      color: AppTheme.primaryGreenDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _unitLabel(entries[i].key),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ),
                  Text(
                    _fmt(entries[i].value),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkText,
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

// -------------------------------------------------------------- Volunteers

class _VolunteerTab extends StatelessWidget {
  final Future<VolunteerActivityModel> future;
  final RefreshCallback onRefresh;
  const _VolunteerTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) => FutureBuilder<VolunteerActivityModel>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        );
      }
      if (snapshot.hasError) {
        return ErrorState(error: snapshot.error.toString(), onRetry: onRefresh);
      }
      return _VolunteerContent(activity: snapshot.data!, onRefresh: onRefresh);
    },
  );
}

class _VolunteerContent extends StatelessWidget {
  final VolunteerActivityModel activity;
  final RefreshCallback onRefresh;
  const _VolunteerContent({required this.activity, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final awaiting = activity.deliveryStatusCounts['PENDING_ASSIGNMENT'] ?? 0;
    final segments = [
      ('Completed', activity.completedDeliveries, AppTheme.primaryGreen),
      ('In progress', activity.activeDeliveries, _blue),
      ('Awaiting volunteer', awaiting, _amber),
    ];
    final totalTracked = segments.fold<int>(0, (sum, s) => sum + s.$2);

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _StatGrid(
            children: [
              _StatCard(
                icon: Icons.groups_outlined,
                value: _fmt(activity.totalVolunteers),
                label: 'Volunteers',
                color: _teal,
              ),
              _StatCard(
                icon: Icons.event_available_outlined,
                value: _fmt(activity.availableVolunteers),
                label: 'Available now',
                color: AppTheme.primaryGreenDark,
              ),
              _StatCard(
                icon: Icons.local_shipping_outlined,
                value: _fmt(activity.completedDeliveries),
                label: 'Completed deliveries',
                color: _blue,
              ),
              _StatCard(
                icon: Icons.route_outlined,
                value: _fmt(activity.activeDeliveries),
                label: 'In progress',
                color: _purple,
              ),
            ],
          ),
          const _SectionHeader('Delivery progress'),
          if (totalTracked == 0)
            const _EmptyPanel('No deliveries yet')
          else
            _Panel(
              child: Column(
                children: [
                  _StackedBar(
                    segments: segments
                        .map((s) => _Segment(s.$2, s.$3))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < segments.length; i++)
                    _LegendRow(
                      color: segments[i].$3,
                      label: segments[i].$1,
                      value: '${segments[i].$2}',
                      share: _percent(segments[i].$2, totalTracked),
                    ),
                ],
              ),
            ),
          _SectionHeader(
            'Volunteer contributions',
            trailing: '${activity.totalAssignedDeliveries} assigned',
          ),
          if (activity.volunteers.isEmpty)
            const _EmptyPanel('No volunteer delivery activity yet')
          else
            for (var i = 0; i < activity.volunteers.length; i++)
              _VolunteerCard(rank: i + 1, volunteer: activity.volunteers[i]),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final int rank;
  final VolunteerActivity volunteer;
  const _VolunteerCard({required this.rank, required this.volunteer});

  @override
  Widget build(BuildContext context) {
    final id = volunteer.volunteerId;
    final shortId = id.length > 12 ? '…${id.substring(id.length - 8)}' : id;
    final last = volunteer.lastDeliveredAt;
    final fraction = volunteer.totalDeliveries == 0
        ? 0.0
        : volunteer.completedDeliveries / volunteer.totalDeliveries;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Panel(
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: rank == 1
                  ? const Color(0xFFFFF1CC)
                  : AppTheme.lightGreen,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: rank == 1 ? _amber : AppTheme.primaryGreenDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volunteer $shortId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    last == null
                        ? 'No completed delivery yet'
                        : 'Last delivery ${formatDate(last.toIso8601String())}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      color: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.lightGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${volunteer.completedDeliveries}/${volunteer.totalDeliveries}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreenDark,
                  ),
                ),
                const Text(
                  'delivered',
                  style: TextStyle(fontSize: 11, color: AppTheme.greyText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- Charts

class _TrendChart extends StatelessWidget {
  final List<MonthlyImpact> data;
  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(
      0,
      (max, item) =>
          [max, item.donations, item.requests].reduce((a, b) => a > b ? a : b),
    );
    if (maxValue == 0) {
      return const _EmptyPanel('No activity in the last 6 months');
    }
    return _Panel(
      child: Column(
        children: [
          const Row(
            children: [
              _Legend(color: AppTheme.primaryGreen, label: 'Donations'),
              SizedBox(width: 16),
              _Legend(color: _blue, label: 'Requests'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (_) => const Divider(height: 1, color: AppTheme.border),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: data
                      .map(
                        (item) => Expanded(
                          child: _BarGroup(item: item, maxValue: maxValue),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarGroup extends StatelessWidget {
  final MonthlyImpact item;
  final int maxValue;
  const _BarGroup({required this.item, required this.maxValue});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(
              value: item.donations,
              maxValue: maxValue,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(width: 3),
            _Bar(value: item.requests, maxValue: maxValue, color: _blue),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        item.month,
        style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
      ),
    ],
  );
}

class _Bar extends StatelessWidget {
  final int value;
  final int maxValue;
  final Color color;
  const _Bar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 14,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value > 0)
          Text(
            '$value',
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        if (value > 0)
          Flexible(
            child: FractionallySizedBox(
              heightFactor: (value / maxValue).clamp(0.04, 1.0) * 0.82,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
      ),
    ],
  );
}

class _CategoryList extends StatelessWidget {
  final List<CategoryImpact> categories;
  const _CategoryList({required this.categories});

  static const _palette = [
    AppTheme.primaryGreen,
    _blue,
    _amber,
    _purple,
    _teal,
  ];

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const _EmptyPanel('No donation data yet');
    final top = categories.take(5).toList();
    final total = categories.fold<int>(0, (sum, c) => sum + c.count);
    return _Panel(
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++)
            _ProgressRow(
              label: top[i].category,
              detail: '${top[i].count} • ${_percent(top[i].count, total)}',
              fraction: total == 0 ? 0 : top[i].count / total,
              color: _palette[i % _palette.length],
              isLast: i == top.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Segment {
  final int value;
  final Color color;
  const _Segment(this.value, this.color);
}

class _StackedBar extends StatelessWidget {
  final List<_Segment> segments;
  const _StackedBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.value > 0).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            for (final s in visible)
              Expanded(
                flex: s.value,
                child: Container(
                  margin: const EdgeInsets.only(right: 1.5),
                  color: s.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- Shared pieces

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: child,
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkText,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.greyText),
          ),
      ],
    ),
  );
}

typedef _StatGrid = MetricGrid;
typedef _StatCard = MetricCard;

class _ProgressRow extends StatelessWidget {
  final String label;
  final String detail;
  final double fraction;
  final Color color;
  final bool isLast;
  const _ProgressRow({
    required this.label,
    required this.detail,
    required this.fraction,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              detail,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.greyText),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: .12),
          ),
        ),
      ],
    ),
  );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String share;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.share,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: AppTheme.darkText),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            share,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.greyText),
          ),
        ),
      ],
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  final String text;
  const _EmptyPanel(this.text);

  @override
  Widget build(BuildContext context) => _Panel(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.greyText, fontSize: 13.5),
        ),
      ),
    ),
  );
}
