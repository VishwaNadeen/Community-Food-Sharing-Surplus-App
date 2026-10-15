import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'ngo_administration_screen.dart';
import 'ngo_dashboard_screen.dart';
import 'ngo_impact_dashboard_screen.dart';
import 'ngo_overview_screen.dart';
import 'ngo_profile_screen.dart';

/// Home of the NGO coordinator: a footer to move between the main areas.
/// Tabs are built the first time they are opened so the app does not load
/// every screen's data at start-up.
class NgoHomeScreen extends StatefulWidget {
  const NgoHomeScreen({super.key});

  @override
  State<NgoHomeScreen> createState() => _NgoHomeScreenState();
}

class _NgoHomeScreenState extends State<NgoHomeScreen> {
  int _index = 0;
  final Set<int> _opened = {0};

  int _homeRefresh = 0;
  int _reviewRefresh = 0;
  int _reviewTab = 0;
  int _manageTab = 0;

  Widget _page(int index, String token) {
    if (!_opened.contains(index)) return const SizedBox.shrink();
    switch (index) {
      case 0:
        return NgoOverviewScreen(
          token: token,
          onNavigate: _goTo,
          refreshTick: _homeRefresh,
        );
      case 1:
        return NgoDashboardScreen(
          initialTab: _reviewTab,
          refreshTick: _reviewRefresh,
        );
      case 2:
        return ImpactDashboardScreen(token: token);
      case 3:
        return NgoAdministrationScreen(token: token, initialTab: _manageTab);
      default:
        return const NgoProfileScreen();
    }
  }

  void _goTo(int value, [int section = 0]) => setState(() {
    if (value == 1) _reviewTab = section.clamp(0, 1);
    if (value == 3) _manageTab = section.clamp(0, 2);
    if (value == 0 && _index != 0) _homeRefresh++;
    if (value == 1 && _index != 1) _reviewRefresh++;
    _index = value;
    _opened.add(value);
  });

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(5, (i) => _page(i, token)),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          indicatorColor: AppTheme.lightGreen,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: _goTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primaryGreenDark),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(
                Icons.fact_check,
                color: AppTheme.primaryGreenDark,
              ),
              label: 'Review',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(
                Icons.insights,
                color: AppTheme.primaryGreenDark,
              ),
              label: 'Impact',
            ),
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(
                Icons.admin_panel_settings,
                color: AppTheme.primaryGreenDark,
              ),
              label: 'Manage',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(
                Icons.person,
                color: AppTheme.primaryGreenDark,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
