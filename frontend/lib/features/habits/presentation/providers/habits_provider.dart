import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class Habit {
  final String id;
  final String name;
  final String? description;
  final String habitType;
  final String frequency;
  final int targetCount;
  final String icon;
  final String color;
  final bool isActive;
  final int currentStreak;
  final int longestStreak;
  final bool completedToday;
  final double completionRate7days;

  const Habit({
    required this.id,
    required this.name,
    this.description,
    required this.habitType,
    required this.frequency,
    required this.targetCount,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedToday,
    required this.completionRate7days,
  });

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'],
        habitType: j['habit_type'] as String,
        frequency: j['frequency'] as String,
        targetCount: j['target_count'] as int,
        icon: j['icon'] as String,
        color: j['color'] as String,
        isActive: j['is_active'] as bool,
        currentStreak: j['current_streak'] as int,
        longestStreak: j['longest_streak'] as int,
        completedToday: j['completed_today'] as bool,
        completionRate7days: (j['completion_rate_7days'] as num).toDouble(),
      );
}

class HabitSummary {
  final int totalHabits;
  final int activeHabits;
  final int completedToday;
  final int bestStreak;
  final List<Habit> habits;

  const HabitSummary({
    required this.totalHabits,
    required this.activeHabits,
    required this.completedToday,
    required this.bestStreak,
    required this.habits,
  });

  factory HabitSummary.fromJson(Map<String, dynamic> j) => HabitSummary(
        totalHabits: j['total_habits'] as int,
        activeHabits: j['active_habits'] as int,
        completedToday: j['completed_today'] as int,
        bestStreak: j['best_streak'] as int,
        habits: (j['habits'] as List).map((h) => Habit.fromJson(h as Map<String, dynamic>)).toList(),
      );
}

final habitsProvider = FutureProvider<HabitSummary>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/habits');
    return HabitSummary.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

class HabitsActions {
  final Dio _dio;
  final Ref _ref;
  HabitsActions(this._dio, this._ref);

  Future<void> logHabit(String habitId) async {
    await _dio.post('/habits/log', data: {
      'habit_id': habitId,
      'completed_at': DateTime.now().toIso8601String().split('T')[0],
    });
    _ref.invalidate(habitsProvider);
  }

  Future<void> createHabit({
    required String name,
    required String habitType,
    String? description,
    String icon = 'star',
    String color = '#6B4EFF',
  }) async {
    await _dio.post('/habits', data: {
      'name': name,
      'habit_type': habitType,
      'description': description,
      'icon': icon,
      'color': color,
    });
    _ref.invalidate(habitsProvider);
  }

  Future<void> deleteHabit(String habitId) async {
    await _dio.delete('/habits/$habitId');
    _ref.invalidate(habitsProvider);
  }
}

final habitsActionsProvider = Provider<HabitsActions>((ref) {
  return HabitsActions(ref.watch(dioProvider), ref);
});

final habitsHeatmapProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/habits/heatmap');
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});
