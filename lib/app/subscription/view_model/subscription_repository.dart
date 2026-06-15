import 'dart:developer';

import '../../../core/services/dio_client.dart';
import '../../../core/services/api_endpoints.dart';
import '../../../core/services/base_service.dart';
import '../models/subscription_plan.dart';

class SubscriptionRepository extends BaseService {
  List<SubscriptionPlan>? _cachedPlans;

  SubscriptionRepository({
    required DioClient dioClient,
  }) : super(dioClient);

  Future<BaseResponse<List<SubscriptionPlan>>> getPlans({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedPlans != null) {
      log('Returning cached subscription plans...');
      return BaseResponse.success(data: _cachedPlans!, message: 'Cached');
    }

    try {
      log('Fetching subscription plans...');
      final response = await get(ApiEndpoints.getSubscriptionPlans);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> plansJson = response.data['plans'] ?? [];
        final plans = plansJson
            .map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>))
            .toList();
        _cachedPlans = plans;
        return BaseResponse.success(data: plans, message: response.message);
      }

      log('Failed to fetch plans: ${response.message}');
      // Fallback
      return BaseResponse.success(data: SubscriptionData.plans, message: response.message);
    } catch (e) {
      log('Error fetching subscription plans: $e');
      // Fallback
      return BaseResponse.success(data: SubscriptionData.plans, message: e.toString());
    }
  }
}


