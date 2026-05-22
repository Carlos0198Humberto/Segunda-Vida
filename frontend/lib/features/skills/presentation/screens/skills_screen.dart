import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/skills_provider.dart';

// ─── Category config with Material icons ────────────────────────────────────

class _CatConfig {
  final String key;
  final IconData icon;
  final Color color;
  const _CatConfig(this.key, this.icon, this.color);
}

const _cats = [
  _CatConfig('language',      Icons.record_voice_over_rounded, Color(0xFF6B4EFF)),
  _CatConfig('fitness',       Icons.fitness_center_rounded,    Color(0xFF00D4AA)),
  _CatConfig('spiritual',     Icons.auto_stories_rounded,      Color(0xFFF59E0B)),
  _CatConfig('tech',          Icons.security_rounded,          Color(0xFF3B82F6)),
  _CatConfig('communication', Icons.mic_rounded,               Color(0xFFEF4444)),
  _CatConfig('reading',       Icons.menu_book_rounded,         Color(0xFF8B5CF6)),
  _CatConfig('other',         Icons.star_rounded,              Color(0xFF64748B)),
];

const _presets = [
  {'name': 'Inglés', 'category': 'language',      'color': '#6B4EFF'},
  {'name': 'Ejercicio', 'category': 'fitness',    'color': '#00D4AA'},
  {'name': 'Lectura Biblia', 'category': 'spiritual', 'color': '#F59E0B'},
  {'name': 'Ciberseguridad', 'category': 'tech',  'color': '#3B82F6'},
  {'name': 'Oratoria', 'category': 'communication', 'color': '#EF4444'},
  {'name': 'Lectura', 'category': 'reading',      'color': '#8B5CF6'},
];

_CatConfig _catFor(String? cat) =>
    _cats.firstWhere((c) => c.key == cat, orElse: () => _cats.last);

// ─── Screen ─────────────────────────────────────────────────────────────────

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});
  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final summaryAsync = ref.watch(skillsSummaryProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(skillsSummaryProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Text(s.skillsTitle),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _showCreateSheet(context, s),
                ),
              ],
            ),
            summaryAsync.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('$e'))),
              data: (summary) => _Body(
                summary: summary,
                filter: _filter,
                s: s,
                onFilter: (f) => setState(() => _filter = f),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext ctx, S s) => showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        builder: (_) => _CreateSheet(s: s),
      );
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final SkillsSummary summary;
  final String filter;
  final S s;
  final ValueChanged<String> onFilter;
  const _Body({required this.summary, required this.filter, required this.s, required this.onFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = filter == 'all'
        ? summary.skills
        : summary.skills.where((sk) => sk.category == filter).toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _StatsRow(summary: summary, s: s),
          const SizedBox(height: 16),
          _FilterRow(filter: filter, s: s, onFilter: onFilter),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _EmptyState(s: s)
          else
            ...filtered.map((sk) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SkillCard(skill: sk, s: s),
                )),
        ]),
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SkillsSummary summary;
  final S s;
  const _StatsRow({required this.summary, required this.s});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat('${summary.activeSkills}', s.navSkills, AppColors.primary, Icons.auto_graph_rounded),
        const SizedBox(width: 10),
        _Stat('${summary.totalSessionsToday}', s.today, AppColors.secondary, Icons.today_rounded),
        const SizedBox(width: 10),
        _Stat('${summary.bestStreak}🔥', s.bestStreak, AppColors.accentOrange, Icons.local_fire_department_rounded),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color color;
  final IconData icon;
  const _Stat(this.value, this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Filter Row ──────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String filter;
  final S s;
  final ValueChanged<String> onFilter;
  const _FilterRow({required this.filter, required this.s, required this.onFilter});

  String _label(String key) {
    switch (key) {
      case 'all': return s.allCategories;
      case 'language': return s.catLanguage;
      case 'fitness': return s.catFitness;
      case 'spiritual': return s.catSpiritual;
      case 'tech': return s.catTech;
      case 'communication': return s.catCommunication;
      case 'reading': return s.catReading;
      default: return s.catOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = ['all', ..._cats.map((c) => c.key)];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final key = keys[i];
          final selected = filter == key;
          final cat = key == 'all' ? null : _cats.firstWhere((c) => c.key == key);
          return FilterChip(
            avatar: key == 'all' ? null : Icon(cat!.icon, size: 14, color: selected ? Colors.white : cat.color),
            label: Text(_label(key)),
            selected: selected,
            onSelected: (_) => onFilter(key),
            showCheckmark: false,
            selectedColor: key == 'all' ? AppColors.primary : cat?.color,
            labelStyle: TextStyle(color: selected ? Colors.white : null, fontSize: 12),
          );
        },
      ),
    );
  }
}

// ─── Skill Card ──────────────────────────────────────────────────────────────

class _SkillCard extends ConsumerWidget {
  final SkillModel skill;
  final S s;
  const _SkillCard({required this.skill, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = _catFor(skill.category);
    final progress = skill.progressPct ?? 0.0;

    return AppCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Colored top bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: cat.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(skill.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          if (skill.description != null)
                            Text(skill.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    // Streak badge
                    if (skill.currentStreak > 0)
                      _Badge('${skill.currentStreak} 🔥', AppColors.accentOrange),
                    // Options
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      onPressed: () => _options(context, ref),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats row
                Row(
                  children: [
                    _InfoChip(Icons.check_circle_outline_rounded, '${skill.totalSessions} ${s.sessions}', cat.color),
                    const SizedBox(width: 8),
                    _InfoChip(Icons.schedule_rounded, '${skill.totalMinutes} ${s.minutes}', AppColors.textSecondary),
                    if (skill.daysSinceStart != null) ...[
                      const SizedBox(width: 8),
                      _InfoChip(Icons.calendar_today_rounded, '${skill.daysSinceStart} ${s.days}', AppColors.textSecondary),
                    ],
                  ],
                ),

                // Progress bar
                if ((skill.targetDays != null || skill.targetSessions != null) && progress > 0) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.progress, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('${progress.toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cat.color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 6,
                      backgroundColor: cat.color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(cat.color),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Log button
                SizedBox(
                  width: double.infinity,
                  child: skill.loggedToday
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(s.loggedToday),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.success),
                        )
                      : FilledButton.icon(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _LogSheet(skill: skill, s: s),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(s.logSession),
                          style: FilledButton.styleFrom(backgroundColor: cat.color),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _options(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              title: const Text('Eliminar habilidad', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(skillsActionsProvider).deleteSkill(skill.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoChip(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      );
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  final S s;
  const _EmptyState({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(Icons.auto_graph_rounded, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(s.noSkills, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Text('Sugerencias', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _presets.map((p) {
            final cat = _catFor(p['category']);
            return ActionChip(
              avatar: Icon(cat.icon, size: 16, color: cat.color),
              label: Text(p['name']!),
              onPressed: () => ref.read(skillsActionsProvider).createSkill({
                'name': p['name'], 'category': p['category'],
                'color': p['color'], 'target_days': 30,
              }),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Create Sheet ─────────────────────────────────────────────────────────────

class _CreateSheet extends ConsumerStatefulWidget {
  final S s;
  const _CreateSheet({required this.s});
  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();
  String _category = 'language';
  bool _loading = false;

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); _daysCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final cat = _catFor(_category);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(s.addSkill, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Category selector
            Text(s.category, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
              children: _cats.map((c) {
                final sel = _category == c.key;
                return GestureDetector(
                  onTap: () => setState(() => _category = c.key),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sel ? c.color : c.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? c.color : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c.icon, color: sel ? Colors.white : c.color, size: 24),
                        const SizedBox(height: 4),
                        Text(_catLabel(c.key, s), style: TextStyle(fontSize: 9, color: sel ? Colors.white : c.color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: s.skillName,
                prefixIcon: Icon(cat.icon, color: cat.color),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: s.skillDesc, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _daysCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.targetDays,
                prefixIcon: const Icon(Icons.flag_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: cat.color),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(s.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _catLabel(String key, S s) {
    switch (key) {
      case 'language': return s.catLanguage;
      case 'fitness': return s.catFitness;
      case 'spiritual': return s.catSpiritual;
      case 'tech': return s.catTech;
      case 'communication': return s.catCommunication;
      case 'reading': return s.catReading;
      default: return s.catOther;
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final cat = _catFor(_category);
      final argb = cat.color.toARGB32();
      final hex = '#${argb.toRadixString(16).substring(2).toUpperCase()}';
      await ref.read(skillsActionsProvider).createSkill({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'category': _category,
        'color': hex,
        'target_days': _daysCtrl.text.trim().isEmpty ? null : int.tryParse(_daysCtrl.text.trim()),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Log Session Sheet ────────────────────────────────────────────────────────

class _LogSheet extends ConsumerStatefulWidget {
  final SkillModel skill;
  final S s;
  const _LogSheet({required this.skill, required this.s});
  @override
  ConsumerState<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends ConsumerState<_LogSheet> {
  final _notesCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  int _duration = 30;
  int _quality = 4;
  bool _loading = false;

  @override
  void dispose() { _notesCtrl.dispose(); _refCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final cat = _catFor(widget.skill.category);
    final showRef = widget.skill.category == 'spiritual' || widget.skill.category == 'reading';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(cat.icon, color: cat.color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(widget.skill.name, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 20),

            Text(s.duration, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [15, 30, 45, 60, 90].map((m) => ChoiceChip(
                    label: Text('$m min'),
                    selected: _duration == m,
                    onSelected: (_) => setState(() => _duration = m),
                    selectedColor: cat.color,
                    labelStyle: TextStyle(color: _duration == m ? Colors.white : null),
                  )).toList(),
            ),
            const SizedBox(height: 16),

            if (showRef) ...[
              TextField(
                controller: _refCtrl,
                decoration: InputDecoration(
                  labelText: widget.skill.category == 'spiritual' ? '📖 Pasaje (ej. Génesis 1-3)' : s.reference,
                  prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.notes,
                hintText: 'Reflexiones, aprendizajes...',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Text(s.quality, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() => _quality = i + 1),
                    child: Icon(
                      i < _quality ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.accentGold, size: 32,
                    ),
                  )),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: cat.color),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(s.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(skillsActionsProvider).logSession({
        'skill_id': widget.skill.id,
        'duration_minutes': _duration,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'reference': _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        'quality': _quality,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
