import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/donation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
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

  String _toIsoString(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final mo = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final mi = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return '$y-$mo-${d}T$h:$mi:$s.000Z';
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryGreen,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _expiryDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 0);
      _expiryDateController.text = _toIsoString(_expiryDate!);
    });
  }

  Future<void> _pickPickupDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryGreen,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
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
      _pickupDateTimeController.text = _toIsoString(_pickupDateTime!);
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final fields = {
      'category': _categoryController.text.trim(),
      'quantity': _quantityController.text.trim(),
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
      await DonationService.createDonation(
        token: token,
        fields: fields,
        imageFile: imageFile,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Donation created successfully!'),
          backgroundColor: AppTheme.primaryGreenDark,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create donation: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _flatDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
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
        borderSide:
            const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppTheme.greyText, fontSize: 14),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: const Text(
          'Create Donation',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkText),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Category is required' : null,
              ),
              const SizedBox(height: 16),

              // Quantity
              CustomTextField(
                controller: _quantityController,
                hint: 'Quantity',
                prefixIcon: Icons.scale_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Quantity is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity Unit dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedQuantityUnit,
                decoration: _flatDecoration('Quantity Unit', Icons.straighten_outlined),
                items: _units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedQuantityUnit = val);
                  }
                },
                validator: (v) =>
                    v == null ? 'Please select a unit' : null,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                hint: 'Description',
                prefixIcon: Icons.description_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),

              // Expiry Date
              TextFormField(
                controller: _expiryDateController,
                readOnly: true,
                onTap: _pickExpiryDate,
                decoration: _flatDecoration('Expiry Date', Icons.calendar_today_outlined),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Expiry date is required' : null,
              ),
              const SizedBox(height: 16),

              // Pickup Location
              CustomTextField(
                controller: _pickupLocationController,
                hint: 'Pickup Location',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Pickup location is required' : null,
              ),
              const SizedBox(height: 16),

              // Pickup Date & Time
              TextFormField(
                controller: _pickupDateTimeController,
                readOnly: true,
                onTap: _pickPickupDateTime,
                decoration: _flatDecoration(
                    'Pickup Date & Time', Icons.access_time_outlined),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Pickup date & time is required' : null,
              ),
              const SizedBox(height: 24),

              // Image picker
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
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 16, color: AppTheme.primaryGreen),
                          label: const Text(
                            'Pick Image',
                            style: TextStyle(color: AppTheme.primaryGreen),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppTheme.primaryGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_imageFile!.path),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                text: 'Create Donation',
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
