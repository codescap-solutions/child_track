part of 'social_apps_bloc.dart';

abstract class SocialAppsEvent extends Equatable {
  const SocialAppsEvent();

  @override
  List<Object> get props => [];
}

class FetchAppUsage extends SocialAppsEvent {
  final String date;
  final String? startDate;
  final String? endDate;

  const FetchAppUsage({required this.date, this.startDate, this.endDate});

  @override
  List<Object> get props => [date, startDate ?? '', endDate ?? ''];
}
