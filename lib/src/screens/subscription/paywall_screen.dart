import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';
import '../../routing/app_router.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    // Lade Subscription-Daten
    Future.microtask(() {
      ref.read(subscriptionProvider.notifier).loadSubscription();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final trialDays = subState.trialDaysRemaining;
    final isExpired = subState.isExpired;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(trialDays, isExpired),
            ),

            // Features
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildFeatures(),
              ),
            ),

            // CTA Button
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildCTAButton(subState),
              ),
            ),

            // Trial Info
            if (!isExpired && trialDays > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: _buildTrialInfo(trialDays),
                ),
              ),

            // Footer
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int trialDays, bool isExpired) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          // Crown Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppColors.onPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isExpired ? 'Your trial has ended' : 'ShredMembers Pro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isExpired
                ? 'Unlock all features and reach your fitness goals'
                : 'Use all premium features and take your training to the next level',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
            textAlign: TextAlign.center,
          ),
          if (!isExpired && trialDays > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$trialDays day${trialDays == 1 ? '' : 's'} remaining',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      ('Unlimited workout plans', Icons.fitness_center),
      ('Detailed progress analytics', Icons.show_chart),
      ('Personal records tracking', Icons.emoji_events),
      ('All exercises unlocked', Icons.sports_gymnastics),
      ('Ad-free experience', Icons.block),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Included features',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...features.map((feature) => _FeatureItem(
                icon: feature.$2,
                text: feature.$1,
              )),
        ],
      ),
    );
  }

  Widget _buildCTAButton(SubscriptionState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => context.go(AppRoutes.home),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Continue to app',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }

  Widget _buildTrialInfo(int trialDays) {
    return AppCard(
      backgroundColor: AppColors.surfaceVariant,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'You have $trialDays day${trialDays == 1 ? '' : 's'} left to try all features for free.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final subState = ref.watch(subscriptionProvider);
    final trialDays = subState.trialDaysRemaining;
    final isExpired = subState.isExpired;

    return Column(
      children: [
        if (!isExpired && trialDays > 0)
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.home),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onBackground,
              side: const BorderSide(color: AppColors.onSurfaceMuted),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Continue – $trialDays day${trialDays == 1 ? '' : 's'} free remaining',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          )
        else
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text(
              'Maybe later',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
          ),
      ],
    );
  }

}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
