import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/food_request_model.dart';
import '../../models/donation_model.dart';
import '../../services/food_request_service.dart';
import '../../services/donation_service.dart';
import 'request_card.dart';
import 'recipient_browse_tab.dart';

/// Home tab: an at-a-glance overview of the recipient's requests and the
/// latest food that is available to claim.
class RecipientDashboardTab extends StatefulWidget {
  final VoidCallback onBrowse;
  final VoidCallback onRequests;
  final VoidCallback? onInitialLoadComplete;

  const RecipientDashboardTab({
    super.key,
    required this.onBrowse,
    required this.onRequests,
    this.onInitialLoadComplete,
  });

  @override
  State<RecipientDashboardTab> createState() => RecipientDashboardTabState();
}

class RecipientDashboardTabState extends State<RecipientDashboardTab> {
  List<FoodRequestModel> _requests = [];
  List<DonationModel> _latest = [];
  bool _loading = true;
  String? _requestsError;
  String? _donationsError;
  bool _notified = false;

  static const double _cardHeight = 240;
  static const Color _blue = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');

  /// Reloads the overview. Called by the parent when the tab is reopened.
  Future<void> refresh({bool silent = false}) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';

    if (!silent && mounted) setState(() => _loading = true);

    await Future.wait([
      _loadRequests(token, silent),
      _loadDonations(token, silent),
    ]);

    if (!mounted) return;
    setState(() => _loading = false);

    if (!_notified) {
      _notified = true;
      widget.onInitialLoadComplete?.call();
    }
  }

  Future<void> _loadRequests(String token, bool silent) async {
    try {
      final r = await FoodRequestService.getMyRequests(token: token);
      _requests = r;
      _requestsError = null;
    } catch (e) {
      if (!silent) _requestsError = _clean(e);
    }
  }

  Future<void> _loadDonations(String token, bool silent) async {
    try {
      final all = await DonationService.browseDonations(
        token: token,
        category: '',
      );
      _latest = all.where((d) => d.isClaimable).take(2).toList();
      _donationsError = null;
    } catch (e) {
      if (!silent) _donationsError = _clean(e);
    }
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF7F9F7);

    if (_loading) {
      return Container(color: bg, child: const _DashboardSkeleton());
    }

    final stages = _requests.map((r) => requestStatusInfo(r)).toList();
    final total = _requests.length;
    final completed =
        stages.where((s) => s.stage == RequestStage.received).length;
    final pending =
        stages.where((s) => s.stage == RequestStage.pending).length;
    final inProgress = stages
        .where((s) =>
            s.stage == RequestStage.approved ||
            s.stage == RequestStage.onTheWay)
        .length;
    final toConfirm = stages.where((s) => s.canConfirm).length;

    return Container(
      color: bg,
      child: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () => refresh(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (toConfirm > 0) ...[
              _attentionCard(toConfirm),
              const SizedBox(height: 16),
            ],

            // ── Overview ──
            _sectionTitle('Your overview'),
            const SizedBox(height: 12),
            if (_requestsError != null)
              _messageTile(
                icon: Icons.cloud_off_rounded,
                text: _requestsError!,
                actionLabel: 'Retry',
                onAction: () => refresh(),
              )
            else ...[
              _heroCard(completed: completed, total: total),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statTile(
                      icon: Icons.receipt_long_rounded,
                      color: AppTheme.primaryGreen,
                      value: total,
                      label: 'Total',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statTile(
                      icon: Icons.hourglass_top_rounded,
                      color: Colors.orange,
                      value: pending,
                      label: 'Pending',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statTile(
                      icon: Icons.delivery_dining_rounded,
                      color: _blue,
                      value: inProgress,
                      label: 'In progress',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 26),

            // ── Latest available food ──
            Row(
              children: [
                Expanded(child: _sectionTitle('Latest available food')),
                TextButton(
                  onPressed: widget.onBrowse,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreenDark,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('See all'),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLatestFood(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PIECES
  // ---------------------------------------------------------------------

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: AppTheme.darkText,
      ),
    );
  }

  // Big green card: number of completed requests.
  Widget _heroCard({required int completed, required int total}) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Completed requests',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completed',
                  style: const TextStyle(
                    fontSize: 46,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'No requests yet. Find food you need!'
                      : 'out of $total ${total == 1 ? 'request' : 'requests'} made',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const Icon(Icons.task_alt_rounded,
                    size: 30, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color color,
    required int value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
          ),
        ],
      ),
    );
  }

  // Shown when something is ready for the user to confirm.
  Widget _attentionCard(int count) {
    return Material(
      color: _blue.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onRequests,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.delivery_dining_rounded,
                    color: _blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? '1 order is on its way'
                          : '$count orders are on their way',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Track it and confirm once you receive your food.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.greyText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestFood() {
    if (_donationsError != null) {
      return _messageTile(
        icon: Icons.cloud_off_rounded,
        text: _donationsError!,
        actionLabel: 'Retry',
        onAction: () => refresh(),
      );
    }

    if (_latest.isEmpty) {
      return _messageTile(
        icon: Icons.no_food_outlined,
        text: 'No food is available right now.\nCheck back soon!',
      );
    }

    return SizedBox(
      height: _cardHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _donationCard(_latest[0])),
          const SizedBox(width: 12),
          Expanded(
            child: _latest.length > 1
                ? _donationCard(_latest[1])
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _donationCard(DonationModel d) {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    return DonationCard(
      donation: d,
      token: token,
      onClaimed: () => refresh(silent: true),
    );
  }

  Widget _messageTile({
    required IconData icon,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppTheme.greyText),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.greyText,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOADING SKELETON
// ---------------------------------------------------------------------------

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  Widget _block(double height, {double radius = 16, double? width}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.fieldFill,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _block(20, radius: 8, width: 130),
        const SizedBox(height: 12),
        _block(138, radius: 22),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _block(94)),
            const SizedBox(width: 10),
            Expanded(child: _block(94)),
            const SizedBox(width: 10),
            Expanded(child: _block(94)),
          ],
        ),
        const SizedBox(height: 26),
        _block(20, radius: 8, width: 170),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _block(240, radius: 20)),
            const SizedBox(width: 12),
            Expanded(child: _block(240, radius: 20)),
          ],
        ),
      ],
    );
  }
}