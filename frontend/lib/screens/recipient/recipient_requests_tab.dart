import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/food_request_model.dart';
import '../../services/food_request_service.dart';
import 'request_card.dart';
import 'recipient_shared_widgets.dart';

class MyRequestsTab extends StatefulWidget {
  const MyRequestsTab({super.key});

  @override
  State<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<MyRequestsTab> {
  List<FoodRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  Future<void> _loadRequests() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token ?? '';
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await FoodRequestService.getMyRequests(token: token);
      if (!mounted) return;
      setState(() => _requests = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------

  Widget _buildHeader() {
    final count = _requests.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count ${count == 1 ? 'request' : 'requests'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreenDark,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _isLoading ? null : _loadRequests,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreenDark,
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';

    return Container(
      color: const Color(0xFFF7F9F7),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? const _SkeletonList(key: ValueKey('loading'))
            : _error != null
            ? KeyedSubtree(
                key: const ValueKey('error'),
                child: RecipientErrorState(
                  message: _error!,
                  onRetry: _loadRequests,
                ),
              )
            : _requests.isEmpty
            ? KeyedSubtree(
                key: const ValueKey('empty'),
                child: RecipientEmptyState(
                  icon: Icons.inbox_outlined,
                  message:
                      "You haven't made any food requests yet.\nBrowse donations and request what you need.",
                  onRetry: _loadRequests,
                ),
              )
            : Column(
                key: const ValueKey('list'),
                children: [
                  _buildHeader(),
                  const Divider(height: 1, color: AppTheme.border),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppTheme.primaryGreen,
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          // Staggered fade + slide-up entrance.
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(
                              milliseconds: 300 + (index % 6) * 70,
                            ),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: RequestCard(
                              request: _requests[index],
                              token: token,
                              onConfirmed: _loadRequests,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOADING SKELETON
// ---------------------------------------------------------------------------

class _SkeletonList extends StatefulWidget {
  const _SkeletonList({super.key});

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _block({double? width, required double height, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.fieldFill,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          _block(width: 64, height: 64, radius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(width: 120, height: 14),
                const SizedBox(height: 8),
                _block(width: 80, height: 12),
                const SizedBox(height: 8),
                _block(width: 150, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _block(width: 60, height: 24, radius: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: 5,
        itemBuilder: (_, __) => _skeletonCard(),
      ),
    );
  }
}
