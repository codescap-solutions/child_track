part of 'homepage_bloc.dart';

sealed class HomepageEvent extends Equatable {
  const HomepageEvent();

  @override
  List<Object> get props => [];
}

final class GetHomepageData extends HomepageEvent {}

final class FetchChildCurrentDetails extends HomepageEvent {}
