// tracker_entry.dart

class TrackerEntry {
  DateTime date;
  double sleepHours;
  int waterIntake;
  String exerciseType;
  int steps;
  double totalCalories;

  TrackerEntry({
    required this.date,
    required this.sleepHours,
    required this.waterIntake,
    required this.exerciseType,
    required this.steps,
    required this.totalCalories,
  });

  factory TrackerEntry.fromJson(Map<String, dynamic> json) {
    return TrackerEntry(
      date: DateTime.parse(json['date'] as String),
      sleepHours: (json['sleepHours'] as num).toDouble(),
      waterIntake: json['waterIntake'] as int,
      exerciseType: json['exerciseType'] as String,
      steps: json['steps'] as int,
      totalCalories: (json['totalCalories'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'sleepHours': sleepHours,
        'waterIntake': waterIntake,
        'exerciseType': exerciseType,
        'steps': steps,
        'totalCalories': totalCalories,
      };
}
