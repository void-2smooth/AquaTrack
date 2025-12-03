import '../models/water_entry.dart';
import '../services/storage_service.dart';

/// Service for calculating analytics and insights
class AnalyticsService {
  final StorageService _storageService;

  AnalyticsService(this._storageService);

  /// Calculate daily hydration score (0-100)
  /// Based on: goal completion (50%), consistency (30%), streak (20%)
  double calculateDailyScore(DateTime date) {
    final entries = _storageService.getEntriesForDate(date);
    final settings = _storageService.getSettings();
    final goal = settings.effectiveDailyGoalMl;
    
    if (entries.isEmpty) return 0.0;

    // Goal completion (50% weight)
    final totalMl = entries.fold(0.0, (sum, e) => sum + e.amountMl);
    final goalCompletion = (totalMl / goal).clamp(0.0, 1.0);
    final goalScore = goalCompletion * 50;

    // Consistency (30% weight) - how evenly distributed throughout the day
    final consistencyScore = _calculateConsistencyScore(entries) * 30;

    // Streak bonus (20% weight)
    final streakScore = _calculateStreakScore(settings.currentStreak) * 20;

    return (goalScore + consistencyScore + streakScore).clamp(0.0, 100.0);
  }

  /// Calculate consistency score (0-1)
  /// Measures how evenly water is distributed throughout the day
  double _calculateConsistencyScore(List<WaterEntry> entries) {
    if (entries.length < 2) return 0.5; // Neutral score for single entry

    // Group entries by hour
    final hourlyDistribution = <int, double>{};
    for (final entry in entries) {
      final hour = entry.timestamp.hour;
      hourlyDistribution[hour] = (hourlyDistribution[hour] ?? 0) + entry.amountMl;
    }

    // Calculate variance - lower variance = more consistent
    final values = hourlyDistribution.values.toList();
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final stdDev = variance > 0 ? variance : 0.0;

    // Normalize to 0-1 (lower stdDev = higher score)
    final maxStdDev = mean * 2; // Rough estimate
    final normalizedStdDev = maxStdDev > 0 ? (stdDev / maxStdDev).clamp(0.0, 1.0) : 0.0;
    
    return 1.0 - normalizedStdDev;
  }

  /// Calculate streak score (0-1)
  double _calculateStreakScore(int streak) {
    // Logarithmic scale: 0 days = 0, 7 days = 0.5, 30 days = 1.0
    if (streak == 0) return 0.0;
    return (1.0 - (1.0 / (1.0 + streak / 7.0))).clamp(0.0, 1.0);
  }

  /// Get weekly average score
  double getWeeklyAverageScore() {
    final now = DateTime.now();
    double total = 0.0;
    int days = 0;

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final score = calculateDailyScore(date);
      if (score > 0) {
        total += score;
        days++;
      }
    }

    return days > 0 ? total / days : 0.0;
  }

  /// Get best hydration time of day
  int getBestHydrationHour() {
    final entries = _storageService.getAllEntries();
    if (entries.isEmpty) return 12; // Default to noon

    final hourlyTotals = <int, double>{};
    for (final entry in entries) {
      final hour = entry.timestamp.hour;
      hourlyTotals[hour] = (hourlyTotals[hour] ?? 0) + entry.amountMl;
    }

    if (hourlyTotals.isEmpty) return 12;

    return hourlyTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get worst hydration time of day
  int getWorstHydrationHour() {
    final entries = _storageService.getAllEntries();
    if (entries.isEmpty) return 0; // Default to midnight

    final hourlyTotals = <int, double>{};
    for (final entry in entries) {
      final hour = entry.timestamp.hour;
      hourlyTotals[hour] = (hourlyTotals[hour] ?? 0) + entry.amountMl;
    }

    if (hourlyTotals.isEmpty) return 0;

    return hourlyTotals.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// Get day-of-week patterns
  Map<String, double> getDayOfWeekPatterns() {
    final entries = _storageService.getAllEntries();
    final patterns = <String, List<double>>{
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
    };

    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    // Group entries by day of week
    final dailyTotals = <String, double>{};
    for (final entry in entries) {
      final dayName = dayNames[entry.timestamp.weekday - 1];
      dailyTotals[dayName] = (dailyTotals[dayName] ?? 0) + entry.amountMl;
      patterns[dayName]!.add(entry.amountMl);
    }

    // Calculate averages
    final averages = <String, double>{};
    for (final entry in patterns.entries) {
      if (entry.value.isNotEmpty) {
        averages[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      } else {
        averages[entry.key] = 0.0;
      }
    }

    return averages;
  }

  /// Get time distribution (for pie chart)
  Map<int, double> getTimeDistribution() {
    final entries = _storageService.getAllEntries();
    final distribution = <int, double>{};

    // Group into 4-hour blocks: 0-4, 4-8, 8-12, 12-16, 16-20, 20-24
    for (final entry in entries) {
      final hour = entry.timestamp.hour;
      final block = (hour ~/ 4) * 4;
      distribution[block] = (distribution[block] ?? 0) + entry.amountMl;
    }

    return distribution;
  }

  /// Get average daily intake for period
  double getAverageDailyIntake(int days) {
    final now = DateTime.now();
    double total = 0.0;
    int dayCount = 0;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final entries = _storageService.getEntriesForDate(date);
      final dayTotal = entries.fold(0.0, (sum, e) => sum + e.amountMl);
      if (dayTotal > 0) {
        total += dayTotal;
        dayCount++;
      }
    }

    return dayCount > 0 ? total / dayCount : 0.0;
  }

  /// Get goal completion rate
  double getGoalCompletionRate(int days) {
    final now = DateTime.now();
    final settings = _storageService.getSettings();
    final goal = settings.effectiveDailyGoalMl;
    
    int completedDays = 0;
    int totalDays = 0;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final entries = _storageService.getEntriesForDate(date);
      final dayTotal = entries.fold(0.0, (sum, e) => sum + e.amountMl);
      
      if (entries.isNotEmpty) {
        totalDays++;
        if (dayTotal >= goal) {
          completedDays++;
        }
      }
    }

    return totalDays > 0 ? (completedDays / totalDays) * 100 : 0.0;
  }

  /// Get total water consumed (all time)
  double getTotalWaterConsumed() {
    final entries = _storageService.getAllEntries();
    return entries.fold(0.0, (sum, e) => sum + e.amountMl);
  }

  /// Get days tracked count
  int getDaysTracked() {
    final entries = _storageService.getAllEntries();
    final uniqueDays = entries.map((e) => 
      DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day)
    ).toSet();
    return uniqueDays.length;
  }

  /// Get improvement suggestions
  List<String> getImprovementSuggestions() {
    final suggestions = <String>[];
    final settings = _storageService.getSettings();
    final goal = settings.effectiveDailyGoalMl;
    final avg7Days = getAverageDailyIntake(7);
    final completionRate = getGoalCompletionRate(7);
    final bestHour = getBestHydrationHour();
    final worstHour = getWorstHydrationHour();

    if (avg7Days < goal * 0.8) {
      suggestions.add('Try to increase your daily intake by ${((goal - avg7Days) / 1000).toStringAsFixed(1)}L');
    }

    if (completionRate < 50) {
      suggestions.add('Focus on completing your daily goal more consistently');
    }

    if (worstHour >= 20 || worstHour < 6) {
      suggestions.add('Consider drinking more water during evening hours');
    }

    if (bestHour >= 6 && bestHour < 12) {
      suggestions.add('Great job hydrating in the morning! Keep it up!');
    }

    if (settings.currentStreak < 3) {
      suggestions.add('Build a streak by logging water every day');
    }

    return suggestions;
  }
}

