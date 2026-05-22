import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class SkillModel {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String emoji;
  final String color;
  final int? targetDays;
  final int? targetSessions;
  final bool isActive;
  final int currentStreak;
  final int longestStreak;
  final int totalSessions;
  final int totalMinutes;
  final int? daysSinceStart;
  final double? progressPct;
  final bool loggedToday;

  const SkillModel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.emoji,
    required this.color,
    this.targetDays,
    this.targetSessions,
    required this.isActive,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalSessions,
    required this.totalMinutes,
    this.daysSinceStart,
    this.progressPct,
    required this.loggedToday,
  });

  factory SkillModel.fromJson(Map<String, dynamic> j) => SkillModel(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        category: j['category'] as String?,
        emoji: j['emoji'] as String? ?? '⭐',
        color: j['color'] as String? ?? '#6B4EFF',
        targetDays: j['target_days'] as int?,
        targetSessions: j['target_sessions'] as int?,
        isActive: j['is_active'] as bool? ?? true,
        currentStreak: j['current_streak'] as int? ?? 0,
        longestStreak: j['longest_streak'] as int? ?? 0,
        totalSessions: j['total_sessions'] as int? ?? 0,
        totalMinutes: j['total_minutes'] as int? ?? 0,
        daysSinceStart: j['days_since_start'] as int?,
        progressPct: (j['progress_pct'] as num?)?.toDouble(),
        loggedToday: j['logged_today'] as bool? ?? false,
      );
}

class SkillsSummary {
  final int totalSkills;
  final int activeSkills;
  final int totalSessionsToday;
  final int bestStreak;
  final List<SkillModel> skills;

  const SkillsSummary({
    required this.totalSkills,
    required this.activeSkills,
    required this.totalSessionsToday,
    required this.bestStreak,
    required this.skills,
  });

  factory SkillsSummary.fromJson(Map<String, dynamic> j) => SkillsSummary(
        totalSkills: j['total_skills'] as int? ?? 0,
        activeSkills: j['active_skills'] as int? ?? 0,
        totalSessionsToday: j['total_sessions_today'] as int? ?? 0,
        bestStreak: j['best_streak'] as int? ?? 0,
        skills: (j['skills'] as List<dynamic>? ?? [])
            .map((e) => SkillModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

final skillsSummaryProvider = FutureProvider<SkillsSummary>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/skills/summary');
  return SkillsSummary.fromJson(res.data as Map<String, dynamic>);
});

class SkillsActions {
  final Ref ref;
  SkillsActions(this.ref);

  Future<void> createSkill(Map<String, dynamic> data) async {
    final dio = ref.read(dioProvider);
    await dio.post('/skills/', data: data);
    ref.invalidate(skillsSummaryProvider);
  }

  Future<void> logSession(Map<String, dynamic> data) async {
    final dio = ref.read(dioProvider);
    await dio.post('/skills/log', data: data);
    ref.invalidate(skillsSummaryProvider);
  }

  Future<void> deleteSkill(String id) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/skills/$id');
    ref.invalidate(skillsSummaryProvider);
  }
}

final skillsActionsProvider = Provider((ref) => SkillsActions(ref));
