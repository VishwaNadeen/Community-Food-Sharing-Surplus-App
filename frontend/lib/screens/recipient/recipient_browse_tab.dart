import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import 'donation_card.dart';
import 'recipient_shared_widgets.dart';

class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key});

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  List<DonationModel> _donations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDonations());
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDonations() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await DonationService.browseDonations(
        token: token,
        category: _categoryCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _donations = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hides the keyboard, then searches.
  void _search() {
    FocusScope.of(context).unfocus();
    _loadDonations();
  }

  // Clears both filters and reloads.
  void _clearFilters() {
    _categoryCtrl.clear();
    _locationCtrl.clear();
    _search();
  }

  // ---------------------------------------------------------------------
  // FILTER PANEL
  // ---------------------------------------------------------------------

  Widget _filterField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputAction action,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      textInputAction: action,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppTheme.darkText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryGreen),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear',
              onPressed: controller.clear,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppTheme.greyText,
              ),
            );
          },
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.fieldFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _filterField(
                      controller: _categoryCtrl,
                      hint: 'What are you looking for?',
                      icon: Icons.category_outlined,
                      action: TextInputAction.next,
                    ),
                    const Divider(
                      height: 1,
                      indent: 14,
                      endIndent: 14,
                      color: AppTheme.border,
                    ),
                    _filterField(
                      controller: _locationCtrl,
                      hint: 'Pickup location',
                      icon: Icons.location_on_outlined,
                      action: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Material(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: _search,
                    child: const SizedBox(
                      width: 52,
                      child: Center(
                        child: Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // RESULTS HEADER
  // ---------------------------------------------------------------------

  Widget _buildResultsHeader() {
    final count = _donations.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count ${count == 1 ? 'donation' : 'donations'} available',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreenDark,
              ),
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: Listenable.merge([_categoryCtrl, _locationCtrl]),
            builder: (_, __) {
              final hasFilters = _categoryCtrl.text.isNotEmpty ||
                  _locationCtrl.text.isNotEmpty;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: hasFilters
                    ? TextButton.icon(
                        key: const ValueKey('clear'),
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off_outlined,
                            size: 16),
                        label: const Text('Clear filters'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreenDark,
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('none')),
              );
            },
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

    return Column(
      children: [
        // ── Search / filter panel ──
        _buildFilterPanel(),
        const Divider(height: 1, color: AppTheme.border),

        // ── List ──
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isLoading
                ? const _SkeletonGrid(key: ValueKey('loading'))
                : _error != null
                    ? RecipientErrorState(
                        message: _error!,
                        onRetry: _loadDonations,
                      )
                    : _donations.isEmpty
                        ? RecipientEmptyState(
                            icon: Icons.no_food_outlined,
                            message:
                                'No donations available.\nCheck back later!',
                            onRetry: _loadDonations,
                          )
                        : Column(
                            key: const ValueKey('list'),
                            children: [
                              _buildResultsHeader(),
                              Expanded(
                                child: RefreshIndicator(
                                  color: AppTheme.primaryGreen,
                                  onRefresh: _loadDonations,
                                  child: GridView.builder(
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 24),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.62,
                                    ),
                                    itemCount: _donations.length,
                                    itemBuilder: (context, index) {
                                      // Staggered fade + slide-up entrance.
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0, end: 1),
                                        duration: Duration(
                                          milliseconds:
                                              350 + (index % 6) * 70,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset:
                                                  Offset(0, 24 * (1 - value)),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: DonationCard(
                                          donation: _donations[index],
                                          token: token,
                                          onClaimed: _loadDonations,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// LOADING SKELETON
// ---------------------------------------------------------------------------

class _SkeletonGrid extends StatefulWidget {
  const _SkeletonGrid({super.key});

  @override
  State<_SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<_SkeletonGrid>
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 112, color: AppTheme.fieldFill),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(width: 90, height: 14),
                const SizedBox(height: 10),
                _block(width: 60, height: 12),
                const SizedBox(height: 10),
                _block(width: 110, height: 12),
                const SizedBox(height: 16),
                _block(height: 34, radius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => _skeletonCard(),
      ),
    );
  }
}