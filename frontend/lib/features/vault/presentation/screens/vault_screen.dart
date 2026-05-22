import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pulse_logo.dart';
import '../providers/vault_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY — PIN GATE
// ─────────────────────────────────────────────────────────────────────────────

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});
  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  bool _unlocked = false;
  @override
  Widget build(BuildContext context) {
    return _unlocked
        ? const _VaultHomeScreen()
        : _VaultLockScreen(onUnlocked: () => setState(() => _unlocked = true));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCK SCREEN — Custom PIN pad
// ─────────────────────────────────────────────────────────────────────────────

class _VaultLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _VaultLockScreen({required this.onUnlocked});
  @override
  State<_VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<_VaultLockScreen>
    with SingleTickerProviderStateMixin {
  static const _masterPin = '2026';
  final List<String> _digits = [];
  bool _isError = false;
  bool _isSuccess = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_isError || _isSuccess || _digits.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() => _digits.add(d));
    if (_digits.length == 4) _verify();
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits.removeLast());
  }

  void _verify() {
    final entered = _digits.join();
    if (entered == _masterPin) {
      HapticFeedback.heavyImpact();
      setState(() => _isSuccess = true);
      Future.delayed(const Duration(milliseconds: 400), widget.onUnlocked);
    } else {
      HapticFeedback.vibrate();
      setState(() => _isError = true);
      _shakeCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() { _digits.clear(); _isError = false; });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final btnH = (screenH * 0.085).clamp(52.0, 72.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0820), Color(0xFF1A0F35), Color(0xFF0D1F30)],
            stops: [0, 0.6, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Header — flexible top section
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PulseOfLifeLogo(size: 56, showText: false)
                        .animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.7, 0.7)),
                    const SizedBox(height: 14),
                    const Text(
                      'Life Vault',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 4),
                    const Text(
                      'Ingresa tu PIN para acceder',
                      style: TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 0.3),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
              // PIN dots
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _digits.length;
                    return Container(
                      width: 16, height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isError
                            ? AppColors.error
                            : _isSuccess
                                ? AppColors.secondary
                                : filled
                                    ? const Color(0xFF6B4EFF)
                                    : Colors.white12,
                        border: Border.all(
                          color: _isError
                              ? AppColors.error
                              : filled ? const Color(0xFF6B4EFF) : Colors.white24,
                          width: 1.5,
                        ),
                        boxShadow: filled
                            ? [BoxShadow(
                                color: (_isSuccess ? AppColors.secondary : const Color(0xFF6B4EFF)).withValues(alpha: 0.6),
                                blurRadius: 8,
                              )]
                            : null,
                      ),
                    ).animate(target: filled ? 1 : 0).scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 150.ms);
                  }),
                ),
              ),
              const SizedBox(height: 20),
              // Custom numpad — flexible bottom section
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _PadRow(digits: const ['1', '2', '3'], onDigit: _onDigit, btnH: btnH),
                      const SizedBox(height: 10),
                      _PadRow(digits: const ['4', '5', '6'], onDigit: _onDigit, btnH: btnH),
                      const SizedBox(height: 10),
                      _PadRow(digits: const ['7', '8', '9'], onDigit: _onDigit, btnH: btnH),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Expanded(child: SizedBox()),
                        Expanded(child: _PadButton(label: '0', onTap: () => _onDigit('0'), btnH: btnH)),
                        Expanded(
                          child: _PadIconButton(
                            icon: Icons.backspace_outlined,
                            onTap: _onBackspace,
                            btnH: btnH,
                          ),
                        ),
                      ]),
                    ],
                  ),
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

class _PadRow extends StatelessWidget {
  final List<String> digits;
  final void Function(String) onDigit;
  final double btnH;
  const _PadRow({required this.digits, required this.onDigit, required this.btnH});
  @override
  Widget build(BuildContext context) => Row(
    children: digits.map((d) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: _PadButton(label: d, onTap: () => onDigit(d), btnH: btnH),
      ),
    )).toList(),
  );
}

class _PadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double btnH;
  const _PadButton({required this.label, required this.onTap, required this.btnH});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: btnH,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

class _PadIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double btnH;
  const _PadIconButton({required this.icon, required this.onTap, required this.btnH});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: btnH,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white54, size: 24),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN — Profile list
// ─────────────────────────────────────────────────────────────────────────────

class _VaultHomeScreen extends ConsumerWidget {
  const _VaultHomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(vaultProfilesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(children: [
              const PulseOfLifeLogo(size: 28, showText: false),
              const SizedBox(width: 10),
              const Text('Life Vault',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ]),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => _showCreateProfile(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Private Memories',
                  style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your loved ones',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
              ]),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
          ),
          profilesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF))),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
            ),
            data: (profiles) {
              if (profiles.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyVaultState(onAdd: () => _showCreateProfile(context, ref)),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ProfileCard(profile: profiles[i])
                        .animate(delay: Duration(milliseconds: 80 * i))
                        .fadeIn().slideY(begin: 0.15, end: 0),
                    childCount: profiles.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateProfile(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateProfileSheet(ref: ref),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyVaultState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyVaultState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6B4EFF).withValues(alpha: 0.15), const Color(0xFF00D4AA).withValues(alpha: 0.1)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12, width: 1.5),
            ),
            child: const Center(child: Text('👶', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 24),
          const Text('No profiles yet',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const Text(
            'Create a profile to start preserving\nprecious moments for those you love.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: const Text('Create first profile', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ]).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────────

const List<List<Color>> _profileGradients = [
  [Color(0xFF6B4EFF), Color(0xFFFF6B9D)],
  [Color(0xFF00D4AA), Color(0xFF0984E3)],
  [Color(0xFFFF9500), Color(0xFFFF6B6B)],
  [Color(0xFF8E44AD), Color(0xFF6B4EFF)],
  [Color(0xFF00B894), Color(0xFF00CEC9)],
  [Color(0xFFE17055), Color(0xFFD63031)],
];

class _ProfileCard extends ConsumerWidget {
  final VaultProfile profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? ageLabel;
    int? totalDays;
    if (profile.birthDate != null) {
      final bd = DateTime.tryParse(profile.birthDate!);
      if (bd != null) {
        final now = DateTime.now();
        totalDays = now.difference(bd).inDays;
        final y = now.year - bd.year - ((now.month < bd.month || (now.month == bd.month && now.day < bd.day)) ? 1 : 0);
        final m = ((totalDays % 365) / 30).floor();
        ageLabel = y > 0 ? '$y yrs $m mos' : '$m months old';
      }
    }

    // Pick gradient based on name hash
    final gradIdx = profile.name.codeUnits.fold(0, (a, b) => a + b) % _profileGradients.length;
    final grad = _profileGradients[gradIdx];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProfile(context, ref),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(children: [
              // Avatar
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: grad.first.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Center(child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 30))),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                if (profile.relationshipLabel != null) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: grad.first.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(profile.relationshipLabel!,
                        style: TextStyle(color: grad.first, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ],
                if (ageLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(ageLabel, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ])),
              // Arrow + days badge
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (totalDays != null) ...[
                  Text('$totalDays', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const Text('days', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context, WidgetRef ref) {
    final container = ProviderScope.containerOf(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: _ProfileDetailScreen(profile: profile),
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE DETAIL — Timeline
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileDetailScreen extends ConsumerWidget {
  final VaultProfile profile;
  const _ProfileDetailScreen({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(vaultTimelineProvider(profile.id));
    final gradIdx = profile.name.codeUnits.fold(0, (a, b) => a + b) % _profileGradients.length;
    final grad = _profileGradients[gradIdx];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0820),
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => _showAddRecord(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Memory', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: grad.first,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHero(profile: profile, gradient: grad),
            ),
          ),
          // Timeline
          timelineAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(40), child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6B4EFF)))),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('$e', style: const TextStyle(color: Colors.red)))),
            data: (data) {
              final grouped = data['timeline'] as Map<String, dynamic>;
              final total = data['total_records'] as int? ?? 0;
              if (total == 0) {
                return SliverFillRemaining(child: _EmptyTimeline(onAdd: () => _showAddRecord(context, ref)));
              }
              final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _YearSection(
                    year: years[i],
                    records: (grouped[years[i]] as List).map((e) => e as Map<String, dynamic>).toList(),
                    profileId: profile.id,
                    accentColor: grad.first,
                  ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn().slideX(begin: -0.05, end: 0),
                  childCount: years.length,
                )),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddRecord(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecordSheet(profileId: profile.id, ref: ref),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final VaultProfile profile;
  final List<Color> gradient;
  const _ProfileHero({required this.profile, required this.gradient});

  @override
  Widget build(BuildContext context) {
    String? ageStr;
    String? birthdayStr;
    if (profile.birthDate != null) {
      final bd = DateTime.tryParse(profile.birthDate!);
      if (bd != null) {
        birthdayStr = DateFormat('MMMM d, yyyy', 'es').format(bd);
        final now = DateTime.now();
        final y = now.year - bd.year - ((now.month < bd.month || (now.month == bd.month && now.day < bd.day)) ? 1 : 0);
        final m = ((now.difference(bd).inDays % 365) / 30).floor();
        final d = now.difference(bd).inDays % 30;
        ageStr = y > 0 ? '$y años, $m meses y $d días' : '$m meses y $d días';
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient.first.withValues(alpha: 0.6), const Color(0xFF0D0820)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            // Large avatar
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: gradient.first.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Center(child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 38))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              if (profile.relationshipLabel != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: gradient.first.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: gradient.first.withValues(alpha: 0.3)),
                  ),
                  child: Text(profile.relationshipLabel!,
                    style: TextStyle(color: gradient.first, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ),
              Text(profile.name,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              if (ageStr != null)
                Text(ageStr, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              if (birthdayStr != null)
                Row(children: [
                  const Icon(Icons.cake_rounded, color: Colors.white30, size: 12),
                  const SizedBox(width: 4),
                  Text(birthdayStr, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTimeline({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📝', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        const Text('No memories yet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Start adding precious moments\nto build a beautiful life story.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add first memory'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B4EFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]).animate().fadeIn(delay: 200.ms),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// YEAR SECTION + RECORD TILES
// ─────────────────────────────────────────────────────────────────────────────

class _YearSection extends ConsumerWidget {
  final String year;
  final List<Map<String, dynamic>> records;
  final String profileId;
  final Color accentColor;
  const _YearSection({required this.year, required this.records, required this.profileId, required this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(year, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Text('${records.length} moment${records.length != 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white30, fontSize: 12)),
        ]),
      ),
      // Timeline with vertical connector
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Left timeline line
          Column(children: [
            Container(width: 2, height: 12, color: accentColor.withValues(alpha: 0.3)),
            Expanded(child: Container(width: 2, color: accentColor.withValues(alpha: 0.15))),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Column(
            children: records.asMap().entries.map((e) =>
              _RecordTile(record: e.value, profileId: profileId, accentColor: accentColor)
                  .animate(delay: Duration(milliseconds: 40 * e.key)).fadeIn().slideX(begin: 0.05, end: 0),
            ).toList(),
          )),
        ]),
      ),
    ]);
  }
}

const Map<String, Map<String, dynamic>> _eventMeta = {
  'milestone': {'icon': Icons.star_rounded, 'label': 'Milestone', 'color': Color(0xFFFFD700)},
  'health':    {'icon': Icons.medical_services_rounded, 'label': 'Health', 'color': Color(0xFF00D4AA)},
  'measure':   {'icon': Icons.straighten_rounded, 'label': 'Measure', 'color': Color(0xFF0984E3)},
  'memory':    {'icon': Icons.favorite_rounded, 'label': 'Memory', 'color': Color(0xFFFF6B9D)},
  'school':    {'icon': Icons.school_rounded, 'label': 'School', 'color': Color(0xFFFF9500)},
  'first_time':{'icon': Icons.auto_awesome_rounded, 'label': 'First time', 'color': Color(0xFF8B5CF6)},
  'trip':      {'icon': Icons.flight_takeoff_rounded, 'label': 'Trip', 'color': Color(0xFF4ECDC4)},
  'achievement':{'icon': Icons.emoji_events_rounded, 'label': 'Achievement', 'color': Color(0xFFFFD700)},
  'other':     {'icon': Icons.push_pin_rounded, 'label': 'Other', 'color': Color(0xFF6B6580)},
};

class _RecordTile extends ConsumerWidget {
  final Map<String, dynamic> record;
  final String profileId;
  final Color accentColor;
  const _RecordTile({required this.record, required this.profileId, required this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventType = record['event_type'] as String? ?? 'other';
    final meta = _eventMeta[eventType] ?? _eventMeta['other']!;
    final color = meta['color'] as Color;
    final icon = meta['icon'] as IconData;
    final title = record['title'] as String? ?? '';
    final notes = record['notes'] as String?;
    final emoji = record['emoji'] as String?;

    final date = DateTime.tryParse(record['event_date'] as String? ?? '');
    final dateStr = date != null ? DateFormat('MMM d', 'es').format(date) : '';

    final ageYears = record['age_years'] as int?;
    final ageMonths = record['age_months'] as int?;
    String? ageStr;
    if (ageYears != null) {
      ageStr = ageYears > 0 ? '${ageYears}a ${ageMonths ?? 0}m' : '${ageMonths ?? 0} meses';
    }
    final weightKg = record['weight_kg'];
    final heightCm = record['height_cm'];

    return Dismissible(
      key: Key(record['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.delete_rounded, color: AppColors.error, size: 22),
          const SizedBox(height: 2),
          const Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 10)),
        ]),
      ),
      onDismissed: (_) => ref.read(vaultActionsProvider).deleteRecord(
        profileId: profileId, recordId: record['id'] as String, ref: ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icon badge
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: emoji != null && emoji.isNotEmpty
                  ? Text(emoji, style: const TextStyle(fontSize: 20))
                  : Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
              Text(dateStr, style: const TextStyle(color: Colors.white30, fontSize: 11)),
            ]),
            const SizedBox(height: 4),
            // Type badge + age
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(meta['label'] as String,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              if (ageStr != null) ...[
                const SizedBox(width: 6),
                Text(ageStr, style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ]),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4)),
            ],
            if (weightKg != null || heightCm != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                if (weightKg != null) ...[
                  const Icon(Icons.monitor_weight_outlined, size: 12, color: Colors.white38),
                  const SizedBox(width: 3),
                  Text('${weightKg}kg', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(width: 10),
                ],
                if (heightCm != null) ...[
                  const Icon(Icons.height_rounded, size: 12, color: Colors.white38),
                  const SizedBox(width: 3),
                  Text('${heightCm}cm', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ]),
            ],
          ])),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE PROFILE SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CreateProfileSheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateProfileSheet({required this.ref});
  @override
  State<_CreateProfileSheet> createState() => _CreateProfileSheetState();
}

class _CreateProfileSheetState extends State<_CreateProfileSheet> {
  final _nameCtrl = TextEditingController();
  final _relCtrl  = TextEditingController();
  final _pinCtrl  = TextEditingController();
  String _emoji = '👶';
  DateTime? _birthDate;
  bool _saving = false;

  static const _emojis = [
    '👶','🧒','👦','👧','🧑','👱','👨','👩','🧓','👴','👵',
    '❤️','🌟','🌈','🐣','🐥','🌺','🌸','🦋','🎀',
  ];

  static const _relationships = ['Hijo/a', 'Sobrino/a', 'Nieto/a', 'Hermano/a', 'Amigo/a', 'Otro'];

  @override
  void dispose() { _nameCtrl.dispose(); _relCtrl.dispose(); _pinCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.ref.read(vaultActionsProvider).createProfile(
        name: _nameCtrl.text.trim(),
        avatarEmoji: _emoji,
        relationshipLabel: _relCtrl.text.trim().isEmpty ? null : _relCtrl.text.trim(),
        birthDate: _birthDate,
        pin: _pinCtrl.text.trim().isEmpty ? null : _pinCtrl.text.trim(),
        ref: widget.ref,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1030),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('New Profile',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Create a space for someone special',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 24),
          // Emoji picker
          const Text('Choose avatar', style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _emojis.map((e) {
              final selected = _emoji == e;
              return GestureDetector(
                onTap: () => setState(() => _emoji = e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF6B4EFF).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? const Color(0xFF6B4EFF) : Colors.transparent, width: 2),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _DarkField(controller: _nameCtrl, label: 'Name *', hint: 'e.g. Matías', icon: Icons.person_rounded),
          const SizedBox(height: 12),
          // Relationship chips
          const Text('Relationship', style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: _relationships.map((r) {
              final sel = _relCtrl.text == r;
              return ChoiceChip(
                label: Text(r, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.white60)),
                selected: sel,
                onSelected: (_) => setState(() => _relCtrl.text = sel ? '' : r),
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                selectedColor: const Color(0xFF6B4EFF).withValues(alpha: 0.4),
                side: BorderSide(color: sel ? const Color(0xFF6B4EFF) : Colors.white12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Birth date
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365)),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _birthDate = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(children: [
                const Icon(Icons.cake_rounded, color: Colors.white38, size: 18),
                const SizedBox(width: 12),
                Text(
                  _birthDate != null ? DateFormat('MMMM d, yyyy').format(_birthDate!) : 'Birth date (optional)',
                  style: TextStyle(color: _birthDate != null ? Colors.white : Colors.white30, fontSize: 14),
                ),
                const Spacer(),
                if (_birthDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _birthDate = null),
                    child: const Icon(Icons.close_rounded, color: Colors.white30, size: 16),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _DarkField(
            controller: _pinCtrl,
            label: 'PIN (optional)',
            hint: 'Profile-specific PIN',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD RECORD SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddRecordSheet extends StatefulWidget {
  final String profileId;
  final WidgetRef ref;
  const _AddRecordSheet({required this.profileId, required this.ref});
  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  String _eventType = 'milestone';
  final _titleCtrl  = TextEditingController();
  final _notesCtrl  = TextEditingController();
  final _emojiCtrl  = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose(); _notesCtrl.dispose(); _emojiCtrl.dispose();
    _weightCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.ref.read(vaultActionsProvider).createRecord(
        profileId: widget.profileId,
        eventDate: _date,
        eventType: _eventType,
        title: _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        emoji: _emojiCtrl.text.trim().isEmpty ? null : _emojiCtrl.text.trim(),
        weightKg: double.tryParse(_weightCtrl.text),
        heightCm: double.tryParse(_heightCtrl.text),
        ref: widget.ref,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _eventMeta[_eventType]!;
    final color = meta['color'] as Color;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1030),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(meta['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('New Memory', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              Text('Add a precious moment', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 22),
          // Event type grid
          const Text('Type', style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _eventMeta.entries.map((e) {
              final sel = _eventType == e.key;
              final c = e.value['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _eventType = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? c.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? c : Colors.white10, width: sel ? 1.5 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(e.value['icon'] as IconData, color: sel ? c : Colors.white38, size: 14),
                    const SizedBox(width: 5),
                    Text(e.value['label'] as String,
                      style: TextStyle(color: sel ? c : Colors.white38, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Date picker
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 16),
                const SizedBox(width: 10),
                Text(DateFormat('MMMM d, yyyy').format(_date),
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const Spacer(),
                const Icon(Icons.edit_calendar_rounded, color: Colors.white30, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _DarkField(controller: _titleCtrl, label: 'Title *', hint: 'e.g. First steps!', icon: Icons.title_rounded),
          const SizedBox(height: 12),
          _DarkField(controller: _emojiCtrl, label: 'Emoji (optional)', hint: '🎉', icon: Icons.emoji_emotions_outlined),
          const SizedBox(height: 12),
          _DarkField(controller: _notesCtrl, label: 'Notes (optional)', hint: 'Describe this moment...', icon: Icons.notes_rounded, maxLines: 3),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _DarkField(controller: _weightCtrl, label: 'Weight (kg)', hint: '8.5', icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: _DarkField(controller: _heightCtrl, label: 'Height (cm)', hint: '72', icon: Icons.height_rounded, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Memory', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final int maxLines;

  const _DarkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );
}
