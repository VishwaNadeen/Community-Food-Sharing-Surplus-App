
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import 'donor_ui.dart';

class CreateDonationScreen extends StatefulWidget {
  final DonationModel? donation;

  const CreateDonationScreen({
    super.key,
    this.donation,
  });

  @override
  State<CreateDonationScreen> createState() =>
      _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupLocationController = TextEditingController();

  // These only hold the friendly text shown in the read-only date fields.
  // The real values are kept in _expiryDate and _pickupDateTime.
  final _expiryDateController = TextEditingController();
  final _pickupDateTimeController = TextEditingController();

  String _selectedQuantityUnit = 'KG';

  DateTime? _expiryDate;
  DateTime? _pickupDateTime;

  XFile? _imageFile;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _submitAttempted = false;

  static const List<String> _suggestedCategories = [
    'Cooked meals',
    'Rice & grains',
    'Vegetables',
    'Fruits',
    'Bakery',
    'Dairy',
    'Packaged food',
    'Drinks',
  ];

  bool get _isEditing => widget.donation != null;

  /// Chip label for a unit: "kg", "L", "Packets"...
  static String _unitChipLabel(String unit) {
    final short = quantityUnitShortName(unit);
    return short.length > 2
        ? '${short[0].toUpperCase()}${short.substring(1)}'
        : short;
  }

  @override
  void initState() {
    super.initState();

    final donation = widget.donation;

    if (donation != null) {
      _categoryController.text = donation.category;
      _quantityController.text = donation.quantity ==
              donation.quantity.roundToDouble()
          ? donation.quantity.toInt().toString()
          : donation.quantity.toString();
      _descriptionController.text = donation.description;
      _pickupLocationController.text = donation.pickupLocation;

      _selectedQuantityUnit =
          kQuantityUnitNames.containsKey(donation.quantityUnit)
              ? donation.quantityUnit
              : 'KG';

      _expiryDate = DateTime.tryParse(donation.expiryDate)?.toLocal();
      _pickupDateTime =
          DateTime.tryParse(donation.pickupDateTime)?.toLocal();

      _syncDateFields();
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _expiryDateController.dispose();
    _pickupLocationController.dispose();
    _pickupDateTimeController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _syncDateFields() {
    _expiryDateController.text =
        _expiryDate == null ? '' : formatFriendlyDate(_expiryDate!);
    _pickupDateTimeController.text = _pickupDateTime == null
        ? ''
        : formatFriendlyDateTime(_pickupDateTime!);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppTheme.primaryGreen,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _pickExpiryDate() async {
    final today = _today;
    final existing = _expiryDate;

    final picked = await showDatePicker(
      context: context,
      helpText: 'When does this food expire?',
      // Past dates cannot be selected.
      initialDate: existing != null && !existing.isBefore(today)
          ? existing
          : today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: _pickerTheme,
    );

    if (picked == null) return;

    setState(() {
      // Food is treated as good until the end of the chosen day.
      _expiryDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
      _hasChanges = true;
      _syncDateFields();
    });

    // The pickup time may now be after the new expiry date.
    if (_submitAttempted) _formKey.currentState?.validate();
  }

  Future<void> _pickPickupDateTime() async {
    final today = _today;
    final existing = _pickupDateTime;

    // Pickup cannot be after the food expires.
    final lastDate = _expiryDate != null && !_expiryDate!.isBefore(today)
        ? DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day)
        : today.add(const Duration(days: 365));

    var initialDate =
        existing != null && !existing.isBefore(today) ? existing : today;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final pickedDate = await showDatePicker(
      context: context,
      helpText: 'Choose a pickup date',
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
      builder: _pickerTheme,
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      helpText: 'Choose a pickup time',
      initialTime: existing != null
          ? TimeOfDay.fromDateTime(existing)
          : TimeOfDay.fromDateTime(
              DateTime.now().add(const Duration(hours: 1)),
            ),
      builder: _pickerTheme,
    );

    if (pickedTime == null) return;

    setState(() {
      _pickupDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _hasChanges = true;
      _syncDateFields();
    });

    // Show a problem with the chosen time straight away.
    if (_submitAttempted) _formKey.currentState?.validate();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      setState(() {
        _imageFile = picked;
        _hasChanges = true;
      });
    } catch (_) {
      if (!mounted) return;
      showDonorError(
        context,
        'We could not open your photos. Allow photo access in your '
        'phone settings and try again.',
      );
    }
  }

  // ---------- Validation ----------

  String? _validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the type of food, or tap one of the suggestions.';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter how much food you are donating, for example 5.';
    }

    final quantity = double.tryParse(value.trim());

    if (quantity == null || !quantity.isFinite) {
      return 'Use numbers only, for example 5 or 2.5.';
    }

    if (quantity <= 0) {
      return 'The amount must be more than 0.';
    }

    return null;
  }

  String? _validateDescription(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Add a short description so recipients know what this is.';
    }

    if (text.length < 5) {
      return 'Add a little more detail (at least 5 letters).';
    }

    return null;
  }

  String? _validateExpiry(String? _) {
    if (_expiryDate == null) {
      return 'Tap here to choose the expiry date.';
    }

    if (_expiryDate!.isBefore(_today)) {
      return 'This date has already passed. Choose today or a later date.';
    }

    return null;
  }

  String? _validatePickupLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter where the volunteer should collect the food.';
    }
    return null;
  }

  String? _validatePickup(String? _) {
    final pickup = _pickupDateTime;

    if (pickup == null) {
      return 'Tap here to choose a pickup date and time.';
    }

    if (pickup.isBefore(DateTime.now())) {
      return 'This time has already passed. Choose a later time.';
    }

    if (_expiryDate != null && pickup.isAfter(_expiryDate!)) {
      return 'Pickup must be on or before the expiry date '
          '(${formatFriendlyDate(_expiryDate!)}).';
    }

    return null;
  }

  // ---------- Submit ----------

  Future<void> _submit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitAttempted = true);

    if (!_formKey.currentState!.validate()) {
      showDonorError(
        context,
        'Some details need fixing. Check the fields marked in red.',
      );
      return;
    }

    final quantity = double.parse(_quantityController.text.trim());

    setState(() => _isLoading = true);

    final fields = <String, String>{
      'category': _categoryController.text.trim(),
      'quantity': quantity.toString(),
      'quantityUnit': _selectedQuantityUnit,
      'description': _descriptionController.text.trim(),
      'expiryDate': _expiryDate!.toUtc().toIso8601String(),
      'pickupLocation': _pickupLocationController.text.trim(),
      'pickupDateTime': _pickupDateTime!.toUtc().toIso8601String(),
    };

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';

      final imageFile =
          _imageFile != null ? File(_imageFile!.path) : null;

      if (_isEditing) {
        await DonationService.updateDonation(
          token: token,
          id: widget.donation!.id,
          fields: fields,
          imageFile: imageFile,
        );
      } else {
        await DonationService.createDonation(
          token: token,
          fields: fields,
          imageFile: imageFile,
        );
      }

      if (!mounted) return;

      showDonorSuccess(
        context,
        _isEditing
            ? 'Your changes have been saved.'
            : 'Donation sent for review. You can follow its status '
                'in My Donations.',
      );

      setState(() => _hasChanges = false);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      showDonorError(
        context,
        '${_isEditing ? 'Your changes were not saved' : 'Your donation was not sent'}. '
        '${friendlyErrorMessage(error)}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBack() async {
    if (_isLoading) return;

    final leave = await confirmDonorAction(
      context,
      title: 'Discard changes?',
      message: _isEditing
          ? 'Your changes to this donation have not been saved.'
          : 'This donation has not been sent yet. If you leave now, '
              'what you entered will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );

    if (leave && mounted) {
      setState(() => _hasChanges = false);
      Navigator.pop(context);
    }
  }

  // ---------- UI ----------

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: DonorTextSize.section,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkText,
        ),
      ),
    );
  }

  Widget _buildCategorySuggestions() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: _suggestedCategories.map((category) {
        final selected =
            _categoryController.text.trim().toLowerCase() ==
                category.toLowerCase();

        return ChoiceChip(
          label: Text(category),
          selected: selected,
          showCheckmark: false,
          labelStyle: TextStyle(
            fontSize: DonorTextSize.small,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.primaryGreenDark,
          ),
          selectedColor: AppTheme.primaryGreen,
          backgroundColor: AppTheme.lightGreen,
          side: BorderSide.none,
          onSelected: (_) {
            setState(() {
              _categoryController.text = category;
              _hasChanges = true;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildImageSection() {
    final existingUrl = widget.donation?.imageUrl?.trim() ?? '';
    final hasImage = _imageFile != null || existingUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5DAD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Food photo (optional)',
            style: TextStyle(
              fontSize: DonorTextSize.body,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A clear photo helps recipients see what you are sharing.',
            style: TextStyle(
              fontSize: DonorTextSize.small,
              color: AppTheme.mutedText,
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 12),
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(_imageFile!.path),
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              DonationImage(url: existingUrl, height: 170, radius: 10),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  style: donorOutlinedButtonStyle(),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasImage ? 'Change photo' : 'Add photo'),
                ),
              ),
              if (_imageFile != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _imageFile = null),
                    style: donorOutlinedButtonStyle(
                      color: AppTheme.mutedText,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges && !_isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.fieldFill,
        appBar: donorAppBar(_isEditing ? 'Edit Donation' : 'New Donation'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitAttempted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'All fields are required unless marked optional.',
                    style: TextStyle(
                      fontSize: DonorTextSize.small,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _sectionLabel('What are you donating?'),
                  TextFormField(
                    controller: _categoryController,
                    style: kDonorFieldTextStyle,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: donorInputDecoration(
                      'Food type',
                      icon: Icons.category_outlined,
                      hint: 'e.g. Vegetables',
                    ),
                    onChanged: (_) => _markChanged(),
                    validator: _validateCategory,
                  ),
                  const SizedBox(height: 10),
                  _buildCategorySuggestions(),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _quantityController,
                    style: kDonorFieldTextStyle,
                    textInputAction: TextInputAction.next,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: donorInputDecoration(
                      'Amount',
                      icon: Icons.scale_outlined,
                      hint: 'e.g. 5',
                    ).copyWith(
                      // Shows the chosen unit, e.g. "5  kg".
                      suffixText: quantityUnitShortName(_selectedQuantityUnit),
                      suffixStyle: const TextStyle(
                        fontSize: DonorTextSize.body,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    onChanged: (_) => _markChanged(),
                    validator: _validateQuantity,
                  ),
                  const SizedBox(height: 14),

                  DonorChipSelector(
                    label: 'Unit',
                    value: _selectedQuantityUnit,
                    options: kQuantityUnitNames.keys
                        .map(
                          (unit) => DonorOption(
                            value: unit,
                            label: _unitChipLabel(unit),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedQuantityUnit = value;
                        _hasChanges = true;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    style: kDonorFieldTextStyle,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    decoration: donorInputDecoration(
                      'Description',
                      icon: Icons.description_outlined,
                      hint: 'e.g. Rice and curry for 10 people',
                    ),
                    onChanged: (_) => _markChanged(),
                    validator: _validateDescription,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _expiryDateController,
                    readOnly: true,
                    style: kDonorFieldTextStyle,
                    onTap: _pickExpiryDate,
                    decoration: donorInputDecoration(
                      'Expiry date',
                      icon: Icons.event_outlined,
                      hint: 'Tap to choose',
                      helper: 'The last day this food is safe to eat.',
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    validator: _validateExpiry,
                  ),
                  const SizedBox(height: 8),

                  _sectionLabel('Pickup details'),
                  TextFormField(
                    controller: _pickupLocationController,
                    style: kDonorFieldTextStyle,
                    textCapitalization: TextCapitalization.words,
                    decoration: donorInputDecoration(
                      'Pickup address',
                      icon: Icons.location_on_outlined,
                      hint: 'e.g. 12 Temple Road, Kandy',
                    ),
                    onChanged: (_) => _markChanged(),
                    validator: _validatePickupLocation,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _pickupDateTimeController,
                    readOnly: true,
                    style: kDonorFieldTextStyle,
                    onTap: _pickPickupDateTime,
                    decoration: donorInputDecoration(
                      'Pickup date and time',
                      icon: Icons.access_time_outlined,
                      hint: 'Tap to choose',
                      helper: 'Must be on or before the expiry date.',
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    validator: _validatePickup,
                  ),
                  const SizedBox(height: 24),

                  _buildImageSection(),
                  const SizedBox(height: 28),

                  PrimaryButton(
                    text: _isEditing ? 'Save Changes' : 'Submit Donation',
                    onPressed: _submit,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
