import 'package:child_track/app/auth/view_model/bloc/auth_event.dart';
import 'package:child_track/app/auth/view_model/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoggedIn>(_onAuthLoggedIn);
    on<AuthLoggedOut>(_onAuthLoggedOut);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    emit(AuthLoading());
  }

  void _onAuthLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) {
    emit(AuthSuccess());
  }

  void _onAuthLoggedOut(AuthLoggedOut event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}
