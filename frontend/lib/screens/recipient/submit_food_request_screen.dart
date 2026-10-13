
import 'package:flutter/material.dart';

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

class _SubmitFoodRequestScreenState
    extends State<SubmitFoodRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _foodItemCtrl;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _foodItemCtrl = TextEditingController(
      text: widget.donation.category,
    );
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
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'foodItem': _foodItemCtrl.text.trim(),
      'quantityRequested': _qtyCtrl.text.trim(),
      'deliveryAddress': _addressCtrl.text.trim(),
      'donationId': widget.donation.id,
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

      // Close only the Claim Food screen.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donation = widget.donation;

    final quantity =
        '${donation.quantity % 1 == 0 ? donation.quantity.toInt() : donation.quantity} ${donation.quantityUnit}';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
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
          'Claim Food',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkText,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppTheme.border,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction.
              const Text(
                'Request a food donation',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Complete the details below to request this donation.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.greyText,
                ),
              ),

              const SizedBox(height: 22),

              // Selected donation summary.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.025),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: donation.imageUrl != null &&
                              donation.imageUrl!.trim().isNotEmpty
                          ? Image.network(
                              donation.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _donationPlaceholder(),
                            )
                          : _donationPlaceholder(),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SELECTED DONATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: AppTheme.greyText,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            donation.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkText,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  donation.pickupLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.greyText,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Available: $quantity',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Form section heading.
              const Text(
                'Your request details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkText,
                ),
              ),

              const SizedBox(height: 18),

              // Food item.
              _fieldLabel('Food item'),
              const SizedBox(height: 8),

              CustomTextField(
                controller: _foodItemCtrl,
                hint: 'e.g. Rice, Bread, Vegetables',
                prefixIcon: Icons.restaurant_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the food item';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Requested quantity.
              _fieldLabel('Quantity requested'),
              const SizedBox(height: 8),

              CustomTextField(
                controller: _qtyCtrl,
                hint: 'e.g. 2 KG',
                prefixIcon: Icons.scale_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Delivery address.
              _fieldLabel('Delivery address'),
              const SizedBox(height: 8),

              CustomTextField(
                controller: _addressCtrl,
                hint: 'Enter your delivery address',
                prefixIcon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your delivery address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Optional notes.
              _fieldLabel('Additional notes'),
              const SizedBox(height: 5),

              const Text(
                'Optional',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.greyText,
                ),
              ),

              const SizedBox(height: 9),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkText,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Dietary needs or special instructions...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(
                      left: 14,
                      right: 10,
                      bottom: 64,
                    ),
                    child: Icon(
                      Icons.notes_rounded,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 45,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Request review notice.
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

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),

      // Fixed submit action.
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
          child: PrimaryButton(
            text: 'Submit Food Request',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _submit,
          ),
        ),
      ),
    );
  }

  Widget _donationPlaceholder() {
    return const Center(
      child: Icon(
        Icons.restaurant,
        size: 28,
        color: AppTheme.primaryGreen,
      ),
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
