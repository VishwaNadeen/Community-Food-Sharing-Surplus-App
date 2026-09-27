import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// UI prototype for CFSASA-97. Administration records are display-only until
/// donor, recipient and complaint management APIs are available.
class NgoAdministrationScreen extends StatefulWidget {
  const NgoAdministrationScreen({super.key});

  @override
  State<NgoAdministrationScreen> createState() => _NgoAdministrationScreenState();
}

class _NgoAdministrationScreenState extends State<NgoAdministrationScreen> {
  int _selectedIndex = 0;

  final _pages = const [
    _NgoHomePage(),
    _DonorManagementPage(),
    _RecipientMonitoringPage(),
    _ComplaintsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    const titles = [
      'NGO Home',
      'Manage Food Donors',
      'Recipient Monitoring',
      'Complaint Monitoring',
    ];
    return Scaffold(
      backgroundColor: AppTheme.fieldFill,
      appBar: AppBar(
        title: Text(titles[_selectedIndex],
            style: const TextStyle(
                color: AppTheme.darkText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkText),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) => setState(() => _selectedIndex = value),
        indicatorColor: const Color(0xFF9BFF72),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism), label: 'Donors'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Recipients'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
        ],
      ),
    );
  }
}

class _NgoHomePage extends StatelessWidget {
  const _NgoHomePage();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('NGO Coordinator', style: TextStyle(color: AppTheme.greyText, fontSize: 12)),
          const Text('Welcome back, Sarah!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
          const SizedBox(height: 20),
          const Text('Active Summary', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkText)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.38,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: const [
              _MetricCard(icon: Icons.favorite_border, value: '47', label: 'Active Donors', trend: '↑ 4%'),
              _MetricCard(icon: Icons.business_outlined, value: '132', label: 'Recipients', trend: '↑ 8%'),
              _MetricCard(icon: Icons.groups_outlined, value: '28', label: 'Volunteers', trend: '↓ 2%', negative: true),
              _MetricCard(icon: Icons.inventory_2_outlined, value: '89', label: 'This Month', trend: '↑ 15%'),
              _MetricCard(icon: Icons.local_shipping_outlined, value: '14', label: 'Pending Deliveries', trend: '↑ Stable'),
              _MetricCard(icon: Icons.flag_outlined, value: '5', label: 'Open Complaints', trend: '↓ 12%', negative: true),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Immediate Priority Tasks', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkText)),
          const SizedBox(height: 10),
          const _TaskCard(title: 'Approve Fresh Farms donation', due: 'Due in 15 mins', priority: 'HIGH', color: Colors.red),
          const _TaskCard(title: 'Re-assign driver for Hope Center', due: 'Due in 1 hour', priority: 'MEDIUM', color: Colors.orange),
          const _TaskCard(title: "Verify Maria's Bakery paperwork", due: 'Today, 5:00 PM', priority: 'LOW', color: Colors.blue),
        ],
      );
}

class _DonorManagementPage extends StatelessWidget {
  const _DonorManagementPage();
  @override
  Widget build(BuildContext context) => _ManagementList(
        hint: 'Search active donors...',
        subtitle: 'Showing 6 partner donors',
        children: const [
          _DonorCard(name: 'Fresh Farms Co', type: 'Agricultural Producer', location: 'North District', rating: '4.8', donations: '156', status: 'ACTIVE'),
          _DonorCard(name: "Maria's Bakery", type: 'Retail Bakery', location: 'Downtown', rating: '4.9', donations: '92', status: 'ACTIVE'),
          _DonorCard(name: 'Green Grocer Market', type: 'Supermarket', location: 'West End', rating: '4.5', donations: '64', status: 'PENDING'),
          _DonorCard(name: 'City Logistics', type: 'Corporate Partner', location: 'South Industrial', rating: '4.2', donations: '28', status: 'ACTIVE'),
          _DonorCard(name: 'Organics Outpost', type: 'Wholesaler', location: 'Metro Hub', rating: '4.7', donations: '112', status: 'SUSPENDED'),
          _DonorCard(name: 'Daily Bread Cafe', type: 'Local Restaurant', location: 'East Plaza', rating: '4.6', donations: '41', status: 'ACTIVE'),
        ],
      );
}

class _RecipientMonitoringPage extends StatelessWidget {
  const _RecipientMonitoringPage();
  @override
  Widget build(BuildContext context) => _ManagementList(
        hint: 'Search shelter partners...',
        subtitle: '6 active centers mapped',
        children: const [
          _RecipientCard(name: 'Hope Community Center', location: 'Downtown Hub', requests: '43', secured: '1,240 kg', score: '95 pts', status: 'VERIFIED'),
          _RecipientCard(name: 'Mercy Food Kitchen', location: 'West Side', requests: '88', secured: '2,450 kg', score: '88 pts', status: 'VERIFIED'),
          _RecipientCard(name: 'East Plaza Shelter', location: 'East End', requests: '12', secured: '340 kg', score: '45 pts', status: 'UNDER REVIEW'),
          _RecipientCard(name: 'Downtown Mission', location: 'Metro Core', requests: '62', secured: '1,890 kg', score: '92 pts', status: 'VERIFIED'),
          _RecipientCard(name: 'Child Alliance Center', location: 'Northeast', requests: '15', secured: '210 kg', score: '65 pts', status: 'UNDER REVIEW'),
        ],
      );
}

class _ComplaintsPage extends StatelessWidget {
  const _ComplaintsPage();
  @override
  Widget build(BuildContext context) => _ManagementList(
        hint: 'Search alert tags...',
        subtitle: '6 cases logged in database',
        children: const [
          _ComplaintCard(name: 'Hope Community Center', issue: 'Delivery Delay (Fresh Farms Batch)', priority: 'HIGH', status: 'OPEN', date: 'Today'),
          _ComplaintCard(name: 'Mercy Food Kitchen', issue: 'Food Quality Issue (Dairy Product)', priority: 'HIGH', status: 'IN PROGRESS', date: 'Yesterday'),
          _ComplaintCard(name: 'David Miller (Driver)', issue: 'Volunteer Conduct (Unprofessional Liaison)', priority: 'MEDIUM', status: 'OPEN', date: 'Oct 11'),
          _ComplaintCard(name: 'East Plaza Shelter', issue: 'Incorrect Dispatch Package', priority: 'LOW', status: 'RESOLVED', date: 'Oct 10'),
          _ComplaintCard(name: "Maria's Bakery", issue: 'Storage Box Allocation Issue', priority: 'LOW', status: 'RESOLVED', date: 'Oct 08'),
        ],
      );
}

class _ManagementList extends StatelessWidget {
  final String hint;
  final String subtitle;
  final List<Widget> children;
  const _ManagementList({required this.hint, required this.subtitle, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: hint, suffixIcon: const Icon(Icons.tune), fillColor: Colors.white)),
          const SizedBox(height: 10),
          Row(children: [Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.greyText)), const Spacer(), const Text('Sort by: Priority ⌄', style: TextStyle(fontSize: 12, color: Color(0xFF008C82), fontWeight: FontWeight.w600))]),
          const SizedBox(height: 10),
          ...children,
        ],
      );
}

class _MetricCard extends StatelessWidget {
  final IconData icon; final String value; final String label; final String trend; final bool negative;
  const _MetricCard({required this.icon, required this.value, required this.label, required this.trend, this.negative = false});
  @override
  Widget build(BuildContext context) => _Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: const Color(0xFFD7FAF2), borderRadius: BorderRadius.circular(7)), child: Icon(icon, color: const Color(0xFF008C82), size: 19)), const Spacer(), Text(trend, style: TextStyle(fontSize: 10, color: negative ? Colors.red : Colors.green, fontWeight: FontWeight.bold))]),
          const Spacer(), Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.greyText)),
        ]),
      );
}

class _TaskCard extends StatelessWidget {
  final String title, due, priority; final Color color;
  const _TaskCard({required this.title, required this.due, required this.priority, required this.color});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _Surface(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 4), Text('◷  $due', style: const TextStyle(fontSize: 11, color: AppTheme.greyText))])), _Badge(text: priority, color: color)])));
}

class _DonorCard extends StatelessWidget {
  final String name, type, location, rating, donations, status;
  const _DonorCard({required this.name, required this.type, required this.location, required this.rating, required this.donations, required this.status});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: _Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))), _StatusBadge(status)]), Text(type, style: const TextStyle(fontSize: 11, color: AppTheme.greyText)), const SizedBox(height: 8), Row(children: [const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.greyText), Text(' $location', style: const TextStyle(fontSize: 11, color: AppTheme.greyText)), const Spacer(), Text('⭐ $rating   ▣ $donations donations', style: const TextStyle(fontSize: 11))])])));
}

class _RecipientCard extends StatelessWidget {
  final String name, location, requests, secured, score, status;
  const _RecipientCard({required this.name, required this.location, required this.requests, required this.secured, required this.score, required this.status});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: _Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))), _StatusBadge(status)]), Text('◉ $location', style: const TextStyle(fontSize: 11, color: AppTheme.greyText)), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_MiniMetric('Total Requests', requests), _MiniMetric('Food Secured', secured), _MiniMetric('Equity Score', score, green: true)])])));
}

class _ComplaintCard extends StatelessWidget {
  final String name, issue, priority, status, date;
  const _ComplaintCard({required this.name, required this.issue, required this.priority, required this.status, required this.date});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9), child: _Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))), Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.greyText))]), const SizedBox(height: 5), Text('⚑  $issue', style: const TextStyle(fontSize: 12, color: AppTheme.greyText)), const Divider(), Row(children: [Text('Priority: ', style: const TextStyle(fontSize: 11, color: AppTheme.greyText)), _Badge(text: priority, color: priority == 'HIGH' ? Colors.red : Colors.orange), const Spacer(), Text('Status: ', style: const TextStyle(fontSize: 11, color: AppTheme.greyText)), _Badge(text: status, color: status == 'RESOLVED' ? Colors.green : Colors.red)])])));
}

class _Surface extends StatelessWidget {
  final Widget child; const _Surface({required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppTheme.border)), child: child);
}

class _StatusBadge extends StatelessWidget {
  final String status; const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) { final color = status == 'SUSPENDED' ? Colors.red : status == 'PENDING' || status == 'UNDER REVIEW' ? Colors.orange : Colors.green; return _Badge(text: status, color: color); }
}

class _Badge extends StatelessWidget {
  final String text; final Color color; const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(5)), child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)));
}

class _MiniMetric extends StatelessWidget {
  final String label, value; final bool green; const _MiniMetric(this.label, this.value, {this.green = false});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.greyText)), Text(value, style: TextStyle(fontSize: 12, color: green ? const Color(0xFF008C82) : AppTheme.darkText, fontWeight: FontWeight.bold))]);
}
