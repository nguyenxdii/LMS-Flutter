import 'package:flutter/material.dart';
import 'package:lms_flutter/screens/driver/driver_account.dart';
import 'package:lms_flutter/screens/driver/driver_dashboard_screen.dart';
import 'package:lms_flutter/screens/driver/driver_orders.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  // globalKeys để gọi refresh từ parent
  final GlobalKey<DriverDashboardScreenState> _dashboardKey = GlobalKey();
  final GlobalKey<DriverOrdersScreenState> _ordersKey = GlobalKey();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DriverDashboardScreen(
        key: _dashboardKey,
        onNavigateToTab: (index) {
          if (index == 1) {
            setState(() => _selectedIndex = 1);
            // refresh danh sách chuyến khi navigate từ dashboard
            _ordersKey.currentState?.refresh();
          }
        },
      ),
      DriverOrdersScreen(key: _ordersKey),
      const DriverAccountScreen(),
    ];
  }

  void _onItemTapped(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedIndex = index;
    });
    // auto-refresh khi chuyển tab
    if (index == 0) {
      _dashboardKey.currentState?.refresh();
    } else if (index == 1) {
      _ordersKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 249, 255),
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Chuyến hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  String _getTitle(int index) {
    if (index == 0) return "Trang chủ";
    if (index == 1) return "Danh sách chuyến";
    return "Tài khoản";
  }
}
