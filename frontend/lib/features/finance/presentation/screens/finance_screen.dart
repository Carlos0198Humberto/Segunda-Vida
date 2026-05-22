import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final transactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final response = await dio.get('/finances/transactions', queryParameters: {
    'start_date': DateFormat('yyyy-MM-dd').format(start),
    'limit': 100,
  });
  return response.data as List;
});

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/finances/categories');
  return response.data as List;
});

final accountsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/finances/accounts');
  return response.data as List;
});

final budgetsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final now = DateTime.now();
  try {
    final response = await dio.get('/finances/budgets', queryParameters: {
      'year': now.year,
      'month': now.month,
    });
    return response.data as List;
  } catch (_) {
    return [];
  }
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filter = 'all'; // all, income, expense

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            title: Text(s.finances),
            floating: true,
            actions: [
              IconButton(
                onPressed: () => _showAddTransaction(context, ref, s),
                icon: const Icon(Icons.add_rounded),
                tooltip: s.addTransaction,
              ),
              IconButton(
                onPressed: () => _showCategoriesSheet(context, ref, s),
                icon: const Icon(Icons.category_rounded),
                tooltip: s.addCategory,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: s.transactions),
                Tab(text: s.byCategory),
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
            _TransactionsTab(filter: _filter, onFilterChange: (f) => setState(() => _filter = f)),
            const _CategoryBreakdownTab(),
          ],
        ),
      ),
    );
  }

  void _showAddTransaction(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTransactionSheet(
        onSave: (data) async {
          final dio = ref.read(dioProvider);
          final accounts = ref.read(accountsProvider).value ?? [];
          if (accounts.isEmpty) {
            final acc = await dio.post('/finances/accounts', data: {
              'name': s.mainAccount,
              'account_type': 'checking',
              'current_balance': 0,
              'is_primary': true,
            });
            data['account_id'] = acc.data['id'];
          } else {
            data['account_id'] = accounts.first['id'];
          }
          await dio.post('/finances/transactions', data: data);
          ref.invalidate(transactionsProvider);
          ref.invalidate(accountsProvider);
          ref.invalidate(dashboardProvider);
        },
        categories: ref.read(categoriesProvider).value ?? [],
      ),
    );
  }

  void _showCategoriesSheet(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoriesSheet(),
    );
  }
}

// ── Transactions Tab ───────────────────────────────────────────────────────────

class _TransactionsTab extends ConsumerWidget {
  final String filter;
  final ValueChanged<String> onFilterChange;
  const _TransactionsTab({required this.filter, required this.onFilterChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final txAsync = ref.watch(transactionsProvider);
    final accAsync = ref.watch(accountsProvider);
    final catAsync = ref.watch(categoriesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(transactionsProvider);
        ref.invalidate(accountsProvider);
        ref.invalidate(categoriesProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card
            accAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (accounts) => accounts.isEmpty
                  ? const SizedBox.shrink()
                  : _AccountsRow(accounts: accounts, s: s).animate().fadeIn(),
            ),
            const SizedBox(height: 16),
            // Filter chips
            Row(
              children: [
                Flexible(
                  child: Text(s.transactions, style: Theme.of(context).textTheme.headlineMedium, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _FilterChip(label: s.allTime, selected: filter == 'all', onTap: () => onFilterChange('all')),
                const SizedBox(width: 6),
                _FilterChip(label: s.income, selected: filter == 'income', onTap: () => onFilterChange('income')),
                const SizedBox(width: 6),
                _FilterChip(label: s.expense, selected: filter == 'expense', onTap: () => onFilterChange('expense')),
              ],
            ),
            const SizedBox(height: 12),
            txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txs) {
                final cats = catAsync.value ?? [];
                final filtered = filter == 'all'
                    ? txs
                    : txs.where((t) => (t as Map)['transaction_type'] == filter).toList();
                if (filtered.isEmpty) {
                  return _EmptyTransactions(s: s, onAdd: () {});
                }
                return Column(
                  children: filtered.asMap().entries.map((e) {
                    final tx = e.value as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TransactionCard(
                        tx: tx,
                        s: s,
                        cats: cats,
                        onDelete: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(s.confirmDelete),
                              content: Text(s.cannotUndo),
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
                            final dio = ref.read(dioProvider);
                            await dio.delete('/finances/transactions/${tx['id']}');
                            ref.invalidate(transactionsProvider);
                            ref.invalidate(accountsProvider);
                            ref.invalidate(dashboardProvider);
                          }
                        },
                      ).animate().fadeIn(delay: Duration(milliseconds: 30 * e.key)).slideX(begin: -0.05),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : null,
          border: Border.all(color: selected ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

// ── Category Breakdown Tab ─────────────────────────────────────────────────────

class _CategoryBreakdownTab extends ConsumerWidget {
  const _CategoryBreakdownTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final txAsync = ref.watch(transactionsProvider);
    final catAsync = ref.watch(categoriesProvider);
    final budgetsAsync = ref.watch(budgetsProvider);

    return txAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (txs) {
        final cats = catAsync.value ?? [];
        final budgets = budgetsAsync.value ?? [];

        // Build budget map: category_id -> budget amount
        final Map<String, double> budgetMap = {};
        for (final b in budgets) {
          final budget = b as Map<String, dynamic>;
          final catId = budget['category_id'] as String?;
          if (catId != null) {
            budgetMap[catId] = (budget['amount'] as num).toDouble();
          }
        }

        // Aggregate by category
        final Map<String, double> catTotals = {};
        for (final tx in txs) {
          final t = tx as Map<String, dynamic>;
          if (t['transaction_type'] != 'expense') continue;
          final catId = t['category_id'] as String?;
          final key = catId ?? '__uncategorized__';
          catTotals[key] = (catTotals[key] ?? 0) + (t['amount'] as num).toDouble();
        }
        final total = catTotals.values.fold(0.0, (a, b) => a + b);

        if (total == 0) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pie_chart_outline_rounded, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text(s.noTransactions, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              ],
            ),
          ));
        }

        final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: sorted.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(
                      '${s.expense}: ${Formatters.currency(total)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    )),
                    TextButton.icon(
                      onPressed: () => _showSetBudgetSheet(context, ref, cats, budgetMap, s),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(s.setBudget, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }
            final entry = sorted[i - 1];
            final catData = cats.firstWhere(
              (c) => c['id'] == entry.key,
              orElse: () => {'name': 'Otros', 'color': '#B2BEC3', 'icon': 'more_horiz'},
            ) as Map<String, dynamic>;
            final pct = total > 0 ? entry.value / total : 0.0;
            final budget = budgetMap[entry.key];
            final budgetPct = budget != null ? (entry.value / budget).clamp(0.0, 1.5) : null;
            final isOverBudget = budgetPct != null && budgetPct >= 1.0;
            final isNearBudget = budgetPct != null && budgetPct >= 0.8 && !isOverBudget;

            Color color;
            try {
              final hex = (catData['color'] as String).replaceFirst('#', '');
              color = Color(int.parse('FF$hex', radix: 16));
            } catch (_) {
              color = AppColors.primary;
            }

            final barColor = isOverBudget
                ? AppColors.error
                : isNearBudget
                    ? AppColors.warning
                    : color;

            return AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(catData['name'] as String, style: Theme.of(context).textTheme.titleMedium)),
                      if (isOverBudget)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text('Excedido', style: const TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
                        )
                      else if (isNearBudget)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(s.budgetAlert, style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        Formatters.currency(entry.value),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: barColor, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (budget != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: budgetPct!.clamp(0.0, 1.0),
                              backgroundColor: barColor.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(barColor),
                              minHeight: 7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${Formatters.currency(entry.value)} ${s.budgetOf} ${Formatters.currency(budget)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: color.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(pct * 100).toInt()}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 40 * i));
          },
        );
      },
    );
  }

  void _showSetBudgetSheet(BuildContext context, WidgetRef ref, List<dynamic> cats, Map<String, double> current, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetBudgetSheet(cats: cats, current: current, s: s, ref: ref),
    );
  }
}

class _SetBudgetSheet extends StatefulWidget {
  final List<dynamic> cats;
  final Map<String, double> current;
  final S s;
  final WidgetRef ref;
  const _SetBudgetSheet({required this.cats, required this.current, required this.s, required this.ref});

  @override
  State<_SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<_SetBudgetSheet> {
  final Map<String, TextEditingController> _ctrls = {};

  @override
  void initState() {
    super.initState();
    final expenseCats = widget.cats.where((c) => (c as Map)['category_type'] == 'expense').toList();
    for (final cat in expenseCats) {
      final id = (cat as Map<String, dynamic>)['id'] as String;
      final existing = widget.current[id];
      _ctrls[id] = TextEditingController(text: existing != null ? existing.toStringAsFixed(0) : '');
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseCats = widget.cats.where((c) => (c as Map)['category_type'] == 'expense').toList();
    final now = DateTime.now();

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(widget.s.setBudget, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text('Presupuesto mensual por categoría', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ...expenseCats.map((c) {
                final cat = c as Map<String, dynamic>;
                final id = cat['id'] as String;
                Color catColor;
                try {
                  final hex = (cat['color'] as String).replaceFirst('#', '');
                  catColor = Color(int.parse('FF$hex', radix: 16));
                } catch (_) {
                  catColor = AppColors.primary;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(cat['name'] as String, style: Theme.of(context).textTheme.bodyMedium)),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _ctrls[id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            prefixText: '\$ ',
                            hintText: '0',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final dio = widget.ref.read(dioProvider);
                    for (final entry in _ctrls.entries) {
                      final amount = double.tryParse(entry.value.text);
                      if (amount != null && amount > 0) {
                        try {
                          await dio.post('/finances/budgets', data: {
                            'category_id': entry.key,
                            'amount': amount,
                            'period': 'monthly',
                            'year': now.year,
                            'month': now.month,
                          });
                        } catch (_) {}
                      }
                    }
                    widget.ref.invalidate(budgetsProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(widget.s.save),
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

// ── Account Row ────────────────────────────────────────────────────────────────

class _AccountsRow extends StatelessWidget {
  final List<dynamic> accounts;
  final S s;
  const _AccountsRow({required this.accounts, required this.s});

  @override
  Widget build(BuildContext context) {
    final totalBalance = accounts.fold<double>(0, (sum, a) => sum + ((a['current_balance'] as num).toDouble()));
    return GradientCard(
      colors: [AppColors.primary, AppColors.primaryLight],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.totalBalance, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(totalBalance),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final acc = accounts[i] as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(acc['name'] as String, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.compactCurrency((acc['current_balance'] as num).toDouble()),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction Card ───────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final S s;
  final List<dynamic> cats;
  final VoidCallback onDelete;
  const _TransactionCard({required this.tx, required this.s, required this.cats, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx['transaction_type'] == 'income';
    final amount = (tx['amount'] as num).toDouble();
    final color = isIncome ? AppColors.success : AppColors.error;
    final catId = tx['category_id'] as String?;
    final catData = catId != null
        ? cats.firstWhere((c) => c['id'] == catId, orElse: () => null)
        : null;

    Color catColor = color;
    if (catData != null) {
      try {
        final hex = (catData['color'] as String).replaceFirst('#', '');
        catColor = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: catColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description'] ?? (isIncome ? s.income : s.expense),
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (catData != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          catData['name'] as String,
                          style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      tx['date'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${Formatters.currency(amount)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  final VoidCallback onAdd;
  final S s;
  const _EmptyTransactions({required this.onAdd, required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(s.noTransactions, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(s.noTransactionsDesc, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Add Transaction Sheet ──────────────────────────────────────────────────────

class _AddTransactionSheet extends ConsumerStatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  final List<dynamic> categories;
  const _AddTransactionSheet({required this.onSave, required this.categories});

  @override
  ConsumerState<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'expense';
  String? _categoryId;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(S s) async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'amount': amount,
        'transaction_type': _type,
        'description': _descCtrl.text.isEmpty ? null : _descCtrl.text,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'category_id': _categoryId,
      });
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
    final filteredCats = widget.categories.where((c) => c['category_type'] == _type).toList();

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
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(s.addTransaction, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            // Type selector
            Row(
              children: ['expense', 'income'].map((t) {
                final selected = _type == t;
                final color = t == 'income' ? AppColors.success : AppColors.error;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: t == 'expense' ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() { _type = t; _categoryId = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: 0.12) : null,
                          border: Border.all(color: selected ? color : AppColors.textHint.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            t == 'income' ? '+ ${s.income}' : '- ${s.expense}',
                            style: TextStyle(fontWeight: FontWeight.w600, color: selected ? color : null),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(hintText: '0.00', prefixText: '\$ ', border: InputBorder.none, filled: false),
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Description
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                hintText: s.descriptionOptional,
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: InputBorder.none,
                filled: false,
              ),
            ),
            const SizedBox(height: 8),
            // Categories
            if (filteredCats.isNotEmpty) ...[
              Text(s.category, style: theme.textTheme.titleMedium?.copyWith(fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: filteredCats.map((c) {
                  final isSelected = _categoryId == c['id'];
                  Color catColor;
                  try {
                    final hex = (c['color'] as String).replaceFirst('#', '');
                    catColor = Color(int.parse('FF$hex', radix: 16));
                  } catch (_) {
                    catColor = AppColors.primary;
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = isSelected ? null : c['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? catColor.withValues(alpha: 0.15) : null,
                        border: Border.all(color: isSelected ? catColor : AppColors.textHint.withValues(alpha: 0.25)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? catColor : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () => _save(s),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(s.saveTransaction),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Categories Sheet ───────────────────────────────────────────────────────────

class _CategoriesSheet extends ConsumerStatefulWidget {
  const _CategoriesSheet();

  @override
  ConsumerState<_CategoriesSheet> createState() => _CategoriesSheetState();
}

class _CategoriesSheetState extends ConsumerState<_CategoriesSheet> {
  final _nameCtrl = TextEditingController();
  String _type = 'expense';
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final catAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(s.addCategory, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              // Create new category
              Row(
                children: ['expense', 'income'].map((t) {
                  final sel = _type == t;
                  final color = t == 'income' ? AppColors.success : AppColors.error;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: t == 'expense' ? 6 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? color.withValues(alpha: 0.12) : null,
                            border: Border.all(color: sel ? color : AppColors.textHint.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text(
                            t == 'income' ? s.income : s.expense,
                            style: TextStyle(color: sel ? color : null, fontWeight: sel ? FontWeight.w600 : null, fontSize: 13),
                          )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(hintText: s.categoryName),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _creating ? null : () async {
                      if (_nameCtrl.text.trim().isEmpty) return;
                      setState(() => _creating = true);
                      try {
                        final dio = ref.read(dioProvider);
                        await dio.post('/finances/categories', data: {
                          'name': _nameCtrl.text.trim(),
                          'category_type': _type,
                          'color': _type == 'income' ? '#00B894' : '#FF6B6B',
                          'icon': 'category',
                        });
                        _nameCtrl.clear();
                        ref.invalidate(categoriesProvider);
                      } finally {
                        if (mounted) setState(() => _creating = false);
                      }
                    },
                    child: _creating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(s.add),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(s.expenseCategories, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              catAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) {
                  final expenses = cats.where((c) => c['category_type'] == 'expense').toList();
                  final incomes = cats.where((c) => c['category_type'] == 'income').toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: expenses.map((c) => _CatChip(cat: c as Map<String, dynamic>, onDelete: () async {
                          final dio = ref.read(dioProvider);
                          await dio.delete('/finances/categories/${c['id']}');
                          ref.invalidate(categoriesProvider);
                        })).toList(),
                      ),
                      const SizedBox(height: 14),
                      Text(s.incomeCategories, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: incomes.map((c) => _CatChip(cat: c as Map<String, dynamic>, onDelete: () async {
                          final dio = ref.read(dioProvider);
                          await dio.delete('/finances/categories/${c['id']}');
                          ref.invalidate(categoriesProvider);
                        })).toList(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final Map<String, dynamic> cat;
  final VoidCallback onDelete;
  const _CatChip({required this.cat, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color color;
    try {
      final hex = (cat['color'] as String).replaceFirst('#', '');
      color = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      color = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(cat['name'] as String, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, size: 14, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
