import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'branches_screen.dart';
import 'staff_screen.dart';
import 'announcements_screen.dart';
import 'services_screen.dart';
import 'statistics_screen.dart';
import 'guides_screen.dart';
import 'useful_links_screen.dart';
import 'quick_links_screen.dart';
import 'collections_screen.dart';
import 'page_content_screen.dart';
import 'forms_screen.dart';
import 'media_screen.dart';
import 'chat_screen.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

const _navItems = [
  _NavItem('Παραρτήματα', Icons.location_on_outlined, Icons.location_on),
  _NavItem('Προσωπικό', Icons.people_outline, Icons.people),
  _NavItem('Ανακοινώσεις', Icons.campaign_outlined, Icons.campaign),
  _NavItem('Υπηρεσίες', Icons.miscellaneous_services_outlined, Icons.miscellaneous_services),
  _NavItem('Στατιστικά', Icons.bar_chart_outlined, Icons.bar_chart),
  _NavItem('Οδηγοί', Icons.menu_book_outlined, Icons.menu_book),
  _NavItem('Χρήσιμοι Σύνδεσμοι', Icons.link_outlined, Icons.link),
  _NavItem('Γρήγοροι Σύνδεσμοι', Icons.flash_on_outlined, Icons.flash_on),
  _NavItem('Συλλογές', Icons.collections_outlined, Icons.collections),
  _NavItem('Περιεχόμενο Σελίδων', Icons.article_outlined, Icons.article),
  _NavItem('Φόρμες', Icons.inbox_outlined, Icons.inbox),
  _NavItem('Αρχεία', Icons.photo_library_outlined, Icons.photo_library),
  _NavItem('Live Chat', Icons.chat_bubble_outline, Icons.chat_bubble),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selected = 0;
  bool _railExtended = true;

  ApiService _api(BuildContext context) =>
      ApiService(context.read<AuthService>().token!);

  Widget _body(BuildContext ctx) {
    final api = _api(ctx);
    return switch (_selected) {
      0 => BranchesScreen(api: api),
      1 => StaffScreen(api: api),
      2 => AnnouncementsScreen(api: api),
      3 => ServicesScreen(api: api),
      4 => StatisticsScreen(api: api),
      5 => GuidesScreen(api: api),
      6 => UsefulLinksScreen(api: api),
      7 => QuickLinksScreen(api: api),
      8 => CollectionsScreen(api: api),
      9 => PageContentScreen(api: api),
      10 => FormsScreen(api: api),
      11 => MediaScreen(api: api),
      12 => ChatScreen(api: api),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: Row(
          children: [
            const Icon(Icons.local_library_rounded),
            const SizedBox(width: 10),
            const Text('UOWM Library Admin',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('👤 ${auth.username ?? ''}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: auth.logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Αποσύνδεση'),
              style: TextButton.styleFrom(foregroundColor: cs.onPrimary),
            ),
          ],
        ),
        leading: isWide
            ? IconButton(
                icon: Icon(
                    _railExtended ? Icons.menu_open : Icons.menu),
                onPressed: () =>
                    setState(() => _railExtended = !_railExtended),
              )
            : null,
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  extended: _railExtended,
                  selectedIndex: _selected,
                  onDestinationSelected: (i) => setState(() => _selected = i),
                  minExtendedWidth: 210,
                  destinations: _navItems
                      .map((n) => NavigationRailDestination(
                            icon: Icon(n.icon),
                            selectedIcon: Icon(n.activeIcon),
                            label: Text(n.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _body(context)),
              ],
            )
          : _body(context),
      drawer: isWide
          ? null
          : Drawer(
              child: ListView(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: cs.primary),
                    child: Text('UOWM Admin',
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ),
                  ..._navItems.asMap().entries.map((e) => ListTile(
                        leading: Icon(e.value.icon),
                        title: Text(e.value.label),
                        selected: _selected == e.key,
                        onTap: () {
                          setState(() => _selected = e.key);
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
            ),
    );
  }
}
