import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_ring.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final nutritionSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/nutrition/summary/today');
  return response.data as Map<String, dynamic>;
});

final latestBodyMetricProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/nutrition/body-metric/latest');
  return response.data as Map<String, dynamic>;
});

final todayFoodLogProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/nutrition/food-log/today');
  return response.data as List;
});

final weekNutritionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/nutrition/summary/week');
  return response.data as Map<String, dynamic>;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            title: Text(s.nutritionTab),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _showReminderDialog(context),
                tooltip: 'Recordatorio',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Mi Cuerpo'),
                Tab(text: 'Registrar'),
                Tab(text: 'Semana'),
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
          children: [
            _BodyTab(onSaved: () => ref.invalidate(latestBodyMetricProvider)),
            _FoodLogTab(onLogAdded: () {
              ref.invalidate(todayFoodLogProvider);
              ref.invalidate(nutritionSummaryProvider);
              ref.invalidate(weekNutritionProvider);
            }),
            _WeekTab(onRefresh: () {
              ref.invalidate(nutritionSummaryProvider);
              ref.invalidate(weekNutritionProvider);
            }),
          ],
        ),
      ),
    );
  }

  void _showReminderDialog(BuildContext context) {
    final enabled = HiveStorage.getBool('notif_food_enabled');
    final h = HiveStorage.getInt('notif_food_hour', defaultValue: 20);
    final m = HiveStorage.getInt('notif_food_minute', defaultValue: 0);

    showDialog(
      context: context,
      builder: (ctx) => _FoodReminderDialog(
        enabled: enabled,
        hour: h,
        minute: m,
      ),
    );
  }
}

// ── Food Reminder Dialog ──────────────────────────────────────────────────────

class _FoodReminderDialog extends StatefulWidget {
  final bool enabled;
  final int hour;
  final int minute;
  const _FoodReminderDialog({required this.enabled, required this.hour, required this.minute});

  @override
  State<_FoodReminderDialog> createState() => _FoodReminderDialogState();
}

class _FoodReminderDialogState extends State<_FoodReminderDialog> {
  late bool _enabled;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _hour = widget.hour;
    _minute = widget.minute;
  }

  String get _timeStr =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Text('🥗', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('Recordatorio diario'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Activa un recordatorio para registrar lo que consumiste durante el día.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Activar'),
              const Spacer(),
              Switch.adaptive(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: _hour, minute: _minute),
                );
                if (t != null) setState(() { _hour = t.hour; _minute = t.minute; });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(_timeStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const Spacer(),
                    const Text('Toca para cambiar', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            await HiveStorage.putBool('notif_food_enabled', _enabled);
            await HiveStorage.putInt('notif_food_hour', _hour);
            await HiveStorage.putInt('notif_food_minute', _minute);
            if (_enabled) {
              await NotificationService.scheduleDaily(
                id: 103,
                title: '🥗 ¿Qué comiste hoy?',
                body: 'Registra tus alimentos del día para mantener tu balance nutricional.',
                hour: _hour,
                minute: _minute,
              );
            } else {
              await NotificationService.cancelNotification(103);
            }
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ── Body Tab ──────────────────────────────────────────────────────────────────

class _BodyTab extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _BodyTab({required this.onSaved});

  @override
  ConsumerState<_BodyTab> createState() => _BodyTabState();
}

class _BodyTabState extends ConsumerState<_BodyTab> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    if (weight == null && height == null) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/nutrition/body-metric', data: {
        if (weight != null) 'weight_kg': weight,
        if (height != null) 'height_cm': height,
      });
      ref.invalidate(latestBodyMetricProvider);
      widget.onSaved();
      _weightCtrl.clear();
      _heightCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Métricas guardadas ✓'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final metricAsync = ref.watch(latestBodyMetricProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(latestBodyMetricProvider.future),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            metricAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) {
                final weight = data['weight_kg'];
                final height = data['height_cm'];
                final bmi = data['bmi'];
                final waterMl = data['water_goal_ml'];
                final kcalGoal = data['daily_kcal_goal'] as int? ?? 2000;
                return Column(
                  children: [
                    Row(children: [
                      Expanded(child: _MetricCard(icon: Icons.monitor_weight_rounded, color: AppColors.primary,
                          label: s.weightKg, value: weight != null ? '${weight}kg' : '--')),
                      const SizedBox(width: 12),
                      Expanded(child: _MetricCard(icon: Icons.height_rounded, color: AppColors.secondary,
                          label: s.heightCm, value: height != null ? '${height}cm' : '--')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _MetricCard(
                          icon: Icons.favorite_rounded, color: _bmiColor(bmi), label: s.bmi,
                          value: bmi != null ? '$bmi' : '--',
                          subtitle: bmi != null ? _bmiLabel(bmi as double, s) : null)),
                      const SizedBox(width: 12),
                      Expanded(child: _MetricCard(icon: Icons.water_drop_rounded, color: AppColors.info,
                          label: s.waterGoal, value: waterMl != null ? '${(waterMl / 1000).toStringAsFixed(1)}L' : '--',
                          subtitle: waterMl != null ? '${waterMl}ml/día' : null)),
                    ]),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: AppColors.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.local_fire_department_rounded, color: AppColors.accentOrange, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Meta calórica diaria', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                          Text('$kcalGoal kcal', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.accentOrange, fontWeight: FontWeight.w700)),
                        ]),
                        const Spacer(),
                        Text('peso × 30', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
                      ]),
                    ),
                  ],
                ).animate().fadeIn();
              },
            ),
            const SizedBox(height: 24),
            Text(s.saveMetrics, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: s.weightKg, prefixIcon: const Icon(Icons.monitor_weight_rounded)),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: s.heightCm, prefixIcon: const Icon(Icons.height_rounded)),
              )),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(s.saveMetrics),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _bmiColor(dynamic bmi) {
    if (bmi == null) return AppColors.textHint;
    final v = (bmi as num).toDouble();
    if (v < 18.5) return AppColors.info;
    if (v < 25) return AppColors.success;
    if (v < 30) return AppColors.warning;
    return AppColors.error;
  }

  String _bmiLabel(double bmi, S s) {
    if (bmi < 18.5) return s.bodyUnder;
    if (bmi < 25) return s.bodyNormal;
    if (bmi < 30) return s.bodyOverweight;
    return s.bodyObese;
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? subtitle;
  const _MetricCard({required this.icon, required this.color, required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        if (subtitle != null)
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ── Food Log Tab ──────────────────────────────────────────────────────────────

class _FoodLogTab extends ConsumerWidget {
  final VoidCallback onLogAdded;
  const _FoodLogTab({required this.onLogAdded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final logAsync = ref.watch(todayFoodLogProvider);
    final summaryAsync = ref.watch(nutritionSummaryProvider);

    return Column(
      children: [
        // Calorie bar
        summaryAsync.maybeWhen(
          data: (data) {
            final kcal = data['total_kcal'] as int? ?? 0;
            final metricAsync = ref.watch(latestBodyMetricProvider);
            final goal = metricAsync.maybeWhen(data: (m) => m['daily_kcal_goal'] as int? ?? 2000, orElse: () => 2000);
            final ratio = (kcal / goal).clamp(0.0, 1.2);
            final isOver = kcal > goal;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.accentOrange, size: 16),
                    const SizedBox(width: 6),
                    Text('$kcal / $goal kcal hoy',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isOver ? AppColors.error : AppColors.textSecondary)),
                    const Spacer(),
                    if (isOver)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Excedido', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      backgroundColor: AppColors.accentOrange.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(isOver ? AppColors.error : AppColors.accentOrange),
                      minHeight: 6,
                    ),
                  ),
                ]),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: ElevatedButton.icon(
            onPressed: () => _showLogFoodSheet(context, ref, s),
            icon: const Icon(Icons.add_rounded),
            label: Text(s.logFood),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(todayFoodLogProvider.future),
            child: logAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🥗', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          Text(s.noFoodLogged, textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text('Registra tus comidas para ver tu balance calórico',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final e = entries[i] as Map<String, dynamic>;
                    return _FoodLogItem(
                      entry: e,
                      onDelete: () async {
                        final dio = ref.read(dioProvider);
                        await dio.delete('/nutrition/food-log/${e['id']}');
                        onLogAdded();
                      },
                    ).animate().fadeIn(delay: Duration(milliseconds: 40 * i));
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showLogFoodSheet(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LogFoodSheet(onSave: (foodName, category, servings, mealTime) async {
        final dio = ref.read(dioProvider);
        await dio.post('/nutrition/food-log', data: {
          'food_name': foodName, 'category': category,
          'servings': servings, 'meal_time': mealTime,
        });
        onLogAdded();
      }),
    );
  }
}

// ── Food Log Item ─────────────────────────────────────────────────────────────

class _FoodLogItem extends ConsumerWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;
  const _FoodLogItem({required this.entry, required this.onDelete});

  static const _catColors = {
    'carbs': Color(0xFFFF9F43), 'protein': Color(0xFFEE5A24),
    'legumes': Color(0xFF8854D0), 'veggies': Color(0xFF20BF6B),
    'fruits': Color(0xFFFECE2F), 'dairy': Color(0xFF45AAF2),
    'treats': Color(0xFFFC5C65),
  };
  static const _catIcons = {
    'carbs': Icons.grain_rounded, 'protein': Icons.set_meal_rounded,
    'legumes': Icons.spa_rounded, 'veggies': Icons.eco_rounded,
    'fruits': Icons.yard_rounded, 'dairy': Icons.local_drink_rounded,
    'treats': Icons.cake_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final cat = entry['category'] as String? ?? 'carbs';
    final color = _catColors[cat] ?? AppColors.primary;
    final icon = _catIcons[cat] ?? Icons.restaurant_rounded;
    final servings = (entry['servings'] as num).toDouble();
    final mealTime = entry['meal_time'] as String?;
    final kcal = entry['kcal'] as int? ?? 0;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry['food_name'] as String, style: Theme.of(context).textTheme.titleMedium),
          Row(children: [
            Text('${servings.toInt()} ${s.portions}${mealTime != null ? ' · $mealTime' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: AppColors.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text('$kcal kcal', style: const TextStyle(color: AppColors.accentOrange, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
        ])),
        IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20), onPressed: onDelete, color: AppColors.error),
      ]),
    );
  }
}

// ── Log Food Sheet ────────────────────────────────────────────────────────────

class _LogFoodSheet extends ConsumerStatefulWidget {
  final Future<void> Function(String foodName, String category, double servings, String mealTime) onSave;
  const _LogFoodSheet({required this.onSave});

  @override
  ConsumerState<_LogFoodSheet> createState() => _LogFoodSheetState();
}

class _LogFoodSheetState extends ConsumerState<_LogFoodSheet> {
  static const _presets = [
    {'name': 'Arroz', 'cat': 'carbs', 'emoji': '🍚', 'kcal': 200},
    {'name': 'Tortillas', 'cat': 'carbs', 'emoji': '🫓', 'kcal': 150},
    {'name': 'Pan', 'cat': 'carbs', 'emoji': '🍞', 'kcal': 160},
    {'name': 'Pasta', 'cat': 'carbs', 'emoji': '🍝', 'kcal': 220},
    {'name': 'Carne', 'cat': 'protein', 'emoji': '🥩', 'kcal': 250},
    {'name': 'Pollo', 'cat': 'protein', 'emoji': '🍗', 'kcal': 200},
    {'name': 'Huevo duro', 'cat': 'protein', 'emoji': '🥚', 'kcal': 78},
    {'name': 'Frijoles', 'cat': 'legumes', 'emoji': '🫘', 'kcal': 120},
    {'name': 'Lentejas', 'cat': 'legumes', 'emoji': '🍲', 'kcal': 115},
    {'name': 'Ensalada', 'cat': 'veggies', 'emoji': '🥗', 'kcal': 40},
    {'name': 'Verduras', 'cat': 'veggies', 'emoji': '🥦', 'kcal': 50},
    {'name': 'Fruta', 'cat': 'fruits', 'emoji': '🍎', 'kcal': 80},
    {'name': 'Plátano', 'cat': 'fruits', 'emoji': '🍌', 'kcal': 90},
    {'name': 'Leche', 'cat': 'dairy', 'emoji': '🥛', 'kcal': 120},
    {'name': 'Queso', 'cat': 'dairy', 'emoji': '🧀', 'kcal': 113},
    {'name': 'Chocolate', 'cat': 'treats', 'emoji': '🍫', 'kcal': 170},
    {'name': 'Pizza', 'cat': 'treats', 'emoji': '🍕', 'kcal': 285},
    {'name': 'Churros', 'cat': 'treats', 'emoji': '🍩', 'kcal': 200},
  ];

  String? _selected;
  String _category = 'carbs';
  double _servings = 1;
  String _mealTime = 'almuerzo';
  int _kcalPerServing = 0;
  bool _loading = false;

  int get _totalKcal => (_kcalPerServing * _servings).round();

  Future<void> _save() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await widget.onSave(_selected!, _category, _servings, _mealTime);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Text(s.logFood, style: theme.textTheme.headlineMedium),
              const Spacer(),
              if (_selected != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text('$_totalKcal kcal',
                      style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 14),
            // Meal time chips
            Wrap(
              spacing: 8,
              children: [
                ('desayuno', '🌅 ${s.breakfast}'),
                ('almuerzo', '☀️ ${s.lunch}'),
                ('cena', '🌙 ${s.dinner}'),
                ('merienda', '🍎 ${s.snack}'),
              ].map((t) => ChoiceChip(
                label: Text(t.$2),
                selected: _mealTime == t.$1,
                onSelected: (_) => setState(() => _mealTime = t.$1),
              )).toList(),
            ),
            const SizedBox(height: 16),
            // Food presets
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _presets.map((p) {
                final isSelected = _selected == p['name'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selected = p['name'] as String;
                    _category = p['cat'] as String;
                    _kcalPerServing = p['kcal'] as int;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${p['emoji']} ${p['name']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected ? AppColors.primary : null,
                              fontWeight: isSelected ? FontWeight.w600 : null)),
                      Text('${p['kcal']} kcal/porción',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Servings
            Row(children: [
              Text('${s.servings}:', style: theme.textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: _servings > 0.5 ? () => setState(() => _servings = (_servings - 0.5).clamp(0.5, 10)) : null,
              ),
              Text('${_servings.toStringAsFixed(1)}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () => setState(() => _servings = (_servings + 0.5).clamp(0.5, 10)),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selected == null || _loading) ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(s.logFood),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Week Tab ─────────────────────────────────────────────────────────────────

class _WeekTab extends ConsumerStatefulWidget {
  final VoidCallback onRefresh;
  const _WeekTab({required this.onRefresh});

  @override
  ConsumerState<_WeekTab> createState() => _WeekTabState();
}

class _WeekTabState extends ConsumerState<_WeekTab> {
  int _selectedDayIndex = -1; // -1 = overview, 0-6 = day detail

  @override
  Widget build(BuildContext context) {
    final weekAsync = ref.watch(weekNutritionProvider);

    return RefreshIndicator(
      onRefresh: () {
        widget.onRefresh();
        return ref.refresh(weekNutritionProvider.future);
      },
      child: weekAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final days = List<Map<String, dynamic>>.from(data['days'] as List);
          final weekScore = data['week_score'] as int;
          final weekKcal = data['week_total_kcal'] as int;
          final loggedDays = data['logged_days'] as int;
          final totalDays = data['total_days_so_far'] as int;
          final weeklyTreats = List<Map<String, dynamic>>.from(data['weekly_treats'] as List);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Week score header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_scoreColor(weekScore).withValues(alpha: 0.8), _scoreColor(weekScore).withValues(alpha: 0.4)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    ProgressRing(
                      progress: weekScore / 100,
                      size: 72,
                      strokeWidth: 8,
                      color: Colors.white,
                      child: Text('$weekScore', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Semana actual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(_scoreLabel(weekScore), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text('$loggedDays de $totalDays días registrados · $weekKcal kcal',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                  ]),
                ).animate().fadeIn(),
                const SizedBox(height: 20),

                // Day selector strip (Mon–Sun)
                Text('Lunes — Domingo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: days.asMap().entries.map((e) {
                    final i = e.key;
                    final d = e.value;
                    final isToday = d['is_today'] as bool;
                    final isFuture = d['is_future'] as bool;
                    final hasData = (d['total_entries'] as int) > 0;
                    final score = d['score'] as int;
                    final isSelected = _selectedDayIndex == i;

                    return Expanded(
                      child: GestureDetector(
                        onTap: isFuture ? null : () => setState(() =>
                            _selectedDayIndex = _selectedDayIndex == i ? -1 : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : isToday
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : null,
                            borderRadius: BorderRadius.circular(10),
                            border: isToday && !isSelected
                                ? Border.all(color: AppColors.primary, width: 1.5)
                                : null,
                          ),
                          child: Column(children: [
                            Text(d['day_name'] as String,
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : isFuture ? AppColors.textHint : AppColors.textSecondary,
                                )),
                            const SizedBox(height: 4),
                            if (isFuture)
                              Container(width: 8, height: 8,
                                  decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.2), shape: BoxShape.circle))
                            else if (hasData)
                              Container(width: 8, height: 8,
                                  decoration: BoxDecoration(color: isSelected ? Colors.white : _scoreColor(score), shape: BoxShape.circle))
                            else
                              Container(width: 8, height: 8,
                                  decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withValues(alpha: 0.4) : AppColors.textHint.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isSelected ? Colors.white30 : AppColors.textHint.withValues(alpha: 0.3)))),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Day detail or week overview
                if (_selectedDayIndex >= 0 && _selectedDayIndex < days.length) ...[
                  _DayDetail(day: days[_selectedDayIndex]),
                ] else ...[
                  // Week category bars
                  Text('Resumen de la semana', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  // Kcal per day mini bars
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Calorías por día', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: days.map((d) {
                          final kcal = d['total_kcal'] as int;
                          final isFuture = d['is_future'] as bool;
                          final isToday = d['is_today'] as bool;
                          final maxKcal = days.fold<int>(1, (m, d2) => (d2['total_kcal'] as int) > m ? (d2['total_kcal'] as int) : m);
                          final ratio = maxKcal > 0 ? kcal / maxKcal : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(children: [
                                Text(kcal > 0 ? '$kcal' : '', style: const TextStyle(fontSize: 8, color: AppColors.textHint)),
                                const SizedBox(height: 2),
                                Container(
                                  height: 48,
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: isFuture ? 0.05 : ratio.clamp(0.05, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isFuture
                                            ? AppColors.textHint.withValues(alpha: 0.1)
                                            : isToday
                                                ? AppColors.primary
                                                : AppColors.accentOrange.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(d['day_name'] as String, style: TextStyle(
                                    fontSize: 10,
                                    color: isToday ? AppColors.primary : AppColors.textHint,
                                    fontWeight: isToday ? FontWeight.w700 : null)),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                    ]),
                  ).animate().fadeIn(),
                  const SizedBox(height: 16),

                  // Weekly treats
                  Text('Control semanal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...weeklyTreats.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Icon(
                          t['status'] == 'over' ? Icons.warning_rounded : Icons.check_circle_rounded,
                          color: t['status'] == 'over' ? AppColors.error : AppColors.success, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t['label'] as String, style: Theme.of(context).textTheme.bodyMedium)),
                        Text('${(t['consumed'] as num).toInt()} / ${t['weekly_limit']} / sem.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: t['status'] == 'over' ? AppColors.error : AppColors.textSecondary,
                                fontWeight: t['status'] == 'over' ? FontWeight.w600 : null)),
                      ]),
                    ),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Excelente semana 🌟';
    if (score >= 60) return 'Buena semana 👍';
    if (score >= 40) return 'Puede mejorar';
    return 'Semana difícil';
  }
}

// ── Day Detail ────────────────────────────────────────────────────────────────

class _DayDetail extends StatelessWidget {
  final Map<String, dynamic> day;
  const _DayDetail({required this.day});

  static const _catColors = {
    'carbs': Color(0xFFFF9F43), 'protein': Color(0xFFEE5A24),
    'legumes': Color(0xFF8854D0), 'veggies': Color(0xFF20BF6B),
    'fruits': Color(0xFFFECE2F), 'dairy': Color(0xFF45AAF2),
    'treats': Color(0xFFFC5C65),
  };

  @override
  Widget build(BuildContext context) {
    final categories = List<Map<String, dynamic>>.from(day['categories'] as List);
    final score = day['score'] as int;
    final kcal = day['total_kcal'] as int;
    final macros = day['macros'] as Map<String, dynamic>;
    final dayName = day['day_name'] as String;
    final isFuture = day['is_future'] as bool;

    if (isFuture) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔮', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('$dayName aún no ha llegado', style: const TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(dayName, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      // Summary row
      Row(children: [
        Expanded(child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text('$score', style: TextStyle(color: _scoreColor(score), fontWeight: FontWeight.w800, fontSize: 22)),
            const Text('Score', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          ]),
        )),
        const SizedBox(width: 8),
        Expanded(child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text('$kcal', style: const TextStyle(color: AppColors.accentOrange, fontWeight: FontWeight.w800, fontSize: 22)),
            const Text('kcal', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          ]),
        )),
        const SizedBox(width: 8),
        Expanded(child: AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text('${(macros['protein_g'] as num).toInt()}g', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800, fontSize: 22)),
            const Text('Proteína', style: TextStyle(color: AppColors.textHint, fontSize: 11)),
          ]),
        )),
      ]),
      const SizedBox(height: 12),
      // Category bars
      ...categories.map((c) {
        final key = c['key'] as String;
        final consumed = (c['consumed'] as num).toDouble();
        final limit = (c['limit'] as num).toDouble();
        final status = c['status'] as String;
        final color = _catColors[key] ?? AppColors.primary;
        final ratio = limit > 0 ? (consumed / limit).clamp(0.0, 1.0) : 0.0;
        Color statusColor = status == 'ok' ? AppColors.success : status == 'over' ? AppColors.error : AppColors.textHint;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(c['label'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                Icon(status == 'ok' ? Icons.check_circle_rounded : status == 'over' ? Icons.warning_rounded : Icons.radio_button_unchecked_rounded,
                    color: statusColor, size: 16),
                const SizedBox(width: 4),
                Text('${consumed.toInt()}/${limit.toInt()} ${c['unit']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio, minHeight: 5,
                  backgroundColor: color.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(status == 'over' ? AppColors.error : color),
                ),
              ),
            ]),
          ),
        );
      }),
    ]);
  }

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

extension _ThemeX on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
