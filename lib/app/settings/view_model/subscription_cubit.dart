import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/services/revenue_cat_service.dart';
import '../../../core/utils/app_logger.dart';

// ── States ───────────────────────────────────────────────────────────────────

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

/// Offerings are loaded. [selectedIndex] 0 = monthly, 1 = yearly.
class SubscriptionLoaded extends SubscriptionState {
  final Package? monthlyPackage;
  final Package? yearlyPackage;
  final int selectedIndex; // 0 = monthly, 1 = yearly

  const SubscriptionLoaded({
    required this.monthlyPackage,
    required this.yearlyPackage,
    required this.selectedIndex,
  });

  Package? get selectedPackage =>
      selectedIndex == 0 ? monthlyPackage : yearlyPackage;

  SubscriptionLoaded copyWith({int? selectedIndex}) {
    return SubscriptionLoaded(
      monthlyPackage: monthlyPackage,
      yearlyPackage: yearlyPackage,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  @override
  List<Object?> get props => [monthlyPackage, yearlyPackage, selectedIndex];
}

/// Native payment sheet is open — lock all buttons, show spinner on CTA.
class SubscriptionPurchasing extends SubscriptionState {
  final Package purchasingPackage;
  const SubscriptionPurchasing(this.purchasingPackage);

  @override
  List<Object?> get props => [purchasingPackage];
}

class SubscriptionSuccess extends SubscriptionState {
  final CustomerInfo customerInfo;
  const SubscriptionSuccess(this.customerInfo);

  @override
  List<Object?> get props => [customerInfo];
}

class SubscriptionRestoring extends SubscriptionState {
  const SubscriptionRestoring();
}

class SubscriptionError extends SubscriptionState {
  final String message;
  final bool isCancelled; // true when user dismissed the sheet

  const SubscriptionError(this.message, {this.isCancelled = false});

  @override
  List<Object?> get props => [message, isCancelled];
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class SubscriptionCubit extends Cubit<SubscriptionState> {
  final RevenueCatService _rc;

  SubscriptionCubit({RevenueCatService? revenueCatService})
    : _rc = revenueCatService ?? RevenueCatService.instance,
      super(const SubscriptionInitial());

  // Product IDs as configured in RevenueCat dashboard
  static const _monthlyProductId = 'naviqpro_99_montly';
  static const _yearlyProductId = 'naviqpro_999_yearly';

  /// Load offerings from RevenueCat and extract monthly + yearly packages.
  Future<void> loadOfferings() async {
    emit(const SubscriptionLoading());
    try {
      final offerings = await _rc.getOfferings();
      if (offerings == null) {
        emit(const SubscriptionError('Unable to load subscription plans.'));
        return;
      }

      Package? monthly;
      Package? yearly;

      // Search all offerings for matching product IDs
      final allOfferings = offerings.all.values.toList();
      allOfferings.insert(0, offerings.current ?? allOfferings.first);

      for (final offering in offerings.all.values) {
        for (final pkg in offering.availablePackages) {
          final id = pkg.storeProduct.identifier;
          if (id == _monthlyProductId) monthly = pkg;
          if (id == _yearlyProductId) yearly = pkg;
        }
      }

      // Also check current offering
      if (offerings.current != null) {
        for (final pkg in offerings.current!.availablePackages) {
          final id = pkg.storeProduct.identifier;
          if (id == _monthlyProductId) monthly = pkg;
          if (id == _yearlyProductId) yearly = pkg;
        }
      }

      emit(SubscriptionLoaded(
        monthlyPackage: monthly,
        yearlyPackage: yearly,
        selectedIndex: 1, // default: yearly (best value)
      ));
    } catch (e) {
      AppLogger.error('SubscriptionCubit loadOfferings: $e');
      emit(SubscriptionError('Failed to load plans: $e'));
    }
  }

  /// Toggle between monthly (0) and yearly (1) tab.
  void selectPlan(int index) {
    if (state is SubscriptionLoaded) {
      emit((state as SubscriptionLoaded).copyWith(selectedIndex: index));
    }
  }

  /// Trigger native OS payment sheet for the currently selected package.
  Future<void> purchase(Package pkg) async {
    emit(SubscriptionPurchasing(pkg));
    try {
      final customerInfo = await _rc.purchasePackage(pkg);

      if (customerInfo.entitlements.active.isNotEmpty) {
        // ── Security: verify server-side ──────────────────────────────────
        // The frontend only unlocks after the backend confirms the receipt.
        // Replace this log with your actual backend call:
        //
        //   final txId = customerInfo.entitlements.active.values.first
        //       .productIdentifier;
        //   await YourApiService.verifyPurchase(txId);
        //
        AppLogger.info(
          'RevenueCat: Purchase successful. '
          'Active entitlements: ${customerInfo.entitlements.active.keys}',
        );
      }

      emit(SubscriptionSuccess(customerInfo));
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        emit(const SubscriptionError('Purchase cancelled.', isCancelled: true));
      } else {
        emit(SubscriptionError('Purchase failed: ${e.name}'));
      }
      AppLogger.error('RevenueCat purchase error: $e');
    } catch (e) {
      emit(SubscriptionError('Unexpected error: $e'));
      AppLogger.error('RevenueCat unexpected error: $e');
    }
  }

  /// Restore previous purchases (required by App Store guidelines).
  Future<void> restorePurchases() async {
    emit(const SubscriptionRestoring());
    try {
      final customerInfo = await _rc.restorePurchases();
      if (customerInfo != null && customerInfo.entitlements.active.isNotEmpty) {
        emit(SubscriptionSuccess(customerInfo));
      } else {
        emit(const SubscriptionError('No active subscriptions found to restore.'));
      }
    } catch (e) {
      emit(SubscriptionError('Restore failed: $e'));
    }
  }
}
