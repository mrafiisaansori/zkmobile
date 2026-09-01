import '../../../core/network/api_client.dart';

// Padanan Api.login/forgotPassword/resendResetOtp/resetPassword (lib/api.dart
// lama) — dipisah jadi repository fitur auth, hanya membungkus request/response
// mentah lewat apiPost. Logika bisnis (validasi role, Session.save, dst) ada
// di AuthCubit, bukan di sini.
class AuthRepository {
  Future<Map<String, dynamic>> login(String username, String password) async =>
      await apiPost('/auth/login', {'username': username, 'password': password})
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> forgotPassword(String email) async =>
      await apiPost('/auth/forgot-password', {'email': email}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> resendResetOtp(String email) async =>
      await apiPost('/auth/forgot-password/resend', {'email': email})
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> resetPassword(
          String email, String otp, String newPassword) async =>
      await apiPost('/auth/reset-password', {
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }) as Map<String, dynamic>;
}
