import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/diary_provider.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final todayAsync = ref.watch(diaryTodayProvider);
    final historyAsync = ref.watch(diaryHistoryProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(s.diaryTitle),
            floating: true,
            snap: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _TodayHeader(s: s),
            ),
          ),
          todayAsync.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
            data: (entries) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: entries.isEmpty
                  ? SliverToBoxAdapter(
                      child: _EmptyToday(s: s, onAdd: () => _showAddSheet(context, ref, s)),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _EntryTile(entry: entries[i], index: i, onDelete: () {
                          ref.read(diaryActionsProvider).deleteEntry(entries[i].id);
                        }),
                        childCount: entries.length,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(s.diaryHistory, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
          historyAsync.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (all) {
              // Group by date
              final grouped = <String, List<DiaryEntry>>{};
              for (final e in all) {
                grouped.putIfAbsent(e.date, () => []).add(e);
              }
              final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

              if (dates.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(s.diaryEmpty, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final dateKey = dates[i];
                    final items = grouped[dateKey]!;
                    final dt = DateTime.parse(dateKey);
                    final label = _dateLabel(dt, s);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(label, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            )),
                          ),
                          ...items.asMap().entries.map((e) => _EntryTile(
                            entry: e.value,
                            index: e.key,
                            compact: true,
                            onDelete: () => ref.read(diaryActionsProvider).deleteEntry(e.value.id),
                          )),
                        ],
                      ),
                    );
                  },
                  childCount: dates.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref, s),
        icon: const Icon(Icons.add_rounded),
        label: Text(s.diaryAdd),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  String _dateLabel(DateTime dt, S s) {
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return s.today;
    if (diff == 1) return s.yesterday;
    return DateFormat('EEEE, d MMMM').format(dt);
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEntrySheet(
        onSave: (content, category, emoji) async {
          await ref.read(diaryActionsProvider).addEntry(
            content: content,
            category: category,
            emoji: emoji,
          );
        },
        s: s,
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  final S s;
  const _TodayHeader({required this.s});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.diaryToday, style: Theme.of(context).textTheme.headlineMedium),
              Text(
                DateFormat('EEEE, d MMMM').format(now),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyToday extends StatelessWidget {
  final S s;
  final VoidCallback onAdd;
  const _EmptyToday({required this.s, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primaryLight],
      onTap: onAdd,
      child: Row(
        children: [
          const Text('📝', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.diaryEmptyToday, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(s.diaryEmptyTodayDesc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final DiaryEntry entry;
  final int index;
  final bool compact;
  final VoidCallback onDelete;
  const _EntryTile({required this.entry, required this.index, this.compact = false, required this.onDelete});

  static const _catColors = {
    'entertainment': AppColors.categoryEntertainment,
    'social': AppColors.secondary,
    'sport': AppColors.accentOrange,
    'culture': AppColors.accentGold,
    'rest': AppColors.info,
    'personal': AppColors.primary,
    'food': AppColors.categoryFood,
    'work': AppColors.textSecondary,
    'other': AppColors.categoryOther,
  };

  static const _catIcons = {
    'entertainment': Icons.movie_rounded,
    'social': Icons.people_rounded,
    'sport': Icons.directions_run_rounded,
    'culture': Icons.auto_stories_rounded,
    'rest': Icons.self_improvement_rounded,
    'personal': Icons.person_rounded,
    'food': Icons.restaurant_rounded,
    'work': Icons.work_rounded,
    'other': Icons.circle_rounded,
  };

  Color get _color => _catColors[entry.category] ?? AppColors.primary;
  IconData get _icon => _catIcons[entry.category] ?? Icons.circle_rounded;

  String get _timeLabel {
    try {
      final dt = DateTime.parse(entry.loggedAt).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      child: Dismissible(
        key: Key(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Eliminar entrada'),
              content: const Text('¿Eliminar esta entrada del diario?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (_) => onDelete(),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: entry.emoji != null
                    ? Center(child: Text(entry.emoji!, style: const TextStyle(fontSize: 20)))
                    : Icon(_icon, color: _color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_catLabel(entry.category), style: TextStyle(fontSize: 10, color: _color, fontWeight: FontWeight.w600)),
                        ),
                        if (entry.source != 'manual') ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.link_rounded, size: 12, color: AppColors.textHint),
                        ],
                        const Spacer(),
                        Text(_timeLabel, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 40 * index)),
      ),
    );
  }

  String _catLabel(String cat) {
    const labels = {
      'entertainment': 'Entretenimiento',
      'social': 'Social',
      'sport': 'Deporte',
      'culture': 'Cultura',
      'rest': 'Descanso',
      'personal': 'Personal',
      'food': 'Comida',
      'work': 'Trabajo',
      'other': 'Otro',
    };
    return labels[cat] ?? cat;
  }
}

// ── Add Entry Bottom Sheet ────────────────────────────────────────────────────

class _AddEntrySheet extends StatefulWidget {
  final Future<void> Function(String content, String category, String? emoji) onSave;
  final S s;
  const _AddEntrySheet({required this.onSave, required this.s});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _ctrl = TextEditingController();
  String _category = 'entertainment';
  String? _emoji;
  bool _loading = false;

  static const _categories = [
    ('entertainment', 'Entretenimiento', '🎬', AppColors.categoryEntertainment),
    ('social', 'Social', '👥', AppColors.secondary),
    ('sport', 'Deporte', '🏃', AppColors.accentOrange),
    ('culture', 'Cultura', '📚', AppColors.accentGold),
    ('rest', 'Descanso', '😌', AppColors.info),
    ('personal', 'Personal', '🙋', AppColors.primary),
    ('food', 'Comida', '🍽️', AppColors.categoryFood),
    ('work', 'Trabajo', '💼', AppColors.textSecondary),
    ('other', 'Otro', '✨', AppColors.categoryOther),
  ];

  static const _presets = [
    ('🎬', 'Vi una película'),
    ('📺', 'Vi una serie'),
    ('🎮', 'Jugué videojuegos'),
    ('📚', 'Leí un libro'),
    ('🏋️', 'Entrené'),
    ('🚶', 'Salí a caminar'),
    ('👨‍👩‍👧', 'Tiempo en familia'),
    ('🍕', 'Comí algo rico'),
    ('🎵', 'Escuché música'),
    ('🧘', 'Medité'),
    ('🎨', 'Creé algo'),
    ('🤝', 'Vi a un amigo'),
  ];

  void _usePreset(String emoji, String text) {
    setState(() {
      _emoji = emoji;
      _ctrl.text = text;
    });
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await widget.onSave(_ctrl.text.trim(), _category, _emoji);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(widget.s.diaryAddTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),

            // Presets
            Text(widget.s.diaryPresets, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) => GestureDetector(
                onTap: () => _usePreset(p.$1, p.$2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _ctrl.text == p.$2
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: _ctrl.text == p.$2
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.$1, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(p.$2, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // Free text
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: widget.s.diaryHint,
                prefixText: _emoji != null ? '$_emoji  ' : null,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 280,
            ),
            const SizedBox(height: 16),

            // Category chips
            Text(widget.s.category, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) => ChoiceChip(
                label: Text('${c.$3} ${c.$2}'),
                selected: _category == c.$1,
                selectedColor: c.$4.withValues(alpha: 0.15),
                onSelected: (_) => setState(() {
                  _category = c.$1;
                  _emoji = c.$3;
                }),
                labelStyle: TextStyle(
                  color: _category == c.$1 ? c.$4 : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: _category == c.$1 ? FontWeight.w600 : FontWeight.normal,
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.s.save),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
