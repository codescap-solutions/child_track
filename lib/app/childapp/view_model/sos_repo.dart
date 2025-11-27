import 'package:child_track/core/models/base_response.dart';
import 'package:child_track/core/services/base_service.dart';

class SosRepo {
  static Future<BaseResponse> postChildData(Map<String, dynamic> data) async {
    Future.delayed(const Duration(seconds: 1));
    return BaseResponse.success(
      data: {'message': 'Child data posted successfully'},
    );
  }
}
