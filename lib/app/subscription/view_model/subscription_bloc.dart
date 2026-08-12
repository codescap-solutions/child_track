import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/services/revenue_cat_service.dart';
import '../../../../core/utils/app_logger.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final RevenueCatService _rc;

  SubscriptionBloc({RevenueCatService? revenueCatService})
    : _rc = revenueCatService ?? RevenueCatService.instance,
      super(const SubscriptionInitial()) {
    on<SelectPlanEvent>(_onSelectPlan);
    on<PurchasePackageEvent>(_onPurchasePackage);
  }

  void _onSelectPlan(SelectPlanEvent event, Emitter<SubscriptionState> emit) {
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
}
