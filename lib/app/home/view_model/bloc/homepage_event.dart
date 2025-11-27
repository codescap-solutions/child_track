part of 'homepage_bloc.dart';

sealed class HomepageEvent extends Equatable {
  const HomepageEvent();

  @override
  List<Object> get props => [];
}

final class GetHomepageData extends HomepageEvent {
  final String? childId;

  const GetHomepageData({this.childId});

  @override
  List<Object> get props => [if (childId != null) childId!];
}

final class FetchChildCurrentDetails extends HomepageEvent {}
