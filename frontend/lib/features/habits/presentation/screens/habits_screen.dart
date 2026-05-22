import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/habits_provider.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(habitsProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(s.habits),
              floating: true,
              actions: [
                IconButton(
                  onPressed: () => _showCreateHabitSheet(context, ref),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            habitsAsync.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
              data: (summary) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HabitsSummaryRow(summary: summary, s: s)
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    const _HabitHeatmap().animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 20),
                    // Positive habits
                    Text(s.positiveHabits, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    ...summary.habits.where((h) => h.habitType == 'positive').toList().asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HabitCard(
                              habit: e.value,
                              onComplete: () => ref.read(habitsActionsProvider).logHabit(e.value.id),
                              onDelete: () => _confirmDeleteHabit(context, ref, e.value, s),
                            ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)).slideY(begin: 0.1),
                          ),
                        ),
                    // Negative habits
                    if (summary.habits.any((h) => h.habitType == 'negative')) ...[
                      const SizedBox(height: 16),
                      Text(s.breakingHabits, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      ...summary.habits.where((h) => h.habitType == 'negative').toList().asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HabitCard(
                                habit: e.value,
                                onComplete: null,
                                onDelete: () => _confirmDeleteHabit(context, ref, e.value, s),
                              ),
                            ),
                          ),
                    ],
                    if (summary.habits.isEmpty)
                      _EmptyHabits(s: s, onAdd: () => _showCreateHabitSheet(context, ref)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteHabit(BuildContext context, WidgetRef ref, Habit habit, S s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text('¿Eliminar el hábito "${habit.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(habitsActionsProvider).deleteHabit(habit.id);
    }
  }

  void _showCreateHabitSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateHabitSheet(
        onCreate: (name, type, desc) => ref.read(habitsActionsProvider).createHabit(
              name: name,
              habitType: type,
              description: desc,
            ),
      ),
    );
  }
}

class _HabitsSummaryRow extends StatelessWidget {
  final HabitSummary summary;
  final S s;
  const _HabitsSummaryRow({required this.summary, required this.s});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.today, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '${summary.completedToday}/${summary.activeHabits}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(s.done, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.bestStreak, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${summary.bestStreak}',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppColors.accentOrange,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                  ],
                ),
                Text(s.days, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final Habit habit;
  final Future<void> Function()? onComplete;
  final VoidCallback onDelete;
  const _HabitCard({required this.habit, this.onComplete, required this.onDelete});

  Color get _color {
    try {
      final hex = habit.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final theme = Theme.of(context);
    final color = _color;
    final isDone = habit.completedToday;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Completion toggle
          GestureDetector(
            onTap: isDone || onComplete == null ? null : onComplete,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDone ? color : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: isDone ? null : Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                color: isDone ? Colors.white : color,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textSecondary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${habit.completionRate7days.toInt()}% ${s.last7Days}',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    if (habit.currentStreak > 0) ...[
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          Text(
                            ' ${habit.currentStreak}d',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (habit.currentStreak >= 30 && habit.currentStreak % 30 == 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🏆', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 2),
                                Text(
                                  '${habit.currentStreak ~/ 30}× ${s.streak}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: habit.completionRate7days / 100,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            onPressed: onDelete,
            color: AppColors.error.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  final VoidCallback onAdd;
  final S s;
  const _EmptyHabits({required this.onAdd, required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('⚡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(s.noHabits, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(s.noHabitsDesc, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Onboarding tip card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(s.habitTip, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(s.habitTipDesc, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s.habitRewardTip, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(s.addFirstHabit),
          ),
        ],
      ),
    );
  }
}

// ── Heatmap ───────────────────────────────────────────────────────────────────

class _HabitHeatmap extends ConsumerWidget {
  const _HabitHeatmap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final heatmapAsync = ref.watch(habitsHeatmapProvider);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(s.last90Days, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          heatmapAsync.when(
            loading: () => const Center(child: SizedBox(height: 60, child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final heatmap = data['heatmap'] as Map<String, dynamic>;
              final today = DateTime.now();
              final start = today.subtract(const Duration(days: 89));

              // Build 13 weeks x 7 days grid
              final weeks = <List<DateTime?>>[];
              var cursor = start;
              // Pad to start of week (Monday)
              final padDays = (cursor.weekday - 1) % 7;
              List<DateTime?> week = List.filled(padDays, null, growable: true);

              while (!cursor.isAfter(today)) {
                week.add(cursor);
                if (week.length == 7) {
                  weeks.add(week);
                  week = <DateTime?>[];
                }
                cursor = cursor.add(const Duration(days: 1));
              }
              if (week.isNotEmpty) {
                while (week.length < 7) week.add(null);
                weeks.add(week);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: weeks.map((w) => Expanded(
                      child: Column(
                        children: w.map((day) {
                          if (day == null) return const SizedBox(height: 14);
                          final key = DateFormat('yyyy-MM-dd').format(day);
                          final count = (heatmap[key] as num?)?.toInt() ?? 0;
                          final totalHabits = (data['total_habits'] as num).toInt();
                          final intensity = totalHabits > 0 ? (count / totalHabits).clamp(0.0, 1.0) : 0.0;
                          Color cellColor;
                          if (intensity == 0) {
                            cellColor = AppColors.secondary.withValues(alpha: 0.06);
                          } else if (intensity < 0.33) {
                            cellColor = AppColors.secondary.withValues(alpha: 0.25);
                          } else if (intensity < 0.67) {
                            cellColor = AppColors.secondary.withValues(alpha: 0.55);
                          } else {
                            cellColor = AppColors.secondary;
                          }
                          final isToday = DateFormat('yyyy-MM-dd').format(today) == key;
                          return Padding(
                            padding: const EdgeInsets.all(1.5),
                            child: Tooltip(
                              message: '$count hábitos — $key',
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: cellColor,
                                  borderRadius: BorderRadius.circular(2),
                                  border: isToday ? Border.all(color: AppColors.secondary, width: 1) : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(s.less, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                      const SizedBox(width: 4),
                      ...List.generate(4, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: [0.06, 0.25, 0.55, 1.0][i]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )),
                      const SizedBox(width: 4),
                      Text(s.more, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CreateHabitSheet extends StatefulWidget {
  final Future<void> Function(String name, String type, String? desc) onCreate;
  const _CreateHabitSheet({required this.onCreate});

  @override
  State<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<_CreateHabitSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'positive';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onCreate(_nameCtrl.text, _type, _descCtrl.text.isEmpty ? null : _descCtrl.text);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // _CreateHabitSheet is a StatefulWidget inside a ConsumerWidget context,
    // so we use the localeProvider via a Consumer to get s
    return Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeProvider);
        final s = S(locale);
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(s.newHabit, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'positive'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'positive' ? AppColors.secondary.withValues(alpha: 0.15) : null,
                            border: Border.all(color: _type == 'positive' ? AppColors.secondary : AppColors.textHint.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(s.positive, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'negative'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'negative' ? AppColors.error.withValues(alpha: 0.15) : null,
                            border: Border.all(color: _type == 'negative' ? AppColors.error : AppColors.textHint.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(s.breakBad, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(controller: _nameCtrl, decoration: InputDecoration(hintText: s.habitName)),
                const SizedBox(height: 12),
                TextField(controller: _descCtrl, decoration: InputDecoration(hintText: s.description)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(s.createHabit),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
