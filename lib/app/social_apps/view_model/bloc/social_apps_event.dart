part of 'social_apps_bloc.dart';

abstract class SocialAppsEvent extends Equatable {
  const SocialAppsEvent();

  @override
  List<Object> get props => [];
}

class FetchAppUsage extends SocialAppsEvent {
  final String date;

  const FetchAppUsage({required this.date});

  @override
  List<Object> get props => [date];
}
