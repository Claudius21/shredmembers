import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/subscription_repository.dart';
import 'supabase_providers.dart';

enum SubscriptionLoadingStatus { idle, loading, loaded, error }

class SubscriptionState {
  final Subscription? subscription;
  final TrialStatus? trialStatus;
  final List<SubscriptionPlan> plans;
  final SubscriptionLoadingStatus status;
  final String? errorMessage;
  final DiscountCode? appliedDiscount;

  const SubscriptionState({
    this.subscription,
    this.trialStatus,
    this.plans = const [],
    this.status = SubscriptionLoadingStatus.idle,
    this.errorMessage,
    this.appliedDiscount,
  });

  bool get hasAccess => trialStatus?.isActive ?? false;

  bool get isInTrial => trialStatus?.subscriptionStatus == 'trial' && !(trialStatus?.trialEnded ?? true);

  int get trialDaysRemaining => trialStatus?.daysRemaining ?? 0;

  bool get isExpired => trialStatus?.trialEnded ?? false;

  bool get isActiveSubscription => trialStatus?.subscriptionStatus == 'active';

  SubscriptionState copyWith({
    Subscription? subscription,
    TrialStatus? trialStatus,
    List<SubscriptionPlan>? plans,
    SubscriptionLoadingStatus? status,
    String? errorMessage,
    DiscountCode? appliedDiscount,
    bool clearDiscount = false,
  }) {
    return SubscriptionState(
      subscription: subscription ?? this.subscription,
      trialStatus: trialStatus ?? this.trialStatus,
      plans: plans ?? this.plans,
      status: status ?? this.status,
      errorMessage: errorMessage,
      appliedDiscount: clearDiscount ? null : (appliedDiscount ?? this.appliedDiscount),
    );
  }
}

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);
  StreamSubscription? _subscriptionStream;

  @override
  SubscriptionState build() {
    // Cleanup previous stream when rebuilding
    ref.onDispose(() {
      _subscriptionStream?.cancel();
    });
    
    return const SubscriptionState();
  }

  /// Lädt Subscription und Trial-Status
  Future<void> loadSubscription() async {
    state = state.copyWith(status: SubscriptionLoadingStatus.loading);

    try {
      final results = await Future.wait([
        _repo.getCurrentSubscription(),
        _repo.checkTrialStatus(),
        _repo.getSubscriptionPlans(),
      ]);

      final subscription = results[0] as Subscription?;
      final trialStatus = results[1] as TrialStatus;
      final plans = results[2] as List<SubscriptionPlan>;

      state = state.copyWith(
        subscription: subscription,
        trialStatus: trialStatus,
        plans: plans,
        status: SubscriptionLoadingStatus.loaded,
      );

      // Starte Realtime-Stream
      _listenToSubscriptionChanges();
    } catch (e) {
      state = state.copyWith(
        status: SubscriptionLoadingStatus.error,
        errorMessage: 'Failed to load subscription: $e',
      );
    }
  }

  /// Hört auf Änderungen der Subscription (z.B. nach Bezahlung)
  void _listenToSubscriptionChanges() {
    _subscriptionStream?.cancel();
    _subscriptionStream = _repo.watchSubscription().listen((subscription) async {
      if (subscription != null) {
        // Trial-Status neu laden bei Änderungen
        final trialStatus = await _repo.checkTrialStatus();
        state = state.copyWith(
          subscription: subscription,
          trialStatus: trialStatus,
        );
      }
    });
  }

  /// Prüft und aktualisiert den Trial-Status
  Future<void> refreshTrialStatus() async {
    try {
      final trialStatus = await _repo.checkTrialStatus();
      state = state.copyWith(trialStatus: trialStatus);
    } catch (e) {
      // Silent fail
    }
  }

  /// Validiert einen Discount Code
  Future<bool> applyDiscountCode(String code) async {
    if (code.isEmpty) {
      state = state.copyWith(clearDiscount: true);
      return false;
    }

    final discountCode = await _repo.validateDiscountCode(code);
    
    if (discountCode != null && discountCode.isValid) {
      state = state.copyWith(appliedDiscount: discountCode);
      return true;
    }
    
    return false;
  }

  /// Entfernt den Discount Code
  void clearDiscount() {
    state = state.copyWith(clearDiscount: true);
  }

  /// Berechnet den Preis mit Discount
  double getDiscountedPrice(double originalPrice) {
    if (state.appliedDiscount == null) return originalPrice;
    
    final discount = state.appliedDiscount!.discountPercent / 100;
    return originalPrice * (1 - discount);
  }

  /// Startet den Checkout-Prozess (Web)
  Future<Map<String, dynamic>?> startCheckout({
    required String priceType, // 'monthly' oder 'yearly'
    String? successUrl,
    String? cancelUrl,
  }) async {
    return await _repo.createCheckoutSession(
      priceType: priceType,
      discountCode: state.appliedDiscount?.code,
      successUrl: successUrl,
      cancelUrl: cancelUrl,
    );
  }

  /// Kündigt das Abonnement
  Future<bool> cancelSubscription() async {
    final success = await _repo.cancelSubscription();
    if (success) {
      await loadSubscription();
    }
    return success;
  }

  /// Reaktiviert das Abonnement
  Future<bool> reactivateSubscription() async {
    final success = await _repo.reactivateSubscription();
    if (success) {
      await loadSubscription();
    }
    return success;
  }

  /// Bestätigt eine Stripe Checkout-Zahlung direkt in der App
  Future<Map<String, dynamic>?> confirmPayment(String sessionId) async {
    return await _repo.confirmPayment(sessionId);
  }

  /// Prüft ob User Zugriff hat (für Paywall)
  Future<bool> checkAccess() async {
    await refreshTrialStatus();
    return state.hasAccess;
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);

// Provider für Zugriffsprüfung
final hasSubscriptionAccessProvider = Provider<bool>((ref) {
  final state = ref.watch(subscriptionProvider);
  return state.hasAccess;
});

// Provider für verbleibende Trial-Tage
final trialDaysRemainingProvider = Provider<int>((ref) {
  final state = ref.watch(subscriptionProvider);
  return state.trialDaysRemaining;
});

// Provider für Subscription-Repository
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final client = ref.read(supabaseClientProvider);
  return SubscriptionRepository(client);
});
