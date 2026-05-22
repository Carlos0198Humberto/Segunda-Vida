import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_ring.dart';

final healthSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/health/summary');
  return response.data as Map<String, dynamic>;
});

final gymSessionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/health/gym', queryParameters: {'limit': 30});
  return response.data as List;
});

final hydrationTodayProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/health/hydration/today');
  return response.data as Map<String, dynamic>;
});

final sleepLogsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/health/sleep', queryParameters: {'limit': 7});
  return response.data as List;
});

final mealsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final response = await dio.get('/health/meals', queryParameters: {'day': today});
  return response.data as List;
});

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            title: Text(s.healthWellness),
            floating: true,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: s.hydrationTab),
                Tab(text: s.sleepTab),
                Tab(text: s.mealsTab),
                Tab(text: s.gymTab),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              dividerColor: Colors.transparent,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _HydrationTab(),
            _SleepTab(),
            _MealsTab(),
            _GymTab(),
          ],
        ),
      ),
    );
  }
}

class _HydrationTab extends ConsumerWidget {
  const _HydrationTab();

  static const _containers = [
    {'label': 'Vaso pequeño', 'ml': 200, 'icon': Icons.local_cafe_rounded, 'emoji': '🥛'},
    {'label': 'Vaso grande', 'ml': 350, 'icon': Icons.local_drink_rounded, 'emoji': '🥤'},
    {'label': 'Botella', 'ml': 500, 'icon': Icons.water_drop_rounded, 'emoji': '💧'},
    {'label': 'Termo', 'ml': 750, 'icon': Icons.coffee_maker_rounded, 'emoji': '🧋'},
  ];

  static const _schedule = [
    {'time': '7:00 AM', 'desc': 'Al despertar'},
    {'time': '10:00 AM', 'desc': 'Media mañana'},
    {'time': '12:00 PM', 'desc': 'Antes del almuerzo'},
    {'time': '3:00 PM', 'desc': 'Media tarde'},
    {'time': '6:00 PM', 'desc': 'Al llegar a casa'},
    {'time': '9:00 PM', 'desc': 'Antes de dormir'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydrationAsync = ref.watch(hydrationTodayProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(hydrationTodayProvider.future),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: hydrationAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final todayMl = data['today_ml'] as int;
            final goalMl = data['goal_ml'] as int;
            final pct = (data['percentage'] as num).toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main ring
                Center(
                  child: ProgressRing(
                    progress: pct / 100,
                    size: 180,
                    strokeWidth: 16,
                    color: AppColors.info,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Formatters.waterAmount(todayMl),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text('de ${Formatters.waterAmount(goalMl)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ).animate().scale(delay: 100.ms),
                const SizedBox(height: 24),
                Text(s.quickAdd, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                // Containers grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: _containers.map((c) {
                    final ml = c['ml'] as int;
                    final label = c['label'] as String;
                    final emoji = c['emoji'] as String;
                    return GestureDetector(
                      onTap: () async {
                        final dio = ref.read(dioProvider);
                        await dio.post('/health/hydration', data: {
                          'amount_ml': ml,
                          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        });
                        ref.invalidate(hydrationTodayProvider);
                      },
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  Text(
                                    Formatters.waterAmount(ml),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle_rounded, color: AppColors.info, size: 22),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
                // Schedule
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.info, size: 18),
                    const SizedBox(width: 8),
                    Text(s.hydrSchedule, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: _schedule.asMap().entries.map((e) {
                      final item = e.value;
                      final isLast = e.key == _schedule.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 64,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['time'] as String,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.water_drop_rounded, color: AppColors.info, size: 16),
                                const SizedBox(width: 6),
                                Text(item['desc'] as String, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.textHint.withValues(alpha: 0.15)),
                        ],
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 20),
                // Link to nutrition
                OutlinedButton.icon(
                  onPressed: () => context.push('/nutrition'),
                  icon: const Icon(Icons.restaurant_menu_rounded),
                  label: const Text('Control de nutrición y peso →'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SleepTab extends ConsumerWidget {
  const _SleepTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(sleepLogsProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showLogSleepSheet(context, ref),
            icon: const Icon(Icons.bedtime_rounded),
            label: Text(s.logSleep),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 20),
          Text(s.sleepHistory, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          sleepAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (logs) => logs.isEmpty
                ? Center(child: Text(s.noSleepLogs))
                : Column(
                    children: logs.asMap().entries.map((e) {
                      final log = e.value as Map<String, dynamic>;
                      final hours = log['duration_hours'] != null ? (log['duration_hours'] as num).toDouble() : 0.0;
                      final quality = log['quality'];
                      final isGood = hours >= 7;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: (isGood ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.bedtime_rounded, color: isGood ? AppColors.success : AppColors.warning, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(log['date'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                    Text(
                                      Formatters.sleepDuration(hours),
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: isGood ? AppColors.success : AppColors.warning,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (quality != null)
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < (quality as int) ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: AppColors.accentGold,
                                    size: 14,
                                  )),
                                ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                color: AppColors.error,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(s.delete),
                                      content: Text(s.cannotUndo),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete, style: const TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    final dio = ref.read(dioProvider);
                                    await dio.delete('/health/sleep/${log['id']}');
                                    ref.invalidate(sleepLogsProvider);
                                    ref.invalidate(healthSummaryProvider);
                                  }
                                },
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _showLogSleepSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogSleepSheet(
        onSave: (bedTime, wakeTime, quality) async {
          final dio = ref.read(dioProvider);
          await dio.post('/health/sleep', data: {
            'bed_time': bedTime.toIso8601String(),
            'wake_time': wakeTime.toIso8601String(),
            'quality': quality,
            'date': DateFormat('yyyy-MM-dd').format(wakeTime),
          });
          ref.invalidate(sleepLogsProvider);
        },
      ),
    );
  }
}

class _LogSleepSheet extends StatefulWidget {
  final Future<void> Function(DateTime bed, DateTime wake, int? quality) onSave;
  const _LogSleepSheet({required this.onSave});

  @override
  State<_LogSleepSheet> createState() => _LogSleepSheetState();
}

class _LogSleepSheetState extends State<_LogSleepSheet> {
  DateTime _bedTime = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _wakeTime = DateTime.now();
  int? _quality;
  bool _loading = false;

  Duration get _duration => _wakeTime.difference(_bedTime);

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.onSave(_bedTime, _wakeTime, _quality);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = _duration.inMinutes / 60;

    return Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(localeProvider);
        final s = S(locale);
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(s.logSleep, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${hours >= 0 ? Formatters.sleepDuration(hours) : "Invalid"}',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: hours >= 7 ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppCard(
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_bedTime));
                          if (t != null) {
                            setState(() {
                              final now = DateTime.now();
                              _bedTime = DateTime(now.year, now.month, now.day, t.hour, t.minute);
                              if (_bedTime.isAfter(_wakeTime)) _bedTime = _bedTime.subtract(const Duration(days: 1));
                            });
                          }
                        },
                        child: Column(
                          children: [
                            const Icon(Icons.bedtime_rounded, color: AppColors.primary, size: 24),
                            const SizedBox(height: 4),
                            Text(s.bedtime, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                            Text(DateFormat('h:mm a').format(_bedTime), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppCard(
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_wakeTime));
                          if (t != null) {
                            final now = DateTime.now();
                            setState(() => _wakeTime = DateTime(now.year, now.month, now.day, t.hour, t.minute));
                          }
                        },
                        child: Column(
                          children: [
                            const Icon(Icons.wb_sunny_rounded, color: AppColors.accentOrange, size: 24),
                            const SizedBox(height: 4),
                            Text(s.wakeUp, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                            Text(DateFormat('h:mm a').format(_wakeTime), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(s.sleepQuality, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _quality = i + 1),
                    child: Icon(
                      i < (_quality ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.accentGold,
                      size: 36,
                    ),
                  )),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(s.saveSleepLog),
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

class _MealsTab extends ConsumerWidget {
  const _MealsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final mealsAsync = ref.watch(mealsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showLogMealSheet(context, ref, s),
            icon: const Icon(Icons.restaurant_rounded),
            label: Text(s.logMeal),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
          const SizedBox(height: 20),
          Text(s.todayMeals, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (meals) => meals.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(s.noMealsToday)))
                : Column(
                    children: meals.map((m) {
                      final meal = m as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: AppColors.categoryFood.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.restaurant_rounded, color: AppColors.categoryFood, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(meal['name'] as String, style: Theme.of(context).textTheme.titleMedium),
                                    Text(_mealTypeLabel(meal['meal_type'] as String, s), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (meal['calories'] != null)
                                Text('${meal['calories']} kcal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _mealTypeLabel(String type, S s) {
    switch (type) {
      case 'breakfast': return s.breakfast;
      case 'lunch': return s.lunch;
      case 'dinner': return s.dinner;
      case 'snack': return s.snack;
      default: return type;
    }
  }

  void _showLogMealSheet(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final nameCtrl = TextEditingController();
        final calCtrl = TextEditingController();
        String mealType = 'lunch';
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
                  Text(s.logMeal, style: Theme.of(ctx).textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('breakfast', s.breakfast),
                      ('lunch', s.lunch),
                      ('dinner', s.dinner),
                      ('snack', s.snack),
                    ].map((t) => ChoiceChip(
                          label: Text(t.$2),
                          selected: mealType == t.$1,
                          onSelected: (_) => setState(() => mealType = t.$1),
                        )).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: InputDecoration(hintText: s.whatDidYouEat)),
                  const SizedBox(height: 12),
                  TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: s.caloriesOptional)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) return;
                        final dio = ref.read(dioProvider);
                        await dio.post('/health/meals', data: {
                          'name': nameCtrl.text,
                          'meal_type': mealType,
                          'calories': int.tryParse(calCtrl.text),
                          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        });
                        ref.invalidate(healthSummaryProvider);
                        ref.invalidate(mealsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(s.logMeal),
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

// â”€â”€ Gym & Health Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GymTab extends ConsumerWidget {
  const _GymTab();

  static const _tips = [
    {'icon': Icons.fitness_center_rounded, 'key': 'gym_tip'},
    {'icon': Icons.bedtime_rounded, 'key': 'sleep_tip'},
    {'icon': Icons.water_drop_rounded, 'key': 'water_tip'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymAsync = ref.watch(gymSessionsProvider);
    final summaryAsync = ref.watch(healthSummaryProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(gymSessionsProvider);
        ref.invalidate(healthSummaryProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Score card
            summaryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) => _HealthScoreCard(summary: summary, s: s).animate().fadeIn(),
            ),
            const SizedBox(height: 24),
            // Log gym button
            ElevatedButton.icon(
              onPressed: () => _showLogGymSheet(context, ref, s),
              icon: const Icon(Icons.fitness_center_rounded),
              label: Text(s.logGym),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 24),
            // Gym history
            Text(s.gymHistory, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            gymAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (sessions) => sessions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(s.noGymSessions, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: sessions.asMap().entries.map((e) {
                        final session = e.value as Map<String, dynamic>;
                        final dateStr = session['date'] as String;
                        final dur = session['duration_minutes'];
                        final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.fitness_center_rounded, color: AppColors.secondary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(dateStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                      if (dur != null)
                                        Text('${dur} ${s.durationMin}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                if (isToday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(s.loggedToday, style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  color: AppColors.error,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(s.delete),
                                        content: Text(s.cannotUndo),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete, style: const TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      final dio = ref.read(dioProvider);
                                      await dio.delete('/health/gym/${session['id']}');
                                      ref.invalidate(gymSessionsProvider);
                                      ref.invalidate(healthSummaryProvider);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),
            // Expert tips
            Text(s.healthTips, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ..._tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tip['icon'] as IconData, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.get(tip['key'] as String),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showLogGymSheet(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final durCtrl = TextEditingController();
        DateTime selectedDate = DateTime.now();
        return StatefulBuilder(
          builder: (ctx, setState) => Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
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
                  Text(s.logGym, style: Theme.of(ctx).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  // Date picker row
                  AppCard(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '${s.durationMin} (opcional)',
                      prefixIcon: const Icon(Icons.timer_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final dio = ref.read(dioProvider);
                        await dio.post('/health/gym', data: {
                          'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                          'duration_minutes': int.tryParse(durCtrl.text),
                        });
                        ref.invalidate(gymSessionsProvider);
                        ref.invalidate(healthSummaryProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(s.save),
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

class _HealthScoreCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  final S s;
  const _HealthScoreCard({required this.summary, required this.s});

  @override
  Widget build(BuildContext context) {
    final score = (summary['health_score'] as num?)?.toInt() ?? 0;
    final gymDays = (summary['gym_days_this_month'] as num?)?.toInt() ?? 0;
    final waterPct = (summary['water_percentage'] as num?)?.toDouble() ?? 0;
    final sleepHours = (summary['last_sleep_hours'] as num?)?.toDouble();
    final sleepGoal = (summary['sleep_goal_hours'] as num?)?.toDouble() ?? 8;

    Color scoreColor;
    String scoreLabel;
    if (score >= 75) {
      scoreColor = AppColors.success;
      scoreLabel = s.excellent;
    } else if (score >= 45) {
      scoreColor = AppColors.warning;
      scoreLabel = s.good;
    } else {
      scoreColor = AppColors.error;
      scoreLabel = s.needsWork;
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.healthScore, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text('/100', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(scoreLabel, style: TextStyle(color: scoreColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: score / 100,
                size: 90,
                strokeWidth: 8,
                color: scoreColor,
                child: Text('$score', style: TextStyle(color: scoreColor, fontWeight: FontWeight.w700, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ScoreRow(label: s.hydrationTab, value: waterPct / 100, color: AppColors.info),
          const SizedBox(height: 8),
          _ScoreRow(
            label: s.sleepTab,
            value: sleepHours != null ? (sleepHours / sleepGoal).clamp(0, 1) : 0,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _ScoreRow(label: s.gymDays, value: (gymDays / 12).clamp(0, 1), color: AppColors.secondary),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('$gymDays ${s.daysThisMonth}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ScoreRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${(value * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
