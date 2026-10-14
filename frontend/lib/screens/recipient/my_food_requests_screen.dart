import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/food_request_model.dart';
import '../../services/food_request_service.dart';
import 'request_card.dart';
import 'recipient_shared_widgets.dart';

enum _Filter { all, pending, approved, onTheWay, received, rejected }

class MyRequestsTab extends StatefulWidget {
  const MyRequestsTab({super.key});

  @override
  State<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends State<MyRequestsTab> {
  List<FoodRequestModel> _requests = [];
  bool _isLoading = false;
  String? _error;
  _Filter _filter = _Filter.all;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());

    // Quietly re-check every 20s while something is in progress, so the
    // status (and the Confirm button) updates when the delivery partner
    // starts delivery.
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _isLoading) return;
      final active = _requests.any((r) {
        final s = requestStatusInfo(r).stage;
        return s == RequestStage.pending ||
            s == RequestStage.approved ||
            s == RequestStage.onTheWay;
      });
      if (active) _loadRequests(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadRequests({bool silent = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token ?? '';
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final results = await FoodRequestService.getMyRequests(token: token);
      if (!mounted) return;
      setState(() => _requests = results);
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------
  // FILTERS
  // ---------------------------------------------------------------------

  bool _matches(FoodRequestModel r, _Filter f) {
    if (f == _Filter.all) return true;
    final stage = requestStatusInfo(r).stage;
    switch (f) {
      case _Filter.pending:
        return stage == RequestStage.pending;
      case _Filter.approved:
        return stage == RequestStage.approved;
      case _Filter.onTheWay:
        return stage == RequestStage.onTheWay;
      case _Filter.received:
        return stage == RequestStage.received;
      case _Filter.rejected:
        return stage == RequestStage.rejected;
      case _Filter.all:
        return true;
    }
  }

  String _filterLabel(_Filter f) {
    switch (f) {
      case _Filter.all:
        return 'All';
      case _Filter.pending:
        return 'Pending';
      case _Filter.approved:
        return 'Approved';
      case _Filter.onTheWay:
        return 'On the way';
      case _Filter.received:
        return 'Received';
      case _Filter.rejected:
        return 'Rejected';
    }
  }

  Widget _filterChip(_Filter f) {
    final count = _requests.where((r) => _matches(r, f)).length;
    final selected = _filter == f;

    // Hide empty categories (except "All" and the one currently selected).
    if (count == 0 && f != _Filter.all && !selected) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : AppTheme.border,
            ),
          ),
          child: Text(
            '${_filterLabel(f)} · $count',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppTheme.darkText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [for (final f in _Filter.values) _filterChip(f)],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : () => _loadRequests(),
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.greyText),
          ),
        ],
      ),
    );
  }

  Widget _filteredEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 70),
        const Icon(Icons.filter_alt_off_outlined,
            size: 46, color: AppTheme.border),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'No requests in this category',
            style: TextStyle(color: AppTheme.greyText, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _filter = _Filter.all),
            child: const Text('Show all requests'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final visible = _requests.where((r) => _matches(r, _filter)).toList();

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
                          _buildFilterBar(),
                          const Divider(height: 1, color: AppTheme.border),
                          Expanded(
                            child: RefreshIndicator(
                              color: AppTheme.primaryGreen,
                              onRefresh: _loadRequests,
                              child: visible.isEmpty
                                  ? _filteredEmpty()
                                  : ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 14, 16, 24),
                                      itemCount: visible.length,
                                      itemBuilder: (context, index) {
                                        return RequestCard(
                                          key: ValueKey(visible[index].id),
                                          request: visible[index],
                                          token: token,
                                          onConfirmed: _loadRequests,
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
    _opacity = Tween<double>(begin: 0.45, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _block(width: 48, height: 48, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(width: 120, height: 14),
                    const SizedBox(height: 8),
                    _block(width: 70, height: 12),
                  ],
                ),
              ),
              _block(width: 70, height: 24, radius: 20),
            ],
          ),
          const SizedBox(height: 18),
          _block(height: 22, radius: 11),
          const SizedBox(height: 14),
          _block(height: 40, radius: 12),
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
        itemCount: 4,
        itemBuilder: (_, __) => _skeletonCard(),
      ),
    );
  }
}