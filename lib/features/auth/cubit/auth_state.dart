import 'package:equatable/equatable.dart';

enum AuthStatus { idle, loading, success, error }

// State generik dipakai LoginPage & ForgotPasswordPage — masing-masing
// membuat instance AuthCubit sendiri lewat BlocProvider per screen, jadi
// field yang sama (successMessage/cooldown/role) tidak saling bentrok walau
// dipakai untuk alur berbeda.
class AuthState extends Equatable {
  final AuthStatus status;
  // Exception mentah (bukan String) supaya diteruskan apa adanya ke
  // toastError() — itu yang membedakan pesan network-error vs ApiException.
  final Object? error;
  final String? successMessage; // pesan dari server, diteruskan ke toastOk()
  final int? cooldown; // detik cooldown OTP, terisi setelah request/resend sukses
  final String? role; // role user setelah login sukses, dipakai shellForRole()

  const AuthState({
    this.status = AuthStatus.idle,
    this.error,
    this.successMessage,
    this.cooldown,
    this.role,
  });

  const AuthState.idle() : this();

  @override
  List<Object?> get props => [status, error, successMessage, cooldown, role];
}
