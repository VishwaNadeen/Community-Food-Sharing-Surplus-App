import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import '../../services/food_request_service.dart';
import '../../services/recipient_service.dart';
import '../../widgets/primary_button.dart';

enum _DeliveryChoice { saved, custom }

class SubmitFoodRequestScreen extends StatefulWidget {
  final DonationModel donation;
  final String token;

  const SubmitFoodRequestScreen({
    super.key,
    required this.donation,
    required this.token,
  });

  @override
  State<SubmitFoodRequestScreen> createState() =>
      _SubmitFoodRequestScreenState();
}

class _SubmitFoodRequestScreenState extends State<SubmitFoodRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Food item is fixed by the donation and cannot be edited by the user.
  late final TextEditingController _foodItemCtrl;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  static const int _notesMax = 300;

  bool _isLoading = false;

  // Saved delivery details (loaded from the user's account).
  bool _loadingDetails = true;
  String? _savedName;
  String? _savedAddress;
  String? _savedPhone;
  _DeliveryChoice _choice = _DeliveryChoice.custom;

  bool get _hasSaved => _savedAddress != null && _savedAddress!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _foodItemCtrl = TextEditingController(text: widget.donation.category);

    final available = widget.donation.quantity;
    _qtyCtrl.text = _fmt(available >= 1 ? 1 : available.toDouble());

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedDetails());
  }

  @override
  void dispose() {
    _foodItemCtrl.dispose();
    _qtyCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // SAVED DELIVERY DETAILS
  // ---------------------------------------------------------------------

  /// Loads the recipient's saved delivery details from the server
  /// (GET /api/recipients/profile).
  Future<void> _loadSavedDetails() async {
    String? name, address, phone;
    try {
      final profile = await RecipientService.getProfile(token: widget.token);

      final fullName = '${profile.firstName} ${profile.lastName}'.trim();
      name = fullName.isEmpty ? null : fullName;

      final parts = <String>[
        profile.addressLine1,
        profile.addressLine2 ?? '',
        profile.city,
        profile.district,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      address = parts.isEmpty ? null : parts.join(', ');

      final ph = profile.phoneNumber.trim();
      phone = ph.isEmpty ? null : ph;
    } catch (e) {
      debugPrint('Failed to load saved delivery details: $e');
    }

    if (!mounted) return;
    setState(() {
      _savedName = name;
      _savedAddress = address;
      _savedPhone = phone;
      _loadingDetails = false;
      _choice = _hasSaved ? _DeliveryChoice.saved : _DeliveryChoice.custom;
    });
  }

  // ---------------------------------------------------------------------
  // QUANTITY
  // ---------------------------------------------------------------------

  String _fmt(num v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  void _adjustQty(double delta) {
    final available = widget.donation.quantity.toDouble();
    final current = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final min = available >= 1 ? 1.0 : available;
    final next = (current + delta).clamp(min, available).toDouble();
    _qtyCtrl.text = _fmt(next);
    FocusScope.of(context).unfocus();
  }

  // ---------------------------------------------------------------------
  // NOTES
  // ---------------------------------------------------------------------

  // ---------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final useSaved = _choice == _DeliveryChoice.saved && _hasSaved;
    final address = useSaved ? _savedAddress! : _addressCtrl.text.trim();
    final phone = useSaved ? (_savedPhone ?? '') : _phoneCtrl.text.trim();

    final qty = double.parse(_qtyCtrl.text.trim());

    final data = <String, dynamic>{
      'foodItem': _foodItemCtrl.text.trim(),
      'quantityRequested': '${_fmt(qty)} ${widget.donation.quantityUnit}',
      'deliveryAddress': address,
      'donationId': widget.donation.id,
    };

    if (phone.isNotEmpty) {
      data['recipientContact'] = phone;
    }

    if (_notesCtrl.text.trim().isNotEmpty) {
      data['notes'] = _notesCtrl.text.trim();
    }

    setState(() => _isLoading = true);

    try {
      await FoodRequestService.submitRequest(
        token: widget.token,
        data: data,
      );

      if (!mounted) return;

      // Close only the Request Food screen.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final donation = widget.donation;

    final available =
        '${_fmt(donation.quantity)} ${donation.quantityUnit}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: AppTheme.darkText,
          ),
        ),
        title: const Text(
          'Request Food',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDonationCard(available),

              const SizedBox(height: 24),

              // ── Quantity ──
              _fieldLabel('Quantity needed'),
              const SizedBox(height: 8),
              _buildQuantityStepper(available),

              const SizedBox(height: 26),

              // ── 2. Delivery ──
              _sectionHeader(1, 'Delivery details',
                  'Where should the food be delivered?'),
              const SizedBox(height: 12),
              _buildDeliverySection(),

              const SizedBox(height: 26),

              // ── 3. Notes ──
              _sectionHeader(2, 'Additional notice', 'Optional – anything related to this order'),
              const SizedBox(height: 12),
              _buildNotes(),

              const SizedBox(height: 20),

              // ── Review notice ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryGreenDark,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your request will be reviewed by the NGO team. '
                        'You can track its status in My Requests.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      // ── Fixed submit bar ──
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _qtyCtrl,
                builder: (_, __) {
                  final q = double.tryParse(_qtyCtrl.text.trim());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Text(
                          'You are requesting',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.greyText,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          q == null
                              ? '-'
                              : '${_fmt(q)} ${donation.quantityUnit} of ${donation.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              PrimaryButton(
                text: 'Submit Food Request',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SECTIONS
  // ---------------------------------------------------------------------

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
        'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildDonationCard(String available) {
    final donation = widget.donation;
    final expiry = _formatDate(donation.expiryDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppTheme.lightGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: donation.imageUrl != null &&
                    donation.imageUrl!.trim().isNotEmpty
                ? Image.network(
                    donation.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _donationPlaceholder(),
                  )
                : _donationPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOU ARE REQUESTING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  donation.category,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 15, color: AppTheme.primaryGreenDark),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '$available available',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.event_available_outlined,
                        size: 15, color: Colors.orange.shade700),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Expires $expiry',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStepper(String available) {
    final max = widget.donation.quantity.toDouble();

    return Row(
      children: [
        _stepButton(Icons.remove_rounded, () => _adjustQty(-1)),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _qtyCtrl,
            textAlign: TextAlign.center,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
            decoration: _decoration(
              hint: '0',
              suffix: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  widget.donation.quantityUnit,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.greyText,
                  ),
                ),
              ),
            ),
            validator: (value) {
              final v = double.tryParse((value ?? '').trim());
              if (v == null || v <= 0) return 'Enter a valid quantity';
              if (v > max) return 'Only $available available';
              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        _stepButton(Icons.add_rounded, () => _adjustQty(1)),
      ],
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppTheme.lightGreen,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 54,
          child: Icon(icon, color: AppTheme.primaryGreenDark),
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    if (_loadingDetails) {
      return Container(
        height: 92,
        decoration: BoxDecoration(
          color: AppTheme.fieldFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_hasSaved) ...[
          _choiceCard(
            selected: _choice == _DeliveryChoice.saved,
            onTap: () => setState(() => _choice = _DeliveryChoice.saved),
            icon: Icons.home_rounded,
            title: 'Use my saved details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_savedName != null)
                  Text(
                    _savedName!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                const SizedBox(height: 4),
                _detailLine(Icons.location_on_outlined, _savedAddress!),
                const SizedBox(height: 3),
                _detailLine(
                  Icons.phone_outlined,
                  (_savedPhone != null && _savedPhone!.isNotEmpty)
                      ? _savedPhone!
                      : 'No phone number saved',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        _choiceCard(
          selected: _choice == _DeliveryChoice.custom || !_hasSaved,
          onTap: () => setState(() => _choice = _DeliveryChoice.custom),
          icon: Icons.add_location_alt_rounded,
          title: _hasSaved ? 'Deliver to a different address' : 'Delivery address',
          child: _choice == _DeliveryChoice.custom || !_hasSaved
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _addressCtrl,
                        minLines: 2,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.darkText),
                        decoration: _decoration(
                          hint: 'House no, street, city',
                          icon: Icons.location_on_outlined,
                        ),
                        validator: (value) {
                          if (_choice != _DeliveryChoice.custom && _hasSaved) {
                            return null;
                          }
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your delivery address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.darkText),
                        decoration: _decoration(
                          hint: 'Phone number for the delivery partner',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (_choice != _DeliveryChoice.custom && _hasSaved) {
                            return null;
                          }
                          final digits =
                              (value ?? '').replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 7 || digits.length > 15) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                )
              : const Text(
                  'Enter a one-time address and phone number.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.greyText),
                ),
        ),
      ],
    );
  }

  Widget _choiceCard({
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? AppTheme.primaryGreen : AppTheme.border,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon,
                        size: 20,
                        color: selected
                            ? AppTheme.primaryGreen
                            : AppTheme.greyText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 22,
                      color: selected
                          ? AppTheme.primaryGreen
                          : AppTheme.border,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: AppTheme.greyText),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppTheme.greyText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return TextFormField(
      controller: _notesCtrl,
      minLines: 4,
      maxLines: 6,
      maxLength: _notesMax,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontSize: 14, height: 1.45, color: AppTheme.darkText),
      decoration: _decoration(
        hint: 'Write anything related to this order, e.g. dietary needs, '
            'allergies, delivery instructions or a message for the NGO...',
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SMALL HELPERS
  // ---------------------------------------------------------------------

  InputDecoration _decoration({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
      prefixIcon:
          icon == null ? null : Icon(icon, size: 20, color: AppTheme.primaryGreen),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: border(AppTheme.border),
      enabledBorder: border(AppTheme.border),
      focusedBorder: border(AppTheme.primaryGreen, 1.5),
      errorBorder: border(Colors.red.shade400),
      focusedErrorBorder: border(Colors.red.shade400, 1.5),
    );
  }

  Widget _sectionHeader(int step, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _donationPlaceholder() {
    return const Center(
      child: Icon(Icons.restaurant, size: 30, color: AppTheme.primaryGreen),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.darkText,
      ),
    );
  }
}