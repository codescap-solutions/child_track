import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../utils/app_logger.dart';

/// Wraps all RevenueCat SDK interactions.
/// Call [initialize] once in main(), then [logIn] after login and
/// [logOut] before clearing session.
class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      final apiKey = Platform.isIOS
          ? dotenv.env['APPLE_API_KEY']
          : dotenv.env['PLAYSTORE_API_KEY'];

      if (apiKey == null || apiKey.isEmpty || apiKey.startsWith('appl_REPLACE') || apiKey.startsWith('goog_REPLACE')) {
        AppLogger.warning(
          'RevenueCat: API key not configured in .env — purchases disabled.',
        );
        return;
      }

      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );

      final config = PurchasesConfiguration(apiKey);
      await Purchases.configure(config);

      AppLogger.info('RevenueCat: Initialized successfully.');
    } catch (e, st) {
      AppLogger.error('RevenueCat init error: $e', e, st);
    }
  }

  // ── User Identity ─────────────────────────────────────────────────────────

  /// Call after successful login with your backend's user ID.
  Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
      AppLogger.info('RevenueCat: Logged in as $userId');
    } catch (e) {
      AppLogger.error('RevenueCat logIn error: $e');
    }
  }

  /// Call on logout before clearing local session.
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      AppLogger.info('RevenueCat: Logged out.');
    } catch (e) {
      AppLogger.error('RevenueCat logOut error: $e');
    }
  }

  // ── Offerings ─────────────────────────────────────────────────────────────

  /// Fetches the current offerings from RevenueCat.
  /// Returns null on error.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      AppLogger.error('RevenueCat getOfferings error: $e');
      return null;
    }
  }

  // ── Purchasing ────────────────────────────────────────────────────────────

  /// Triggers the native OS payment sheet for [pkg].
  /// Uses the modern SDK API — not deprecated purchasePackage.
  /// Throws [PurchasesErrorCode] on failure.
  Future<CustomerInfo> purchasePackage(Package pkg) async {
    final result = await Purchases.purchasePackage(pkg);
    return result;
  }

  // ── Customer Info ─────────────────────────────────────────────────────────

  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      AppLogger.error('RevenueCat getCustomerInfo error: $e');
      return null;
    }
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  Future<CustomerInfo?> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      AppLogger.error('RevenueCat restorePurchases error: $e');
      return null;
    }
  }
}
