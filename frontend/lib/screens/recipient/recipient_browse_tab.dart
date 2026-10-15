import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import 'recipient_shared_widgets.dart';
import 'donation_detail_screen.dart';
import 'submit_food_request_screen.dart';

// Shared card proportions (grid + skeleton use the same values).
const double _kCardHeight = 240;
const double _kCardImageHeight = 124;

class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key});

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  final TextEditingController _categoryCtrl = TextEditingController();
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

  // Clears the search filter and reloads.
  void _clearFilters() {
    _categoryCtrl.clear();
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.fieldFill,
          borderRadius: BorderRadius.circular(16),
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
                      action: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Material(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _search,
                    child: const SizedBox(
                      width: 50,
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
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreenDark,
              ),
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _categoryCtrl,
            builder: (_, __) {
              final hasFilters = _categoryCtrl.text.isNotEmpty;

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
                                        16, 10, 16, 24),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: _kCardHeight,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: _kCardImageHeight, color: AppTheme.fieldFill),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(width: 96, height: 14),
                const SizedBox(height: 8),
                _block(width: 120, height: 12),
                const SizedBox(height: 14),
                _block(height: 38, radius: 12),
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
          mainAxisExtent: _kCardHeight,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => _skeletonCard(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DONATION CARD
// ---------------------------------------------------------------------------

class DonationCard extends StatefulWidget {
  final DonationModel donation;
  final String token;
  final VoidCallback onClaimed;

  const DonationCard({
    super.key,
    required this.donation,
    required this.token,
    required this.onClaimed,
  });

  @override
  State<DonationCard> createState() => _DonationCardState();
}

class _DonationCardState extends State<DonationCard> {
  // Used for the small "press" animation.
  bool _pressed = false;

  DonationModel get donation => widget.donation;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'APPROVED':
        return AppTheme.primaryGreen;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      case 'COLLECTED':
      case 'COMPLETED':
        return Colors.blue;
      default:
        return AppTheme.greyText;
    }
  }

  // "AVAILABLE" -> "Available"
  String _statusLabel(String status) {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  Future<void> _openDetails(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DonationDetailScreen(
          donation: donation,
          token: widget.token,
        ),
      ),
    );
    if (result == true) {
      widget.onClaimed();
    }
  }

  Future<void> _requestFood(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitFoodRequestScreen(
          donation: donation,
          token: widget.token,
        ),
      ),
    );
    if (result == true) {
      widget.onClaimed();
    }
  }

  // ---------------------------------------------------------------------
  // PIECES
  // ---------------------------------------------------------------------

  Widget _buildImage() {
    final hasImage =
        donation.imageUrl != null && donation.imageUrl!.isNotEmpty;

    if (!hasImage) {
      return const Center(
        child: Icon(
          Icons.restaurant,
          size: 44,
          color: AppTheme.primaryGreen,
        ),
      );
    }

    return Image.network(
      donation.imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Food image failed: ${donation.imageUrl}');
        debugPrint('Image error: $error');
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 44,
            color: AppTheme.primaryGreen,
          ),
        );
      },
    );
  }

  // Status pill shown on the image (top-left).
  Widget _statusBadge(Color statusColor) {
    final label = _statusLabel(donation.status);
    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Quantity pill shown on the image (bottom-left) so the most important
  // fact is visible at a glance.
  Widget _quantityChip(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
    final statusColor = _statusColor(donation.status);

    final quantityText =
        '${donation.quantity % 1 == 0 ? donation.quantity.toInt() : donation.quantity} ${donation.quantityUnit}';

    return Semantics(
      button: true,
      label:
          '${donation.category}, $quantityText, pickup at ${donation.pickupLocation}',
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppTheme.border.withValues(alpha: 0.6),
                ),
              ),
              child: InkWell(
                onTap: () => _openDetails(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Food image with overlays ──
                    SizedBox(
                      height: _kCardImageHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: AppTheme.lightGreen,
                            child: _buildImage(),
                          ),

                          // Top gradient keeps the status badge readable.
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 46,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.28),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom gradient keeps the quantity chip readable.
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 52,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.35),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Status badge (top-left)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _statusBadge(statusColor),
                          ),

                          // "Open details" hint (top-right)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_outward_rounded,
                                size: 15,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ),

                          // Quantity chip (bottom-left)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: _quantityChip(quantityText),
                          ),
                        ],
                      ),
                    ),

                    // ── Donation information and action ──
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donation.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: AppTheme.darkText,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    donation.pickupLocation,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.25,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.greyText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton.icon(
                                onPressed: () => _requestFood(context),
                                icon: const Icon(
                                  Icons.volunteer_activism_rounded,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Request Food',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}