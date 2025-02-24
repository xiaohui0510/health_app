import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

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