import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final s = S(locale);
    final user = HiveStorage.getUser();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(title: Text(s.settingsTitle), floating: true),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Profile card — long-press avatar 5× to open secret vault
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _SecretAvatarButton(
                        label: (user?['full_name'] ?? user?['email'] ?? 'U')[0].toUpperCase(),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?['full_name'] ?? 'User', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(user?['email'] ?? '', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Life Vault — prominent access at top
                GestureDetector(
                  onTap: () => context.push('/vault'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A0A2E), Color(0xFF2D1B69)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6B4EFF), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4EFF).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.lock_rounded, color: Color(0xFFB39DFF), size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Life Vault 🔐', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('Memorias privadas de tus seres queridos', style: TextStyle(color: Color(0xFFB39DFF), fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B4EFF)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _SectionTitle(s.language),
                const SizedBox(height: 8),
                AppCard(
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.language_rounded, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(child: Text(s.language)),
                      ChoiceChip(
                        label: Text(s.spanish),
                        selected: locale == 'es',
                        onSelected: (_) => ref.read(localeProvider.notifier).setLocale('es'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(s.english),
                        selected: locale == 'en',
                        onSelected: (_) => ref.read(localeProvider.notifier).setLocale('en'),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _SectionTitle(s.appearance),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.dark_mode_rounded,
                        title: s.darkMode,
                        trailing: Switch.adaptive(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _SectionTitle(s.security),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.pin_rounded,
                        title: s.pinProtection,
                        subtitle: s.pinDesc,
                        onTap: () => context.push('/pin'),
                      ),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.fingerprint_rounded,
                        title: s.biometric,
                        subtitle: s.biometricDesc,
                        trailing: Switch.adaptive(
                          value: HiveStorage.getBool('biometric_enabled'),
                          onChanged: (v) => HiveStorage.putBool('biometric_enabled', v),
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _SectionTitle(s.goals),
                const SizedBox(height: 8),
                _GoalsCard(s: s),
                const SizedBox(height: 16),

                _SectionTitle(locale == 'es' ? 'Notificaciones' : 'Notifications'),
                const SizedBox(height: 8),
                const _NotificationsCard(),
                const SizedBox(height: 16),

                _SectionTitle(locale == 'es' ? 'Mis Módulos' : 'My Modules'),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.bar_chart_rounded,
                        iconColor: AppColors.primary,
                        title: s.analytics,
                        subtitle: locale == 'es' ? 'Tendencias, hábitos e historial multi-año' : 'Finance trends, habits & multi-year history',
                        onTap: () => context.push('/analytics'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                      ),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.restaurant_menu_rounded,
                        iconColor: AppColors.secondary,
                        title: s.nutritionTab,
                        subtitle: locale == 'es' ? 'Control calórico semanal y registro de comidas' : 'Weekly caloric control & food log',
                        onTap: () => context.push('/nutrition'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                      ),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.book_rounded,
                        iconColor: AppColors.accentOrange,
                        title: s.diaryTitle,
                        subtitle: locale == 'es' ? 'Diario diario y seguimiento de momentos' : 'Daily journal & moment tracking',
                        onTap: () => context.push('/diary'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                      ),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.auto_stories_rounded,
                        iconColor: AppColors.info,
                        title: s.yourLibrary,
                        subtitle: locale == 'es' ? 'Cursos, libros y horas de estudio' : 'Courses, books & study hours',
                        onTap: () => context.push('/learning'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                      ),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.access_time_rounded,
                        iconColor: AppColors.accentGold,
                        title: s.timeTracking,
                        subtitle: locale == 'es' ? 'Horas productivas y sesiones de enfoque' : 'Productive hours & focus sessions',
                        onTap: () => context.push('/time'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                      ),
                      const Divider(height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.emoji_events_rounded,
                        iconColor: AppColors.accentGold,
                        title: s.rewards,
                        subtitle: locale == 'es' ? 'Logros y sistema de XP' : 'Achievements & XP system',
                        onTap: () => context.push('/rewards'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _SectionTitle(s.about),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.primary,
                        title: 'Pulse of Life',
                        subtitle: 'v1.0.0 — Track what matters. Live with purpose.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: Text(s.signOut, style: const TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notifications Card ────────────────────────────────────────────────────────

class _NotificationsCard extends ConsumerStatefulWidget {
  const _NotificationsCard();

  @override
  ConsumerState<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends ConsumerState<_NotificationsCard> {
  bool _waterEnabled = false;
  int _waterH = 8, _waterM = 0;
  bool _habitsEnabled = false;
  int _habitsH = 20, _habitsM = 0;
  bool _sleepEnabled = false;
  int _sleepH = 22, _sleepM = 30;

  @override
  void initState() {
    super.initState();
    _waterEnabled = NotificationPrefs.waterEnabled;
    _waterH = NotificationPrefs.waterHour;
    _waterM = NotificationPrefs.waterMinute;
    _habitsEnabled = NotificationPrefs.habitsEnabled;
    _habitsH = NotificationPrefs.habitsHour;
    _habitsM = NotificationPrefs.habitsMinute;
    _sleepEnabled = NotificationPrefs.sleepEnabled;
    _sleepH = NotificationPrefs.sleepHour;
    _sleepM = NotificationPrefs.sleepMinute;
  }

  String _fmt(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _pickTime(BuildContext context, int h, int m, Function(int, int) onPicked) async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: h, minute: m));
    if (t != null) onPicked(t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _NotifTile(
            icon: Icons.water_drop_rounded,
            color: AppColors.info,
            title: 'Recordatorio de agua',
            subtitle: _waterEnabled ? 'Todos los días a las ${_fmt(_waterH, _waterM)}' : 'Desactivado',
            enabled: _waterEnabled,
            onToggle: (v) async {
              if (v) await NotificationService.requestPermissions();
              await NotificationPrefs.setWater(v, _waterH, _waterM);
              setState(() => _waterEnabled = v);
            },
            onTimeTap: _waterEnabled ? () => _pickTime(context, _waterH, _waterM, (h, m) async {
              await NotificationPrefs.setWater(true, h, m);
              setState(() { _waterH = h; _waterM = m; });
            }) : null,
          ),
          const Divider(height: 1, indent: 56),
          _NotifTile(
            icon: Icons.track_changes_rounded,
            color: AppColors.secondary,
            title: 'Recordatorio de hábitos',
            subtitle: _habitsEnabled ? 'Todos los días a las ${_fmt(_habitsH, _habitsM)}' : 'Desactivado',
            enabled: _habitsEnabled,
            onToggle: (v) async {
              if (v) await NotificationService.requestPermissions();
              await NotificationPrefs.setHabits(v, _habitsH, _habitsM);
              setState(() => _habitsEnabled = v);
            },
            onTimeTap: _habitsEnabled ? () => _pickTime(context, _habitsH, _habitsM, (h, m) async {
              await NotificationPrefs.setHabits(true, h, m);
              setState(() { _habitsH = h; _habitsM = m; });
            }) : null,
          ),
          const Divider(height: 1, indent: 56),
          _NotifTile(
            icon: Icons.bedtime_rounded,
            color: AppColors.accentGold,
            title: 'Recordatorio de sueño',
            subtitle: _sleepEnabled ? 'Todos los días a las ${_fmt(_sleepH, _sleepM)}' : 'Desactivado',
            enabled: _sleepEnabled,
            onToggle: (v) async {
              if (v) await NotificationService.requestPermissions();
              await NotificationPrefs.setSleep(v, _sleepH, _sleepM);
              setState(() => _sleepEnabled = v);
            },
            onTimeTap: _sleepEnabled ? () => _pickTime(context, _sleepH, _sleepM, (h, m) async {
              await NotificationPrefs.setSleep(true, h, m);
              setState(() { _sleepH = h; _sleepM = m; });
            }) : null,
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTimeTap;

  const _NotifTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: GestureDetector(
        onTap: onTimeTap,
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: enabled ? color : AppColors.textSecondary,
            fontWeight: enabled ? FontWeight.w500 : null,
            decoration: enabled && onTimeTap != null ? TextDecoration.underline : null,
          ),
        ),
      ),
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: onToggle,
        activeColor: color,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ── Secret vault entry — tap avatar 5 times quickly ──────────────────────────

class _SecretAvatarButton extends StatefulWidget {
  final String label;
  const _SecretAvatarButton({required this.label});

  @override
  State<_SecretAvatarButton> createState() => _SecretAvatarButtonState();
}

class _SecretAvatarButtonState extends State<_SecretAvatarButton> {
  int _tapCount = 0;
  DateTime? _firstTap;

  void _onTap() {
    final now = DateTime.now();
    if (_firstTap == null || now.difference(_firstTap!) > const Duration(seconds: 3)) {
      _firstTap = now;
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    if (_tapCount >= 5) {
      _tapCount = 0;
      _firstTap = null;
      context.push('/vault');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
          ),
        ),
      ),
    );
  }
}

// ── Goals Card ────────────────────────────────────────────────────────────────

class _GoalsCard extends ConsumerStatefulWidget {
  final S s;
  const _GoalsCard({required this.s});

  @override
  ConsumerState<_GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends ConsumerState<_GoalsCard> {
  late int _waterMl;
  late double _sleepH;

  @override
  void initState() {
    super.initState();
    final user = HiveStorage.getUser();
    _waterMl = int.tryParse(user?['daily_water_goal_ml']?.toString() ?? '2000') ?? 2000;
    _sleepH = double.tryParse(user?['daily_sleep_goal_hours']?.toString() ?? '8') ?? 8.0;
  }

  Future<void> _saveGoals({int? waterMl, double? sleepH}) async {
    try {
      final dio = ref.read(dioProvider);
      final body = <String, String>{};
      if (waterMl != null) body['daily_water_goal_ml'] = waterMl.toString();
      if (sleepH != null) body['daily_sleep_goal_hours'] = sleepH.toString();
      await dio.put('/auth/me', data: body);
      // Update local cache
      final user = HiveStorage.getUser() ?? {};
      if (waterMl != null) user['daily_water_goal_ml'] = waterMl.toString();
      if (sleepH != null) user['daily_sleep_goal_hours'] = sleepH.toString();
      await HiveStorage.saveUser(user);
      if (waterMl != null) setState(() => _waterMl = waterMl);
      if (sleepH != null) setState(() => _sleepH = sleepH);
    } catch (_) {}
  }

  Future<void> _pickWater(BuildContext context) async {
    final options = [1000, 1500, 2000, 2500, 3000, 3500];
    int selected = _waterMl;
    final result = await showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(widget.s.dailyWaterGoal),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((ml) => ChoiceChip(
              label: Text('$ml ml'),
              selected: selected == ml,
              onSelected: (_) => ss(() => selected = ml),
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(widget.s.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: Text(widget.s.save)),
          ],
        ),
      ),
    );
    if (result != null) _saveGoals(waterMl: result);
  }

  Future<void> _pickSleep(BuildContext context) async {
    final options = [6.0, 7.0, 7.5, 8.0, 8.5, 9.0];
    double selected = _sleepH;
    final result = await showDialog<double>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text(widget.s.sleepGoal),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((h) => ChoiceChip(
              label: Text('${h}h'),
              selected: selected == h,
              onSelected: (_) => ss(() => selected = h),
            )).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(widget.s.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, selected), child: Text(widget.s.save)),
          ],
        ),
      ),
    );
    if (result != null) _saveGoals(sleepH: result);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.water_drop_rounded,
            title: widget.s.dailyWaterGoal,
            subtitle: '$_waterMl ml',
            onTap: () => _pickWater(context),
          ),
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.bedtime_rounded,
            title: widget.s.sleepGoal,
            subtitle: '${_sleepH}h ${widget.s.hours}',
            onTap: () => _pickSleep(context),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textHint) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
