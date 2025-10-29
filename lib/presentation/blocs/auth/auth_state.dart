import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final String message;
  final Map<String, dynamic>? data;

  const AuthSuccess({required this.message, this.data});

  @override
  List<Object?> get props => [message, data];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class OtpSentSuccess extends AuthState {
  final String message;

  const OtpSentSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class OtpVerifiedSuccess extends AuthState {
  final String message;
  final Map<String, dynamic>? userData;

  const OtpVerifiedSuccess({required this.message, this.userData});

  @override
  List<Object?> get props => [message, userData];
}

class LogoutSuccess extends AuthState {
  const LogoutSuccess();
}
