import 'package:flutter/material.dart';
import 'tracker_screen.dart';
import 'trend_screen.dart';
import 'user_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  static final List<Widget> _pages = <Widget>[
    const TrackerScreen(),
    const TrendScreen(),
    const UserProfileScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              double sidebarWidth = MediaQuery.of(context).size.width * 0.2;
              if (sidebarWidth < 80) sidebarWidth = 80;
              if (sidebarWidth > 300) sidebarWidth = 300;
              bool isExpanded = sidebarWidth > 150;
              
              return Container(
                width: sidebarWidth,
                color: Colors.blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DrawerHeader(
                      decoration: BoxDecoration(color: Colors.blue),
                      child: Text('Navigation', style: TextStyle(color: Colors.white, fontSize: 24)),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.track_changes, color: Colors.white),
                          title: isExpanded ? const Text('Tracker', style: TextStyle(color: Colors.white)) : null,
                          onTap: () => _onItemTapped(0),
                        ),
                        ListTile(
                          leading: const Icon(Icons.show_chart, color: Colors.white),
                          title: isExpanded ? const Text('Trend', style: TextStyle(color: Colors.white)) : null,
                          onTap: () => _onItemTapped(1),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.white),
                          title: isExpanded ? const Text('View Profile', style: TextStyle(color: Colors.white)) : null,
                          onTap: () => _onItemTapped(2),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            flex: 1,
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}