import 'package:equatable/equatable.dart';

/// EVENTS
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationSettings extends NotificationEvent {}

class ToggleMasterNotification extends NotificationEvent {
  final bool value;
  const ToggleMasterNotification(this.value);
}

class UpdateNotificationItem extends NotificationEvent {
  final String category;
  final String key;
  final bool value;

  const UpdateNotificationItem({
    required this.category,
    required this.key,
    required this.value,
  });

  @override
  List<Object?> get props => [category, key, value];
}
