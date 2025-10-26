import 'package:flutter/material.dart';
import 'package:skidpark/screens/ski_management_screen.dart';
import 'package:skidpark/screens/ski_testing_screen.dart';

class BottomNavigator extends StatefulWidget {
  const BottomNavigator({super.key});

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  int currentPageIndex = 0;

  final List<Widget> _screens = [
    const SkiManagementScreen(),
    const SkiTestingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        indicatorColor: theme.primaryColor,
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            selectedIcon: Icon(Icons.ac_unit),
            icon: Icon(Icons.ac_unit_outlined),
            label: 'Min skidpark',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.compare_arrows),
            icon: Icon(Icons.compare_arrows_outlined),
            label: 'GlidLabbet',
          ),
        ],
      ),
      body:  IndexedStack(
        index: currentPageIndex,
        children: _screens,
      ),
    );
  }
}
