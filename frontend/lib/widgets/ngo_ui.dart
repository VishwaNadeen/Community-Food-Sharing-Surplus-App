import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared building blocks for the NGO coordinator screens so they look
/// consistent on phone-sized displays.

Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
    case 'REPORTED':
    case 'SUGGESTED':
      return Colors.orange.shade700;
    case 'APPROVED':
    case 'AVAILABLE':
    case 'ACTIVE':
    case 'RESOLVED':
    case 'ACCEPTED':
    case 'COLLECTED':
      return AppTheme.primaryGreenDark;
    case 'ACKNOWLEDGED':
    case 'NEW':
      return Colors.blue.shade700;
    case 'REJECTED':
    case 'DECLINED':
    case 'CANCELLED':
      return Colors.red.shade600;
    default:
      return AppTheme.greyText;
  }
}

String titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s]+'))
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats an ISO date string as "11 Oct 2026, 14:30" (local time).
String formatDateTime(String? iso) {
  final parsed = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return iso == null || iso.isEmpty ? '—' : iso;
  final hh = parsed.hour.toString().padLeft(2, '0');
  final mm = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}, $hh:$mm';
}

String formatDate(String? iso) {
  final parsed = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return '—';
  return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
}

String timeAgo(String? iso) {
  final parsed = iso == null ? null : DateTime.tryParse(iso);
  if (parsed == null) return '—';
  final diff = DateTime.now().difference(parsed);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 30) return '${diff.inDays} d ago';
  return formatDate(iso);
}

class NgoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const NgoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.fromLTRB(16, 6, 16, 6),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusChip(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        titleCase(label),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: resolved,
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const InfoRow(this.icon, this.text, {super.key, this.maxLines = 2});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: AppTheme.greyText),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF4A4F55),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.greyText),
            ),
        ],
      ),
    );
  }
}

/// Small stat shown inside cards: a big value above a muted label.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const StatTile(this.value, this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color ?? AppTheme.darkText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppTheme.greyText),
        ),
      ],
    );
  }
}

/// Square icon badge used at the start of cards and metric tiles.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge(this.icon, {super.key, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Small rounded label with an icon, e.g. "40 packets".
class IconPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const IconPill(this.icon, this.text, {super.key, this.color = AppTheme.primaryGreenDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Metric tile: icon, big value and label. Sizes itself to its content so it
/// never overflows with large system fonts.
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = AppTheme.primaryGreenDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon, color: color, size: 36),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
          ),
        ],
      ),
    );
  }
}

/// Two-column grid whose rows are as tall as their tallest card.
class MetricGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const MetricGrid({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i += 2)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: children[i]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: i + 1 < children.length
                          ? children[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Green summary card with a headline number, used at the top of screens.
class HeroSummary extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final List<(String, String)> stats;

  const HeroSummary({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF168A55), Color(0xFF2FAE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332FAE60),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0x40FFFFFF))),
              ),
              child: Row(
                children: [
                  for (final stat in stats)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              stat.$1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stat.$2,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? hint;

  const EmptyState(
    this.message, {
    super.key,
    this.icon = Icons.inbox_outlined,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppTheme.lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTheme.primaryGreenDark),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.greyText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              error.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrollable filter chips (works on narrow phone screens).
class FilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final String Function(String)? labelOf;

  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final option = options[i];
          final isSelected = option == selected;
          return ChoiceChip(
            label: Text(labelOf?.call(option) ?? titleCase(option)),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            showCheckmark: false,
            selectedColor: AppTheme.lightGreen,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.primaryGreenDark : AppTheme.greyText,
            ),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
