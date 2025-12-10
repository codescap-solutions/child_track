part of 'connectivity_bloc.dart';

sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object> get props => [];
}

final class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

final class ConnectivityOnline extends ConnectivityState {
  final ConnectivityStatus status;

  const ConnectivityOnline({required this.status});

  @override
  List<Object> get props => [status];
}

final class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}
