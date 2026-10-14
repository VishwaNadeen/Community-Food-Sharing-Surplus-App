import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'recipient_profile_screen.dart';
import 'recipient_dashboard_tab.dart';
import 'recipient_browse_tab.dart';
import 'recipient_requests_tab.dart';
import '../../models/recipient_model.dart';
import '../../services/recipient_service.dart';

class RecipientHomeScreen extends StatefulWidget {
  const RecipientHomeScreen({super.key});

  @override
  State<RecipientHomeScreen> createState() => _RecipientHomeScreenState();
}

class _RecipientHomeScreenState extends State<RecipientHomeScreen> {
  String _recipientName = '';

  // Profile photo. Null for now – the avatar falls back to the user's
  // initials. Later, set this from the profile API to show the real photo.
  String? _photoUrl;

  bool _isProfileLoading = true;
  bool _isDashboardLoading = true;
  int _currentIndex = 0;

  // Lets the home screen refresh the overview when the user returns to it.
  final GlobalKey<RecipientDashboardTabState> _dashboardKey =
      GlobalKey<RecipientDashboardTabState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecipientName();
    });
  }

  Future<void> _loadRecipientName() async {
    final auth = Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final token = auth.token;

    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _isProfileLoading = false);
      return;
    }

    try {
      final RecipientModel profile =
          await RecipientService.getProfile(token: token);

      if (mounted) {
        setState(() {
          _recipientName =
              '${profile.firstName} ${profile.lastName}'.trim();
        });
      }
    } catch (e) {
      debugPrint('Failed to load recipient name: $e');
    } finally {
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  final List<String> _titles = [
    'Home',
    'Browse Donations',
    'My Requests',
    'Profile',
  ];

  // Short helper text shown under each title.
  final List<String> _subtitles = [
    '',
    'Find food available near you',
    'Track the status of your requests',
    '',
  ];

  void _onTabTapped(int index) {
    final goingHome = index == 0 && _currentIndex != 0;

    setState(() {
      _currentIndex = index;
    });

    if (goingHome) {
      _dashboardKey.currentState?.refresh(silent: true);
    }
  }

  void _onDashboardInitialLoadComplete() {
    if (mounted) setState(() => _isDashboardLoading = false);
  }

  Future<void> _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (_) => false,
    );
  }

  // Good morning / afternoon / evening based on the current time.
  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _userName() {
    return _recipientName.isNotEmpty ? _recipientName : 'there';
  }

  // "Vishwa Nadeen" -> "VN", "Vishwa" -> "VI"
  String _initials() {
    final parts = _recipientName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final w = parts[0];
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }

  PreferredSizeWidget _buildAppBar() {
    final isHome = _currentIndex == 0;
    final subtitle = _subtitles[_currentIndex];

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      centerTitle: false,
      toolbarHeight: 68,
      titleSpacing: 20,
      title: isHome
          // ---------- GREETING (Home tab) ----------
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _greeting(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            )
          // ---------- TITLE (other tabs) ----------
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _titles[_currentIndex],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppTheme.darkText,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.greyText,
                    ),
                  ),
              ],
            ),
      // ---------- PROFILE PHOTO (Home tab, top right) ----------
      actions: isHome
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: _ProfileAvatar(
                  initials: _initials(),
                  imageUrl: _photoUrl,
                  onTap: () => _onTabTapped(3),
                ),
              ),
            ]
          : null,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: AppTheme.border,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,

          // The profile screen already has its own AppBar.
          appBar: _currentIndex == 3 ? null : _buildAppBar(),

          body: IndexedStack(
            index: _currentIndex,
            children: [
              RecipientDashboardTab(
                key: _dashboardKey,
                onBrowse: () => _onTabTapped(1),
                onRequests: () => _onTabTapped(2),
                onInitialLoadComplete: _onDashboardInitialLoadComplete,
              ),
              const BrowseTab(),
              const MyRequestsTab(),
              RecipientProfileScreen(token: token),
            ],
          ),

          bottomNavigationBar: _BottomNav(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ),
        if (_isProfileLoading || _isDashboardLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PROFILE AVATAR (photo or initials)
// ---------------------------------------------------------------------------

class _ProfileAvatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.initials,
    required this.imageUrl,
    required this.onTap,
  });

  Widget _initialsView() {
    return Center(
      child: initials.isEmpty
          ? const Icon(Icons.person_rounded, color: Colors.white, size: 22)
          : Text(
              initials,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Semantics(
      button: true,
      label: 'Open profile',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
            ),
            border: Border.all(color: AppTheme.lightGreen, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initialsView(),
                )
              : _initialsView(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BOTTOM NAVIGATION
// ---------------------------------------------------------------------------

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu_rounded,
      label: 'Browse',
    ),
    _NavItem(
      icon: Icons.list_alt_outlined,
      activeIcon: Icons.list_alt_rounded,
      label: 'Requests',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;

              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: selected ? 60 : 36,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.lightGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 24,
                              color: selected
                                  ? AppTheme.primaryGreenDark
                                  : AppTheme.greyText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppTheme.primaryGreenDark
                                  : AppTheme.greyText,
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}