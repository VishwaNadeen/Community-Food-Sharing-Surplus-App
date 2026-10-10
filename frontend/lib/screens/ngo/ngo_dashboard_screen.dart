import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../models/ngo_food_match_model.dart';
import '../../models/food_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../services/food_request_service.dart';
import '../../services/ngo_matching_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ngo_ui.dart';
import 'ngo_administration_screen.dart';
import 'ngo_impact_dashboard_screen.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Pending tab state ---
  List<FoodRequestModel> _pendingRequests = [];
  bool _isPendingLoading = true;
  String? _pendingError;

  // --- All Requests tab state ---
  List<FoodRequestModel> _allRequests = [];
  List<FoodRequestModel> _filteredRequests = [];
  bool _isAllLoading = true;
  String? _allError;
  String _selectedFilter = 'All';

  // --- Pending donations tab state ---
  List<DonationModel> _pendingDonations = [];
  bool _isDonationsLoading = true;
  String? _donationsError;

  // --- All donations tab state ---
  List<DonationModel> _allDonations = [];
  bool _isAllDonationsLoading = true;
  String? _allDonationsError;
  String _selectedDonationFilter = 'All';

  // --- Food matches tab state ---
  List<FoodMatchModel> _matches = [];
  bool _isMatchesLoading = true;
  String? _matchesError;

  String _requestFilter = 'Pending';
  String _donationFilter = 'Pending';

  static const List<String> _filterOptions = [
    'Pending',
    'All',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingRequests();
    _loadAllRequests();
    _loadPendingDonations();
    _loadAllDonations();
    _loadMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isPendingLoading = true;
      _pendingError = null;
    });
    try {
      final requests = await FoodRequestService.getPendingRequests(
        token: _token,
      );
      if (!mounted) return;
      setState(() {
        _pendingRequests = requests;
        _isPendingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pendingError = e.toString();
        _isPendingLoading = false;
      });
    }
  }

  Future<void> _loadAllRequests() async {
    setState(() {
      _isAllLoading = true;
      _allError = null;
    });
    try {
      final requests = await FoodRequestService.getAllRequests(token: _token);
      if (!mounted) return;
      setState(() {
        _allRequests = requests;
        _applyFilter();
        _isAllLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allError = e.toString();
        _isAllLoading = false;
      });
    }
  }

  Future<void> _loadPendingDonations() async {
    setState(() {
      _isDonationsLoading = true;
      _donationsError = null;
    });
    try {
      final donations = await DonationService.getPendingDonations(
        token: _token,
      );
      if (!mounted) return;
      setState(() {
        _pendingDonations = donations;
        _isDonationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _donationsError = e.toString();
        _isDonationsLoading = false;
      });
    }
  }

  Future<void> _loadAllDonations() async {
    setState(() {
      _isAllDonationsLoading = true;
      _allDonationsError = null;
    });
    try {
      final donations = await DonationService.getAllDonations(
        token: _token,
        status: _selectedDonationFilter,
      );
      if (!mounted) return;
      setState(() {
        _allDonations = donations;
        _isAllDonationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allDonationsError = e.toString();
        _isAllDonationsLoading = false;
      });
    }
  }

  Future<void> _loadMatches({bool generate = false}) async {
    setState(() {
      _isMatchesLoading = true;
      _matchesError = null;
    });
    try {
      final matches = generate
          ? await MatchingService.generateMatches(token: _token)
          : await MatchingService.getMatches(token: _token);
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _isMatchesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _matchesError = e.toString();
        _isMatchesLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredRequests = List.from(_allRequests);
    } else {
      _filteredRequests = _allRequests
          .where((r) => r.status.toUpperCase() == _selectedFilter)
          .toList();
    }
  }

  Future<void> _approveRequest(FoodRequestModel request) async {
    try {
      await FoodRequestService.approveRequest(token: _token, id: request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved successfully.'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
      _loadPendingRequests();
      _loadAllRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _rejectRequest(FoodRequestModel request) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      reasonController.dispose();
      return;
    }
    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rejection reason cannot be empty.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    try {
      await FoodRequestService.rejectRequest(
        token: _token,
        id: request.id,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected.'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
      _loadPendingRequests();
      _loadAllRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _approveDonation(DonationModel donation) async {
    try {
      await DonationService.approveDonation(token: _token, id: donation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation approved successfully.'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
      _loadPendingDonations();
      _loadAllDonations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve donation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectDonation(DonationModel donation) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Donation'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Rejection reason',
            hintText: 'Explain why this donation is unsuitable',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || reason.isEmpty) {
      if (confirmed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A rejection reason is required.')),
        );
      }
      return;
    }
    try {
      await DonationService.rejectDonation(
        token: _token,
        id: donation.id,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation rejected.'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
      _loadPendingDonations();
      _loadAllDonations();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject donation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _logout();
  }

  Tab _buildTab(String label, int pendingCount) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (pendingCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Widget _buildActionButtons({
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkText,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.greyText,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }

  Widget _waitingLabel(String? createdAt) {
    if (createdAt == null) return const SizedBox.shrink();
    return Text(
      timeAgo(createdAt),
      style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
    );
  }

  Widget _buildRequestCard(
    FoodRequestModel request, {
    bool showActions = false,
  }) {
    final rejected = request.status.toUpperCase() == 'REJECTED';
    final hasName = (request.recipientName ?? '').isNotEmpty;
    return NgoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.restaurant_menu_outlined,
            color: AppTheme.primaryGreenDark,
            title: request.foodItem,
            subtitle: hasName ? request.recipientName : request.recipientEmail,
            trailing: showActions
                ? _waitingLabel(request.createdAt)
                : StatusChip(request.status),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              IconPill(
                Icons.inventory_2_outlined,
                request.quantityRequested,
              ),
              if (request.createdAt != null)
                IconPill(
                  Icons.schedule,
                  formatDate(request.createdAt),
                  color: AppTheme.greyText,
                ),
            ],
          ),
          if (hasName && (request.recipientEmail ?? '').isNotEmpty)
            InfoRow(Icons.email_outlined, request.recipientEmail!, maxLines: 1),
          if ((request.recipientContact ?? '').isNotEmpty)
            InfoRow(Icons.phone_outlined, request.recipientContact!, maxLines: 1),
          if ((request.deliveryAddress ?? '').isNotEmpty)
            InfoRow(Icons.location_on_outlined, request.deliveryAddress!),
          if (request.notes != null && request.notes!.isNotEmpty)
            InfoRow(Icons.notes_outlined, request.notes!, maxLines: 3),
          if (rejected && (request.rejectionReason ?? '').isNotEmpty)
            InfoRow(
              Icons.info_outline,
              'Reason: ${request.rejectionReason}',
              maxLines: 3,
            ),
          if (showActions)
            _buildActionButtons(
              onApprove: () => _approveRequest(request),
              onReject: () => _rejectRequest(request),
            ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(DonationModel donation, {bool showActions = true}) {
    final quantity = donation.quantity % 1 == 0
        ? donation.quantity.toInt().toString()
        : donation.quantity.toString();
    return NgoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.volunteer_activism_outlined,
            color: AppTheme.primaryGreenDark,
            title: donation.category,
            subtitle: donation.pickupLocation,
            trailing: showActions
                ? _waitingLabel(donation.createdAt)
                : StatusChip(donation.status),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              IconPill(
                Icons.inventory_2_outlined,
                '$quantity ${titleCase(donation.quantityUnit)}',
              ),
              IconPill(
                Icons.timer_outlined,
                'Expires ${formatDate(donation.expiryDate)}',
                color: Colors.orange.shade800,
              ),
            ],
          ),
          InfoRow(Icons.description_outlined, donation.description, maxLines: 3),
          InfoRow(
            Icons.event_outlined,
            'Pickup ${formatDateTime(donation.pickupDateTime)}',
            maxLines: 1,
          ),
          if (showActions)
            _buildActionButtons(
              onApprove: () => _approveDonation(donation),
              onReject: () => _rejectDonation(donation),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isPendingLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }
    if (_pendingError != null) {
      return _buildErrorView(_pendingError!, _loadPendingRequests);
    }
    if (_pendingRequests.isEmpty) {
      return _buildEmptyView(
        'No pending requests',
        hint: 'New food requests from recipients will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _pendingRequests.length,
        itemBuilder: (_, i) =>
            _buildRequestCard(_pendingRequests[i], showActions: true),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Column(
      children: [
        FilterChips(
          options: _filterOptions,
          selected: _requestFilter,
          labelOf: (o) => o == 'Pending' && _pendingRequests.isNotEmpty
              ? 'Pending (${_pendingRequests.length})'
              : o,
          onSelected: (value) => setState(() {
            _requestFilter = value;
            _selectedFilter = value == 'All' ? 'All' : value.toUpperCase();
            _applyFilter();
          }),
        ),
        Expanded(
          child: _requestFilter == 'Pending'
              ? _buildPendingTab()
              : _buildAllRequestsTab(),
        ),
      ],
    );
  }

  Widget _buildPendingDonationsTab() {
    if (_isDonationsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }
    if (_donationsError != null) {
      return _buildErrorView(_donationsError!, _loadPendingDonations);
    }
    if (_pendingDonations.isEmpty) {
      return _buildEmptyView(
        'No pending donations',
        hint: 'New donations from donors will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadPendingDonations,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _pendingDonations.length,
        itemBuilder: (_, i) => _buildDonationCard(_pendingDonations[i]),
      ),
    );
  }

  Widget _buildDonationsTab() {
    return Column(
      children: [
        FilterChips(
          options: _filterOptions,
          selected: _donationFilter,
          labelOf: (o) => o == 'Pending' && _pendingDonations.isNotEmpty
              ? 'Pending (${_pendingDonations.length})'
              : o,
          onSelected: (value) {
            setState(() {
              _donationFilter = value;
              if (value != 'Pending') {
                _selectedDonationFilter =
                    value == 'All' ? 'All' : value.toUpperCase();
              }
            });
            if (value != 'Pending') _loadAllDonations();
          },
        ),
        Expanded(
          child: _donationFilter == 'Pending'
              ? _buildPendingDonationsTab()
              : _buildAllDonationsTab(),
        ),
      ],
    );
  }

  Widget _buildAllDonationsTab() {
    return Column(
      children: [
        Expanded(
          child: _isAllDonationsLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                )
              : _allDonationsError != null
              ? _buildErrorView(_allDonationsError!, _loadAllDonations)
              : _allDonations.isEmpty
              ? _buildEmptyView('No donations found')
              : RefreshIndicator(
                  onRefresh: _loadAllDonations,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: _allDonations.length,
                    itemBuilder: (_, index) => _buildDonationCard(
                      _allDonations[index],
                      showActions: false,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMatchesTab() {
    if (_isMatchesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }
    if (_matchesError != null) {
      return _buildErrorView(_matchesError!, _loadMatches);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _loadMatches(generate: true),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Find suitable matches'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _matches.isEmpty
              ? _buildEmptyView(
                  'No suitable matches yet',
                  hint:
                      'Tap "Find suitable matches" to pair approved donations with approved requests.',
                )
              : RefreshIndicator(
                  onRefresh: _loadMatches,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _matches.length,
                    itemBuilder: (_, index) => _buildMatchCard(_matches[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(FoodMatchModel match) {
    final donation = match.donation;
    final request = match.foodRequest;
    final scoreColor = match.score >= 80
        ? AppTheme.primaryGreenDark
        : match.score >= 50
        ? Colors.orange.shade700
        : AppTheme.greyText;
    return NgoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: (match.score / 100).clamp(0.0, 1.0),
                        strokeWidth: 5,
                        color: scoreColor,
                        backgroundColor: scoreColor.withValues(alpha: 0.15),
                      ),
                    ),
                    Text(
                      '${match.score}%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation['category']?.toString() ?? 'Food donation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'for ${request['foodItem'] ?? 'a food request'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(match.status),
            ],
          ),
          InfoRow(
            Icons.person_outline,
            'Recipient: ${request['recipientName'] ?? 'Not provided'}',
            maxLines: 1,
          ),
          if ((donation['pickupLocation']?.toString() ?? '').isNotEmpty)
            InfoRow(
              Icons.location_on_outlined,
              'Pickup: ${donation['pickupLocation']}',
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              IconPill(
                match.categoryMatched ? Icons.check : Icons.close,
                'Category',
                color: match.categoryMatched
                    ? AppTheme.primaryGreenDark
                    : AppTheme.greyText,
              ),
              IconPill(
                match.locationMatched ? Icons.check : Icons.close,
                'Location',
                color: match.locationMatched
                    ? AppTheme.primaryGreenDark
                    : AppTheme.greyText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllRequestsTab() {
    return Column(
      children: [
        Expanded(
          child: _isAllLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                  ),
                )
              : _allError != null
              ? _buildErrorView(_allError!, _loadAllRequests)
              : _filteredRequests.isEmpty
              ? _buildEmptyView('No requests found')
              : RefreshIndicator(
                  onRefresh: _loadAllRequests,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: _filteredRequests.length,
                    itemBuilder: (_, i) =>
                        _buildRequestCard(_filteredRequests[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyView(String message, {String? hint}) {
    return EmptyState(message, hint: hint);
  }

  Widget _buildErrorView(String error, VoidCallback retry) {
    return ErrorState(error: error, onRetry: retry);
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: IconBadge(icon, color: AppTheme.primaryGreenDark, size: 40),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12.5, color: AppTheme.greyText),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDrawer() {
    final email = Provider.of<AuthProvider>(context, listen: false).user?.email;
    void open(Widget screen) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF168A55), Color(0xFF2FAE60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.eco_outlined, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'NGO Coordinator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (email != null && email.isNotEmpty)
                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(
              icon: Icons.fact_check_outlined,
              label: 'Review & matching',
              subtitle: 'Requests, donations and matches',
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              icon: Icons.insights_outlined,
              label: 'Platform impact',
              subtitle: 'Statistics and downloadable reports',
              onTap: () => open(ImpactDashboardScreen(token: _token)),
            ),
            _drawerItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Administration',
              subtitle: 'Donors, recipients and alerts',
              onTap: () => open(NgoAdministrationScreen(token: _token)),
            ),
            const Spacer(),
            const Divider(height: 1, color: AppTheme.border),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Icon(Icons.logout_outlined, color: Colors.red.shade600),
              title: Text(
                'Log out',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: const Text(
          'NGO Dashboard',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkText),
        surfaceTintColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppTheme.primaryGreenDark,
          unselectedLabelColor: AppTheme.greyText,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: [
            _buildTab('Requests', _pendingRequests.length),
            _buildTab('Donations', _pendingDonations.length),
            const Tab(text: 'Matches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(),
          _buildDonationsTab(),
          _buildMatchesTab(),
        ],
      ),
    );
  }
}
