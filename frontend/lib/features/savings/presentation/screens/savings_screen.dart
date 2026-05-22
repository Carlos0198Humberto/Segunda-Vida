import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/progress_ring.dart';
import '../providers/savings_provider.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingsAsync = ref.watch(savingsProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(savingsProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(s.savingsFunds),
              floating: true,
              actions: [
                IconButton(
                  onPressed: () => _showCreateFundSheet(context, ref),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            savingsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (summary) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary header
                    _SavingsSummaryCard(summary: summary, s: s)
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.1),
                    const SizedBox(height: 20),
                    Text(
                      s.yourFunds,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    ...summary.funds.asMap().entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FundCard(
                              fund: e.value,
                              s: s,
                              onContribute: () => _showContributeSheet(context, ref, e.value),
                              onDelete: () => _confirmDeleteFund(context, ref, e.value, s),
                            ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)).slideY(begin: 0.1),
                          ),
                        ),
                    if (summary.funds.isEmpty)
                      _EmptyFunds(s: s, onAdd: () => _showCreateFundSheet(context, ref)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateFundSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateFundSheet(onSave: (data) async {
        await ref.read(savingsActionsProvider).createFund(
              name: data['name'],
              description: data['description'],
              targetAmount: data['target_amount'],
              monthlyContribution: data['monthly_contribution'],
              currentAmount: data['current_amount'],
              color: data['color'],
            );
      }),
    );
  }

  Future<void> _confirmDeleteFund(BuildContext context, WidgetRef ref, SavingsFund fund, S s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text('¿Eliminar "${fund.name}"? Esta acción no se puede deshacer.'),
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
      await ref.read(savingsActionsProvider).deleteFund(fund.id);
    }
  }

  void _showContributeSheet(BuildContext context, WidgetRef ref, SavingsFund fund) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContributeSheet(
        fund: fund,
        onContribute: (amount) async {
          await ref.read(savingsActionsProvider).contribute(
                fund.id,
                amount,
                DateFormat('yyyy-MM-dd').format(DateTime.now()),
              );
        },
      ),
    );
  }
}

class _SavingsSummaryCard extends StatelessWidget {
  final SavingsSummary summary;
  final S s;
  const _SavingsSummaryCard({required this.summary, required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientCard(
      colors: [AppColors.secondary, const Color(0xFF0984E3)],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.totalSaved, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency(summary.totalSaved),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'de ${Formatters.currency(summary.totalTarget)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                progress: summary.overallProgress / 100,
                size: 80,
                strokeWidth: 7,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  '${summary.overallProgress.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryStat(
                value: '${summary.activeFunds}',
                label: s.active,
                icon: Icons.savings_rounded,
              ),
              _SummaryStat(
                value: '${summary.achievedFunds}',
                label: s.achieved,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _SummaryStat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        margin: const EdgeInsets.only(right: 8),
      ),
    );
  }
}

class _FundCard extends StatelessWidget {
  final SavingsFund fund;
  final S s;
  final VoidCallback onContribute;
  final VoidCallback onDelete;
  const _FundCard({required this.fund, required this.s, required this.onContribute, required this.onDelete});

  Color get _color {
    try {
      final hex = fund.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.savings_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(fund.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        if (fund.isAchieved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(s.done, style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          onPressed: onDelete,
                          color: AppColors.error,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      Formatters.currency(fund.currentAmount),
                      style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
                    ),
                    if (fund.description != null && fund.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.flag_rounded, size: 12, color: color.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                fund.description!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color.withValues(alpha: 0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (fund.progressPercentage / 100).clamp(0, 1),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fund.progressPercentage.toInt()}% · ${s.goal}: ${Formatters.currency(fund.targetAmount)}',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              if (fund.monthsToGoal != null)
                Text(
                  '~${fund.monthsToGoal}${s.monthsLeft}',
                  style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          if (fund.monthlyContribution > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${Formatters.currency(fund.monthlyContribution)}${s.perMonth}',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (!fund.isAchieved) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onContribute,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(s.addContribution),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyFunds extends StatelessWidget {
  final VoidCallback onAdd;
  final S s;
  const _EmptyFunds({required this.onAdd, required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.savings_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(s.noFunds, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              s.noFundsDesc,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(s.createFirstFund),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateFundSheet extends ConsumerStatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _CreateFundSheet({required this.onSave});

  @override
  ConsumerState<_CreateFundSheet> createState() => _CreateFundSheetState();
}

class _CreateFundSheetState extends ConsumerState<_CreateFundSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  bool _loading = false;
  String _color = '#6B4EFF';

  List<Map<String, String>> _buildPresets(S s) => [
    {'name': s.presetEmergency, 'color': '#FF6B6B'},
    {'name': s.presetTravel, 'color': '#45B7D1'},
    {'name': s.presetCar, 'color': '#4ECDC4'},
    {'name': s.presetStudies, 'color': '#A29BFE'},
    {'name': s.presetHealth, 'color': '#96CEB4'},
    {'name': s.presetWedding, 'color': '#DDA0DD'},
    {'name': s.presetTech, 'color': '#6B4EFF'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _monthlyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'name': _nameCtrl.text,
        'description': _descCtrl.text.isEmpty ? null : _descCtrl.text,
        'target_amount': double.tryParse(_targetCtrl.text) ?? 0,
        'current_amount': double.tryParse(_currentCtrl.text) ?? 0,
        'monthly_contribution': double.tryParse(_monthlyCtrl.text) ?? 0,
        'color': _color,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final presets = _buildPresets(s);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(s.newSavingsFund, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(s.newFundSubtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              // Quick presets
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final preset = presets[i];
                    return ActionChip(
                      label: Text(preset['name']!),
                      onPressed: () => setState(() {
                        _nameCtrl.text = preset['name']!;
                        _color = preset['color']!;
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(hintText: s.fundName),
                validator: (v) => v == null || v.isEmpty ? s.required : null,
              ),
              const SizedBox(height: 12),
              // Purpose/description field — personalized goal label
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  label: Text(s.fundPurpose),
                  hintText: s.fundPurposeHint,
                  prefixIcon: const Icon(Icons.flag_rounded, size: 18),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: s.targetAmount, prefixText: '\$ '),
                validator: (v) => v == null || double.tryParse(v) == null ? s.required : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(hintText: s.currentAmount, prefixText: '\$ '),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _monthlyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(hintText: s.monthlyContrib, prefixText: '\$ '),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(s.createFund),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributeSheet extends StatefulWidget {
  final SavingsFund fund;
  final Future<void> Function(double) onContribute;
  const _ContributeSheet({required this.fund, required this.onContribute});

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    try {
      await widget.onContribute(amount);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('${s.addTo} ${widget.fund.name}', style: theme.textTheme.headlineMedium),
                Text(
                  '${Formatters.currency(widget.fund.currentAmount)} / ${Formatters.currency(widget.fund.targetAmount)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(hintText: s.amountToAdd, prefixText: '\$ '),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [50.0, 100.0, 200.0, 500.0].map((a) => ActionChip(
                        label: Text('\$${a.toInt()}'),
                        onPressed: () => _amountCtrl.text = a.toString(),
                      )).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(s.addContribution),
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
