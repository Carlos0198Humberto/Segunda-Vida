import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../providers/dashboard_provider.dart';
import '../../../diary/presentation/providers/diary_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(dashboardProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final userData = HiveStorage.getUser();
    final userName = userData?['full_name'] ?? userData?['email']?.split('@').first ?? 'there';
    final now = DateTime.now();
    final greeting = now.hour < 12 ? s.goodMorning : now.hour < 17 ? s.goodAfternoon : s.goodEvening;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(floating: true, snap: true, expandedHeight: 0, toolbarHeight: 0),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$greeting,', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
                            Text(userName.split(' ').first, style: Theme.of(context).textTheme.displayMedium),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.push('/analytics'),
                              icon: const Icon(Icons.bar_chart_rounded),
                              style: IconButton.styleFrom(backgroundColor: Theme.of(context).cardColor),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => context.push('/settings'),
                              icon: const Icon(Icons.settings_outlined),
                              style: IconButton.styleFrom(backgroundColor: Theme.of(context).cardColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(now),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ),
            dashAsync.when(
              loading: () => SliverToBoxAdapter(child: _buildSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(s.couldNotLoad, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.refresh(dashboardProvider),
                          child: Text(s.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (data) => _DashboardContent(data: data, s: s),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardData data;
  final S s;
  const _DashboardContent({required this.data, required this.s});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _MotivationalCard(message: data.motivationalMessage, insights: data.insights, s: s)
              .animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          _BalanceCard(data: data, s: s).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: s.habitsToday,
                  value: '${data.habitsCompletedToday}/${data.totalActiveHabits}',
                  icon: Icons.track_changes_rounded,
                  iconColor: AppColors.secondary,
                  subtitle: '${data.bestStreak}d ${s.streak}',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: s.productive,
                  value: '${data.productiveHoursToday}h',
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.accentOrange,
                  subtitle: s.today,
                  onTap: () {},
                ),
              ),
            ],
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          _SavingsCard(data: data, s: s).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          _HealthRow(data: data, s: s).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 16),
          _LearningCard(data: data, s: s).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          const _DiaryTodayCard().animate().fadeIn(delay: 330.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          const _DayReviewCard().animate().fadeIn(delay: 360.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          const _WeeklyReviewCard().animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          const _QuickActions().animate().fadeIn(delay: 410.ms),
        ]),
      ),
    );
  }
}

class _MotivationalCard extends StatelessWidget {
  final String message;
  final List<String> insights;
  final S s;
  const _MotivationalCard({required this.message, required this.insights, required this.s});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: [AppColors.primary, AppColors.primaryLight],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(s.dailyInsight, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w500, height: 1.4),
          ),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: insights.map((i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 11)),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final DashboardData data;
  final S s;
  const _BalanceCard({required this.data, required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.totalBalance, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(Formatters.currency(data.totalBalance), style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _FinanceItem(
                label: s.income,
                value: Formatters.compactCurrency(data.monthlyIncome),
                color: AppColors.success,
                icon: Icons.arrow_downward_rounded,
              )),
              Container(width: 1, height: 40, color: AppColors.textHint.withValues(alpha: 0.2)),
              Expanded(child: _FinanceItem(
                label: s.expense,
                value: Formatters.compactCurrency(data.monthlyExpenses),
                color: AppColors.error,
                icon: Icons.arrow_upward_rounded,
              )),
              Container(width: 1, height: 40, color: AppColors.textHint.withValues(alpha: 0.2)),
              Expanded(child: _FinanceItem(
                label: s.saved,
                value: '${data.monthlySavingsRate.toStringAsFixed(0)}%',
                color: AppColors.primary,
                icon: Icons.trending_up_rounded,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinanceItem extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _FinanceItem({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SavingsCard extends StatelessWidget {
  final DashboardData data;
  final S s;
  const _SavingsCard({required this.data, required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          ProgressRing(
            progress: data.savingsProgress / 100,
            size: 72,
            strokeWidth: 7,
            color: AppColors.secondary,
            child: Text(
              '${data.savingsProgress.toInt()}%',
              style: theme.textTheme.labelLarge?.copyWith(color: AppColors.secondary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.savingsProgress, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.currency(data.totalSaved)} de ${Formatters.currency(data.totalSavingsTarget)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                if (data.topFundName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${data.topFundName}: ${data.topFundProgress?.toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final DashboardData data;
  final S s;
  const _HealthRow({required this.data, required this.s});

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
                Row(
                  children: [
                    const Icon(Icons.water_drop_rounded, color: AppColors.info, size: 18),
                    const SizedBox(width: 6),
                    Text(s.hydration, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (data.waterPercentage / 100).clamp(0, 1),
                  backgroundColor: AppColors.info.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(AppColors.info),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
                const SizedBox(height: 6),
                Text(
                  '${Formatters.waterAmount(data.todayWaterMl)} / ${Formatters.waterAmount(data.waterGoalMl)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
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
                Row(
                  children: [
                    const Icon(Icons.bedtime_rounded, color: AppColors.accentGold, size: 18),
                    const SizedBox(width: 6),
                    Text(s.sleep, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data.lastSleepHours != null
                      ? Formatters.sleepDuration(data.lastSleepHours!)
                      : s.notLogged,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: data.lastSleepHours != null && data.lastSleepHours! >= data.sleepGoalHours * 0.85
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.goal}: ${data.sleepGoalHours.toStringAsFixed(0)}h',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningCard extends StatelessWidget {
  final DashboardData data;
  final S s;
  const _LearningCard({required this.data, required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.accentGold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.learning, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${data.activeLearningItems} ${s.active} · ${data.learningHoursWeek}h ${s.thisWeek}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.sunriseGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${data.studyHoursWeek}h ${s.study}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    final items = [
      _QAData(s.qaExpense, Icons.add_shopping_cart_rounded, AppColors.error, '/finance'),
      _QAData(s.qaWater, Icons.water_drop_rounded, AppColors.info, '/health'),
      _QAData(s.qaHabit, Icons.check_circle_rounded, AppColors.secondary, '/habits'),
      _QAData(s.qaStudy, Icons.timer_rounded, AppColors.accentOrange, '/time'),
      _QAData(s.qaSavings, Icons.savings_rounded, AppColors.primary, '/savings'),
      _QAData(s.qaSleep, Icons.bedtime_rounded, AppColors.accentGold, '/health'),
      _QAData(s.qaPlan, Icons.calendar_today_rounded, AppColors.primaryLight, '/planning'),
      _QAData(s.qaLearn, Icons.book_rounded, const Color(0xFFFF6B6B), '/learning'),
      _QAData(s.diaryTitle, Icons.auto_stories_rounded, AppColors.secondary, '/diary'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.quickActions, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 86,
          ),
          children: items
              .map((d) => _QuickActionItem(label: d.label, icon: d.icon, color: d.color, path: d.path))
              .toList(),
        ),
      ],
    );
  }
}

class _QAData {
  final String label;
  final IconData icon;
  final Color color;
  final String path;
  const _QAData(this.label, this.icon, this.color, this.path);
}

// ── Diary Today Card ──────────────────────────────────────────────────────────

class _DiaryTodayCard extends ConsumerWidget {
  const _DiaryTodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final todayAsync = ref.watch(diaryTodayProvider);

    return todayAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entries) => AppCard(
        onTap: () => context.push('/diary'),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.diaryTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    entries.isEmpty
                        ? s.diaryEmptyToday
                        : '${entries.length} ${s.dayActivities}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (entries.isNotEmpty)
              Wrap(
                spacing: 4,
                children: entries.take(3).map((e) => Text(
                  e.emoji ?? '📝',
                  style: const TextStyle(fontSize: 20),
                )).toList(),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Day Review Card (visible after 4pm) ──────────────────────────────────────

class _DayReviewCard extends ConsumerWidget {
  const _DayReviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DateTime.now().hour < 16) return const SizedBox.shrink();

    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final dashAsync = ref.watch(dashboardProvider);
    final diaryCountAsync = ref.watch(diaryTodayCountProvider);

    return dashAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final habitScore = data.totalActiveHabits > 0
            ? (data.habitsCompletedToday / data.totalActiveHabits * 100).round()
            : 0;
        final waterScore = data.waterPercentage.round().clamp(0, 100);
        final sleepScore = data.lastSleepHours != null
            ? (data.lastSleepHours! / data.sleepGoalHours * 100).round().clamp(0, 100)
            : 50;
        final productiveScore = (data.productiveHoursToday / 4 * 100).round().clamp(0, 100);
        final dayScore = ((habitScore + waterScore + sleepScore + productiveScore) / 4).round();

        Color scoreColor;
        String scoreEmoji;
        if (dayScore >= 75) {
          scoreColor = AppColors.success;
          scoreEmoji = '🌟';
        } else if (dayScore >= 45) {
          scoreColor = AppColors.warning;
          scoreEmoji = '💪';
        } else {
          scoreColor = AppColors.error;
          scoreEmoji = '📈';
        }

        return GradientCard(
          colors: [const Color(0xFF1A1625), const Color(0xFF231E35)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(scoreEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(s.dayReviewTitle, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  Text(
                    '$dayScore/100',
                    style: TextStyle(color: scoreColor, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DayScoreRow(label: s.habitsToday, value: habitScore / 100, color: AppColors.secondary),
              const SizedBox(height: 8),
              _DayScoreRow(label: s.hydration, value: waterScore / 100, color: AppColors.info),
              const SizedBox(height: 8),
              _DayScoreRow(label: s.sleep, value: sleepScore / 100, color: AppColors.accentGold),
              const SizedBox(height: 8),
              _DayScoreRow(label: s.productive, value: productiveScore / 100, color: AppColors.accentOrange),
              const SizedBox(height: 12),
              diaryCountAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (count) => count > 0
                    ? Row(
                        children: [
                          const Icon(Icons.auto_stories_rounded, color: Colors.white54, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '$count ${s.dayActivities}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayScoreRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _DayScoreRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).round()}%',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── Weekly Review Card (visible on Mon/Tue showing last week, or any day) ────

class _WeeklyReviewCard extends ConsumerWidget {
  const _WeeklyReviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekday = DateTime.now().weekday;
    // Show only on Sunday (7) or Monday (1)
    if (weekday != 7 && weekday != 1) return const SizedBox.shrink();

    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final reviewAsync = ref.watch(weeklyReviewProvider);

    return reviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final score = (data['score'] as num).toInt();
        final habitPct = (data['habit_pct'] as num).toInt();
        final prodH = (data['productive_hours'] as num).toDouble();
        final gymSessions = (data['gym_sessions'] as num).toInt();
        final avgSleep = (data['avg_sleep'] as num).toDouble();
        final diaryCount = (data['diary_entries'] as num).toInt();

        return GradientCard(
          colors: [AppColors.secondary, AppColors.primary],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(s.weeklyReviewTitle, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$score/100', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _WeekStat(label: s.weeklyReviewHabits, value: '$habitPct%', icon: Icons.track_changes_rounded),
                  _WeekStat(label: s.weeklyReviewGym, value: '$gymSessions', icon: Icons.fitness_center_rounded),
                  _WeekStat(label: s.weeklyReviewSleep, value: '${avgSleep}h', icon: Icons.bedtime_rounded),
                  _WeekStat(label: s.weeklyReviewProductivity, value: '${prodH}h', icon: Icons.bolt_rounded),
                  _WeekStat(label: s.weeklyReviewDiary, value: '$diaryCount', icon: Icons.auto_stories_rounded),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _WeekStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String path;
  const _QuickActionItem({required this.label, required this.icon, required this.color, required this.path});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(path),
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
