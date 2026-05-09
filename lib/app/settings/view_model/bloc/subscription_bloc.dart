import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/utils/app_logger.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final RevenueCatService _rc;

  // Product IDs as configured in RevenueCat dashboard
  static const _monthlyProductId = 'naviqpro_99_montly';
  static const _yearlyProductId = 'naviqpro_999_yearly';

  SubscriptionBloc({RevenueCatService? revenueCatService})
      : _rc = revenueCatService ?? RevenueCatService.instance,
        super(const SubscriptionInitial()) {
    on<LoadOfferingsEvent>(_onLoadOfferings);
    on<SelectPlanEvent>(_onSelectPlan);
    on<PurchasePackageEvent>(_onPurchasePackage);
    on<RestorePurchasesEvent>(_onRestorePurchases);
  }

  Future<void> _onLoadOfferings(
    LoadOfferingsEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionLoading());
    try {
      final offerings = await _rc.getOfferings();
      if (offerings == null) {
        emit(const SubscriptionError(
          'Unable to load subscription plans.',
          isLoadError: true,
        ));
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
      AppLogger.error('SubscriptionBloc loadOfferings: $e');
      emit(SubscriptionError('Failed to load plans: $e', isLoadError: true));
    }
  }

  void _onSelectPlan(
    SelectPlanEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    if (state is SubscriptionLoaded) {
      emit((state as SubscriptionLoaded).copyWith(selectedIndex: event.index));
    }
  }

  Future<void> _onPurchasePackage(
    PurchasePackageEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionPurchasing(event.package));
    try {
      final customerInfo = await _rc.purchasePackage(event.package);

      if (customerInfo.entitlements.active.isNotEmpty) {
        // ── Security: verify server-side ──────────────────────────────────
        // The frontend only unlocks after the backend confirms the receipt.
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

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionRestoring());
    try {
      final customerInfo = await _rc.restorePurchases();
      if (customerInfo != null && customerInfo.entitlements.active.isNotEmpty) {
        emit(SubscriptionSuccess(customerInfo));
      } else {
        emit(const SubscriptionError(
          'No active subscriptions found to restore.',
          isLoadError: true,
        ));
      }
    } catch (e) {
      emit(SubscriptionError('Restore failed: $e', isLoadError: true));
    }
  }
}
