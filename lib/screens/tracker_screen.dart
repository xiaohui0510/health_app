import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracker_entry.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  List<TrackerEntry> _entries = [];
  bool _isLoading = true;

  // Filter type: 'week', 'month', or 'year'
  String _selectedFilterType = 'week';
  // For week filter: offset in weeks (0 = current week, -1 = previous, +1 = next)
  int _weekOffset = 0;
  // For month filter: selected month (1-12) and year.
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? entryStrings = prefs.getStringList('trackerEntries');
    if (entryStrings != null) {
      _entries = entryStrings
          .map((e) => TrackerEntry.fromJson(jsonDecode(e)))
          .toList();
      _entries.sort((a, b) => a.date.compareTo(b.date));
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> entryStrings =
        _entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('trackerEntries', entryStrings);
  }

  /// Returns the filtered entries based on the selected filter.
  List<TrackerEntry> get _filteredEntries {
    DateTime now = DateTime.now();
    if (_selectedFilterType == 'week') {
      // Get Monday (00:00) of current week.
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime monday = today.subtract(Duration(days: now.weekday - 1));
      // Apply week offset.
      DateTime startOfWeek = monday.add(Duration(days: _weekOffset * 7));
      // Sunday of that week.
      DateTime sunday = startOfWeek.add(const Duration(days: 6));
      // Set filter range: Monday 00:00 to Sunday 23:59:59.
      DateTime filterStart = startOfWeek;
      DateTime filterEnd =
          DateTime(sunday.year, sunday.month, sunday.day).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      return _entries.where((entry) {
        return entry.date.isAfter(filterStart.subtract(const Duration(milliseconds: 1))) &&
            entry.date.isBefore(filterEnd.add(const Duration(milliseconds: 1)));
      }).toList();
    } else if (_selectedFilterType == 'month') {
      return _entries.where((entry) {
        return entry.date.month == _selectedMonth && entry.date.year == _selectedYear;
      }).toList();
    } else if (_selectedFilterType == 'year') {
      return _entries.where((entry) {
        return entry.date.year == _selectedYear;
      }).toList();
    }
    return _entries;
  }

  /// Returns a sorted list of distinct years available in the entries.
  List<int> _availableYears() {
    final yearsSet = _entries.map((e) => e.date.year).toSet();
    List<int> years = yearsSet.toList();
    if (years.isEmpty) {
      years = [DateTime.now().year];
    }
    years.sort();
    return years;
  }

  void _openEntryForm({TrackerEntry? entry, int? index}) {
    final isEditing = entry != null && index != null;
    TextEditingController sleepController = TextEditingController(
        text: isEditing ? entry.sleepHours.toString() : '');
    TextEditingController waterController = TextEditingController(
        text: isEditing ? entry.waterIntake.toString() : '');
    TextEditingController exerciseController = TextEditingController(
        text: isEditing ? entry.exerciseType : '');
    TextEditingController stepsController = TextEditingController(
        text: isEditing ? entry.steps.toString() : '');
    TextEditingController caloriesController = TextEditingController(
        text: isEditing ? entry.totalCalories.toString() : '');
    DateTime selectedDate = isEditing ? entry.date : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? 'Edit Entry' : 'Add Entry',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Date picker row
                  Row(
                    children: [
                      const Text('Date: '),
                      Text("${selectedDate.toLocal()}".split(' ')[0]),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: sleepController,
                    decoration: const InputDecoration(labelText: 'Sleep Hours'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  TextField(
                    controller: waterController,
                    decoration: const InputDecoration(labelText: 'Water Intake (cups)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: exerciseController,
                    decoration: const InputDecoration(labelText: 'Exercise Type'),
                  ),
                  TextField(
                    controller: stepsController,
                    decoration: const InputDecoration(labelText: 'Steps'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: caloriesController,
                    decoration: const InputDecoration(labelText: 'Total Calories Used'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      double sleep = double.tryParse(sleepController.text) ?? 0;
                      int water = int.tryParse(waterController.text) ?? 0;
                      String exercise = exerciseController.text;
                      int steps = int.tryParse(stepsController.text) ?? 0;
                      double calories = double.tryParse(caloriesController.text) ?? 0;

                      TrackerEntry newEntry = TrackerEntry(
                        date: selectedDate,
                        sleepHours: sleep,
                        waterIntake: water,
                        exerciseType: exercise,
                        steps: steps,
                        totalCalories: calories,
                      );

                      if (isEditing) {
                        _entries[index!] = newEntry;
                      } else {
                        _entries.add(newEntry);
                      }
                      _entries.sort((a, b) => a.date.compareTo(b.date));
                      _saveEntries();
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: Text(isEditing ? 'Update Entry' : 'Add Entry'),
                  ),
                  if (isEditing)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        _entries.removeAt(index!);
                        _saveEntries();
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text('Delete Entry'),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Helper to format numbers as 'k' (e.g., 5430 becomes "5.4k")
  String _formatK(double value) {
    return "${(value / 1000).toStringAsFixed(1)}k";
  }

  // Build a chart with auto-scaled y-axis.
  Widget _buildChart(List<FlSpot> spots, Color color, {String Function(double)? leftFormatter}) {
    if (spots.isEmpty) return const Center(child: Text('Not enough data'));
    double minY = spots.first.y;
    double maxY = spots.first.y;
    for (var spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }
    double padding = (maxY - minY) * 0.5;
    if (padding == 0) padding = 1;
    minY -= padding;
    maxY += padding;
    double interval = (maxY - minY) / 4;
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: _bottomTitleWidgets,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              getTitlesWidget: (value, meta) {
                String label = leftFormatter != null ? leftFormatter(value) : value.toStringAsFixed(1);
                return Text(label, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: const SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: const SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black54,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((barSpot) {
                String valueText = leftFormatter != null ? leftFormatter(barSpot.y) : barSpot.y.toStringAsFixed(2);
                return LineTooltipItem("$valueText", const TextStyle(color: Colors.white, fontSize: 10));
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: color,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  // Convert relative days to formatted date for the x-axis.
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    if (_filteredEntries.isEmpty) return const SizedBox();
    final baseDate = _filteredEntries.first.date;
    final date = baseDate.add(Duration(days: value.toInt()));
    final formattedDate = "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
    return Text(formattedDate, style: const TextStyle(fontSize: 10));
  }

  List<FlSpot> _generateSleepData() {
    if (_filteredEntries.isEmpty) return [];
    final baseDate = _filteredEntries.first.date;
    return _filteredEntries.map((entry) {
      final x = entry.date.difference(baseDate).inDays.toDouble();
      return FlSpot(x, entry.sleepHours);
    }).toList();
  }

  List<FlSpot> _generateWaterData() {
    if (_filteredEntries.isEmpty) return [];
    final baseDate = _filteredEntries.first.date;
    return _filteredEntries.map((entry) {
      final x = entry.date.difference(baseDate).inDays.toDouble();
      return FlSpot(x, entry.waterIntake.toDouble());
    }).toList();
  }

  List<FlSpot> _generateStepsData() {
    if (_filteredEntries.isEmpty) return [];
    final baseDate = _filteredEntries.first.date;
    return _filteredEntries.map((entry) {
      final x = entry.date.difference(baseDate).inDays.toDouble();
      return FlSpot(x, entry.steps.toDouble());
    }).toList();
  }

  List<FlSpot> _generateCaloriesData() {
    if (_filteredEntries.isEmpty) return [];
    final baseDate = _filteredEntries.first.date;
    return _filteredEntries.map((entry) {
      final x = entry.date.difference(baseDate).inDays.toDouble();
      return FlSpot(x, entry.totalCalories);
    }).toList();
  }

  // Build filter widget(s) with a dropdown and week navigation buttons.
  Widget _buildFilterDropdowns() {
    if (_selectedFilterType == 'week') {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      // Get Monday of current week.
      DateTime monday = today.subtract(Duration(days: now.weekday - 1));
      DateTime startOfWeek = monday.add(Duration(days: _weekOffset * 7));
      DateTime sunday = startOfWeek.add(const Duration(days: 6));

      // For navigation label, always show the full Monday-Sunday range.
      String weekRangeLabel =
          "${startOfWeek.month.toString().padLeft(2, '0')}/${startOfWeek.day.toString().padLeft(2, '0')} - ${sunday.month.toString().padLeft(2, '0')}/${sunday.day.toString().padLeft(2, '0')}";

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Primary filter type dropdown.
          DropdownButton<String>(
            value: _selectedFilterType,
            items: const [
              DropdownMenuItem(value: 'week', child: Text('Week')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFilterType = value!;
                if (_selectedFilterType == 'week') {
                  _weekOffset = 0;
                } else if (_selectedFilterType == 'month') {
                  _selectedMonth = DateTime.now().month;
                  _selectedYear = DateTime.now().year;
                } else if (_selectedFilterType == 'year') {
                  _selectedYear = DateTime.now().year;
                }
              });
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.arrow_left),
            onPressed: () {
              setState(() {
                _weekOffset -= 1;
              });
            },
          ),
          Text(weekRangeLabel, style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.arrow_right),
            onPressed: () {
              setState(() {
                _weekOffset += 1;
              });
            },
          ),
        ],
      );
    } else if (_selectedFilterType == 'month') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: _selectedFilterType,
            items: const [
              DropdownMenuItem(value: 'week', child: Text('Week')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFilterType = value!;
                if (_selectedFilterType == 'month') {
                  _selectedMonth = DateTime.now().month;
                  _selectedYear = DateTime.now().year;
                } else if (_selectedFilterType == 'year') {
                  _selectedYear = DateTime.now().year;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _selectedMonth,
            items: List.generate(12, (index) {
              int month = index + 1;
              return DropdownMenuItem(
                value: month,
                child: Text(month.toString().padLeft(2, '0')),
              );
            }),
            onChanged: (value) {
              setState(() {
                _selectedMonth = value!;
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _selectedYear,
            items: _availableYears()
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text('$year'),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedYear = value!;
              });
            },
          ),
        ],
      );
    } else if (_selectedFilterType == 'year') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: _selectedFilterType,
            items: const [
              DropdownMenuItem(value: 'week', child: Text('Week')),
              DropdownMenuItem(value: 'month', child: Text('Month')),
              DropdownMenuItem(value: 'year', child: Text('Year')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedFilterType = value!;
                if (_selectedFilterType == 'year') {
                  _selectedYear = DateTime.now().year;
                }
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _selectedYear,
            items: _availableYears()
                .map((year) => DropdownMenuItem(
                      value: year,
                      child: Text('$year'),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedYear = value!;
              });
            },
          ),
        ],
      );
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracker & Trends'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openEntryForm();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter widget (dropdown and navigation if week)
                    _buildFilterDropdowns(),
                    const SizedBox(height: 20),
                    // Sleep Trend Graph
                    const Text('Sleep Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 200, child: _buildChart(_generateSleepData(), Colors.blue)),
                    const SizedBox(height: 20),
                    // Water Intake Trend Graph
                    const Text('Water Intake Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 200, child: _buildChart(_generateWaterData(), Colors.green)),
                    const SizedBox(height: 20),
                    // Steps Trend Graph with custom formatter (k format)
                    const Text('Steps Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 200, child: _buildChart(_generateStepsData(), Colors.orange, leftFormatter: _formatK)),
                    const SizedBox(height: 20),
                    // Calories Trend Graph with custom formatter (k format)
                    const Text('Calories Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 200, child: _buildChart(_generateCaloriesData(), Colors.purple, leftFormatter: _formatK)),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text('Tracker Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _filteredEntries.isEmpty
                        ? const Text('No entries yet.')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredEntries[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text('Date: ${entry.date.toLocal().toString().split(" ")[0]}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Sleep Hours: ${entry.sleepHours}'),
                                      Text('Water Intake: ${entry.waterIntake} cups'),
                                      Text('Exercise: ${entry.exerciseType}'),
                                      Text('Steps: ${entry.steps}'),
                                      Text('Calories: ${entry.totalCalories}'),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _openEntryForm(entry: entry, index: index);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
