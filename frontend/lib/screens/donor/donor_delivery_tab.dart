import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/donor_delivery_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donor_delivery_service.dart';
import '../../theme/app_theme.dart';
import 'donor_ui.dart';

class DonorDeliveryTab extends StatefulWidget {
  /// Whether this tab is currently on screen. Automatic refresh only runs
  /// while it is, so hidden tabs do not keep calling the server.
  final bool isActive;

  const DonorDeliveryTab({super.key, this.isActive = true});

  @override
  State<DonorDeliveryTab> createState() => _DonorDeliveryTabState();
}

class _DonorDeliveryTabState extends State<DonorDeliveryTab> {
  // How often the delivery status is checked while the tab is open.
  static const Duration _refreshInterval = Duration(seconds: 30);

  List<DonorDeliveryModel> _deliveries = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  Timer? _refreshTimer;

  // Delivery steps in order, as shown in the progress list.
  static const List<(String status, String label, IconData icon)> _steps = [
    ('ACCEPTED', 'Volunteer accepted the delivery', Icons.how_to_reg),
    ('PICKED_UP', 'Food collected from you', Icons.inventory_2_outlined),
    ('IN_TRANSIT', 'Volunteer is on the way', Icons.local_shipping_outlined),
    ('DELIVERED', 'Delivered to the recipient', Icons.task_alt_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
    _updateRefreshTimer();
  }

  @override
  void didUpdateWidget(DonorDeliveryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) _updateRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = widget.isActive
        ? Timer.periodic(_refreshInterval, (_) => _loadDeliveries(silent: true))
        : null;
  }

  /// Loads the deliveries. A [silent] refresh (from the timer) keeps the
  /// current details on screen if it fails, instead of showing an error.
  Future<void> _loadDeliveries({bool silent = false}) async {
    if (!mounted || _isRefreshing) return;

    _isRefreshing = true;

    if (!silent) {
      setState(() {
        _isLoading = _deliveries.isEmpty;
        _error = null;
      });
    }

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';

      final deliveries = await DonorDeliveryService.getMyDeliveries(
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _deliveries = deliveries;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      if (silent && _deliveries.isNotEmpty) return;

      setState(() {
        _error = friendlyErrorMessage(e);
        _isLoading = false;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  // ---------- Small building blocks ----------

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: DonorTextSize.section,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value, {bool selectable = false}) {
    final text = (value == null || value.trim().isEmpty)
        ? 'Not provided'
        : value.trim();

    const valueStyle = TextStyle(
      fontSize: DonorTextSize.body,
      fontWeight: FontWeight.w600,
      color: AppTheme.darkText,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: DonorTextSize.body,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: selectable
                ? SelectableText(
                    text,
                    textAlign: TextAlign.end,
                    style: valueStyle,
                  )
                : Text(text, textAlign: TextAlign.end, style: valueStyle),
          ),
        ],
      ),
    );
  }

  /// Label, icon and colours for each delivery status.
  static ({String label, IconData icon, Color foreground, Color background})
  _statusStyle(String status) {
    return switch (status.toUpperCase()) {
      'ACCEPTED' => (
        label: 'Accepted',
        icon: Icons.how_to_reg,
        foreground: const Color(0xFF1E40AF),
        background: const Color(0xFFDBEAFE),
      ),
      'PICKED_UP' => (
        label: 'Picked up',
        icon: Icons.inventory_2_outlined,
        foreground: AppTheme.warning,
        background: AppTheme.warningLight,
      ),
      'IN_TRANSIT' => (
        label: 'On the way',
        icon: Icons.local_shipping_outlined,
        foreground: AppTheme.warning,
        background: AppTheme.warningLight,
      ),
      'DELIVERED' => (
        label: 'Delivered',
        icon: Icons.task_alt_rounded,
        foreground: AppTheme.primaryGreenDark,
        background: AppTheme.lightGreen,
      ),
      _ => (
        label: status,
        icon: Icons.info_outline,
        foreground: AppTheme.mutedText,
        background: const Color(0xFFE5E7EB),
      ),
    };
  }

  Widget _statusBadge(String status) {
    final style = _statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 16, color: style.foreground),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.foreground,
              fontSize: DonorTextSize.small,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress(String status) {
    final currentIndex = _steps.indexWhere(
      (step) => step.$1 == status.toUpperCase(),
    );

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  i <= currentIndex
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: i <= currentIndex
                      ? AppTheme.primaryGreen
                      : AppTheme.greyText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _steps[i].$2,
                    style: TextStyle(
                      fontSize: DonorTextSize.body,
                      fontWeight: i == currentIndex
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: i <= currentIndex
                          ? AppTheme.darkText
                          : AppTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _foodTitle(DonorDeliveryModel delivery) =>
      delivery.foodItem.isEmpty ? 'Food donation' : delivery.foodItem;

  // ---------- List row ----------

  /// Compact row: food item, delivery ID and status. Tap for details.
  Widget _deliveryTile(DonorDeliveryModel delivery) {
    final style = _statusStyle(delivery.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: () => _showDeliveryDetails(delivery),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: style.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.foreground),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _foodTitle(delivery),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: DonorTextSize.body,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Delivery ${delivery.reference}',
                      style: const TextStyle(
                        fontSize: DonorTextSize.small,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _statusBadge(delivery.status),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.greyText),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Details sheet ----------

  Future<void> _showDeliveryDetails(DonorDeliveryModel delivery) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _deliveryDetails(delivery),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
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
      ),
    );
  }

  Widget _deliveryDetails(DonorDeliveryModel delivery) {
    final volunteer = delivery.volunteer;
    final recipient = delivery.recipient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery ${delivery.reference}',
                    style: const TextStyle(
                      fontSize: DonorTextSize.small,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _foodTitle(delivery),
                    style: const TextStyle(
                      fontSize: DonorTextSize.title,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),
            ),
            _statusBadge(delivery.status),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 16),

        // Volunteer
        _sectionTitle('Volunteer', Icons.person_outline),
        if (volunteer == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Volunteer details are not available yet.',
              style: TextStyle(
                fontSize: DonorTextSize.body,
                color: AppTheme.mutedText,
              ),
            ),
          )
        else ...[
          _infoRow('Name', volunteer.fullName),
          _infoRow('Phone', volunteer.phoneNumber, selectable: true),
          _infoRow('Email', volunteer.email, selectable: true),
          _infoRow('Vehicle', volunteer.vehicle),
        ],
        const SizedBox(height: 4),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 16),

        // Food
        _sectionTitle('Food', Icons.fastfood_outlined),
        _infoRow('Food item', delivery.foodItem),
        _infoRow('Quantity', formatQuantity(delivery.foodQuantityKg, 'KG')),
        _infoRow(
          'Expiry date',
          delivery.foodExpiryDate == null
              ? null
              : formatFriendlyDateTime(delivery.foodExpiryDate!),
        ),
        const SizedBox(height: 4),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 16),

        // Route
        _sectionTitle('Delivery', Icons.route_outlined),
        _infoRow('Pickup address', delivery.pickupAddress),
        _infoRow(
          'Recipient',
          recipient == null
              ? null
              : [
                  recipient.name,
                  recipient.area,
                ].where((part) => part.isNotEmpty).join('\n'),
        ),
        _infoRow('Delivery address', delivery.dropoffAddress),
        if (delivery.distanceKm != null)
          _infoRow('Distance', '${delivery.distanceKm!.toStringAsFixed(1)} km'),
        if (delivery.acceptedAt != null)
          _infoRow('Accepted on', formatFriendlyDateTime(delivery.acceptedAt!)),
        const SizedBox(height: 4),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 16),

        // Progress
        _sectionTitle('Delivery Status', Icons.timeline_outlined),
        _progress(delivery.status),
      ],
    );
  }

  // ---------- Page ----------

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Delivery',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'See who is collecting your food and where it is going.',
          style: TextStyle(
            fontSize: DonorTextSize.body,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const DonorLoadingView(message: 'Loading your deliveries...');
    }

    if (_error != null) {
      return DonorMessageView.error(
        title: 'Could not load your deliveries',
        message: _error!,
        onAction: () {
          setState(() => _isLoading = true);
          _loadDeliveries();
        },
      );
    }

    if (_deliveries.isEmpty) {
      return const DonorMessageView(
        icon: Icons.local_shipping_outlined,
        title: 'No accepted deliveries yet',
        message:
            'When a volunteer accepts one of your donations, their '
            'details will appear here. Pull down to refresh.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _deliveries.length,
      itemBuilder: (_, index) => _deliveryTile(_deliveries[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.fieldFill,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: _header(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDeliveries,
                color: AppTheme.primaryGreen,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
