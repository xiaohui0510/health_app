import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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