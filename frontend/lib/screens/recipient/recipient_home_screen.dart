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
  int _currentIndex = 0;

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

    if (token == null || token.isEmpty) return;

    try {
      final RecipientModel profile =
          await RecipientService.getProfile(token: token);

      if (!mounted) return;

      setState(() {
        _recipientName =
            '${profile.firstName} ${profile.lastName}'.trim();
      });
    } catch (e) {
      debugPrint('Failed to load recipient name: $e');
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

  // Icon shown beside each title (not used on the Home tab).
  final List<IconData> _titleIcons = [
    Icons.home_rounded,
    Icons.restaurant_menu_rounded,
    Icons.list_alt_rounded,
    Icons.person_rounded,
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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

  // Reads the user's name from AuthProvider.
  // NOTE: replace the dynamic lookups below with your real field,
  // e.g. `return auth.userName ?? 'there';`
  String _userName() {
    return _recipientName.isNotEmpty
        ? _recipientName
        : 'there';
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
        // ---------- TITLE (other tabs) – NO ICON ----------
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
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
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

    return Scaffold(
      backgroundColor: Colors.white,

      // The profile screen already has its own AppBar.
      appBar: _currentIndex == 3 ? null : _buildAppBar(),

      body: IndexedStack(
        index: _currentIndex,
        children: [
          RecipientDashboardTab(
            onBrowse: () => _onTabTapped(1),
            onRequests: () => _onTabTapped(2),
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
            color: Colors.black.withOpacity(0.07),
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