import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ngo_admin_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ngo_admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ngo_ui.dart';

/// NGO coordinator profile. The backend stores only account details for NGO
/// users (email, ID, role, verification), so those are what is shown.
class NgoProfileScreen extends StatefulWidget {
  final String token;
  const NgoProfileScreen({super.key, required this.token});

  @override
  State<NgoProfileScreen> createState() => _NgoProfileScreenState();
}

class _NgoProfileScreenState extends State<NgoProfileScreen> {
  late Future<AdminOverview> _workload;

  @override
  void initState() {
    super.initState();
    _workload = NgoAdminService.getOverview(token: widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _workload = NgoAdminService.getOverview(token: widget.token);
    });
    try {
      await _workload;
    } catch (_) {
      // The workload card shows its own error state.
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    await auth.logout();
    navigator.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final email = user?.email ?? '';
    final initial = email.isEmpty ? 'N' : email[0].toUpperCase();
    final verified = user?.isEmailVerified == true;

    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppTheme.darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ProfileHeader(
              initial: initial,
              email: email,
              verified: verified,
            ),
            const SectionTitle('Your workload', horizontal: 4),
            _WorkloadCard(future: _workload, onRetry: _refresh),
            const SectionTitle('Account details', horizontal: 4),
            NgoCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: email.isEmpty ? '—' : email,
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  _DetailRow(
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    value: user?.customUserId ?? '—',
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  const _DetailRow(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Role',
                    value: 'NGO Coordinator',
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  _DetailRow(
                    icon: Icons.verified_outlined,
                    label: 'Email status',
                    value: verified ? 'Verified' : 'Not verified',
                    valueColor: verified
                        ? AppTheme.primaryGreenDark
                        : Colors.orange.shade700,
                  ),
                ],
              ),
            ),
            const SectionTitle('Security', horizontal: 4),
            NgoCard(
              margin: EdgeInsets.zero,
              onTap: () => Navigator.pushNamed(context, '/change-password'),
              child: const Row(
                children: [
                  IconBadge(
                    Icons.lock_outline,
                    color: AppTheme.primaryGreenDark,
                    size: 40,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change password',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Update the password you use to sign in',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.greyText),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String initial;
  final String email;
  final bool verified;

  const _ProfileHeader({
    required this.initial,
    required this.email,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) => Container(
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
    child: Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white,
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreenDark,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NGO Coordinator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      verified ? Icons.verified : Icons.info_outline,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      verified ? 'Verified account' : 'Email not verified',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WorkloadCard extends StatelessWidget {
  final Future<AdminOverview> future;
  final VoidCallback onRetry;
  const _WorkloadCard({required this.future, required this.onRetry});

  @override
  Widget build(BuildContext context) => FutureBuilder<AdminOverview>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const NgoCard(
          margin: EdgeInsets.zero,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return NgoCard(
          margin: EdgeInsets.zero,
          onTap: onRetry,
          child: const Row(
            children: [
              Icon(Icons.refresh, color: AppTheme.greyText),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Could not load your workload. Tap to try again.',
                  style: TextStyle(color: AppTheme.greyText),
                ),
              ),
            ],
          ),
        );
      }
      final o = snapshot.data!;
      return NgoCard(
        margin: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatTile(
              '${o.pendingDonations}',
              'Donations to review',
              color: Colors.orange.shade700,
            ),
            StatTile(
              '${o.pendingRequests}',
              'Requests to review',
              color: Colors.orange.shade700,
            ),
            StatTile(
              '${o.openProblems}',
              'Open alerts',
              color: o.openProblems > 0
                  ? Colors.red.shade600
                  : AppTheme.primaryGreenDark,
            ),
          ],
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.greyText),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: AppTheme.greyText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.darkText,
            ),
          ),
        ),
      ],
    ),
  );
}
