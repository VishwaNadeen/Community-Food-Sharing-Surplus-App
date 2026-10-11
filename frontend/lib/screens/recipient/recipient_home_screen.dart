import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import '../../models/food_request_model.dart';
import '../../services/donation_service.dart';
import '../../services/food_request_service.dart';
import 'donation_detail_screen.dart';

class RecipientHomeScreen extends StatefulWidget {
  const RecipientHomeScreen({super.key});

  @override
  State<RecipientHomeScreen> createState() => _RecipientHomeScreenState();
}

class _RecipientHomeScreenState extends State<RecipientHomeScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Browse Donations',
    'My Requests',
    'Profile',
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/recipient-profile');
      return;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.greyText),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          BrowseTab(),
          MyRequestsTab(),
          SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: AppTheme.greyText,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_dining_outlined),
            activeIcon: Icon(Icons.local_dining),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'My Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BROWSE TAB
// ---------------------------------------------------------------------------

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
    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';
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

  @override
  Widget build(BuildContext context) {
    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';
    return Column(
      children: [
        // ── Search / filter row ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Category…',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13.5),
                    prefixIcon: const Icon(Icons.category_outlined,
                        size: 18, color: AppTheme.primaryGreen),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppTheme.fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryGreen, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _locationCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _loadDonations(),
                  decoration: InputDecoration(
                    hintText: 'Location…',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13.5),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        size: 18, color: AppTheme.primaryGreen),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppTheme.fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryGreen, width: 1.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _loadDonations,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        // ── List ──
        Expanded(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryGreen))
              : _error != null
                  ? _ErrorState(
                      message: _error!, onRetry: _loadDonations)
                  : _donations.isEmpty
                      ? _EmptyState(
                          icon: Icons.no_food_outlined,
                          message:
                              'No donations available.\nCheck back later!',
                          onRetry: _loadDonations,
                        )
                      : RefreshIndicator(
                          color: AppTheme.primaryGreen,
                          onRefresh: _loadDonations,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            itemCount: _donations.length,
                            itemBuilder: (context, index) => DonationCard(
                              donation: _donations[index],
                              token: token,
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DONATION CARD
// ---------------------------------------------------------------------------

class DonationCard extends StatelessWidget {
  final DonationModel donation;
  final String token;

  const DonationCard(
      {super.key, required this.donation, required this.token});

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppTheme.primaryGreen;
      case 'COLLECTED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      case 'EXPIRED':
        return Colors.orange;
      default:
        return AppTheme.greyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DonationDetailScreen(donation: donation, token: token),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──
              if (donation.imageUrl != null && donation.imageUrl!.isNotEmpty)
                SizedBox(
                  width: 90,
                  height: 110,
                  child: Image.network(
                    donation.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null
                            ? child
                            : Container(
                                color: AppTheme.lightGreen,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                    errorBuilder: (_, _, _) => Container(
                      color: AppTheme.lightGreen,
                      child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppTheme.greyText),
                    ),
                  ),
                )
              else
                Container(
                  width: 90,
                  height: 110,
                  color: AppTheme.lightGreen,
                  child: const Icon(Icons.local_dining_outlined,
                      color: AppTheme.primaryGreen, size: 32),
                ),
              // ── Info ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.category,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppTheme.greyText),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              donation.pickupLocation,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.greyText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.scale_outlined,
                              size: 14, color: AppTheme.greyText),
                          const SizedBox(width: 3),
                          Text(
                            '${donation.quantity % 1 == 0 ? donation.quantity.toInt() : donation.quantity} ${donation.quantityUnit}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.greyText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(donation.status)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          donation.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor(donation.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8, top: 8),
                child: Icon(Icons.chevron_right,
                    color: AppTheme.greyText, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MY REQUESTS TAB
// ---------------------------------------------------------------------------

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
    final recipientId = auth.user?.customUserId ?? '';
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await FoodRequestService.getMyRequests(
        token: token,
        recipientId: recipientId,
      );
      if (!mounted) return;
      setState(() => _requests = results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadRequests);
    }
    if (_requests.isEmpty) {
      return _EmptyState(
        icon: Icons.inbox_outlined,
        message: "You haven't made any food requests yet.",
        onRetry: _loadRequests,
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        itemCount: _requests.length,
        itemBuilder: (context, index) =>
            RequestCard(request: _requests[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REQUEST CARD (exported so my_food_requests_screen.dart can reuse it)
// ---------------------------------------------------------------------------

class RequestCard extends StatelessWidget {
  final FoodRequestModel request;
  const RequestCard({super.key, required this.request});

  Color _chipColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACCEPTED':
        return AppTheme.primaryGreen;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _chipLabel(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return '✓ Approved';
      case 'ACCEPTED':
        return '✓ Accepted';
      case 'REJECTED':
        return '✕ Rejected';
      default:
        return '⏳ Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _chipColor(request.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.foodItem,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _chipLabel(request.status),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _infoLine(
              Icons.scale_outlined, 'Qty: ${request.quantityRequested}'),
          if (request.deliveryAddress != null &&
              request.deliveryAddress!.isNotEmpty)
            _infoLine(
                Icons.location_on_outlined, request.deliveryAddress!),
          if (request.customRequestId != null)
            _infoLine(Icons.tag, 'ID: ${request.customRequestId}'),
          if (request.createdAt != null)
            _infoLine(Icons.access_time_outlined,
                _formatDate(request.createdAt!)),
          if (request.isRejected &&
              request.rejectionReason != null &&
              request.rejectionReason!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 15, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: ${request.rejectionReason}',
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.greyText),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppTheme.greyText)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ---------------------------------------------------------------------------
// SHARED HELPER WIDGETS
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  const _EmptyState(
      {required this.icon, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.border),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppTheme.greyText, fontSize: 15),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            label: const Text('Refresh',
                style: TextStyle(color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.greyText, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
