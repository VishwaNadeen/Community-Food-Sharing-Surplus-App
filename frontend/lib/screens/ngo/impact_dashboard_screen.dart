import 'package:flutter/material.dart';
import '../../models/impact_analytics_model.dart';
import '../../services/impact_service.dart';
import '../../theme/app_theme.dart';

class ImpactDashboardScreen extends StatefulWidget {
  final String token;
  const ImpactDashboardScreen({super.key, required this.token});

  @override
  State<ImpactDashboardScreen> createState() => _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState extends State<ImpactDashboardScreen> {
  late Future<ImpactAnalyticsModel> _impactFuture;
  late Future<VolunteerActivityModel> _volunteerFuture;

  @override
  void initState() {
    super.initState();
    _impactFuture = ImpactService.getImpact(token: widget.token);
    _volunteerFuture = ImpactService.getVolunteerActivity(token: widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _impactFuture = ImpactService.getImpact(token: widget.token);
      _volunteerFuture = ImpactService.getVolunteerActivity(token: widget.token);
    });
    await Future.wait([_impactFuture, _volunteerFuture]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.fieldFill,
    appBar: AppBar(
      title: const Text(
        'Platform Impact',
        style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppTheme.darkText),
    ),
    body: FutureBuilder<ImpactAnalyticsModel>(
      future: _impactFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }
        if (snapshot.hasError) {
          return _ErrorView(
            error: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }
        return _ImpactContent(
          impact: snapshot.data!,
          volunteerFuture: _volunteerFuture,
          onRefresh: _refresh,
        );
      },
    ),
  );
}

class _ImpactContent extends StatelessWidget {
  final ImpactAnalyticsModel impact;
  final Future<VolunteerActivityModel> volunteerFuture;
  final RefreshCallback onRefresh;
  const _ImpactContent({
    required this.impact,
    required this.volunteerFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        Container(
          color: Colors.white,
          child: const TabBar(
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: AppTheme.greyText,
            indicatorColor: AppTheme.primaryGreen,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Donations'),
              Tab(text: 'Volunteers'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _OverviewTab(impact: impact, onRefresh: onRefresh),
              _DonationsTab(impact: impact, onRefresh: onRefresh),
              _VolunteerTab(future: volunteerFuture, onRefresh: onRefresh),
            ],
          ),
        ),
      ],
    ),
  );
}

class _OverviewTab extends StatelessWidget {
  final ImpactAnalyticsModel impact;
  final RefreshCallback onRefresh;
  const _OverviewTab({required this.impact, required this.onRefresh});

  List<String> _quantityParts(Map<String, double> values) => values.entries
      .map(
        (entry) =>
            '${entry.value % 1 == 0 ? entry.value.toInt() : entry.value} ${entry.key}',
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final summary = impact.summary;
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Community impact overview',
            style: TextStyle(color: AppTheme.greyText, fontSize: 13),
          ),
          const SizedBox(height: 5),
          const Text(
            'Platform impact overview',
            style: TextStyle(
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 16),
          _ImpactHero(
            donations: summary.totalDonations,
            requests: summary.approvedRequests,
            matches: summary.suitableMatches,
          ),
          const SizedBox(height: 18),
          const Text(
            'Impact at a glance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ImpactCard(
                icon: Icons.volunteer_activism_outlined,
                value: '${summary.totalDonations}',
                label: 'Donations received',
                color: AppTheme.primaryGreen,
              ),
              _ImpactCard(
                icon: Icons.request_page_outlined,
                value: '${summary.approvedRequests}',
                label: 'Requests approved',
                color: const Color(0xFF3F6EDC),
              ),
              _ImpactCard(
                icon: Icons.hub_outlined,
                value: '${summary.suitableMatches}',
                label: 'Matches identified',
                color: const Color(0xFF9B6DCE),
              ),
              _ImpactCard(
                icon: Icons.check_circle_outline,
                value: '${summary.mealsDelivered ?? 0}',
                label: 'Estimated meals delivered',
                color: const Color(0xFF008C82),
              ),
              _ImpactCard(
                icon: Icons.local_shipping_outlined,
                value: '${summary.completedDeliveries}',
                label: 'Completed deliveries',
                color: const Color(0xFFDB7A00),
              ),
              _ImpactCard(
                icon: Icons.groups_outlined,
                value: '${summary.activeVolunteers ?? 0}',
                label: 'Active volunteers',
                color: const Color(0xFF0D7EBC),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FoodSavedCard(
            quantityParts: _quantityParts(summary.foodWastePreventedByUnit),
          ),
          const SizedBox(height: 24),
          const Text(
            'Monthly activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 10),
          _TrendChart(data: impact.monthlyImpact),
          const SizedBox(height: 24),
          const Text(
            'Donations by category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 10),
          _CategoryList(categories: impact.donationsByCategory),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DonationsTab extends StatelessWidget {
  final ImpactAnalyticsModel impact;
  final RefreshCallback onRefresh;
  const _DonationsTab({required this.impact, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final stats = impact.donationStatistics;
    final statuses = stats.byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxStatusCount = statuses.fold<int>(
      1,
      (max, entry) => entry.value > max ? entry.value : max,
    );

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Donation activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A clear view of contributions and their progress.',
            style: TextStyle(color: AppTheme.greyText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ImpactCard(
                icon: Icons.volunteer_activism_outlined,
                value: '${stats.total}',
                label: 'Total donations',
                color: AppTheme.primaryGreen,
              ),
              _ImpactCard(
                icon: Icons.verified_outlined,
                value: '${stats.approved}',
                label: 'Approved donations',
                color: const Color(0xFF3F6EDC),
              ),
              _ImpactCard(
                icon: Icons.local_shipping_outlined,
                value: '${stats.completedDeliveryRecords}',
                label: 'Completed deliveries',
                color: const Color(0xFF008C82),
              ),
              _ImpactCard(
                icon: Icons.inventory_2_outlined,
                value: '${stats.byStatus['PENDING'] ?? 0}',
                label: 'Awaiting review',
                color: const Color(0xFFDB7A00),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Donation status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 10),
          if (statuses.isEmpty)
            const _EmptyLabel('No donation data yet')
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: statuses.map((entry) {
                  final fraction = entry.value / maxStatusCount;
                  final color = switch (entry.key) {
                    'APPROVED' || 'AVAILABLE' || 'COLLECTED' =>
                      AppTheme.primaryGreen,
                    'REJECTED' || 'CANCELLED' || 'EXPIRED' =>
                      const Color(0xFFD85B5B),
                    _ => const Color(0xFFDB7A00),
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 94,
                          child: Text(
                            _statusLabel(entry.key),
                            style: const TextStyle(
                              color: AppTheme.darkText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 8,
                              color: color,
                              backgroundColor: AppTheme.lightGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${entry.value}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 22),
          const Text(
            'Donated quantity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 10),
          _DonationQuantityCard(values: stats.quantityByUnit),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3E2BE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFF9A6500)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Completed deliveries are shown separately. The current data model does not link each delivery to a specific donation.',
                    style: TextStyle(fontSize: 12, color: AppTheme.darkText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _statusLabel(String value) => switch (value) {
    'PENDING' => 'Pending review',
    'APPROVED' => 'Approved',
    'AVAILABLE' => 'Available',
    'COLLECTED' => 'Collected',
    'REJECTED' => 'Rejected',
    'CANCELLED' => 'Cancelled',
    'EXPIRED' => 'Expired',
    _ => value,
  };
}

class _DonationQuantityCard extends StatelessWidget {
  final Map<String, double> values;
  const _DonationQuantityCard({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const _EmptyLabel('No quantity data yet');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: values.entries.map((entry) {
          final amount = entry.value % 1 == 0
              ? entry.value.toInt().toString()
              : entry.value.toStringAsFixed(1);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(
              Icons.scale_outlined,
              color: AppTheme.primaryGreen,
            ),
            title: Text(
              entry.key,
              style: const TextStyle(fontSize: 13, color: AppTheme.darkText),
            ),
            trailing: Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

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
        return _ErrorView(
          error: snapshot.error.toString(),
          onRetry: onRefresh,
        );
      }
      return _VolunteerActivityContent(
        activity: snapshot.data!,
        onRefresh: onRefresh,
      );
    },
  );
}

class _VolunteerActivityContent extends StatelessWidget {
  final VolunteerActivityModel activity;
  final RefreshCallback onRefresh;
  const _VolunteerActivityContent({
    required this.activity,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final statusRows = [
      ('Active', activity.activeDeliveries, const Color(0xFF3F6EDC)),
      (
        'Completed',
        activity.completedDeliveries,
        AppTheme.primaryGreen,
      ),
      (
        'Awaiting volunteer',
        activity.deliveryStatusCounts['PENDING_ASSIGNMENT'] ?? 0,
        const Color(0xFFDB7A00),
      ),
    ];
    final maxCount = statusRows.fold<int>(
      1,
      (max, item) => item.$2 > max ? item.$2 : max,
    );

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Volunteer activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Delivery participation across the community.',
            style: TextStyle(color: AppTheme.greyText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ImpactCard(
                icon: Icons.groups_outlined,
                value: '${activity.totalVolunteers}',
                label: 'Volunteers participating',
                color: const Color(0xFF0D7EBC),
              ),
              _ImpactCard(
                icon: Icons.event_available_outlined,
                value: '${activity.availableVolunteers}',
                label: 'Currently available',
                color: AppTheme.primaryGreen,
              ),
              _ImpactCard(
                icon: Icons.local_shipping_outlined,
                value: '${activity.completedDeliveries}',
                label: 'Completed deliveries',
                color: const Color(0xFF008C82),
              ),
              _ImpactCard(
                icon: Icons.route_outlined,
                value: '${activity.activeDeliveries}',
                label: 'Deliveries in progress',
                color: const Color(0xFF9B6DCE),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Delivery progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: statusRows.map((row) {
                final fraction = row.$2 / maxCount;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 112,
                        child: Text(
                          row.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            color: row.$3,
                            backgroundColor: AppTheme.lightGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${row.$2}',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Volunteer contributions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Text(
                '${activity.totalAssignedDeliveries} total',
                style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (activity.volunteers.isEmpty)
            const _EmptyLabel('No volunteer delivery activity yet')
          else
            ...activity.volunteers.map((volunteer) => _VolunteerCard(
                  volunteer: volunteer,
                )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final VolunteerActivity volunteer;
  const _VolunteerCard({required this.volunteer});

  @override
  Widget build(BuildContext context) {
    final shortId = volunteer.volunteerId.length > 12
        ? '…${volunteer.volunteerId.substring(volunteer.volunteerId.length - 8)}'
        : volunteer.volunteerId;
    final lastDelivery = volunteer.lastDeliveredAt;
    final lastDeliveryLabel = lastDelivery == null
        ? 'No completed delivery yet'
        : 'Last completed ${lastDelivery.toLocal().toString().substring(0, 10)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F4F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Color(0xFF008C82)),
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
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastDeliveryLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${volunteer.completedDeliveries}/${volunteer.totalDeliveries}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Text(
                'completed',
                style: TextStyle(fontSize: 10, color: AppTheme.greyText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _ImpactCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const Spacer(),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
        ),
      ],
    ),
  );
}

class _ImpactHero extends StatelessWidget {
  final int donations;
  final int requests;
  final int matches;
  const _ImpactHero({
    required this.donations,
    required this.requests,
    required this.matches,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF168A55), Color(0xFF2FAE60)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_graph_rounded, color: Colors.white, size: 21),
            SizedBox(width: 8),
            Text(
              'PLATFORM CONTRIBUTION',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          '$matches food connections made',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _HeroMetric(value: '$donations', label: 'donations'),
            _HeroMetric(value: '$requests', label: 'requests helped'),
          ],
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
    child: Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

class _FoodSavedCard extends StatelessWidget {
  final List<String> quantityParts;
  const _FoodSavedCard({required this.quantityParts});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF8F4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFC9EBE0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFBDECDD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.recycling_outlined, color: Color(0xFF008C82)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
              'Food waste prevented',
                style: TextStyle(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                quantityParts.isEmpty
                    ? 'No approved food donations yet'
                    : quantityParts.join('  •  '),
                style: const TextStyle(
                  color: Color(0xFF087469),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TrendChart extends StatelessWidget {
  final List<MonthlyImpact> data;
  const _TrendChart({required this.data});
  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(
      1,
      (max, item) =>
          [max, item.donations, item.requests].reduce((a, b) => a > b ? a : b),
    );
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              _Legend(color: AppTheme.primaryGreen, label: 'Donations'),
              SizedBox(width: 16),
              _Legend(color: Color(0xFF3F6EDC), label: 'Requests'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data
                  .map(
                    (item) => Expanded(
                      child: _BarGroup(item: item, maxValue: maxValue),
                    ),
                  )
                  .toList(),
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
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (item.donations > 0 || item.requests > 0)
              Text(
                '${item.donations} / ${item.requests}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
            const SizedBox(height: 4),
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
                  _Bar(
                    value: item.requests,
                    maxValue: maxValue,
                    color: const Color(0xFF3F6EDC),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        item.month,
        style: const TextStyle(fontSize: 10, color: AppTheme.greyText),
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
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox(width: 10);
    return FractionallySizedBox(
      heightFactor: value / maxValue,
      child: Container(
        width: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
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
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
      ),
    ],
  );
}

class _CategoryList extends StatelessWidget {
  final List<CategoryImpact> categories;
  const _CategoryList({required this.categories});
  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const _EmptyLabel('No donation data yet');
    final top = categories.take(5).toList();
    final maxCount = top.first.count;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: top
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        item.category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.count / maxCount,
                          minHeight: 8,
                          color: AppTheme.primaryGreen,
                          backgroundColor: AppTheme.lightGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.count}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final RefreshCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.greyText),
          ),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _EmptyLabel extends StatelessWidget {
  final String text;
  const _EmptyLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Center(
      child: Text(text, style: const TextStyle(color: AppTheme.greyText)),
    ),
  );
}
