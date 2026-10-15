import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import 'submit_food_request_screen.dart';

class _Expiry {
  final String text;
  final bool urgent;
  const _Expiry(this.text, this.urgent);
}

class DonationDetailScreen extends StatelessWidget {
  final DonationModel donation;
  final String token;

  const DonationDetailScreen({
    super.key,
    required this.donation,
    required this.token,
  });

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${_months[dt.month]} ${dt.year} • $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day} ${_months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  // Friendly countdown derived from the expiry date, e.g. "3 days left".
  // Returns null when the date can't be parsed.
  _Expiry? _expiryHint(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final days = DateTime(dt.year, dt.month, dt.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (days < 0) return const _Expiry('Expired', true);
      if (days == 0) return const _Expiry('Expires today', true);
      if (days == 1) return const _Expiry('Expires tomorrow', true);
      return _Expiry('$days days left', days <= 2);
    } catch (_) {
      return null;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'APPROVED':
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

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'APPROVED':
        return 'Available';
      case 'COLLECTED':
        return 'Collected';
      case 'CANCELLED':
        return 'Cancelled';
      case 'EXPIRED':
        return 'Expired';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final qtyDisplay =
        '${donation.quantity % 1 == 0 ? donation.quantity.toInt() : donation.quantity} ${donation.quantityUnit}';

    final claimable = donation.isClaimable;
    final statusColor = _statusColor(donation.status);
    final expiry = _expiryHint(donation.expiryDate);
    final expiryColor =
        (expiry?.urgent ?? false) ? Colors.orange.shade800 : AppTheme.darkText;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      body: CustomScrollView(
        slivers: [
          // ── Collapsing hero image ──
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: _roundIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
            title: const Text(
              'Donation Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildFoodImage(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Colors.transparent,
                          Color(0x99000000),
                        ],
                        stops: [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroStatusPill(
                          _statusLabel(donation.status),
                          statusColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          donation.category,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 27,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Key facts at a glance ──
                IntrinsicHeight(
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _factTile(
                        icon: Icons.inventory_2_outlined,
                        label: 'Quantity',
                        value: qtyDisplay,
                        iconColor: AppTheme.primaryGreen,
                        iconBackground: AppTheme.lightGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _factTile(
                        icon: Icons.timer_outlined,
                        label: 'Expiry',
                        value: expiry?.text ?? _formatDate(donation.expiryDate),
                        valueColor: expiryColor,
                        iconColor: Colors.orange.shade700,
                        iconBackground: const Color(0xFFFFF3E0),
                      ),
                    ),
                  ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Availability message ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: claimable
                        ? AppTheme.lightGreen
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: claimable
                          ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        claimable
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        size: 20,
                        color: claimable
                            ? AppTheme.primaryGreen
                            : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          claimable
                              ? 'This donation is available. Submit a food request before it expires.'
                              : 'This donation is no longer available for claiming.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.5,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── Pickup ──
                _sectionTitle('Pickup'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      _detailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: donation.pickupLocation,
                        trailing: donation.pickupLocation.trim().isEmpty
                            ? null
                            : Builder(
                                builder: (ctx) => IconButton(
                                  tooltip: 'Copy address',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: donation.pickupLocation));
                                    ScaffoldMessenger.of(ctx)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(const SnackBar(
                                        content: Text('Address copied'),
                                        duration: Duration(seconds: 2),
                                      ));
                                  },
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                    color: AppTheme.greyText,
                                  ),
                                ),
                              ),
                      ),
                      _rowDivider(),
                      _detailRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Date & time',
                        value: _formatDateTime(donation.pickupDateTime),
                      ),
                      _rowDivider(),
                      _detailRow(
                        icon: Icons.event_available_outlined,
                        label: 'Expiry date',
                        value: _formatDate(donation.expiryDate),
                        iconColor: Colors.orange.shade700,
                        iconBackground: const Color(0xFFFFF3E0),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── Description ──
                _sectionTitle('About this donation'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: _cardDecoration(),
                  child: Text(
                    donation.description.trim().isNotEmpty
                        ? donation.description
                        : 'No description provided for this donation.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: AppTheme.greyText,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ]),
            ),
          ),
        ],
      ),

      // ── Fixed claim bar ──
      bottomNavigationBar: claimable
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Reminder of what is being claimed.
                    Flexible(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            qtyDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            expiry?.text ?? 'Available',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: (expiry?.urgent ?? false)
                                  ? Colors.orange.shade800
                                  : AppTheme.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () async {
                            final claimed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubmitFoodRequestScreen(
                                  donation: donation,
                                  token: token,
                                ),
                              ),
                            );

                            if (claimed == true && context.mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.volunteer_activism_outlined,
                                  size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Claim This Food',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------
  // PIECES
  // ---------------------------------------------------------------------

  Widget _buildFoodImage() {
    final imageUrl = donation.imageUrl?.trim() ?? '';

    if (imageUrl.isEmpty) {
      return Container(
        color: AppTheme.lightGreen,
        child: const Center(
          child: Icon(
            Icons.restaurant,
            size: 70,
            color: AppTheme.primaryGreen,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Container(
          color: AppTheme.lightGreen,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.lightGreen,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 55,
              color: AppTheme.greyText,
            ),
          ),
        );
      },
    );
  }

  Widget _heroStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color iconBackground,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.30),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppTheme.darkText,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppTheme.border.withValues(alpha: 0.7),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _rowDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Divider(
        height: 1,
        color: AppTheme.border.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? iconBackground,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBackground ?? AppTheme.lightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppTheme.primaryGreen,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.greyText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value.trim().isNotEmpty ? value : 'Not provided',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}