import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';

final rewardsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/rewards');
  return response.data as List;
});

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(rewardsProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(s.rewards),
              floating: true,
              actions: [
                IconButton(
                  onPressed: () => _showCreateRewardSheet(context, ref, s),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppCard(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF9500)],
                    ),
                    child: Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 48)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.rewardSystem, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(
                                s.rewardSystemDesc,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 20),
                  rewardsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (rewards) {
                      final unlocked = rewards.where((r) => (r as Map)['is_unlocked'] == true && (r)['is_claimed'] == false).toList();
                      final locked = rewards.where((r) => (r as Map)['is_unlocked'] == false).toList();
                      final claimed = rewards.where((r) => (r as Map)['is_claimed'] == true).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (unlocked.isNotEmpty) ...[
                            Text(s.readyToClaim, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.accentGold)),
                            const SizedBox(height: 12),
                            ...unlocked.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _RewardCard(
                                    reward: e.value as Map<String, dynamic>,
                                    s: s,
                                    onClaim: () async {
                                      final dio = ref.read(dioProvider);
                                      final id = (e.value as Map)['id'];
                                      await dio.post('/rewards/$id/claim');
                                      ref.invalidate(rewardsProvider);
                                    },
                                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)),
                                )),
                            const SizedBox(height: 16),
                          ],
                          if (locked.isNotEmpty) ...[
                            Text(s.upcomingRewards, style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 12),
                            ...locked.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _RewardCard(
                                    reward: e.value as Map<String, dynamic>,
                                    s: s,
                                    onUnlock: () async {
                                      final dio = ref.read(dioProvider);
                                      final id = (e.value as Map)['id'];
                                      await dio.post('/rewards/$id/unlock');
                                      ref.invalidate(rewardsProvider);
                                    },
                                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * e.key)),
                                )),
                            const SizedBox(height: 16),
                          ],
                          if (claimed.isNotEmpty) ...[
                            Text(s.claimedRewards, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ...claimed.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _RewardCard(reward: r as Map<String, dynamic>, s: s),
                                )),
                          ],
                          if (rewards.isEmpty) _EmptyRewards(s: s, onAdd: () => _showCreateRewardSheet(context, ref, s)),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRewardSheet(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final nameCtrl = TextEditingController();
        final descCtrl = TextEditingController();
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
                Text(s.createReward, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(s.createRewardDesc, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Cinema 🎬', 'Hamburger 🍔', 'New book 📚', 'Day off 🌴',
                    'New game 🎮', 'Nice dinner 🍽️', 'Mini trip ✈️',
                  ].map((p) => ActionChip(label: Text(p), onPressed: () => nameCtrl.text = p)).toList(),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: InputDecoration(hintText: s.rewardName)),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: InputDecoration(hintText: s.createRewardDesc)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) return;
                      final dio = ref.read(dioProvider);
                      await dio.post('/rewards', data: {
                        'name': nameCtrl.text,
                        'description': descCtrl.text.isEmpty ? null : descCtrl.text,
                        'condition_type': 'manual',
                      });
                      ref.invalidate(rewardsProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(s.createReward),
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

class _RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;
  final S s;
  final VoidCallback? onClaim;
  final VoidCallback? onUnlock;

  const _RewardCard({required this.reward, required this.s, this.onClaim, this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = reward['is_unlocked'] as bool;
    final isClaimed = reward['is_claimed'] as bool;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isUnlocked && !isClaimed) ? AppColors.accentGold.withValues(alpha: 0.15) : AppColors.textHint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                isClaimed ? '✅' : isUnlocked ? '🎁' : '🔒',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward['name'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isClaimed ? AppColors.textSecondary : null,
                    decoration: isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (reward['description'] != null)
                  Text(reward['description'] as String, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (onClaim != null)
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(s.claim, style: const TextStyle(fontSize: 13)),
            ),
          if (onUnlock != null)
            OutlinedButton(
              onPressed: onUnlock,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(s.unlock, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _EmptyRewards extends StatelessWidget {
  final VoidCallback onAdd;
  final S s;
  const _EmptyRewards({required this.onAdd, required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(s.noRewards, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(s.noRewardsDesc, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: Text(s.createFirstReward)),
          ],
        ),
      ),
    );
  }
}
