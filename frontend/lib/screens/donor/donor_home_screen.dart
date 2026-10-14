
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import 'cancelled_donations_screen.dart';
import 'create_donation_screen.dart';
import 'donor_bottom_nav_bar.dart';
import 'donor_home_tab.dart';
import 'donor_delivery_tab.dart';
import 'donor_profile_tab.dart';
import 'donor_ui.dart';

/// Opens the create donation form. Returns true when a donation was saved.
Future<bool> openCreateDonation(BuildContext context) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const CreateDonationScreen()),
  );

  return result == true;
}

/// Sections of the My Donations page. Cancelled donations have their own
/// page (Cancelled button).
const String kDonationFilterAll = 'ALL';
const String kDonationFilterPending = 'PENDING';
const String kDonationFilterApproved = 'APPROVED';
const String kDonationFilterRejected = 'REJECTED';

class _DonorDonationsTab extends StatefulWidget {
  /// Section shown first, e.g. Rejected when opened from the Home tab.
  final String initialFilter;

  const _DonorDonationsTab({
    super.key,
    this.initialFilter = kDonationFilterAll,
  });

  @override
  State<_DonorDonationsTab> createState() => _DonorDonationsTabState();
}

class _DonorDonationsTabState extends State<_DonorDonationsTab> {
  List<DonationModel> _donations = [];
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _error;
  late String _filter = widget.initialFilter;

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  /// Whether a donation belongs in a section. Approved also includes
  /// AVAILABLE (approved and listed for recipients).
  static bool _matchesFilter(DonationModel donation, String filter) {
    final status = donation.status.toUpperCase();

    switch (filter) {
      case kDonationFilterPending:
        return status == 'PENDING';
      case kDonationFilterApproved:
        return status == 'APPROVED' || status == 'AVAILABLE';
      case kDonationFilterRejected:
        return status == 'REJECTED';
      default:
        return true;
    }
  }

  List<DonationModel> get _visibleDonations => _donations
      .where((donation) => _matchesFilter(donation, _filter))
      .toList();

  int _countFor(String filter) =>
      _donations.where((donation) => _matchesFilter(donation, filter)).length;

  Future<void> _loadDonations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = _donations.isEmpty;
      _error = null;
    });

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';

      final donations =
          await DonationService.getMyDonations(token: token);

      // Show every donation except cancelled donations.
      // Pending, approved and rejected donations remain visible.
      final myDonations = donations
          .where(
            (donation) =>
                donation.status.toUpperCase() != 'CANCELLED',
          )
          .toList()
        ..sort(
          (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''),
        );

      if (!mounted) return;

      setState(() {
        _donations = myDonations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  bool _canEdit(DonationModel donation) =>
      donation.status.toUpperCase() == 'PENDING';

  Future<void> _openCreate() async {
    if (await openCreateDonation(context) && mounted) {
      await _loadDonations();
    }
  }

  Future<void> _openEdit(DonationModel donation) async {
    if (!_canEdit(donation)) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateDonationScreen(
          donation: donation,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadDonations();
    }
  }

  Future<void> _openCancelledDonations() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const CancelledDonationsScreen(),
      ),
    );

    if (mounted) {
      await _loadDonations();
    }
  }

  Future<void> _cancelDonation(DonationModel donation) async {
    if (!_canEdit(donation) || _isCancelling) return;

    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';

    final confirmed = await confirmDonorAction(
      context,
      title: 'Cancel this donation?',
      message: '"${donation.category}" will be removed from your active '
          'donations and will no longer be offered to recipients. '
          'This cannot be undone.',
      confirmLabel: 'Cancel donation',
      cancelLabel: 'Keep donation',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    setState(() => _isCancelling = true);

    try {
      await DonationService.cancelDonation(
        token: token,
        id: donation.id,
      );

      if (!mounted) return;

      showDonorSuccess(
        context,
        'Donation cancelled. You can find it under Cancelled.',
      );

      await _loadDonations();
    } catch (e) {
      if (!mounted) return;

      showDonorError(
        context,
        'The donation was not cancelled. ${friendlyErrorMessage(e)}',
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AppTheme.mutedText),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: DonorTextSize.body,
              color: AppTheme.mutedText,
            ),
          ),
        ),
      ],
    );
  }

  String _shortExpiry(DonationModel donation) {
    final date = DateTime.tryParse(donation.expiryDate);
    return date == null ? donation.expiryDate : 'Exp. ${formatShortDate(date)}';
  }

  /// Grid card: photo on top, then food type, amount, expiry and status.
  Widget _buildDonationCard(DonationModel donation) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => _showDonationDetails(donation),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DonationImage(
              url: donation.imageUrl,
              height: 120,
              radius: 0,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: DonorTextSize.body,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _iconText(
                      Icons.scale_outlined,
                      formatQuantity(
                        donation.quantity,
                        donation.quantityUnit,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _iconText(Icons.event_outlined, _shortExpiry(donation)),
                    const Spacer(),
                    DonationStatusBadge(status: donation.status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDonationDetails(
    DonationModel donation,
  ) async {
    final canManage = _canEdit(donation);
    final statusStyle = DonationStatusStyle.of(donation.status);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                    bottom: 8,
                  ),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DonationImage(
                          url: donation.imageUrl,
                          height: 200,
                          radius: 16,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          donation.category,
                          style: const TextStyle(
                            fontSize: DonorTextSize.title,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DonationStatusBadge(status: donation.status),
                        if (statusStyle.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            statusStyle.description,
                            style: const TextStyle(
                              fontSize: DonorTextSize.body,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                        // Why it was rejected, so the donor can fix it
                        // next time.
                        if (donation.status.toUpperCase() == 'REJECTED' &&
                            (donation.rejectionReason?.trim().isNotEmpty ??
                                false)) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.danger,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Reason for rejection',
                                        style: TextStyle(
                                          fontSize: DonorTextSize.small,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.danger,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        donation.rejectionReason!.trim(),
                                        style: const TextStyle(
                                          fontSize: DonorTextSize.body,
                                          height: 1.4,
                                          color: AppTheme.darkText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        DonorDetailRow(
                          icon: Icons.scale_outlined,
                          label: 'Amount',
                          value: formatQuantity(
                            donation.quantity,
                            donation.quantityUnit,
                          ),
                        ),
                        DonorDetailRow(
                          icon: Icons.description_outlined,
                          label: 'Description',
                          value: donation.description,
                        ),
                        DonorDetailRow(
                          icon: Icons.event_outlined,
                          label: 'Expiry date',
                          value: formatApiDate(donation.expiryDate),
                        ),
                        DonorDetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Pickup address',
                          value: donation.pickupLocation,
                        ),
                        DonorDetailRow(
                          icon: Icons.access_time_outlined,
                          label: 'Pickup date and time',
                          value: formatApiDate(
                            donation.pickupDateTime,
                            withTime: true,
                          ),
                        ),
                        if (!canManage)
                          const Text(
                            'Only pending donations can be edited or '
                            'cancelled.',
                            style: TextStyle(
                              fontSize: DonorTextSize.small,
                              color: AppTheme.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    20,
                  ),
                  child: canManage
                      ? Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(sheetContext);
                                  await _openEdit(donation);
                                },
                                style: donorOutlinedButtonStyle(),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(sheetContext);
                                  await _cancelDonation(donation);
                                },
                                style: donorOutlinedButtonStyle(
                                  color: AppTheme.danger,
                                ),
                                icon: const Icon(Icons.block_outlined),
                                label: const Text('Cancel donation'),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: donorFilledButtonStyle(),
                            child: const Text('Close'),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDonationContent() {
    if (_isLoading) {
      return const DonorLoadingView(message: 'Loading your donations...');
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadDonations,
        color: AppTheme.primaryGreen,
        child: DonorMessageView.error(
          title: 'Could not load your donations',
          message: _error!,
          onAction: () {
            setState(() => _isLoading = true);
            _loadDonations();
          },
        ),
      );
    }

    if (_donations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDonations,
        color: AppTheme.primaryGreen,
        child: DonorMessageView(
          icon: Icons.volunteer_activism_outlined,
          title: 'No donations yet',
          message: 'Share your extra food with people who need it. '
              'It only takes a minute.',
          actionLabel: 'Create a donation',
          onAction: _openCreate,
        ),
      );
    }

    final visible = _visibleDonations;

    // The selected section has nothing in it.
    if (visible.isEmpty) {
      final empty = switch (_filter) {
        kDonationFilterPending => (
            icon: Icons.hourglass_empty_rounded,
            title: 'Nothing waiting for review',
            message: 'New donations appear here until they are approved '
                'or rejected.',
          ),
        kDonationFilterApproved => (
            icon: Icons.check_circle_outline,
            title: 'No approved donations yet',
            message: 'Donations appear here once they are approved and '
                'offered to recipients.',
          ),
        _ => (
            icon: Icons.thumb_up_alt_outlined,
            title: 'No rejected donations',
            message: 'Good news: none of your donations were rejected.',
          ),
      };

      return RefreshIndicator(
        onRefresh: _loadDonations,
        color: AppTheme.primaryGreen,
        child: DonorMessageView(
          icon: empty.icon,
          title: empty.title,
          message: empty.message,
          actionLabel: 'Show all donations',
          actionIcon: Icons.grid_view_rounded,
          onAction: () => setState(() => _filter = kDonationFilterAll),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDonations,
      color: AppTheme.primaryGreen,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom padding keeps the last card clear of the button.
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          // Two columns on phones, more on wider screens.
          maxCrossAxisExtent: 240,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          // Card height = photo (120) + text area. The text area grows
          // with the phone's text size so larger fonts are not cut off.
          // It has some spare room because line heights differ between
          // devices; the Spacer in the card absorbs any extra.
          mainAxisExtent:
              120 + MediaQuery.textScalerOf(context).scale(1) * 148,
        ),
        itemCount: visible.length,
        itemBuilder: (_, index) => _buildDonationCard(visible[index]),
      ),
    );
  }

  /// Section chips: All · Pending · Approved · Rejected, with counts.
  Widget _buildFilterBar() {
    final filters = [
      (value: kDonationFilterAll, label: 'All', status: ''),
      (value: kDonationFilterPending, label: 'Pending', status: 'PENDING'),
      (value: kDonationFilterApproved, label: 'Approved', status: 'APPROVED'),
      (value: kDonationFilterRejected, label: 'Rejected', status: 'REJECTED'),
    ];

    return SizedBox(
      height: kDonorTapHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = filters[index];
          final selected = _filter == filter.value;
          final count = _countFor(filter.value);
          final style = filter.status.isEmpty
              ? null
              : DonationStatusStyle.of(filter.status);

          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            avatar: style == null
                ? null
                : Icon(
                    style.icon,
                    size: 18,
                    color: selected ? Colors.white : style.foreground,
                  ),
            label: Text(_isLoading ? filter.label : '${filter.label}  $count'),
            labelStyle: TextStyle(
              fontSize: DonorTextSize.body,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.darkText,
            ),
            selectedColor: AppTheme.primaryGreenDark,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected
                  ? AppTheme.primaryGreenDark
                  : const Color(0xFFD5DAD8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            onSelected: (_) => setState(() => _filter = filter.value),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _donations.length;

    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: donorAppBar('My Donations'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New donation',
          style: TextStyle(
            fontSize: DonorTextSize.body,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isCancelling)
            const LinearProgressIndicator(color: AppTheme.primaryGreen),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isLoading || _error != null
                        ? 'Active donations'
                        : '$count active donation${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: DonorTextSize.body,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openCancelledDonations,
                  style: donorOutlinedButtonStyle(
                    color: AppTheme.mutedText,
                  ),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Cancelled'),
                ),
              ],
            ),
          ),
          if (_error == null && _donations.isNotEmpty) ...[
            _buildFilterBar(),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: _buildDonationContent(),
          ),
        ],
      ),
    );
  }
}


/// Main donor screen. The Donations tab reuses the complete existing
/// My Donations implementation above, without requiring another Dart file.
class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  // Start on Donations to preserve the previous initial screen.
  int _currentIndex = 1;

  // Changing a key rebuilds that tab, so it reloads fresh data when the
  // donor switches back to it (for example after creating a donation).
  int _homeVersion = 0;
  int _donationsVersion = 0;
  int _deliveryVersion = 0;

  // Section the Donations tab opens on.
  String _donationsFilter = kDonationFilterAll;

  void _selectTab(int index) {
    setState(() {
      if (index == 0 && _currentIndex != 0) _homeVersion++;
      if (index == 1 && _currentIndex != 1) _donationsVersion++;
      if (index == 2 && _currentIndex != 2) _deliveryVersion++;
      _currentIndex = index;
    });
  }

  /// Opens the Donations tab on a section (e.g. from the Home overview).
  void _openDonations(String filter) {
    setState(() {
      _donationsFilter = filter;
      _donationsVersion++;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DonorHomeTab(
            key: ValueKey('home-$_homeVersion'),
            onViewDonations: _openDonations,
          ),
          _DonorDonationsTab(
            key: ValueKey('donations-$_donationsVersion'),
            initialFilter: _donationsFilter,
          ),
          DonorDeliveryTab(
            key: ValueKey('delivery-$_deliveryVersion'),
            isActive: _currentIndex == 2,
          ),
          const DonorProfileTab(),
        ],
      ),
      bottomNavigationBar: DonorBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // The bottom bar always opens Donations on "All".
          if (index == 1) _donationsFilter = kDonationFilterAll;
          _selectTab(index);
        },
      ),
    );
  }
}
