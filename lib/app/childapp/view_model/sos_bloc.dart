import 'package:child_track/app/home/model/device_model.dart';
import 'package:child_track/core/services/device_info_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sos_event.dart';
part 'sos_state.dart';

class SosBloc extends Bloc<SosEvent, SosState> {
  final DeviceInfoService _deviceInfoService;

  SosBloc({
    DeviceInfoService? deviceInfoService,
  })  : _deviceInfoService = deviceInfoService ?? DeviceInfoService(),
        super(SosInitial()) {
    on<LoadDeviceInfo>(_onLoadDeviceInfo);
  }

  Future<void> _onLoadDeviceInfo(
    LoadDeviceInfo event,
    Emitter<SosState> emit,
  ) async {
    emit(SosLoading());
    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      emit(SosDeviceInfoLoaded(deviceInfo: deviceInfo));
    } catch (e) {
      emit(SosError(message: 'Failed to load device info: ${e.toString()}'));
    }
  }
}

