import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                  TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name')),
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
                  ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile')),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: $name', style: const TextStyle(fontSize: 18)),
                  Text('Age: $age', style: const TextStyle(fontSize: 18)),
                  Text('Height: $height cm',
                      style: const TextStyle(fontSize: 18)),
                  Text('Weight: $weight kg',
                      style: const TextStyle(fontSize: 18)),
                  Text('Goal: $selectedGoal',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = true;
                          nameController.text = name ?? '';
                          ageController.text = age?.toString() ?? '';
                          heightController.text = height?.toString() ?? '';
                          weightController.text = weight?.toString() ?? '';
                        });
                      },
                      child: const Text('Edit Profile')),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: _deleteProfile,
                      child: const Text('Delete Profile')),
                ],
              ),
      ),
    );
  }
}
