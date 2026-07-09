import 'package:equatable/equatable.dart';

enum SubscriptionStatus { trial, active, canceled, expired, paused }

extension SubscriptionStatusLabel on SubscriptionStatus {
  String get label => switch (this) {
        SubscriptionStatus.trial => 'Trial',
        SubscriptionStatus.active => 'Active',
        SubscriptionStatus.canceled => 'Cancelled',
        SubscriptionStatus.expired => 'Expired',
        SubscriptionStatus.paused => 'Paused',
      };
}

class SubscriptionPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final double priceMonthly;
  final double priceYearly;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceMonthly,
    required this.priceYearly,
    this.isActive = true,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      priceMonthly: (json['price_monthly'] as num?)?.toDouble() ?? 0.0,
      priceYearly: (json['price_yearly'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, description, priceMonthly, priceYearly, isActive];
}

class DiscountCode extends Equatable {
  final String id;
  final String code;
  final int discountPercent;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? maxUses;
  final int currentUses;
  final bool isActive;

  const DiscountCode({
    required this.id,
    required this.code,
    required this.discountPercent,
    this.validFrom,
    this.validUntil,
    this.maxUses,
    this.currentUses = 0,
    this.isActive = true,
  });

  bool get isValid {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    if (maxUses != null && currentUses >= maxUses!) return false;
    return isActive;
  }

  factory DiscountCode.fromJson(Map<String, dynamic> json) {
    return DiscountCode(
      id: json['id'] as String,
      code: json['code'] as String,
      discountPercent: json['discount_percent'] as int,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
      maxUses: json['max_uses'] as int?,
      currentUses: json['current_uses'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, code, discountPercent, validFrom, validUntil, maxUses, currentUses, isActive];
}

class Subscription extends Equatable {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime trialStartedAt;
  final DateTime trialEndsAt;
  final DateTime? subscribedAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? discountCodeId;
  final bool discountApplied;
  final SubscriptionPlan? plan;
  final String priceType; // 'monthly' or 'yearly'

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.trialStartedAt,
    required this.trialEndsAt,
    this.subscribedAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.discountCodeId,
    this.discountApplied = false,
    this.plan,
    this.priceType = 'monthly',
  });

  bool get isInTrial => status == SubscriptionStatus.trial && !isTrialExpired;

  bool get isTrialExpired => DateTime.now().isAfter(trialEndsAt);

  bool get hasActiveAccess => status == SubscriptionStatus.active || isInTrial;

  int get trialDaysRemaining {
    if (isTrialExpired) return 0;
    final remaining = trialEndsAt.difference(DateTime.now()).inDays;
    return remaining.clamp(0, 30);
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.trial,
      ),
      trialStartedAt: DateTime.parse(json['trial_started_at'] as String),
      trialEndsAt: DateTime.parse(json['trial_ends_at'] as String),
      subscribedAt: json['subscribed_at'] != null
          ? DateTime.parse(json['subscribed_at'] as String)
          : null,
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'] as String)
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      stripeCustomerId: json['stripe_customer_id'] as String?,
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      discountCodeId: json['discount_code_id'] as String?,
      discountApplied: json['discount_applied'] as bool? ?? false,
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      priceType: json['price_type'] as String? ?? 'monthly',
    );
  }

  @override
  List<Object?> get props => [
        id, userId, planId, status, trialStartedAt, trialEndsAt,
        subscribedAt, currentPeriodStart, currentPeriodEnd,
        cancelAtPeriodEnd, stripeCustomerId, stripeSubscriptionId,
        discountCodeId, discountApplied, plan, priceType,
      ];
}

class TrialStatus {
  final bool isActive;
  final int daysRemaining;
  final bool trialEnded;
  final String subscriptionStatus;

  const TrialStatus({
    required this.isActive,
    required this.daysRemaining,
    required this.trialEnded,
    required this.subscriptionStatus,
  });

  factory TrialStatus.fromJson(Map<String, dynamic> json) {
    return TrialStatus(
      isActive: json['is_active'] as bool,
      daysRemaining: json['days_remaining'] as int,
      trialEnded: json['trial_ended'] as bool,
      subscriptionStatus: json['subscription_status'] as String,
    );
  }
}
