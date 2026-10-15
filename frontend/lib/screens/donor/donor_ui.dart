import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

// ============================================================
// Shared building blocks for the donor screens.
// Keeping colours, wording, text sizes and feedback states in one
// place makes every donor screen look and behave the same way.
// ============================================================

/// Text sizes used across the donor screens.
/// Body text never goes below 16; 14 is only used for small labels
/// such as status badges and field captions.
class DonorTextSize {
  static const double small = 14;
  static const double body = 16;
  static const double section = 18;
  static const double title = 22;
}

/// Minimum height for anything the user taps.
const double kDonorTapHeight = 48;

// ------------------------------------------------------------
// Donation status: one label, icon and colour pair per status.
// ------------------------------------------------------------

class DonationStatusStyle {
  final String label;
  final String description;
  final IconData icon;
  final Color background;
  final Color foreground;

  const DonationStatusStyle({
    required this.label,
    required this.description,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  static DonationStatusStyle of(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const DonationStatusStyle(
          label: 'Pending',
          description: 'Waiting for review. You can still edit or cancel it.',
          icon: Icons.hourglass_top_rounded,
          background: AppTheme.warningLight,
          foreground: AppTheme.warning,
        );
      case 'APPROVED':
        return const DonationStatusStyle(
          label: 'Approved',
          description: 'Approved and ready to be shared.',
          icon: Icons.check_circle_outline,
          background: Color(0xFFD1FAE5),
          foreground: Color(0xFF166534),
        );
      case 'AVAILABLE':
        return const DonationStatusStyle(
          label: 'Available',
          description: 'Listed and available for recipients.',
          icon: Icons.check_circle_outline,
          background: Color(0xFFD1FAE5),
          foreground: Color(0xFF166534),
        );
      case 'REJECTED':
        return const DonationStatusStyle(
          label: 'Rejected',
          description: 'This donation was not accepted.',
          icon: Icons.cancel_outlined,
          background: AppTheme.dangerLight,
          foreground: AppTheme.danger,
        );
      case 'CANCELLED':
        return const DonationStatusStyle(
          label: 'Cancelled',
          description: 'You cancelled this donation.',
          icon: Icons.block_outlined,
          background: Color(0xFFE5E7EB),
          foreground: Color(0xFF374151),
        );
      case 'COLLECTED':
        return const DonationStatusStyle(
          label: 'Collected',
          description: 'The food has been picked up. Thank you!',
          icon: Icons.task_alt_rounded,
          background: Color(0xFFDBEAFE),
          foreground: Color(0xFF1E40AF),
        );
      case 'EXPIRED':
        return const DonationStatusStyle(
          label: 'Expired',
          description: 'The expiry date has passed.',
          icon: Icons.event_busy_outlined,
          background: Color(0xFFFFEDD5),
          foreground: Color(0xFF9A3412),
        );
      default:
        return DonationStatusStyle(
          label: status.isEmpty
              ? 'Unknown'
              : '${status[0].toUpperCase()}'
                    '${status.substring(1).toLowerCase()}',
          description: '',
          icon: Icons.info_outline,
          background: const Color(0xFFE5E7EB),
          foreground: const Color(0xFF374151),
        );
    }
  }
}

class DonationStatusBadge extends StatelessWidget {
  final String status;

  const DonationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = DonationStatusStyle.of(status);

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
              fontSize: DonorTextSize.small,
              fontWeight: FontWeight.w700,
              color: style.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Quantity units: stored codes and friendly names.
// ------------------------------------------------------------

const Map<String, String> kQuantityUnitNames = {
  'KG': 'Kilograms (kg)',
  'G': 'Grams (g)',
  'LITRE': 'Litres (L)',
  'ML': 'Millilitres (ml)',
  'PACKETS': 'Packets',
  'BOXES': 'Boxes',
  'PIECES': 'Pieces',
};

const Map<String, String> _quantityUnitShort = {
  'KG': 'kg',
  'G': 'g',
  'LITRE': 'L',
  'ML': 'ml',
  'PACKETS': 'packets',
  'BOXES': 'boxes',
  'PIECES': 'pieces',
};

/// Short unit name, e.g. "kg" for KG or "packets" for PACKETS.
String quantityUnitShortName(String unit) =>
    _quantityUnitShort[unit.toUpperCase()] ?? unit;

/// Formats a quantity such as "10 kg" or "2.5 L".
String formatQuantity(double quantity, String unit) {
  final amount = quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();

  final unitName = quantityUnitShortName(unit);

  return '$amount $unitName';
}

// ------------------------------------------------------------
// Dates
// ------------------------------------------------------------

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Tue, 14 Oct 2026"
String formatFriendlyDate(DateTime date) {
  final local = date.toLocal();

  return '${_weekdays[local.weekday - 1]}, '
      '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// "14 Oct", or "14 Oct 2027" when the date is not in the current year.
/// Used where space is tight, such as grid cards.
String formatShortDate(DateTime date) {
  final local = date.toLocal();
  final dayMonth = '${local.day} ${_months[local.month - 1]}';

  return local.year == DateTime.now().year
      ? dayMonth
      : '$dayMonth ${local.year}';
}

/// "4:30 PM"
String formatFriendlyTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');

  return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
}

/// "Tue, 14 Oct 2026 at 4:30 PM"
String formatFriendlyDateTime(DateTime date) =>
    '${formatFriendlyDate(date)} at ${formatFriendlyTime(date)}';

/// Formats an ISO date string from the API, keeping the raw value
/// if it cannot be parsed.
String formatApiDate(String value, {bool withTime = false}) {
  final date = DateTime.tryParse(value);

  if (date == null) return value;

  return withTime ? formatFriendlyDateTime(date) : formatFriendlyDate(date);
}

// ------------------------------------------------------------
// Error messages
// ------------------------------------------------------------

const String kNetworkErrorMessage =
    'We could not reach the server. Check your internet connection '
    'and try again.';

const String kServerErrorMessage =
    'Something went wrong on our side. Please try again in a few minutes.';

const String kSessionErrorMessage =
    'Your session has expired. Please log out and log in again.';

/// Turns an exception into a short, plain message that tells the
/// donor what to do next. Validation messages from the server are
/// already written for people, so they are passed through.
String friendlyErrorMessage(Object error) {
  if (error is SocketException || error is TimeoutException) {
    return kNetworkErrorMessage;
  }

  final message = error
      .toString()
      .replaceFirst(RegExp(r'^(Exception|ClientException):\s*'), '')
      .trim();

  final lower = message.toLowerCase();

  if (lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('connection refused') ||
      lower.contains('connection closed') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('timed out')) {
    return kNetworkErrorMessage;
  }

  if (lower.contains('unauthorized') ||
      lower.contains('invalid token') ||
      lower.contains('token expired') ||
      lower.contains('jwt') ||
      lower.contains('no token')) {
    return kSessionErrorMessage;
  }

  if (message.isEmpty ||
      lower.contains('non-json') ||
      lower.contains('empty response') ||
      lower.contains('unexpected response') ||
      lower.contains('internal server') ||
      lower.contains('invalid donation') ||
      lower.contains('formatexception') ||
      lower.contains('http 5')) {
    return kServerErrorMessage;
  }

  return message;
}

// ------------------------------------------------------------
// Snackbars and confirmation dialogs
// ------------------------------------------------------------

void showDonorSuccess(BuildContext context, String message) {
  _showDonorSnackBar(
    context,
    message: message,
    icon: Icons.check_circle_outline,
    color: AppTheme.primaryGreenDark,
    duration: const Duration(seconds: 3),
  );
}

void showDonorError(BuildContext context, String message) {
  _showDonorSnackBar(
    context,
    message: message,
    icon: Icons.error_outline,
    color: AppTheme.danger,
    duration: const Duration(seconds: 6),
  );
}

void _showDonorSnackBar(
  BuildContext context, {
  required String message,
  required IconData icon,
  required Color color,
  required Duration duration,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: DonorTextSize.body,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Asks the donor to confirm an action. Returns true only when the
/// confirm button is tapped.
Future<bool> confirmDonorAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Go back',
  bool isDestructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: DonorTextSize.section,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkText,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: DonorTextSize.body,
          height: 1.4,
          color: AppTheme.darkText,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(
            minimumSize: const Size(64, kDonorTapHeight),
            foregroundColor: AppTheme.darkText,
            textStyle: const TextStyle(fontSize: DonorTextSize.body),
          ),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, kDonorTapHeight),
            backgroundColor: isDestructive
                ? AppTheme.danger
                : AppTheme.primaryGreen,
            textStyle: const TextStyle(
              fontSize: DonorTextSize.body,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed == true;
}

// ------------------------------------------------------------
// Buttons
// ------------------------------------------------------------

ButtonStyle donorOutlinedButtonStyle({Color color = AppTheme.primaryGreen}) {
  return OutlinedButton.styleFrom(
    foregroundColor: color,
    minimumSize: const Size(64, kDonorTapHeight),
    side: BorderSide(color: color, width: 1.4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(
      fontSize: DonorTextSize.body,
      fontWeight: FontWeight.w600,
    ),
  );
}

ButtonStyle donorFilledButtonStyle({Color color = AppTheme.primaryGreen}) {
  return FilledButton.styleFrom(
    backgroundColor: color,
    foregroundColor: Colors.white,
    minimumSize: const Size(64, kDonorTapHeight),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(
      fontSize: DonorTextSize.body,
      fontWeight: FontWeight.w600,
    ),
  );
}

// ------------------------------------------------------------
// Form fields
// ------------------------------------------------------------

InputDecoration donorInputDecoration(
  String label, {
  IconData? icon,
  String? hint,
  String? helper,
  Widget? suffixIcon,
}) {
  OutlineInputBorder outline(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    errorMaxLines: 3,
    prefixIcon: icon == null ? null : Icon(icon, color: AppTheme.primaryGreen),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(
      fontSize: DonorTextSize.body,
      color: AppTheme.mutedText,
    ),
    hintStyle: const TextStyle(
      fontSize: DonorTextSize.body,
      color: AppTheme.greyText,
    ),
    helperStyle: const TextStyle(
      fontSize: DonorTextSize.small,
      color: AppTheme.mutedText,
    ),
    errorStyle: const TextStyle(
      fontSize: DonorTextSize.small,
      color: AppTheme.danger,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: outline(AppTheme.border),
    enabledBorder: outline(const Color(0xFFD5DAD8)),
    focusedBorder: outline(AppTheme.primaryGreen, 1.6),
    errorBorder: outline(AppTheme.danger),
    focusedErrorBorder: outline(AppTheme.danger, 1.6),
  );
}

const TextStyle kDonorFieldTextStyle = TextStyle(
  fontSize: DonorTextSize.body,
  color: AppTheme.darkText,
);

// ------------------------------------------------------------
// Feedback states: loading, empty and error
// ------------------------------------------------------------

class DonorLoadingView extends StatelessWidget {
  final String message;

  const DonorLoadingView({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: DonorTextSize.body,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// A centred icon, title, message and optional button. Used for both
/// empty screens and error screens. It is always scrollable so it can
/// sit inside a RefreshIndicator.
class DonorMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool isError;

  const DonorMessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.isError = false,
  });

  const DonorMessageView.error({
    super.key,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel = 'Try again',
  }) : icon = Icons.wifi_off_rounded,
       actionIcon = Icons.refresh,
       isError = true;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.danger : AppTheme.primaryGreen;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: DonorTextSize.section,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: DonorTextSize.body,
                      height: 1.4,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: onAction,
                      style: donorFilledButtonStyle(),
                      icon: Icon(actionIcon ?? Icons.add),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Donation image and detail rows
// ------------------------------------------------------------

class DonationImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double height;
  final double radius;

  const DonationImage({
    super.key,
    required this.url,
    this.width,
    required this.height,
    this.radius = 12,
  });

  Widget _placeholder(IconData icon) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      color: AppTheme.lightGreen,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: height > 120 ? 44 : 30,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl.isEmpty
          ? _placeholder(Icons.fastfood_outlined)
          : Image.network(
              imageUrl,
              width: width ?? double.infinity,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _placeholder(Icons.image_outlined),
              errorBuilder: (_, _, _) =>
                  _placeholder(Icons.broken_image_outlined),
            ),
    );
  }
}

/// Label above value, so long values wrap without squeezing the label.
class DonorDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DonorDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: DonorTextSize.small,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    fontSize: DonorTextSize.body,
                    height: 1.35,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard white app bar used by donor pages.
PreferredSizeWidget donorAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        color: AppTheme.darkText,
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.white,
    elevation: 0,
    iconTheme: const IconThemeData(color: AppTheme.darkText),
    actions: actions,
  );
}

// ------------------------------------------------------------
// Selection fields (used instead of plain dropdowns)
// ------------------------------------------------------------

/// One choice in a [DonorPickerField], [DonorChoiceCards] or
/// [DonorChipSelector].
class DonorOption {
  final String value;
  final String label;
  final String? description;
  final IconData? icon;

  const DonorOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });
}

/// A form field that opens a bottom sheet to pick one option.
///
/// Easier to use than a small dropdown menu: large rows, a tick on the
/// current choice, and a search box when the list is long. When there is
/// nothing to choose yet it is shown as locked with [disabledHint].
class DonorPickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<DonorOption> options;
  final ValueChanged<String> onChanged;
  final String requiredMessage;
  final String? disabledHint;
  final String? sheetTitle;

  /// Show a search box when there are more options than this.
  final int searchThreshold;

  const DonorPickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.requiredMessage,
    this.disabledHint,
    this.sheetTitle,
    this.searchThreshold = 6,
  });

  bool get _enabled => options.isNotEmpty;

  String? get _selectedLabel {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return null;
  }

  Future<void> _openSheet(
    BuildContext context,
    FormFieldState<String> field,
  ) async {
    FocusScope.of(context).unfocus();

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DonorOptionSheet(
        title: sheetTitle ?? 'Choose ${label.toLowerCase()}',
        options: options,
        selected: value,
        showSearch: options.length > searchThreshold,
      ),
    );

    if (picked != null && picked != value) {
      field.didChange(picked);
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      // The key rebuilds the field when the value is changed from outside
      // (for example, district cleared after a new province is chosen).
      key: ValueKey('$label-$value-${options.length}'),
      initialValue: value,
      validator: (_) => value == null ? requiredMessage : null,
      builder: (field) {
        final selectedLabel = _selectedLabel;

        return Semantics(
          button: true,
          enabled: _enabled,
          label: label,
          value: selectedLabel,
          child: InkWell(
            onTap: _enabled ? () => _openSheet(context, field) : null,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              isEmpty: selectedLabel == null,
              decoration:
                  donorInputDecoration(
                    label,
                    icon: _enabled ? icon : Icons.lock_outline,
                    hint: _enabled ? 'Tap to choose' : disabledHint,
                    suffixIcon: Icon(
                      Icons.expand_more,
                      color: _enabled ? AppTheme.darkText : AppTheme.greyText,
                    ),
                  ).copyWith(
                    errorText: field.errorText,
                    fillColor: _enabled ? Colors.white : AppTheme.fieldFill,
                    // Keep the label up so the hint explaining why the field
                    // is locked is always visible.
                    floatingLabelBehavior: _enabled
                        ? FloatingLabelBehavior.auto
                        : FloatingLabelBehavior.always,
                  ),
              child: selectedLabel == null
                  ? null
                  : Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kDonorFieldTextStyle,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _DonorOptionSheet extends StatefulWidget {
  final String title;
  final List<DonorOption> options;
  final String? selected;
  final bool showSearch;

  const _DonorOptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.showSearch,
  });

  @override
  State<_DonorOptionSheet> createState() => _DonorOptionSheetState();
}

class _DonorOptionSheetState extends State<_DonorOptionSheet> {
  String _query = '';

  List<DonorOption> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.options;

    return widget.options
        .where((option) => option.label.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final media = MediaQuery.of(context);

    return Padding(
      // Keep the sheet above the keyboard while searching.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      // A Material (not a decorated Container) so the list rows' tap
      // ripple and selected highlight are visible.
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.75),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: DonorTextSize.section,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                if (widget.showSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      style: kDonorFieldTextStyle,
                      textInputAction: TextInputAction.search,
                      onChanged: (text) => setState(() => _query = text),
                      decoration: donorInputDecoration(
                        'Search',
                        icon: Icons.search,
                      ).copyWith(fillColor: AppTheme.fieldFill),
                    ),
                  ),
                const Divider(height: 1, color: AppTheme.border),
                Flexible(
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            'No matches. Try a different spelling.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: DonorTextSize.body,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: filtered.length,
                          itemBuilder: (_, index) {
                            final option = filtered[index];
                            final isSelected = option.value == widget.selected;

                            return ListTile(
                              minTileHeight: 56,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              selected: isSelected,
                              selectedTileColor: AppTheme.lightGreen,
                              leading: option.icon == null
                                  ? null
                                  : Icon(
                                      option.icon,
                                      color: AppTheme.primaryGreen,
                                    ),
                              title: Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: DonorTextSize.body,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: AppTheme.darkText,
                                ),
                              ),
                              subtitle: option.description == null
                                  ? null
                                  : Text(
                                      option.description!,
                                      style: const TextStyle(
                                        fontSize: DonorTextSize.small,
                                        color: AppTheme.mutedText,
                                      ),
                                    ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primaryGreen,
                                    )
                                  : null,
                              onTap: () => Navigator.pop(context, option.value),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Large side-by-side cards for a choice between a few options (for
/// example Individual or Organization). Everything is visible at once
/// and one tap selects.
class DonorChoiceCards extends StatelessWidget {
  final String label;
  final String? value;
  final List<DonorOption> options;
  final ValueChanged<String> onChanged;
  final String requiredMessage;

  const DonorChoiceCards({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.requiredMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      validator: (_) => value == null ? requiredMessage : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: DonorTextSize.body,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _card(options[i], field)),
                ],
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    fontSize: DonorTextSize.small,
                    color: AppTheme.danger,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _card(DonorOption option, FormFieldState<String> field) {
    final selected = option.value == value;
    final borderColor = selected
        ? AppTheme.primaryGreen
        : field.hasError
        ? AppTheme.danger
        : const Color(0xFFD5DAD8);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppTheme.lightGreen : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            field.didChange(option.value);
            onChanged(option.value);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      option.icon ?? Icons.circle_outlined,
                      color: selected
                          ? AppTheme.primaryGreenDark
                          : AppTheme.mutedText,
                    ),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? AppTheme.primaryGreen
                          : AppTheme.greyText,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: DonorTextSize.body,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? AppTheme.primaryGreenDark
                        : AppTheme.darkText,
                  ),
                ),
                if (option.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    option.description!,
                    style: const TextStyle(
                      fontSize: DonorTextSize.small,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapping row of chips for picking one short option, such as a unit.
/// All options are visible and one tap selects.
class DonorChipSelector extends StatelessWidget {
  final String label;
  final String value;
  final List<DonorOption> options;
  final ValueChanged<String> onChanged;

  const DonorChipSelector({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: DonorTextSize.body,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final selected = option.value == value;

            return ChoiceChip(
              label: Text(option.label),
              selected: selected,
              showCheckmark: true,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: DonorTextSize.body,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.darkText,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              selectedColor: AppTheme.primaryGreen,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected
                    ? AppTheme.primaryGreen
                    : const Color(0xFFD5DAD8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => onChanged(option.value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
