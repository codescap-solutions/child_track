import 'package:equatable/equatable.dart';

abstract class TimeLimitEvent extends Equatable {
  const TimeLimitEvent();

  @override
  List<Object> get props => [];
}

/// Fetches configured daily limits for the currently selected child.
class FetchTimeLimits extends TimeLimitEvent {}

class SetTimeLimit extends TimeLimitEvent {
  final String packageName;
  final String appName;
  final int dailyLimitMinutes;

  const SetTimeLimit({
    required this.packageName,
    required this.appName,
    required this.dailyLimitMinutes,
  });

  @override
  List<Object> get props => [packageName, appName, dailyLimitMinutes];
}

class RemoveTimeLimit extends TimeLimitEvent {
  final String packageName;

  const RemoveTimeLimit(this.packageName);

  @override
  List<Object> get props => [packageName];
}
