import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/donation_model.dart';
import '../../models/food_match_model.dart';
import '../../models/food_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../services/food_request_service.dart';
import '../../services/matching_service.dart';
import '../../theme/app_theme.dart';
import 'ngo_administration_screen.dart';

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

  int _requestView = 0;
  int _donationView = 0;

  static const List<String> _filterOptions = [
    'All',
    'PENDING',
    'APPROVED',
    'REJECTED',
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

  Future<void> _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'APPROVED':
        return AppTheme.primaryGreen;
      case 'REJECTED':
        return Colors.red.shade600;
      default:
        return AppTheme.greyText;
    }
  }

  Widget _buildRequestCard(
    FoodRequestModel request, {
    bool showActions = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.foodItem,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                if (!showActions)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        request.status,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(request.status),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.email_outlined, request.recipientEmail ?? 'N/A'),
            const SizedBox(height: 4),
            _infoRow(
              Icons.inventory_2_outlined,
              'Qty: ${request.quantityRequested}',
            ),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoRow(Icons.notes_outlined, request.notes!),
            ],
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(DonationModel donation, {bool showActions = true}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    donation.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                if (!showActions)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        donation.status,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      donation.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(donation.status),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.inventory_2_outlined,
              'Quantity: ${donation.quantity} ${donation.quantityUnit}',
            ),
            const SizedBox(height: 4),
            _infoRow(Icons.description_outlined, donation.description),
            const SizedBox(height: 4),
            _infoRow(Icons.location_on_outlined, donation.pickupLocation),
            const SizedBox(height: 4),
            _infoRow(
              Icons.event_outlined,
              'Pickup: ${donation.pickupDateTime}',
            ),
            const SizedBox(height: 4),
            _infoRow(Icons.timer_outlined, 'Expires: ${donation.expiryDate}'),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveDonation(donation),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Approve',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectDonation(donation),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.greyText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppTheme.greyText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      return _buildEmptyView('No pending requests');
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
        _buildViewToggle(
          firstLabel: 'Pending',
          secondLabel: 'All requests',
          selected: _requestView,
          onChanged: (value) => setState(() => _requestView = value),
        ),
        Expanded(
          child: _requestView == 0
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
      return _buildEmptyView('No pending donations');
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
        _buildViewToggle(
          firstLabel: 'Pending',
          secondLabel: 'All donations',
          selected: _donationView,
          onChanged: (value) => setState(() => _donationView = value),
        ),
        Expanded(
          child: _donationView == 0
              ? _buildPendingDonationsTab()
              : _buildAllDonationsTab(),
        ),
      ],
    );
  }

  Widget _buildViewToggle({
    required String firstLabel,
    required String secondLabel,
    required int selected,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildToggleOption(
              label: firstLabel,
              isSelected: selected == 0,
              onTap: () => onChanged(0),
              isLeft: true,
            ),
            _buildToggleOption(
              label: secondLabel,
              isSelected: selected == 1,
              onTap: () => onChanged(1),
              isLeft: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(11) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(11),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.lightGreen : Colors.transparent,
              borderRadius: BorderRadius.horizontal(
                left: isLeft ? const Radius.circular(11) : Radius.zero,
                right: isLeft ? Radius.zero : const Radius.circular(11),
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryGreenDark
                    : AppTheme.greyText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllDonationsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Text(
                'Filter: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedDonationFilter,
                  items: _filterOptions
                      .map(
                        (filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedDonationFilter = value);
                    _loadAllDonations();
                  },
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _loadMatches(generate: true),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                'Find Suitable Matches',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
            ),
          ),
        ),
        Expanded(
          child: _matches.isEmpty
              ? _buildEmptyView('No suitable matches found')
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${donation['category'] ?? 'Food donation'} → ${request['foodItem'] ?? 'Food request'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ),
                Text(
                  match.status,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.person_outline,
              request['recipientName']?.toString() ?? 'Recipient',
            ),
            const SizedBox(height: 4),
            _infoRow(
              Icons.location_on_outlined,
              donation['pickupLocation']?.toString() ?? '',
            ),
            const SizedBox(height: 8),
            Text(
              'Match score: ${match.score}% • Category and location verified',
              style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllRequestsTab() {
    return Column(
      children: [
        // Filter dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Text(
                'Filter: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFilter,
                  items: _filterOptions
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedFilter = val;
                      _applyFilter();
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: AppTheme.greyText),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppTheme.greyText, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, VoidCallback retry) {
    return Center(
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Administration and monitoring',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NgoAdministrationScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.greyText,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Donations'),
            Tab(text: 'Matches'),
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
