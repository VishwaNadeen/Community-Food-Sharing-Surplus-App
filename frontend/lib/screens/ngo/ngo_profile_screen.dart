import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ngo_profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ngo_ui.dart';

/// Account details and security actions for the NGO coordinator.
class NgoProfileScreen extends StatefulWidget {
  const NgoProfileScreen({super.key});

  @override
  State<NgoProfileScreen> createState() => _NgoProfileScreenState();
}

class _NgoProfileScreenState extends State<NgoProfileScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? _firstName;
  String? _lastName;
  String? _profileImageUrl;
  bool _savingName = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;
    try {
      final profile = await NgoProfileService.getProfile(token);
      if (!mounted) return;
      setState(() {
        _firstName = profile['firstName'] as String?;
        _lastName = profile['lastName'] as String?;
        _profileImageUrl = profile['profileImageUrl'] as String?;
      });
      auth.setNgoCoordinatorName(_firstName, _lastName);
    } catch (_) {
      // Profile remains available; users can still add their name.
    }
  }

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null || !mounted) return;
    if (await image.length() > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an image smaller than 5 MB.')),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final profile = await NgoProfileService.uploadPhoto(
        token: token,
        image: image,
      );
      if (!mounted) return;
      setState(() => _profileImageUrl = profile['profileImageUrl'] as String?);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _editName() async {
    _firstNameController.text = _firstName ?? '';
    _lastNameController.text = _lastName ?? '';
    String? validationMessage;
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Your name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
              if (validationMessage != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    validationMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (_firstNameController.text.trim().isEmpty ||
                    _lastNameController.text.trim().isEmpty) {
                  setDialogState(() {
                    validationMessage = 'Enter both your first and last name';
                  });
                  return;
                }
                Navigator.pop(dialogContext, [
                  _firstNameController.text.trim(),
                  _lastNameController.text.trim(),
                ]);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (values == null || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;
    setState(() => _savingName = true);
    try {
      final profile = await NgoProfileService.updateProfile(
        token: token,
        firstName: values[0],
        lastName: values[1],
      );
      if (!mounted) return;
      setState(() {
        _firstName = profile['firstName'] as String?;
        _lastName = profile['lastName'] as String?;
      });
      auth.setNgoCoordinatorName(_firstName, _lastName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
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
    final verified = user?.isEmailVerified == true;
    final displayName = Provider.of<AuthProvider>(context).ngoCoordinatorName;
    final initial = (displayName?.isNotEmpty == true
            ? displayName![0]
            : email.isNotEmpty
                ? email[0]
                : 'N')
        .toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: Column(
        children: [
          const NgoHeader(
            title: 'Profile',
            subtitle: 'Your account and security',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _ProfileHeader(
                  initial: initial,
                  email: email,
                  verified: verified,
                  displayName: displayName,
                  photoUrl: _profileImageUrl,
                  uploadingPhoto: _uploadingPhoto,
                  onEditPhoto: _uploadingPhoto ? null : _changePhoto,
                  savingName: _savingName,
                  onEditName: _savingName ? null : _editName,
                ),
                const SectionTitle('Account details', horizontal: 4),
                NgoCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email.isEmpty ? '—' : email,
                      ),
                      _DetailRow(
                        icon: Icons.badge_outlined,
                        label: 'User ID',
                        value: user?.customUserId ?? '—',
                      ),
                      const _DetailRow(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Role',
                        value: 'NGO Coordinator',
                      ),
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
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String initial;
  final String email;
  final bool verified;
  final String? displayName;
  final String? photoUrl;
  final bool uploadingPhoto;
  final VoidCallback? onEditPhoto;
  final bool savingName;
  final VoidCallback? onEditName;

  const _ProfileHeader({
    required this.initial,
    required this.email,
    required this.verified,
    required this.displayName,
    required this.photoUrl,
    required this.uploadingPhoto,
    required this.onEditPhoto,
    required this.savingName,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) => NgoCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: AppTheme.lightGreen,
              child: ClipOval(
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? Image.network(
                        photoUrl!,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _initial(),
                      )
                    : _initial(),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -1,
              child: Material(
                color: AppTheme.primaryGreen,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEditPhoto,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Center(
                      child: uploadingPhoto
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_outlined, size: 15, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName ?? 'NGO Coordinator',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 17,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.greyText, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              StatusChip(
                verified ? 'Verified' : 'Not verified',
                color: verified
                    ? AppTheme.primaryGreenDark
                    : Colors.orange.shade700,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onEditName,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: Text(savingName ? 'Saving…' : 'Edit name'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _initial() => Text(
        initial,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryGreenDark,
        ),
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
    padding: const EdgeInsets.symmetric(vertical: 15),
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
