import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class DashboardData {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlySavingsRate;
  final double totalSaved;
  final double totalSavingsTarget;
  final double savingsProgress;
  final String? topFundName;
  final double? topFundProgress;
  final int habitsCompletedToday;
  final int totalActiveHabits;
  final int bestStreak;
  final int todayWaterMl;
  final int waterGoalMl;
  final double waterPercentage;
  final double? lastSleepHours;
  final double sleepGoalHours;
  final double productiveHoursToday;
  final double studyHoursWeek;
  final int activeLearningItems;
  final double learningHoursWeek;
  final String motivationalMessage;
  final List<String> insights;
  final int streakDays;

  const DashboardData({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlySavingsRate,
    required this.totalSaved,
    required this.totalSavingsTarget,
    required this.savingsProgress,
    this.topFundName,
    this.topFundProgress,
    required this.habitsCompletedToday,
    required this.totalActiveHabits,
    required this.bestStreak,
    required this.todayWaterMl,
    required this.waterGoalMl,
    required this.waterPercentage,
    this.lastSleepHours,
    required this.sleepGoalHours,
    required this.productiveHoursToday,
    required this.studyHoursWeek,
    required this.activeLearningItems,
    required this.learningHoursWeek,
    required this.motivationalMessage,
    required this.insights,
    required this.streakDays,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        totalBalance: (json['total_balance'] as num).toDouble(),
        monthlyIncome: (json['monthly_income'] as num).toDouble(),
        monthlyExpenses: (json['monthly_expenses'] as num).toDouble(),
        monthlySavingsRate: (json['monthly_savings_rate'] as num).toDouble(),
        totalSaved: (json['total_saved'] as num).toDouble(),
        totalSavingsTarget: (json['total_savings_target'] as num).toDouble(),
        savingsProgress: (json['savings_progress'] as num).toDouble(),
        topFundName: json['top_fund_name'],
        topFundProgress: json['top_fund_progress'] != null
            ? (json['top_fund_progress'] as num).toDouble()
            : null,
        habitsCompletedToday: json['habits_completed_today'] as int,
        totalActiveHabits: json['total_active_habits'] as int,
        bestStreak: json['best_streak'] as int,
        todayWaterMl: json['today_water_ml'] as int,
        waterGoalMl: json['water_goal_ml'] as int,
        waterPercentage: (json['water_percentage'] as num).toDouble(),
        lastSleepHours: json['last_sleep_hours'] != null
            ? (json['last_sleep_hours'] as num).toDouble()
            : null,
        sleepGoalHours: (json['sleep_goal_hours'] as num).toDouble(),
        productiveHoursToday: (json['productive_hours_today'] as num).toDouble(),
        studyHoursWeek: (json['study_hours_week'] as num).toDouble(),
        activeLearningItems: json['active_learning_items'] as int,
        learningHoursWeek: (json['learning_hours_week'] as num).toDouble(),
        motivationalMessage: json['motivational_message'] as String,
        insights: List<String>.from(json['insights'] as List),
        streakDays: json['streak_days'] as int,
      );
}

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/dashboard');
    return DashboardData.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

final weeklyReviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/analytics/weekly-review');
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

final diaryTodayCountProvider = FutureProvider<int>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/diary/today');
    return (response.data as List).length;
  } catch (_) {
    return 0;
  }
});
