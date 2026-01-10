import 'package:flutter/material.dart';
import 'package:lms_flutter/screens/driver_account.dart';
import 'package:lms_flutter/screens/driver_dashboard_screen.dart';
import 'package:lms_flutter/screens/driver_orders.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DriverDashboardScreen(
        onNavigateToTab: (index) {
          if (index == 1) {
            setState(() => _selectedIndex = 1);
          }
        },
      ),
      const DriverOrdersScreen(),
      const DriverAccountScreen(),
    ];
  }

  void _onItemTapped(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
