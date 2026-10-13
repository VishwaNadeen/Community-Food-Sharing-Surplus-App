
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

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
  final _expiryDateController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _pickupDateTimeController = TextEditingController();

  String _selectedQuantityUnit = 'KG';

  DateTime? _expiryDate;
  DateTime? _pickupDateTime;

  XFile? _imageFile;
  bool _isLoading = false;

  static const List<String> _units = [
    'KG',
    'G',
    'LITRE',
    'ML',
    'PACKETS',
    'BOXES',
    'PIECES',
  ];

  bool get _isEditing => widget.donation != null;

  @override
  void initState() {
    super.initState();

    final donation = widget.donation;

    if (donation != null) {
      _categoryController.text = donation.category;
      _quantityController.text = donation.quantity.toString();
      _descriptionController.text = donation.description;
      _pickupLocationController.text = donation.pickupLocation;

      _selectedQuantityUnit = _units.contains(donation.quantityUnit)
          ? donation.quantityUnit
          : 'KG';

      _expiryDate = DateTime.tryParse(donation.expiryDate);
      _pickupDateTime = DateTime.tryParse(donation.pickupDateTime);

      if (_expiryDate != null) {
        _expiryDateController.text = _toIsoString(_expiryDate!);
      }

      if (_pickupDateTime != null) {
        _pickupDateTimeController.text =
            _toIsoString(_pickupDateTime!);
      }
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

  String _toIsoString(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final existingDate = _expiryDate?.toLocal();

    final initialDate = existingDate != null &&
            existingDate.isAfter(now)
        ? existingDate
        : now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryGreen,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      _expiryDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
      );

      _expiryDateController.text = _toIsoString(_expiryDate!);
    });
  }

  Future<void> _pickPickupDateTime() async {
    final now = DateTime.now();
    final existingDate = _pickupDateTime?.toLocal();

    final initialDate = existingDate != null &&
            !existingDate.isBefore(
              DateTime(now.year, now.month, now.day),
            )
        ? existingDate
        : now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryGreen,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null || !mounted) return;

    final initialTime = existingDate != null
        ? TimeOfDay.fromDateTime(existingDate)
        : TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryGreen,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _pickupDateTime = combined;
      _pickupDateTimeController.text = _toIsoString(combined);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      _imageFile = picked;
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    final quantity = double.tryParse(
      _quantityController.text.trim(),
    );

    if (quantity == null ||
        !quantity.isFinite ||
        quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be greater than zero.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final fields = <String, String>{
      'category': _categoryController.text.trim(),
      'quantity': quantity.toString(),
      'quantityUnit': _selectedQuantityUnit,
      'description': _descriptionController.text.trim(),
      'expiryDate': _expiryDateController.text.trim(),
      'pickupLocation': _pickupLocationController.text.trim(),
      'pickupDateTime': _pickupDateTimeController.text.trim(),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Donation updated successfully!'
                : 'Donation created successfully!',
          ),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${_isEditing ? 'update' : 'create'} donation: $error',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _flatDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppTheme.primaryGreen,
        size: 20,
      ),
      filled: true,
      fillColor: AppTheme.fieldFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.primaryGreen,
          width: 1.5,
        ),
      ),
      labelStyle: const TextStyle(
        color: AppTheme.greyText,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 12,
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(_imageFile!.path),
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    final imageUrl = widget.donation?.imageUrl;

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            height: 80,
            child: Center(
              child: Text('Unable to load existing image'),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Donation' : 'Create Donation',
          style: const TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppTheme.darkText,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              CustomTextField(
                controller: _categoryController,
                hint: 'Category (e.g. Vegetables)',
                prefixIcon: Icons.category_outlined,
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Category is required'
                        : null,
              ),
              const SizedBox(height: 16),

              // Quantity
              CustomTextField(
                controller: _quantityController,
                hint: 'Quantity',
                prefixIcon: Icons.scale_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Quantity is required';
                  }

                  final quantity = double.tryParse(value.trim());

                  if (quantity == null ||
                      !quantity.isFinite ||
                      quantity <= 0) {
                    return 'Enter a number greater than zero';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity unit
              DropdownButtonFormField<String>(
                initialValue: _selectedQuantityUnit,
                decoration: _flatDecoration(
                  'Quantity Unit',
                  Icons.straighten_outlined,
                ),
                items: _units
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedQuantityUnit = value;
                    });
                  }
                },
                validator: (value) =>
                    value == null ? 'Please select a unit' : null,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                hint: 'Description',
                prefixIcon: Icons.description_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }

                  if (value.trim().length < 5) {
                    return 'Description must be at least 5 characters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Expiry date
              TextFormField(
                controller: _expiryDateController,
                readOnly: true,
                onTap: _pickExpiryDate,
                decoration: _flatDecoration(
                  'Expiry Date',
                  Icons.calendar_today_outlined,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Expiry date is required'
                        : null,
              ),
              const SizedBox(height: 16),

              // Pickup location
              CustomTextField(
                controller: _pickupLocationController,
                hint: 'Pickup Location',
                prefixIcon: Icons.location_on_outlined,
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Pickup location is required'
                        : null,
              ),
              const SizedBox(height: 16),

              // Pickup date and time
              TextFormField(
                controller: _pickupDateTimeController,
                readOnly: true,
                onTap: _pickPickupDateTime,
                decoration: _flatDecoration(
                  'Pickup Date & Time',
                  Icons.access_time_outlined,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Pickup date & time is required'
                        : null,
              ),
              const SizedBox(height: 24),

              // Optional food image
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Food Image (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 16,
                            color: AppTheme.primaryGreen,
                          ),
                          label: const Text(
                            'Pick Image',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.primaryGreen,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_imageFile != null ||
                        (widget.donation?.imageUrl?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 12),
                      _buildImagePreview(),
                      if (_imageFile != null) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'New image selected',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                text: _isEditing
                    ? 'Save Changes'
                    : 'Create Donation',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
