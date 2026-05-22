import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';

final analyticsOverviewProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, year) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/analytics/overview', queryParameters: {'year': year});
  return response.data as Map<String, dynamic>;
});

final financeTrendsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/analytics/finance/trends', queryParameters: {'months': 6});
  return response.data as Map<String, dynamic>;
});

final multiYearProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, years) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/analytics/multi-year', queryParameters: {'years': years});
  return response.data as Map<String, dynamic>;
});

final heatmapProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/analytics/habits/heatmap', queryParameters: {'days': 90});
  return response.data as Map<String, dynamic>;
});

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _year = DateTime.now().year;

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
            title: Text(s.analytics),
            floating: true,
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: s.financeTab),
                Tab(text: s.habits),
                Tab(text: s.overview),
                const Tab(text: 'Histórico'),
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
            _FinanceAnalyticsTab(year: _year),
            _HabitsAnalyticsTab(),
            _OverviewTab(year: _year),
            const _MultiYearTab(),
          ],
        ),
      ),
    );
  }
}

class _FinanceAnalyticsTab extends ConsumerWidget {
  final int year;
  const _FinanceAnalyticsTab({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(financeTrendsProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: trendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final trends = List<Map<String, dynamic>>.from(data['trends'] as List);
          if (trends.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(s.noFinancialData)));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.incomeVsExpenses, style: Theme.of(context).textTheme.headlineMedium),
              Text(s.last6Months, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: trends.fold<double>(0, (max, t) => [max, (t['income'] as num).toDouble(), (t['expenses'] as num).toDouble()].reduce((a, b) => a > b ? a : b)) * 1.2,
                      barGroups: trends.asMap().entries.map((e) {
                        final t = e.value;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(toY: (t['income'] as num).toDouble(), color: AppColors.success, width: 10, borderRadius: BorderRadius.circular(4)),
                            BarChartRodData(toY: (t['expenses'] as num).toDouble(), color: AppColors.error, width: 10, borderRadius: BorderRadius.circular(4)),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= trends.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  (trends[idx]['label'] as String).split(' ').first,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, _) => Text(
                              Formatters.compactCurrency(value),
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.textHint.withValues(alpha: 0.15), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 16),
              // Legend
              Row(
                children: [
                  _LegendItem(color: AppColors.success, label: s.income),
                  const SizedBox(width: 16),
                  _LegendItem(color: AppColors.error, label: s.expense),
                ],
              ),
              const SizedBox(height: 20),
              // Net savings trend
              Text(s.monthlyNet, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...trends.map((t) {
                final net = (t['net'] as num).toDouble();
                final isPos = net >= 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(t['label'] as String, style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          '${isPos ? '+' : ''}${Formatters.currency(net)}',
                          style: TextStyle(color: isPos ? AppColors.success : AppColors.error, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _HabitsAnalyticsTab extends ConsumerWidget {
  const _HabitsAnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final heatmapAsync = ref.watch(heatmapProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: heatmapAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (data) {
          final heatmap = List<Map<String, dynamic>>.from(data['heatmap'] as List);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.habitConsistency, style: Theme.of(context).textTheme.headlineMedium),
              Text(s.last90Days, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: heatmap.map((day) {
                    final intensity = (day['intensity'] as num).toDouble();
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: intensity == 0
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.primary.withValues(alpha: 0.2 + intensity * 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(s.less, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                  ...List.generate(5, (i) => Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1 + i * 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                  const SizedBox(width: 6),
                  Text(s.more, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final int year;
  const _OverviewTab({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(analyticsOverviewProvider(year));
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final monthly = List<Map<String, dynamic>>.from(data['monthly'] as List);
          final withData = monthly.where((m) => (m['income'] as num) > 0 || (m['habits_completed'] as int) > 0).toList();

          if (withData.isEmpty) {
            return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(s.noYearlyData)));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$year ${s.overview}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: monthly.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['productive_hours'] as num).toDouble())).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= monthly.length) return const SizedBox.shrink();
                              return Text(monthly[idx]['month_name'] as String, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.textHint.withValues(alpha: 0.12), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              Text(s.productiveHoursMonth, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            ],
          );
        },
      ),
    );
  }
}

// ── Multi-Year Historical Tab ─────────────────────────────────────────────────

class _MultiYearTab extends ConsumerStatefulWidget {
  const _MultiYearTab();

  @override
  ConsumerState<_MultiYearTab> createState() => _MultiYearTabState();
}

class _MultiYearTabState extends ConsumerState<_MultiYearTab> {
  int _yearsBack = 3;
  String _metric = 'net_savings';

  static const _metrics = [
    {'key': 'net_savings', 'label': 'Ahorro neto', 'color': AppColors.success},
    {'key': 'income', 'label': 'Ingresos', 'color': AppColors.primary},
    {'key': 'habits_completed', 'label': 'Hábitos', 'color': AppColors.secondary},
    {'key': 'productive_hours', 'label': 'Horas productivas', 'color': AppColors.accentOrange},
    {'key': 'gym_sessions', 'label': 'Gym', 'color': AppColors.error},
    {'key': 'learning_hours', 'label': 'Aprendizaje', 'color': AppColors.info},
  ];

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(multiYearProvider(_yearsBack));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comparación histórica', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Evolución año a año de tu vida', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          // Year range selector
          Row(
            children: [3, 5, 10].map((y) {
              final selected = _yearsBack == y;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$y años'),
                  selected: selected,
                  onSelected: (_) => setState(() => _yearsBack = y),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Metric selector
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _metrics.map((m) {
                final key = m['key'] as String;
                final color = m['color'] as Color;
                final selected = _metric == key;
                return GestureDetector(
                  onTap: () => setState(() => _metric = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
                    ),
                    child: Text(
                      m['label'] as String,
                      style: TextStyle(color: selected ? color : AppColors.textSecondary, fontSize: 12, fontWeight: selected ? FontWeight.w700 : null),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          dataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (result) {
              final data = List<Map<String, dynamic>>.from(result['data'] as List);
              final metricInfo = _metrics.firstWhere((m) => m['key'] == _metric);
              final color = metricInfo['color'] as Color;

              double maxVal = 1;
              for (final d in data) {
                final v = (d[_metric] as num).toDouble().abs();
                if (v > maxVal) maxVal = v;
              }

              return Column(
                children: [
                  // Bar chart
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxVal * 1.25,
                          minY: _metric == 'net_savings'
                              ? (data.any((d) => (d[_metric] as num) < 0) ? -maxVal * 0.3 : 0)
                              : 0,
                          barGroups: data.asMap().entries.map((e) {
                            final val = (e.value[_metric] as num).toDouble();
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: val,
                                  color: val >= 0 ? color : AppColors.error,
                                  width: 22,
                                  borderRadius: BorderRadius.circular(6),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxVal * 1.25,
                                    color: color.withValues(alpha: 0.05),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      data[idx]['year'].toString(),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(color: AppColors.textHint.withValues(alpha: 0.1), strokeWidth: 1),
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 16),

                  // Year-over-year comparison cards
                  ...data.reversed.map((d) {
                    final year = d['year'] as int;
                    final val = (d[_metric] as num).toDouble();
                    final prevIdx = data.indexWhere((x) => x['year'] == year - 1);
                    double? change;
                    if (prevIdx >= 0) {
                      final prev = (data[prevIdx][_metric] as num).toDouble();
                      if (prev != 0) change = ((val - prev) / prev.abs()) * 100;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text('$year', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(metricInfo['label'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  Text(
                                    _formatValue(_metric, val),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            if (change != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: change >= 0 ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: change >= 0 ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatValue(String metric, double val) {
    switch (metric) {
      case 'income':
      case 'expenses':
      case 'net_savings':
        return Formatters.currency(val);
      case 'productive_hours':
      case 'learning_hours':
        return '${val.toStringAsFixed(0)}h';
      case 'habits_completed':
        return '${val.toInt()} completados';
      case 'gym_sessions':
        return '${val.toInt()} sesiones';
      default:
        return val.toStringAsFixed(1);
    }
  }
}
