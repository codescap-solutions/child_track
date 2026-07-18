import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/app_logger.dart';

class SubscriptionManager {
  SubscriptionManager._();
  static final SubscriptionManager instance = SubscriptionManager._();

  bool _hasPremiumAccess = false;

  /// Synchronous check if the user has premium access.
  /// This value is kept in sync via [initialize] and [checkAndUpdateStatus].
  bool get hasPremiumAccess => _hasPremiumAccess;

  /// Should be called during app startup after RevenueCat is configured.
  Future<void> initialize() async {
    try {
      // 1. Check initial status
      await checkAndUpdateStatus();

      // 2. Listen for future updates (e.g., successful purchases)
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateAccessFromInfo(customerInfo);
      });
    } catch (e) {
      AppLogger.error('Failed to initialize SubscriptionManager: $e');
    }
  }

  /// Manually checks RevenueCat for the latest entitlement status.
  Future<bool> checkAndUpdateStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateAccessFromInfo(customerInfo);
      return _hasPremiumAccess;
    } catch (e) {
      AppLogger.error('Failed to get customer info in SubscriptionManager: $e');
      return false;
    }
  }

  void _updateAccessFromInfo(CustomerInfo customerInfo) {
    // Check if the 'premium_access' entitlement is active
    final isActive = customerInfo.entitlements.active.containsKey('premium_access');
    
    if (_hasPremiumAccess != isActive) {
      _hasPremiumAccess = isActive;
      AppLogger.info('SubscriptionManager: Premium access updated to $_hasPremiumAccess');
    }
  }
}
