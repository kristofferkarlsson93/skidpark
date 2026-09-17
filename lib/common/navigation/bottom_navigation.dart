import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skidpark/features/glide_testing/explore/screen/glide_testing_home_screen.dart';
import 'package:skidpark/features/more_page/screens/more_page.dart';
import 'package:skidpark/features/ski_management/exlore/screen/ski_management_screen.dart';

class BottomNavigator extends StatefulWidget {
  const BottomNavigator({super.key});

  @override
  State<BottomNavigator> createState() => _BottomNavigatorState();
}

class _BottomNavigatorState extends State<BottomNavigator> {
  int currentPageIndex = 0;

  final List<Widget> _screens = [
    const GlideTestingHomeScreen(),
    const SkiManagementScreen(),
    const MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: [
          Semantics(
            identifier: 'navigation-tests',
            child: const NavigationDestination(
              selectedIcon: Icon(Icons.show_chart_rounded),
              icon: Icon(Icons.show_chart_outlined),
              label: 'Tester',
            ),
          ),
          Semantics(
            identifier: 'navigation-skis',
            child: NavigationDestination(
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
              label: 'Skidor',
            ),
          ),
          Semantics(
            identifier: 'navigation-more',
            child: const NavigationDestination(
              selectedIcon: Icon(Icons.more_horiz),
              icon: Icon(Icons.more_horiz_outlined),
              label: 'Mer',
            ),
          ),
        ],
      ),
      body: IndexedStack(index: currentPageIndex, children: _screens),
    );
  }
}
