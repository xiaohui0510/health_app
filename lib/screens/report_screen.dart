import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tracker_entry.dart';

enum ReportType { daily, weekly, monthly }

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<TrackerEntry> _entries = [];
  bool _isLoading = true;
  String _reportText = "";

  ReportType _selectedReportType = ReportType.daily;
  DateTime _selectedDate = DateTime.now();

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _loadEntriesAndInitialize();
  }

  Future<void> _loadEntriesAndInitialize() async {
    await _loadEntries();
    final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint("❌ API Key is missing. Please check your .env file.");
      return;
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
    _chatSession = _model.startChat();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedEntries = prefs.getStringList('trackerEntries');
    if (storedEntries != null) {
      _entries = storedEntries
          .map((e) => TrackerEntry.fromJson(jsonDecode(e)))
          .toList();
      _entries.sort((a, b) => a.date.compareTo(b.date));
    }
  }

  /// Filters entries based on the selected report type and _selectedDate.
  List<TrackerEntry> get _filteredEntries {
    if (_entries.isEmpty) return [];
    switch (_selectedReportType) {
      case ReportType.daily:
        return _entries.where((entry) {
          return entry.date.year == _selectedDate.year &&
              entry.date.month == _selectedDate.month &&
              entry.date.day == _selectedDate.day;
        }).toList();
      case ReportType.weekly:
        // Compute Monday of the week for the selected date.
        DateTime day = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        DateTime monday = day.subtract(Duration(days: day.weekday - 1));
        DateTime sunday = monday.add(const Duration(days: 6));
        return _entries.where((entry) {
          DateTime d = entry.date;
          return d.isAtSameMomentAs(monday) ||
              (d.isAfter(monday) && d.isBefore(sunday)) ||
              d.isAtSameMomentAs(sunday);
        }).toList();
      case ReportType.monthly:
        return _entries.where((entry) {
          return entry.date.year == _selectedDate.year &&
              entry.date.month == _selectedDate.month;
        }).toList();
    }
  }

  /// Preprocess the filtered data to compute summary statistics.
  String _preprocessData() {
    final data = _filteredEntries;
    if (data.isEmpty) {
      return "No health data available for the selected period.";
    }
    int count = data.length;
    double totalSleep = 0, totalCalories = 0;
    int totalWater = 0, totalSteps = 0;
    Map<String, int> exerciseFrequency = {};
    for (var entry in data) {
      totalSleep += entry.sleepHours;
      totalWater += entry.waterIntake;
      totalSteps += entry.steps;
      totalCalories += entry.totalCalories;
      exerciseFrequency[entry.exerciseType] =
          (exerciseFrequency[entry.exerciseType] ?? 0) + 1;
    }
    double avgSleep = totalSleep / count;
    double avgCalories = totalCalories / count;
    int avgWater = (totalWater / count).round();
    int avgSteps = (totalSteps / count).round();

    String exerciseSummary = exerciseFrequency.entries
        .map((e) => "${e.key}: ${e.value} times")
        .join(", ");

    String period;
    switch (_selectedReportType) {
      case ReportType.daily:
        period = "on ${_selectedDate.toLocal().toString().split(' ')[0]}";
        break;
      case ReportType.weekly:
        DateTime day = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        DateTime monday = day.subtract(Duration(days: day.weekday - 1));
        DateTime sunday = monday.add(const Duration(days: 6));
        period =
            "from ${monday.toLocal().toString().split(' ')[0]} to ${sunday.toLocal().toString().split(' ')[0]}";
        break;
      case ReportType.monthly:
        period = "in ${_selectedDate.month}/${_selectedDate.year}";
        break;
    }

    return "For the period $period over $count day(s), the average sleep was ${avgSleep.toStringAsFixed(1)} hours, average water intake was $avgWater cups, average steps were $avgSteps, and average calories burned were ${avgCalories.toStringAsFixed(0)}. Exercise activities recorded include: $exerciseSummary.";
  }

  /// Sends the preprocessed summary as a prompt to the AI model and retrieves a report.
  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _reportText = "";
    });
    String rawSummary = _preprocessData();
    String prompt = "Based on the following health data summary, generate a detailed report and provide some health advice:\n\n"
        "$rawSummary\n\nReport:";
    try {
      final response = await _chatSession.sendMessage(Content.text(prompt));
      String aiReport = response.text ?? "No report generated.";
      setState(() {
        _reportText = aiReport;
      });
    } catch (e) {
      setState(() {
        _reportText = "Error generating report: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// A simple markdown parser that renders text between ** or ## in bold.
  TextSpan _parseMarkdown(String text) {
    // Split on ** first.
    List<String> parts = text.split('**');
    List<TextSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      if (i % 2 == 1) {
        spans.add(TextSpan(text: parts[i], style: const TextStyle(fontWeight: FontWeight.bold)));
      } else {
        // Also split on "##" to treat them as bold.
        List<String> subParts = parts[i].split('##');
        for (int j = 0; j < subParts.length; j++) {
          if (subParts[j].isEmpty) continue;
          if (j % 2 == 1) {
            spans.add(TextSpan(text: subParts[j], style: const TextStyle(fontWeight: FontWeight.bold)));
          } else {
            spans.add(TextSpan(text: subParts[j]));
          }
        }
      }
    }
    return TextSpan(children: spans, style: const TextStyle(fontSize: 16, color: Colors.black));
  }

  /// Builds the report view.
  Widget _buildReportView() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reportText.isEmpty
                ? const Center(child: Text("Press 'Generate Report' to view your report."))
                : SingleChildScrollView(child: RichText(text: _parseMarkdown(_reportText))),
      ),
    );
  }

  /// Builds the report options row with a dropdown for report type and a date picker button.
  Widget _buildReportOptions() {
    String buttonLabel;
    switch (_selectedReportType) {
      case ReportType.daily:
        buttonLabel = "Select Date: ${_selectedDate.toLocal().toString().split(' ')[0]}";
        break;
      case ReportType.weekly:
        DateTime day = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        DateTime monday = day.subtract(Duration(days: day.weekday - 1));
        DateTime sunday = monday.add(const Duration(days: 6));
        buttonLabel =
            "${monday.toLocal().toString().split(' ')[0]} - ${sunday.toLocal().toString().split(' ')[0]}";
        break;
      case ReportType.monthly:
        buttonLabel = "Select Month: ${_selectedDate.month}/${_selectedDate.year}";
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton<ReportType>(
          value: _selectedReportType,
          items: const [
            DropdownMenuItem(value: ReportType.daily, child: Text("Daily")),
            DropdownMenuItem(value: ReportType.weekly, child: Text("Weekly")),
            DropdownMenuItem(value: ReportType.monthly, child: Text("Monthly")),
          ],
          onChanged: (value) {
            setState(() {
              _selectedReportType = value!;
              // Reset to current date when report type changes.
              _selectedDate = DateTime.now();
            });
          },
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked; // Use picked! if necessary.
              });
            }
          },
          child: Text(buttonLabel),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Report"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildReportOptions(),
          const SizedBox(height: 16),
          Expanded(child: _buildReportView()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateReport,
        icon: const Icon(Icons.assessment),
        label: const Text("Generate Report"),
      ),
    );
  }
}
