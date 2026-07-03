import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../routing/app_router.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHeader(user: user),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.settings,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(
                      title: l10n.goals,
                      children: [
                        _GoalSelector(user: user, ref: ref),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(
                      title: l10n.personalDetails,
                      children: [
                        _PersonalDetailsSelector(user: user, ref: ref),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(
                      title: l10n.training,
                      children: [
                        _WeeklyTargetSelector(user: user, ref: ref),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(
                      title: l10n.subscription,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final subState = ref.watch(subscriptionProvider);
                            final isTrial = subState.isInTrial;
                            final isActive = subState.isActiveSubscription;
                            final daysLeft = subState.trialDaysRemaining;

                            return _SettingsTile(
                              icon: isActive
                                  ? Icons.workspace_premium
                                  : isTrial
                                      ? Icons.access_time
                                      : Icons.lock_outline,
                              label: isActive
                                  ? l10n.proSubscription
                                  : isTrial
                                      ? l10n.trialDaysLeft(daysLeft)
                                      : l10n.subscriptionRequired,
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppColors.onSurfaceMuted),
                              onTap: () =>
                                  context.push(AppRoutes.subscriptionManage),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(
                      title: l10n.account,
                      children: [
                        _NotificationToggle(),
                        _LanguageSelector(),
                        _SettingsTile(
                          icon: Icons.info_outline,
                          label: l10n.aboutApp,
                          onTap: () => _showAbout(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppCard(
                      onTap: () {
                        ref.read(authProvider.notifier).signOut();
                        context.go(AppRoutes.onboarding);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.signOut,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.error,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Text(
                        'shredMembers v1.0.0 · MVP',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'shredMembers',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 shredMembers',
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AppUser user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2C24), AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(user.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.fullRadius,
            ),
            child: Text(
              user.goal.label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children.indexed
                .map(
                  (e) => Column(
                    children: [
                      e.$2,
                      if (e.$1 < children.length - 1)
                        const Divider(height: 1, indent: 52),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _NotificationToggle extends StatefulWidget {
  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = LocalStorageService.getNotificationsEnabled();
  }

  Future<void> _toggle(bool value) async {
    await LocalStorageService.setNotificationsEnabled(value);
    if (value) {
      await NotificationService.requestPermission();
    } else {
      await NotificationService.cancelWorkoutReminder();
    }
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _enabled
            ? Icons.notifications_active_outlined
            : Icons.notifications_off_outlined,
        color: AppColors.onSurface,
        size: 22,
      ),
      title: Text(AppLocalizations.of(context)!.workoutReminders,
          style: Theme.of(context).textTheme.bodyMedium),
      trailing: Switch(
        value: _enabled,
        onChanged: _toggle,
        activeThumbColor: AppColors.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurface, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: trailing ??
          const Icon(Icons.chevron_right,
              color: AppColors.onSurfaceMuted, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _GoalSelector extends StatelessWidget {
  final AppUser user;
  final WidgetRef ref;

  const _GoalSelector({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  color: AppColors.onSurface, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(AppLocalizations.of(context)!.fitnessGoal,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FitnessGoal.values.map((goal) {
              final isSelected = user.goal == goal;
              return GestureDetector(
                onTap: () => ref
                    .read(authProvider.notifier)
                    .updateUser(user.copyWith(goal: goal)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceVariant,
                    borderRadius: AppRadius.fullRadius,
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    goal.label,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.primary : AppColors.onSurface,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PersonalDetailsSelector extends StatefulWidget {
  final AppUser user;
  final WidgetRef ref;

  const _PersonalDetailsSelector({required this.user, required this.ref});

  @override
  State<_PersonalDetailsSelector> createState() =>
      _PersonalDetailsSelectorState();
}

class _PersonalDetailsSelectorState extends State<_PersonalDetailsSelector> {
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late Gender _selectedGender;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _heightCtrl = TextEditingController(
      text: widget.user.heightCm?.toStringAsFixed(1) ?? '',
    );
    _weightCtrl = TextEditingController(
      text: widget.user.weightKg?.toStringAsFixed(1) ?? '',
    );
    _selectedGender = widget.user.gender ?? Gender.preferNotToSay;

    // Add listeners to track changes
    _heightCtrl.addListener(_checkChanges);
    _weightCtrl.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final height = double.tryParse(_heightCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);

    final hasHeightChanged = height != widget.user.heightCm;
    final hasWeightChanged = weight != widget.user.weightKg;
    final hasGenderChanged = _selectedGender != widget.user.gender;

    setState(() {
      _hasChanges = hasHeightChanged || hasWeightChanged || hasGenderChanged;
    });
  }

  void _save() async {
    final height = double.tryParse(_heightCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);

    try {
      await widget.ref.read(authProvider.notifier).updateUser(
            widget.user.copyWith(
              gender: _selectedGender,
              heightCm: height,
              weightKg: weight,
            ),
          );

      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.profileUpdated),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        AppLocalizations.of(context)!.profileUpdateFailed)),
              ],
            ),
            backgroundColor: const Color(0xFFD32F2F),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gender
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: AppColors.onSurface, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(AppLocalizations.of(context)!.gender,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Gender.values.map((gender) {
              final isSelected = _selectedGender == gender;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedGender = gender);
                  _checkChanges();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.surfaceVariant,
                    borderRadius: AppRadius.fullRadius,
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    gender.label,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.primary : AppColors.onSurface,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Height
          Row(
            children: [
              const Icon(Icons.height_outlined,
                  color: AppColors.onSurface, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(AppLocalizations.of(context)!.height,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.heightHint,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  onEditingComplete: () {
                    _save();
                    FocusScope.of(context).nextFocus();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Weight
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined,
                  color: AppColors.onSurface, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(AppLocalizations.of(context)!.weight,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.weightHint,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ],
          ),

          if (_hasChanges) ...[
            const SizedBox(height: AppSpacing.lg),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.saveDetails),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyTargetSelector extends StatelessWidget {
  final AppUser user;
  final WidgetRef ref;

  const _WeeklyTargetSelector({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.repeat_rounded,
              color: AppColors.onSurface, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(AppLocalizations.of(context)!.weeklyTarget,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(6, (i) {
              final day = i + 2;
              final isSelected = user.weeklyTargetDays == day;
              return GestureDetector(
                onTap: () => ref
                    .read(authProvider.notifier)
                    .updateUser(user.copyWith(weeklyTargetDays: day)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    final options = [
      (const Locale('en'), l10n.languageEnglish),
      (const Locale('de'), l10n.languageGerman),
      (const Locale('fr'), l10n.languageFrench),
      (const Locale('it'), l10n.languageItalian),
      (const Locale('es'), l10n.languageSpanish),
    ];

    return ListTile(
      leading: const Icon(Icons.language_outlined,
          color: AppColors.onSurface, size: 22),
      title: Text(l10n.language, style: Theme.of(context).textTheme.bodyMedium),
      trailing: DropdownButton<Locale>(
        value: locale,
        underline: const SizedBox(),
        dropdownColor: AppColors.surface,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
        iconEnabledColor: AppColors.primary,
        icon: const Icon(Icons.arrow_drop_down),
        onChanged: (value) {
          if (value != null) {
            ref.read(localeProvider.notifier).setLocale(value);
          }
        },
        items: options.map((option) {
          return DropdownMenuItem<Locale>(
            value: option.$1,
            child: Text(option.$2),
          );
        }).toList(),
      ),
    );
  }
}
