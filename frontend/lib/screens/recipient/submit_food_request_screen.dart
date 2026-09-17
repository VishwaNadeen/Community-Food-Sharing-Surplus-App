import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/donation_model.dart';
import '../../services/food_request_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

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

  late final TextEditingController _foodItemCtrl;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _foodItemCtrl =
        TextEditingController(text: widget.donation.category);
  }

  @override
  void dispose() {
    _foodItemCtrl.dispose();
    _qtyCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final recipientId = auth.user?.customUserId ?? '';

    final data = <String, dynamic>{
      'foodItem': _foodItemCtrl.text.trim(),
      'quantityRequested': _qtyCtrl.text.trim(),
      'deliveryAddress': _addressCtrl.text.trim(),
      'donationId': widget.donation.id,
      'recipientName': recipientId,
    };
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food request submitted successfully!'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
      // Pop back past both DonationDetailScreen and here
      Navigator.pop(context, true);
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
          'Request Food',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkText,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Donation summary banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_dining,
                        color: AppTheme.primaryGreen, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.donation.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            widget.donation.pickupLocation,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _sectionLabel('Food Item'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _foodItemCtrl,
                hint: 'e.g. Rice, Bread, Vegetables',
                prefixIcon: Icons.fastfood_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _sectionLabel('Quantity Requested'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _qtyCtrl,
                hint: 'e.g. 2 KG',
                prefixIcon: Icons.scale_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _sectionLabel('Delivery Address'),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _addressCtrl,
                hint: 'Enter your delivery address',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _sectionLabel('Notes (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(
                    fontSize: 15, color: AppTheme.darkText),
                decoration: InputDecoration(
                  hintText:
                      'Any special instructions or dietary needs…',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: AppTheme.fieldFill,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 0, 0),
                    child: Icon(Icons.notes_outlined,
                        color: AppTheme.primaryGreenDark, size: 20),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryGreen, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Submit Request',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Your request will be reviewed by our NGO team.',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppTheme.greyText),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppTheme.darkText,
      ),
    );
  }
}
