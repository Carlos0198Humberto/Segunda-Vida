import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';

final weeklyTimeReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/time/report/weekly');
  return response.data as Map<String, dynamic>;
});

final todayTimeEntriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final response = await dio.get('/time/entries', queryParameters: {'start_date': today, 'end_date': today});
  return response.data as List;
});

class TimeTrackingScreen extends ConsumerStatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  ConsumerState<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends ConsumerState<TimeTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(weeklyTimeReportProvider);
    final entriesAsync = ref.watch(todayTimeEntriesProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weeklyTimeReportProvider);
          ref.invalidate(todayTimeEntriesProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(s.timeTracking),
              floating: true,
              actions: [
                IconButton(
                  onPressed: () => _showLogTimeSheet(context, ref, s),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Weekly summary
                  reportAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (report) => _WeeklyReport(report: report, s: s).animate().fadeIn().slideY(begin: 0.1),
                  ),
                  const SizedBox(height: 20),
                  Text(s.todayActivity, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  entriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (entries) => entries.isEmpty
                        ? AppCard(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 48, color: AppColors.textHint),
                                  const SizedBox(height: 12),
                                  Text(s.noTimeTracked, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _showLogTimeSheet(context, ref, s),
                                    icon: const Icon(Icons.add_rounded),
                                    label: Text(s.logTime),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: entries.asMap().entries.map((e) {
                              final entry = e.value as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _TimeEntryCard(entry: entry, s: s)
                                    .animate()
                                    .fadeIn(delay: Duration(milliseconds: 50 * e.key))
                                    .slideX(begin: -0.05),
                              );
                            }).toList(),
                          ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogTimeSheet(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final nameCtrl = TextEditingController();
        final minutesCtrl = TextEditingController();
        String category = 'productive';
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
                  Text(s.logTime, style: Theme.of(ctx).textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ('study', s.catStudy),
                      ('productive', s.catProductive),
                      ('learning', s.catLearning),
                      ('reading', s.actReading),
                      ('exercise', s.catExercise),
                      ('phone', s.catPhone),
                      ('entertainment', s.catEntertainment),
                      ('wasted', s.catWasted),
                    ].map((c) =>
                      ChoiceChip(label: Text(c.$2), selected: category == c.$1, onSelected: (_) => setState(() => category = c.$1))
                    ).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: InputDecoration(hintText: s.activityName)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: minutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: s.duration, suffixText: 'min'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60, 90, 120].map((m) => ActionChip(
                          label: Text('${m}m'),
                          onPressed: () => minutesCtrl.text = m.toString(),
                        )).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final minutes = int.tryParse(minutesCtrl.text);
                        if (minutes == null || minutes <= 0) return;
                        final dio = ref.read(dioProvider);
                        await dio.post('/time/entries', data: {
                          'category': category,
                          'activity_name': nameCtrl.text.isEmpty ? null : nameCtrl.text,
                          'duration_minutes': minutes,
                          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        });
                        ref.invalidate(weeklyTimeReportProvider);
                        ref.invalidate(todayTimeEntriesProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(s.saveEntry),
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

class _WeeklyReport extends StatelessWidget {
  final Map<String, dynamic> report;
  final S s;
  const _WeeklyReport({required this.report, required this.s});

  @override
  Widget build(BuildContext context) {
    final productive = (report['productive_hours'] as num).toDouble();
    final study = (report['study_hours'] as num).toDouble();
    final wasted = (report['wasted_hours'] as num).toDouble();
    final total = (report['total_tracked_hours'] as num).toDouble();
    final score = (report['productivity_score'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.thisWeek, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        GradientCard(
          colors: [AppColors.primary, AppColors.primaryLight],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.productivity, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${score.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 36)),
                    Text('${total}${s.hTracked}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                children: [
                  _ReportStat(label: s.productive, value: '${productive}h', color: Colors.greenAccent),
                  const SizedBox(height: 8),
                  _ReportStat(label: s.study, value: '${study}h', color: Colors.lightBlueAccent),
                  const SizedBox(height: 8),
                  _ReportStat(label: s.wasted, value: '${wasted}h', color: Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ReportStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _TimeEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final S s;
  const _TimeEntryCard({required this.entry, required this.s});

  @override
  Widget build(BuildContext context) {
    final category = entry['category'] as String;
    final minutes = entry['duration_minutes'] as int;
    final color = _categoryColor(category);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_categoryIcon(category), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry['activity_name'] ?? _categoryLabel(category), style: Theme.of(context).textTheme.titleMedium),
                Text(_categoryLabel(category), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(Formatters.duration(minutes), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'study': return s.catStudy;
      case 'productive': return s.catProductive;
      case 'learning': return s.catLearning;
      case 'reading': return s.actReading;
      case 'exercise': return s.catExercise;
      case 'phone': return s.catPhone;
      case 'entertainment': return s.catEntertainment;
      case 'wasted': return s.catWasted;
      default: return cat;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'study': return AppColors.primary;
      case 'productive': return AppColors.secondary;
      case 'learning': return AppColors.accentGold;
      case 'reading': return AppColors.info;
      case 'exercise': return AppColors.success;
      case 'phone': return AppColors.warning;
      case 'entertainment': return AppColors.accentOrange;
      case 'wasted': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'study': return Icons.book_rounded;
      case 'productive': return Icons.bolt_rounded;
      case 'learning': return Icons.lightbulb_rounded;
      case 'reading': return Icons.menu_book_rounded;
      case 'exercise': return Icons.fitness_center_rounded;
      case 'phone': return Icons.phone_android_rounded;
      case 'entertainment': return Icons.movie_rounded;
      case 'wasted': return Icons.timer_off_rounded;
      default: return Icons.access_time_rounded;
    }
  }
}
