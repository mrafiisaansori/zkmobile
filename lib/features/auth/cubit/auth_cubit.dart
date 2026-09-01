import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

// Padanan alur Api.login/forgotPassword/resendResetOtp/resetPassword +
// setState di login_page.dart/forgot_password_page.dart lama. loading/error/
// sukses sekarang jadi AuthState lewat emit(), tapi step wizard & cooldown
// timer di ForgotPasswordPage tetap state lokal widget — bukan concern cubit
// generik ini (lihat komentar _PendingAction di forgot_password_page.dart).
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  AuthCubit([AuthRepository? repo])
      : _repo = repo ?? AuthRepository(),
        super(const AuthState.idle());

  Future<void> login(String username, String password) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final res = await _repo.login(username, password);
      final u = res['user'] as Map<String, dynamic>;
      final role = '${u['role']}';
      if (role != 'kasir' && role != 'admin') {
        throw ApiException('Role akun ini belum didukung di aplikasi mobile.');
      }
      await Session.save('${res['token']}', u);
      emit(AuthState(status: AuthStatus.success, role: role));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, error: e));
    }
  }

  Future<void> requestOtp(String email) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final res = await _repo.forgotPassword(email);
      emit(AuthState(
        status: AuthStatus.success,
        successMessage:
            '${res['message'] ?? 'Jika email terdaftar, instruksi reset password akan dikirim.'}',
        cooldown: 60,
      ));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, error: e));
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      final res = await _repo.resendResetOtp(email);
      emit(AuthState(
        status: AuthStatus.success,
        successMessage:
            '${res['message'] ?? 'OTP baru telah dikirim bila email terdaftar.'}',
        cooldown: (res['cooldown'] as num?)?.toInt() ?? 60,
      ));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, error: e));
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final res = await _repo.resetPassword(email, otp, newPassword);
      emit(AuthState(
        status: AuthStatus.success,
        successMessage: '${res['message'] ?? 'Password berhasil diperbarui.'}',
      ));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, error: e));
    }
  }
}
