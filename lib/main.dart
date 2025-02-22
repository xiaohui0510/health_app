import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

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

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});
  
  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  bool showSummary = false;
  final TextEditingController sleepController = TextEditingController();
  final TextEditingController waterController = TextEditingController();
  final TextEditingController exerciseController = TextEditingController();
  final TextEditingController walkingController = TextEditingController();
  final TextEditingController anxietyController = TextEditingController();
  
  Future<void> _saveTrackerData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sleepHours', double.tryParse(sleepController.text) ?? 0.0);
    await prefs.setInt('waterIntake', int.tryParse(waterController.text) ?? 0);
    await prefs.setString('exercise', exerciseController.text);
    await prefs.setDouble('walkingDistance', double.tryParse(walkingController.text) ?? 0.0);
    await prefs.setInt('anxietyLevel', int.tryParse(anxietyController.text) ?? 0);
    
    // Save history data for sleep, water, and anxiety.
    List<String>? sleepHistory = prefs.getStringList('sleepHistory') ?? [];
    sleepHistory.add(sleepController.text);
    await prefs.setStringList('sleepHistory', sleepHistory);
    
    List<String>? waterHistory = prefs.getStringList('waterHistory') ?? [];
    waterHistory.add(waterController.text);
    await prefs.setStringList('waterHistory', waterHistory);
    
    List<String>? anxietyHistory = prefs.getStringList('anxietyHistory') ?? [];
    anxietyHistory.add(anxietyController.text);
    await prefs.setStringList('anxietyHistory', anxietyHistory);
    
    setState(() {
      showSummary = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView( // Enables scrolling if needed.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: sleepController,
              decoration: const InputDecoration(labelText: 'Sleep Hours'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: waterController,
              decoration: const InputDecoration(labelText: 'Water Intake (cups)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: exerciseController,
              decoration: const InputDecoration(labelText: 'Exercise Type & Duration (minutes)'),
            ),
            TextField(
              controller: walkingController,
              decoration: const InputDecoration(labelText: 'Walking Distance (km)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextField(
              controller: anxietyController,
              decoration: const InputDecoration(labelText: 'Anxiety Level (1-10)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveTrackerData, child: const Text('Save Data')),
            const SizedBox(height: 20),
            if (showSummary)
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Summary of Today\'s Activities:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('Sleep Hours: ${sleepController.text}'),
                      Text('Water Intake: ${waterController.text} cups'),
                      Text('Exercise: ${exerciseController.text}'),
                      Text('Walking Distance: ${walkingController.text} km'),
                      Text('Anxiety Level: ${anxietyController.text} /10'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TrendScreen extends StatefulWidget {
  const TrendScreen({super.key});
  
  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen> {
  List<FlSpot> sleepData = [];
  List<FlSpot> waterData = [];
  List<FlSpot> anxietyData = [];
  
  @override
  void initState() {
    super.initState();
    _loadTrendData();
  }
  
  Future<void> _loadTrendData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Load Sleep Data
    List<String>? sleepStrings = prefs.getStringList('sleepHistory');
    if (sleepStrings != null && sleepStrings.isNotEmpty) {
      sleepData = sleepStrings.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), double.tryParse(entry.value) ?? 8);
      }).toList();
    } else {
      // Dummy data for sleep (all values at 8)
      sleepData = List.generate(7, (index) => FlSpot(index.toDouble(), 8));
    }
    
    // Load Water Intake Data
    List<String>? waterStrings = prefs.getStringList('waterHistory');
    if (waterStrings != null && waterStrings.isNotEmpty) {
      waterData = waterStrings.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), double.tryParse(entry.value) ?? 8);
      }).toList();
    } else {
      // Dummy data for water intake (all values at 8)
      waterData = List.generate(7, (index) => FlSpot(index.toDouble(), 8));
    }
    
    // Load Anxiety Level Data
    List<String>? anxietyStrings = prefs.getStringList('anxietyHistory');
    if (anxietyStrings != null && anxietyStrings.isNotEmpty) {
      anxietyData = anxietyStrings.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), double.tryParse(entry.value) ?? 8);
      }).toList();
    } else {
      // Dummy data for anxiety level (all values at 8)
      anxietyData = List.generate(7, (index) => FlSpot(index.toDouble(), 8));
    }
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: sleepData.isEmpty || waterData.isEmpty || anxietyData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Text('Sleep Hours Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 6,
                      maxY: 10,
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sleepData,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.blue,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Water Intake Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 10,
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: waterData,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.green,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Anxiety Level Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 1,
                      maxY: 10,
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: anxietyData,
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.red,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});
  
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String selectedGoal = 'Keep Fit';
  final List<String> goals = ['Keep Fit', 'Good Health', 'Lose Weight'];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  
  String? name;
  int? age;
  double? height;
  double? weight;
  
  bool isEditing = false;
  
  Future<void> _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
      age = prefs.getInt('age');
      height = prefs.getDouble('height');
      weight = prefs.getDouble('weight');
      selectedGoal = prefs.getString('goal') ?? 'Keep Fit';
    });
  }
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _saveProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', nameController.text);
    await prefs.setInt('age', int.tryParse(ageController.text) ?? 0);
    await prefs.setDouble('height', double.tryParse(heightController.text) ?? 0.0);
    await prefs.setDouble('weight', double.tryParse(weightController.text) ?? 0.0);
    await prefs.setString('goal', selectedGoal);
    setState(() {
      isEditing = false;
    });
    _loadProfile();
  }
  
  Future<void> _deleteProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data
    setState(() {
      name = null;
      age = null;
      height = null;
      weight = null;
      nameController.clear();
      ageController.clear();
      heightController.clear();
      weightController.clear();
      isEditing = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing || name == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  TextField(
                    controller: heightController,
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedGoal,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    items: goals.map((goal) {
                      return DropdownMenuItem<String>(
                        value: goal,
                        child: Text(goal),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedGoal = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _saveProfile, child: const Text('Save Profile')),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $name', style: const TextStyle(fontSize: 18)),
                  Text('Age: $age', style: const TextStyle(fontSize: 18)),
                  Text('Height: $height cm', style: const TextStyle(fontSize: 18)),
                  Text('Weight: $weight kg', style: const TextStyle(fontSize: 18)),
                  Text('Goal: $selectedGoal', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () {
                    setState(() {
                      isEditing = true;
                      nameController.text = name ?? '';
                      ageController.text = age?.toString() ?? '';
                      heightController.text = height?.toString() ?? '';
                      weightController.text = weight?.toString() ?? '';
                    });
                  }, child: const Text('Edit Profile')),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _deleteProfile, child: const Text('Delete Profile')),
                ],
              ),
      ),
    );
  }
}

