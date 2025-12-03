part of 'connectivity_bloc.dart';

sealed class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object> get props => [];
}

final class ConnectivityChanged extends ConnectivityEvent {
  final List<ConnectivityResult> connectivityResult;

  const ConnectivityChanged(this.connectivityResult);

  @override
  List<Object> get props => [connectivityResult];
}
