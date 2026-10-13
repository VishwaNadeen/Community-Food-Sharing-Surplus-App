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

  @override

  Widget build(BuildContext context) {

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';

    if (_isLoading) {

      return const Center(

        child: CircularProgressIndicator(color: AppTheme.primaryGreen),

      );

    }

    if (_error != null) {

      return RecipientErrorState(message: _error!, onRetry: _loadRequests);

    }

    if (_requests.isEmpty) {

      return RecipientEmptyState(

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

        itemBuilder: (context, index) => RequestCard(

          request: _requests[index],

          token: token,

          onConfirmed: _loadRequests,

        ),

      ),

    );

  }

}

// ---------------------------------------------------------------------------

// REQUEST CARD

// ---------------------------------------------------------------------------
