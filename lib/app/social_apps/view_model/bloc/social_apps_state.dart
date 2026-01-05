part of 'social_apps_bloc.dart';

abstract class SocialAppsState extends Equatable {
  const SocialAppsState();

  @override
  List<Object> get props => [];
}

class SocialAppsInitial extends SocialAppsState {}

class SocialAppsLoading extends SocialAppsState {}

class SocialAppsLoaded extends SocialAppsState {
  final AppUsageResponse data;
  final String selectedDate;
  final DateTime? currentDate;

  const SocialAppsLoaded({
    required this.data,
    required this.selectedDate,
    this.currentDate,
  });

  @override
  List<Object> get props => [data, selectedDate];
}

class SocialAppsError extends SocialAppsState {
  final String message;

  const SocialAppsError(this.message);

  @override
  List<Object> get props => [message];
}
