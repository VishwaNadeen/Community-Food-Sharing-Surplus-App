import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_request_service.dart';
import '../../theme/app_theme.dart';

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

  static const List<String> _filterOptions = [
    'All',
    'PENDING',
    'APPROVED',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingRequests();
    _loadAllRequests();
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
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.greyText,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'All Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPendingTab(), _buildAllRequestsTab()],
      ),
    );
  }
}
