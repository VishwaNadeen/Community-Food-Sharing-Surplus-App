import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/food_request_model.dart';
import '../../services/food_request_service.dart';
import 'recipient_home_screen.dart' show RequestCard;

/// Standalone full-screen version of the "My Food Requests" list.
/// Can be reached via direct named route or push navigation.
class MyFoodRequestsScreen extends StatefulWidget {
  const MyFoodRequestsScreen({super.key});

  @override
  State<MyFoodRequestsScreen> createState() => _MyFoodRequestsScreenState();
}

class _MyFoodRequestsScreenState extends State<MyFoodRequestsScreen> {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'My Food Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.greyText),
            onPressed: _isLoading ? null : _loadRequests,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_error != null) {
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
                _error!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppTheme.greyText, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadRequests,
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

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: AppTheme.border),
            const SizedBox(height: 16),
            const Text(
              "You haven't made any food requests yet.",
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppTheme.greyText, fontSize: 15),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _loadRequests,
              icon:
                  const Icon(Icons.refresh, color: AppTheme.primaryGreen),
              label: const Text('Refresh',
                  style: TextStyle(color: AppTheme.primaryGreen)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _requests.length,
        itemBuilder: (context, index) =>
            RequestCard(request: _requests[index]),
      ),
    );
  }
}
