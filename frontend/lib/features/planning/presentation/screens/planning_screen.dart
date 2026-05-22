import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';

final currentWeekPlanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/planning/current');
  return response.data as Map<String, dynamic>;
});

class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(currentWeekPlanProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(currentWeekPlanProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(s.weeklyPlan),
              floating: true,
              actions: [
                IconButton(
                  onPressed: () => _showAddItemSheet(context, ref, '', s),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            planAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e'))),
              data: (plan) {
                final items = List<Map<String, dynamic>>.from(plan['items'] as List);
                final weekStart = DateTime.parse(plan['week_start'] as String);
                final completionRate = (plan['completion_rate'] as num).toDouble();

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Week header
                      _WeekHeader(weekStart: weekStart, completionRate: completionRate, plan: plan, s: s)
                          .animate()
                          .fadeIn()
                          .slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      // Goal
                      if (plan['main_goal'] != null)
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.flag_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(plan['main_goal'] as String, style: Theme.of(context).textTheme.titleMedium)),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 16),
                      // Days
                      ...List.generate(7, (dayIdx) {
                        final dayDate = weekStart.add(Duration(days: dayIdx));
                        final dayItems = items.where((i) {
                          final itemDate = DateTime.parse(i['date'] as String);
                          return itemDate.day == dayDate.day && itemDate.month == dayDate.month;
                        }).toList();
                        final isToday = dayDate.day == DateTime.now().day && dayDate.month == DateTime.now().month;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DaySection(
                            date: dayDate,
                            items: dayItems,
                            isToday: isToday,
                            planId: plan['id'] as String,
                            s: s,
                            onAddItem: () => _showAddItemSheet(context, ref, DateFormat('yyyy-MM-dd').format(dayDate), s),
                            onToggle: (itemId) async {
                              final dio = ref.read(dioProvider);
                              final item = items.firstWhere((i) => i['id'] == itemId);
                              await dio.put('/planning/items/$itemId', data: {'is_completed': !(item['is_completed'] as bool)});
                              ref.invalidate(currentWeekPlanProvider);
                            },
                          ).animate().fadeIn(delay: Duration(milliseconds: 80 * dayIdx)),
                        );
                      }),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context, WidgetRef ref, String date, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final titleCtrl = TextEditingController();
        String actType = 'work';
        return StatefulBuilder(
          builder: (ctx, setState) => Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(color: Theme.of(ctx).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text(s.addPlanItem, style: Theme.of(ctx).textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  TextField(controller: titleCtrl, autofocus: true, decoration: InputDecoration(hintText: s.whatWillYouDo)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('work', s.actWork),
                      ('study', s.actStudy),
                      ('exercise', s.actExercise),
                      ('learning', s.actLearning),
                      ('rest', s.actRest),
                      ('social', s.actSocial),
                      ('routine', s.actRoutine),
                    ].map((t) =>
                      ChoiceChip(label: Text(t.$2), selected: actType == t.$1, onSelected: (_) => setState(() => actType = t.$1))
                    ).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty) return;
                        final dio = ref.read(dioProvider);
                        final plan = ref.read(currentWeekPlanProvider).value;
                        if (plan == null) return;
                        final itemDate = date.isEmpty ? DateFormat('yyyy-MM-dd').format(DateTime.now()) : date;
                        await dio.post('/planning/items', data: {
                          'weekly_plan_id': plan['id'],
                          'date': itemDate,
                          'title': titleCtrl.text,
                          'activity_type': actType,
                        });
                        ref.invalidate(currentWeekPlanProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(s.addItem),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final DateTime weekStart;
  final double completionRate;
  final Map<String, dynamic> plan;
  final S s;
  const _WeekHeader({required this.weekStart, required this.completionRate, required this.plan, required this.s});

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return GradientCard(
      colors: [AppColors.primary, AppColors.primaryLight],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d').format(weekEnd)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                '${completionRate.toInt()}% ${s.percentDone}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionRate / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<Map<String, dynamic>> items;
  final bool isToday;
  final String planId;
  final S s;
  final VoidCallback onAddItem;
  final Future<void> Function(String itemId) onToggle;

  const _DaySection({
    required this.date,
    required this.items,
    required this.isToday,
    required this.planId,
    required this.s,
    required this.onAddItem,
    required this.onToggle,
  });

  String _activityLabel(String type) {
    switch (type) {
      case 'work': return s.actWork;
      case 'study': return s.actStudy;
      case 'exercise': return s.actExercise;
      case 'learning': return s.actLearning;
      case 'rest': return s.actRest;
      case 'social': return s.actSocial;
      case 'routine': return s.actRoutine;
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isToday ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isToday ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('EEEE').format(date),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isToday ? AppColors.primary : null,
                fontWeight: isToday ? FontWeight.w700 : null,
              ),
            ),
            const Spacer(),
            IconButton(onPressed: onAddItem, icon: const Icon(Icons.add_rounded, size: 18), style: IconButton.styleFrom(minimumSize: const Size(28, 28), padding: EdgeInsets.zero)),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 40),
              child: GestureDetector(
                onTap: () => onToggle(item['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (item['is_completed'] as bool)
                        ? AppColors.success.withValues(alpha: 0.08)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (item['is_completed'] as bool)
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.textHint.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (item['is_completed'] as bool) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: (item['is_completed'] as bool) ? AppColors.success : AppColors.textHint,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: (item['is_completed'] as bool) ? TextDecoration.lineThrough : null,
                            color: (item['is_completed'] as bool) ? AppColors.textSecondary : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _activityColor(item['activity_type'] as String).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _activityLabel(item['activity_type'] as String),
                          style: TextStyle(fontSize: 10, color: _activityColor(item['activity_type'] as String), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 4),
            child: Text(s.nothingPlanned, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
          ),
      ],
    );
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'study': return AppColors.primary;
      case 'work': return AppColors.info;
      case 'exercise': return AppColors.secondary;
      case 'rest': return AppColors.accentGold;
      case 'social': return AppColors.accentOrange;
      default: return AppColors.textSecondary;
    }
  }
}
