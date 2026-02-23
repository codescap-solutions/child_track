import 'package:equatable/equatable.dart';

import '../../models/notification_settings_model.dart';

/// STATES
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final NotificationSettingsModel model;

  const NotificationLoaded(this.model);

  @override
  List<Object?> get props => [model];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
