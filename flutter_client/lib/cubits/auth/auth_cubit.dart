import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_client/services/auth/auth_services.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final AuthServices authServices = AuthServices();

  void signupUser({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final res = await authServices.signUpUser(
        name: name,
        email: email,
        password: password,
      );
      emit(AuthSignupSuccess(res));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void confirmSignupUser({required String email, required String otp}) async {
    emit(AuthLoading());
    try {
      final res = await authServices.confirmSignupUser(email: email, otp: otp);
      emit(AuthConfirmSignupSuccess(res));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void loginUser({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final res = await authServices.loginUser(
        email: email,
        password: password,
      );
      emit(AuthLoginSuccess(res));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void isAuthenticated() async {
    emit(AuthLoading());
    try {
      final res = await authServices.isAuthenticated();
      if (res) {
        emit(AuthLoginSuccess("Logged In"));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
