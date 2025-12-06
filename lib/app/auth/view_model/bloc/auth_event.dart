import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class SendOtp extends AuthEvent {
  final String phoneNumber;

  const SendOtp({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtp extends AuthEvent {
  final String otp;

  const VerifyOtp({required this.otp});

  @override
  List<Object?> get props => [otp];
}

class AuthLoggedIn extends AuthEvent {}

class AuthLoggedOut extends AuthEvent {}
