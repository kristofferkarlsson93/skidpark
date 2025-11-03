import 'package:flutter/material.dart';
import 'package:skidpark/features/glide_testing/explore/screen/glide_testing_home_screen.dart';
import 'package:skidpark/features/ski_management/exlore/screen/ski_management_screen.dart';

import '../../features/glide_testing/ski_testing_screen_temp_data_collection.dart';

class BottomNavigator extends StatefulWidget {
  const BottomNavigator({super.key});

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  int currentPageIndex = 0;

  final List<Widget> _screens = [
    const SkiManagementScreen(),
    const GlideTestingHomeScreen(),
    const TempDataCollectionScreen(),
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
            selectedIcon: Icon(Icons.science),
            icon: Icon(Icons.science_outlined),
            label: 'GlidLabbet',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.compare_arrows),
            icon: Icon(Icons.compare_arrows_outlined),
            label: 'Temp datainsamling',
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
