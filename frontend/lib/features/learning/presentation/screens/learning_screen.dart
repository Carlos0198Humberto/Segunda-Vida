import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';

final learningItemsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/learning');
  return response.data as List;
});

final learningSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/learning/summary');
  return response.data as Map<String, dynamic>;
});

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(learningItemsProvider);
    final summaryAsync = ref.watch(learningSummaryProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(learningItemsProvider);
          ref.invalidate(learningSummaryProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(s.learning),
              floating: true,
              actions: [
                IconButton(
                  onPressed: () => _showAddItemSheet(context, ref, s),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  summaryAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (sum) => _LearningSummaryCard(summary: sum, s: s).animate().fadeIn().slideY(begin: 0.1),
                  ),
                  const SizedBox(height: 20),
                  Text(s.yourLibrary, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  itemsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (items) => items.isEmpty
                        ? _EmptyLearning(s: s, onAdd: () => _showAddItemSheet(context, ref, s))
                        : Column(
                            children: items.asMap().entries.map((e) {
                              final item = e.value as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _LearningItemCard(
                                  item: item,
                                  s: s,
                                  onLogSession: () => _showLogSessionSheet(context, ref, item['id'] as String, s),
                                ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)).slideY(begin: 0.1),
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

  void _showAddItemSheet(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final titleCtrl = TextEditingController();
        final authorCtrl = TextEditingController();
        String itemType = 'book';
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
                  Text(s.addToLibrary, style: Theme.of(ctx).textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: ['book', 'course', 'topic', 'video', 'podcast'].map((t) =>
                      ChoiceChip(label: Text(t), selected: itemType == t, onSelected: (_) => setState(() => itemType = t))
                    ).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: titleCtrl, autofocus: true, decoration: InputDecoration(hintText: s.title)),
                  const SizedBox(height: 12),
                  TextField(controller: authorCtrl, decoration: InputDecoration(hintText: s.authorCreator)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty) return;
                        final dio = ref.read(dioProvider);
                        await dio.post('/learning', data: {
                          'title': titleCtrl.text,
                          'item_type': itemType,
                          'author': authorCtrl.text.isEmpty ? null : authorCtrl.text,
                        });
                        ref.invalidate(learningItemsProvider);
                        ref.invalidate(learningSummaryProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(s.addToLibrary),
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

  void _showLogSessionSheet(BuildContext context, WidgetRef ref, String itemId, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final minutesCtrl = TextEditingController();
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(s.logStudySession, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 14),
                TextField(
                  controller: minutesCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(hintText: s.duration, suffixText: 'min'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [15, 30, 45, 60, 90].map((m) => ActionChip(
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
                      await dio.post('/learning/sessions', data: {
                        'learning_item_id': itemId,
                        'duration_minutes': minutes,
                        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      });
                      ref.invalidate(learningItemsProvider);
                      ref.invalidate(learningSummaryProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(s.logSession),
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

class _LearningSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  final S s;
  const _LearningSummaryCard({required this.summary, required this.s});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: [AppColors.accentOrange, const Color(0xFFFF6B6B)],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.totalHours, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '${summary['total_hours']}h',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                Text('${summary['weekly_hours']}${s.hThisWeek}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _LearningStatItem(value: '${summary['total_items']}', label: s.total),
              _LearningStatItem(value: '${summary['in_progress_items']}', label: s.inProgress),
              _LearningStatItem(value: '${summary['completed_items']}', label: s.completed),
            ],
          ),
        ],
      ),
    );
  }
}

class _LearningStatItem extends StatelessWidget {
  final String value, label;
  const _LearningStatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            TextSpan(text: ' $label', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _LearningItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final S s;
  final VoidCallback onLogSession;
  const _LearningItemCard({required this.item, required this.s, required this.onLogSession});

  Color get _statusColor {
    switch (item['status'] as String) {
      case 'completed': return AppColors.success;
      case 'in_progress': return AppColors.primary;
      case 'paused': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (item['item_type'] as String) {
      case 'book': return Icons.menu_book_rounded;
      case 'course': return Icons.school_rounded;
      case 'video': return Icons.play_circle_rounded;
      case 'podcast': return Icons.headphones_rounded;
      default: return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = item['progress_percentage'] as int;
    final status = item['status'] as String;
    final statusColor = _statusColor;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(_typeIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] as String, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (item['author'] != null)
                      Text(item['author'] as String, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (status != 'planned') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(statusColor),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$progress%', style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ],
          if (status != 'completed') ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onLogSession,
              icon: const Icon(Icons.timer_rounded, size: 16),
              label: Text(s.logSession),
              style: TextButton.styleFrom(foregroundColor: statusColor, padding: EdgeInsets.zero),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyLearning extends StatelessWidget {
  final VoidCallback onAdd;
  final S s;
  const _EmptyLearning({required this.onAdd, required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('📚', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(s.emptyLibrary, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(s.emptyLibraryDesc, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: Text(s.addFirstItem)),
          ],
        ),
      ),
    );
  }
}
