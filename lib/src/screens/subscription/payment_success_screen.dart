import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/subscription_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final String? sessionId;

  const PaymentSuccessScreen({super.key, this.sessionId});

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('[SUCCESS] sessionId: ${widget.sessionId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSubscription();
    });
  }

  Future<void> _refreshSubscription() async {
    debugPrint('[SUCCESS] _refreshSubscription called');
    try {
      if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        debugPrint('[SUCCESS] calling confirmPayment for ${widget.sessionId}');
        final result = await ref
            .read(subscriptionProvider.notifier)
            .confirmPayment(widget.sessionId!);

        debugPrint('[SUCCESS] confirmPayment result: $result');

        if (result != null && result['error'] != null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = 'Could not confirm payment: ${result['error']}';
            });
          }
          return;
        }
      } else {
        debugPrint('[SUCCESS] no sessionId, skipping confirmPayment');
      }

      debugPrint('[SUCCESS] reloading subscription');
      await ref.read(subscriptionProvider.notifier).loadSubscription();
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not update subscription: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 80,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Payment successful!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Thank you for your subscription. Your premium access is now active.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                textAlign: TextAlign.center,
              ),
              if (widget.sessionId != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Session ID: ${widget.sessionId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
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
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
}
