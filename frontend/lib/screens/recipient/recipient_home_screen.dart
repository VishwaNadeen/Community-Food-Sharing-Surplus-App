import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'recipient_profile_screen.dart';
import 'recipient_dashboard_tab.dart';
import 'recipient_browse_tab.dart';
import 'recipient_requests_tab.dart';

class RecipientHomeScreen extends StatefulWidget {

  const RecipientHomeScreen({super.key});

  @override

  State<RecipientHomeScreen> createState() => _RecipientHomeScreenState();

}

class _RecipientHomeScreenState extends State<RecipientHomeScreen> {

  int _currentIndex = 0;

  final List<String> _titles = [

    'Home',

    'Browse Donations',

    'My Requests',

    'Profile',

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

  @override

  Widget build(BuildContext context) {

    final token =

        Provider.of<AuthProvider>(context, listen: false).token ?? '';

    return Scaffold(

      backgroundColor: Colors.white,

      // The profile screen already has its own AppBar.

      appBar: _currentIndex == 3

          ? null

          : AppBar(

              backgroundColor: Colors.white,

              elevation: 0,

              surfaceTintColor: Colors.white,

              centerTitle: false,

              title: Text(

                _titles[_currentIndex],

                style: const TextStyle(

                  fontSize: 20,

                  fontWeight: FontWeight.w700,

                  color: AppTheme.darkText,

                ),

              ),


              bottom: PreferredSize(

                preferredSize: const Size.fromHeight(1),

                child: Divider(

                  height: 1,

                  color: AppTheme.border,

                ),

              ),

            ),

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

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: _currentIndex,

        onTap: _onTabTapped,

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,

        selectedItemColor: AppTheme.primaryGreen,

        unselectedItemColor: AppTheme.greyText,

        elevation: 8,

        selectedFontSize: 12,

        unselectedFontSize: 12,

        showSelectedLabels: true,

        showUnselectedLabels: true,

        selectedLabelStyle: const TextStyle(

          fontWeight: FontWeight.w600,

          fontSize: 12,

        ),

        unselectedLabelStyle: const TextStyle(fontSize: 12),

        items: const [

          BottomNavigationBarItem(

            icon: Icon(Icons.home_outlined),

            activeIcon: Icon(Icons.home),

            label: 'Home',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.restaurant_menu_outlined),

            activeIcon: Icon(Icons.restaurant_menu),

            label: 'Browse',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.list_alt_outlined),

            activeIcon: Icon(Icons.list_alt),

            label: 'Requests',

          ),

          BottomNavigationBarItem(

            icon: Icon(Icons.person_outline),

            activeIcon: Icon(Icons.person),

            label: 'Profile',

          ),

        ],

      ),

    );

  }

}

// ---------------------------------------------------------------------------

// BROWSE TAB

// ---------------------------------------------------------------------------
