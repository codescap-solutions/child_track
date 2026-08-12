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

class RegisterUser extends AuthEvent {
  final String phoneNumber;
  final String name;
  final String parentingSituation;
  final String parentRoutine;
  final Map<String, dynamic>? address;

  const RegisterUser({
    required this.phoneNumber,
    required this.name,
    required this.parentingSituation,
    required this.parentRoutine,
    this.address,
  });

  @override
  List<Object?> get props => [
        phoneNumber,
        name,
        parentingSituation,
        parentRoutine,
        if (address != null) address!,
      ];
}

class SelectChild extends AuthEvent {
  final String childId;

  const SelectChild({required this.childId});

  @override
  List<Object?> get props => [childId];
}

class AuthLoggedIn extends AuthEvent {}

class AuthLoggedOut extends AuthEvent {}
