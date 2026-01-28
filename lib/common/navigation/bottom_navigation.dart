import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skidpark/features/glide_testing/explore/screen/glide_testing_home_screen.dart';
import 'package:skidpark/features/more_page/screens/more_page.dart';
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
    const MorePage(),
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
            selectedIcon: SvgPicture.asset(
              'assets/icons/ski_icon.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.primary,
                BlendMode.srcIn,
              ),
            ),
            icon: SvgPicture.asset(
              'assets/icons/ski_icon.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
            label: 'Min skidpark',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.science),
            icon: Icon(Icons.science_outlined),
            label: 'GlidLabbet',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.more_horiz),
            icon: Icon(Icons.more_horiz_outlined),
            label: 'Mer',
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
