import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable{
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {
  final String phoneNumber;

  const AuthOtpSent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthSuccess extends AuthState {
  final bool hasChildren;

  const AuthSuccess({this.hasChildren = false});

  @override
  List<Object?> get props => [hasChildren];
}

class AuthNewUser extends AuthState {
  final String phoneNumber;

  const AuthNewUser({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class AuthNeedsRegistration extends AuthState {}