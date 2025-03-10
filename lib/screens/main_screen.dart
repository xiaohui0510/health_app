import 'package:flutter/material.dart';
import 'tracker_screen.dart';
// import 'trend_screen.dart';
import 'user_profile_screen.dart';
import 'ai_model_screen.dart';
import 'health_connect.dart';
// import 'watchOS_screen.dart';
// import 'bluetooth_screen.dart';
import 'map_screen.dart';
import 'report_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = false; // Initially collapsed
  // You can adjust this offset if needed.
  double _sidebarTopOffset = 100;

  static final List<Widget> _pages = <Widget>[
    const TrackerScreen(),
    const ReportScreen(),
    // const TrendScreen(),
    const ChatboxScreen(),
    const HealthApp(),
    // const BleSmartWatchScreen(),
    const MapScreen(),
    const UserProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Auto-collapse sidebar when switching screens.
      _isSidebarExpanded = false;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sidebar width: 300 if expanded, 50 if collapsed.
    final double sidebarWidth = _isSidebarExpanded ? 200 : 40;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: sidebarWidth,
            color: Colors.blue,
            child: _isSidebarExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DrawerHeader(
                        decoration: BoxDecoration(color: Colors.blue),
                        child: Text(
                          'Menu',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                      // Toggle button.
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                          onPressed: _toggleSidebar,
                        ),
                      ),
                      // Navigation list.
                      Expanded(
                        child: ListView(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.track_changes,
                                  color: Colors.white),
                              title: const Text('Health Tracker',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () => _onItemTapped(0),
                            ),
                            ListTile(
                              leading: const Icon(Icons.report,
                                  color: Colors.white),
                              title: const Text('Health Report',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () => _onItemTapped(1),
                            ),
                            ListTile(
                              leading:
                                  const Icon(Icons.chat, color: Colors.white),
                              title: const Text('Health Assistant',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () => _onItemTapped(2),
                            ),
                            ListTile(
                              leading: const Icon(Icons.data_array,
                                  color: Colors.white),
                              title: const Text('Health App',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () => _onItemTapped(3),
                            ),
                            ListTile(
                              leading:
                                  const Icon(Icons.map, color: Colors.white),
                              title: const Text('Hospital Nearby',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () => _onItemTapped(4),
                            ),
                            ListTile(
                              leading:
                                  const Icon(Icons.person, color: Colors.white),
                              title: const Text('User Profile',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () => _onItemTapped(4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: _toggleSidebar,
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
