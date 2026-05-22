import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class SavingsFund {
  final String id;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final double monthlyContribution;
  final int priority;
  final String color;
  final String icon;
  final String? deadline;
  final bool isAchieved;
  final String? notes;
  final double progressPercentage;
  final int? monthsToGoal;

  const SavingsFund({
    required this.id,
    required this.name,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlyContribution,
    required this.priority,
    required this.color,
    required this.icon,
    this.deadline,
    required this.isAchieved,
    this.notes,
    required this.progressPercentage,
    this.monthsToGoal,
  });

  factory SavingsFund.fromJson(Map<String, dynamic> j) => SavingsFund(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'],
        targetAmount: (j['target_amount'] as num).toDouble(),
        currentAmount: (j['current_amount'] as num).toDouble(),
        monthlyContribution: (j['monthly_contribution'] as num).toDouble(),
        priority: j['priority'] as int,
        color: j['color'] as String,
        icon: j['icon'] as String,
        deadline: j['deadline'],
        isAchieved: j['is_achieved'] as bool,
        notes: j['notes'],
        progressPercentage: (j['progress_percentage'] as num).toDouble(),
        monthsToGoal: j['months_to_goal'],
      );
}

class SavingsSummary {
  final double totalSaved;
  final double totalTarget;
  final double overallProgress;
  final int activeFunds;
  final int achievedFunds;
  final List<SavingsFund> funds;

  const SavingsSummary({
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgress,
    required this.activeFunds,
    required this.achievedFunds,
    required this.funds,
  });

  factory SavingsSummary.fromJson(Map<String, dynamic> j) => SavingsSummary(
        totalSaved: (j['total_saved'] as num).toDouble(),
        totalTarget: (j['total_target'] as num).toDouble(),
        overallProgress: (j['overall_progress'] as num).toDouble(),
        activeFunds: j['active_funds'] as int,
        achievedFunds: j['achieved_funds'] as int,
        funds: (j['funds'] as List).map((f) => SavingsFund.fromJson(f as Map<String, dynamic>)).toList(),
      );
}

final savingsProvider = FutureProvider<SavingsSummary>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/savings');
    return SavingsSummary.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

class SavingsActions {
  final Dio _dio;
  final Ref _ref;
  SavingsActions(this._dio, this._ref);

  Future<void> createFund({
    required String name,
    String? description,
    required double targetAmount,
    double currentAmount = 0,
    double monthlyContribution = 0,
    int priority = 3,
    String color = '#6B4EFF',
    String icon = 'savings',
    String? deadline,
    String? notes,
  }) async {
    await _dio.post('/savings', data: {
      'name': name,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'monthly_contribution': monthlyContribution,
      'priority': priority,
      'color': color,
      'icon': icon,
      'deadline': deadline,
      'notes': notes,
    });
    _ref.invalidate(savingsProvider);
  }

  Future<void> contribute(String fundId, double amount, String date) async {
    await _dio.post('/savings/$fundId/contribute', data: {
      'fund_id': fundId,
      'amount': amount,
      'date': date,
    });
    _ref.invalidate(savingsProvider);
  }

  Future<void> deleteFund(String fundId) async {
    await _dio.delete('/savings/$fundId');
    _ref.invalidate(savingsProvider);
  }
}

final savingsActionsProvider = Provider<SavingsActions>((ref) {
  return SavingsActions(ref.watch(dioProvider), ref);
});
