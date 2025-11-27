part of 'sos_bloc.dart';

sealed class SosEvent extends Equatable {
  const SosEvent();

  @override
  List<Object> get props => [];
}

final class LoadDeviceInfo extends SosEvent {}

