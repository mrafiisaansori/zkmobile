import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

// Padanan alur 2 langkah di /forgot-password web: minta OTP -> verifikasi + password baru.
// Desain disamakan dengan LoginPage: ilustrasi di atas, card form di bawah, tanpa scroll.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => AuthCubit(),
        child: const _ForgotPasswordForm(),
      );
}

// Cubit generik cuma tahu loading/success/error — bukan "OTP diminta" vs
// "OTP dikirim ulang" vs "password direset". Widget ini yang melacak aksi
// mana yang sedang berjalan supaya listener tahu efek samping (pindah step,
// mulai cooldown, pop halaman) mana yang harus dijalankan saat sukses/gagal.
enum _PendingAction { none, requestOtp, resendOtp, resetPassword }

class _ForgotPasswordForm extends StatefulWidget {
  const _ForgotPasswordForm();
  @override
  State<_ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 1;
  bool _showPass = false, _showConfirm = false;
  int _cooldown = 0;
  _PendingAction _pending = _PendingAction.none;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _tickCooldown() {
    if (_cooldown <= 0 || !mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
      _tickCooldown();
    });
  }

  void _requestOtp(AuthState state) {
    if (state.status == AuthStatus.loading || !_emailForm.currentState!.validate()) return;
    setState(() => _pending = _PendingAction.requestOtp);
    context.read<AuthCubit>().requestOtp(_email.text.trim());
  }

  void _resendOtp() {
    if (_cooldown > 0) return;
    setState(() => _pending = _PendingAction.resendOtp);
    context.read<AuthCubit>().resendOtp(_email.text.trim());
  }

  void _doReset(AuthState state) {
    if (state.status == AuthStatus.loading || !_resetForm.currentState!.validate()) return;
    if (_newPass.text != _confirm.text) {
      toastError(context, 'Konfirmasi password tidak cocok.');
      return;
    }
    setState(() => _pending = _PendingAction.resetPassword);
    context
        .read<AuthCubit>()
        .resetPassword(_email.text.trim(), _otp.text.trim(), _newPass.text);
  }

  void _onAuthState(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.error) {
      toastError(context, state.error!);
      setState(() => _pending = _PendingAction.none);
      return;
    }
    if (state.status != AuthStatus.success) return;
    switch (_pending) {
      case _PendingAction.requestOtp:
        setState(() {
          _step = 2;
          _cooldown = state.cooldown ?? 60;
        });
        _tickCooldown();
        toastOk(context,
            state.successMessage ?? 'Jika email terdaftar, instruksi reset password akan dikirim.');
      case _PendingAction.resendOtp:
        setState(() => _cooldown = state.cooldown ?? 60);
        _tickCooldown();
        toastOk(context,
            state.successMessage ?? 'OTP baru telah dikirim bila email terdaftar.');
      case _PendingAction.resetPassword:
        toastOk(context, state.successMessage ?? 'Password berhasil diperbarui.');
        Navigator.of(context).pop();
      case _PendingAction.none:
        break;
    }
    setState(() => _pending = _PendingAction.none);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthCubit, AuthState>(
        listener: _onAuthState,
        builder: (context, state) {
          final loading = state.status == AuthStatus.loading;
          final dark = Theme.of(context).brightness == Brightness.dark;
          final bg = Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/login_illustration.jpeg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.35),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: isTablet(context) ? 0.45 : 0.28),
                        Colors.black.withValues(alpha: isTablet(context) ? 0.25 : 0.08),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          if (isTablet(context)) {
            return Scaffold(
              backgroundColor: dark ? ZK.bgDark : Colors.white,
              body: Stack(
                children: [
                  bg,
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Card(
                        margin: const EdgeInsets.all(24),
                        color: dark ? ZK.cardDark : Colors.white,
                        elevation: 12,
                        shape: const RoundedRectangleBorder(borderRadius: r14),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                          child: SingleChildScrollView(child: _cardContent(dark, loading, state)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Scaffold(
            backgroundColor: dark ? ZK.bgDark : Colors.white,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Stack(
                children: [
                  // Ilustrasi mengisi seluruh layar di belakang — card mengambang
                  // di atasnya sesuai tinggi kontennya sendiri (bukan dipaksa penuh),
                  // jadi makin sedikit isi form, makin banyak ilustrasi yang terlihat.
                  bg,
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _card(dark, loading, state),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _card(bool dark, bool loading, AuthState state) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -8)),
          ],
        ),
        child: SingleChildScrollView(child: _cardContent(dark, loading, state)),
      );

  Widget _cardContent(bool dark, bool loading, AuthState state) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset('assets/icon.png', height: 32, width: 32),
          ),
          const SizedBox(height: 12),
          Text(
            _step == 1 ? 'Atur ulang password' : 'Verifikasi & password baru',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : ZK.ink),
          ),
          const SizedBox(height: 6),
          Text(
            _step == 1
                ? 'Masukkan email akun Anda untuk menerima kode OTP.'
                : 'Masukkan kode OTP yang dikirim ke ${_email.text}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: dark ? Colors.white70 : ZK.slate500),
          ),
          const SizedBox(height: 20),
          _step == 1 ? _emailStep(dark, loading, state) : _resetStep(dark, loading, state),
          const SizedBox(height: 16),
          Text('Powered by zonakasir.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  color: dark ? Colors.white60 : ZK.slate500,
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _emailStep(bool dark, bool loading, AuthState state) => Form(
        key: _emailForm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Label('Email', dark),
            TextFormField(
              controller: _email,
              style: TextStyle(color: dark ? Colors.white : ZK.ink),
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('email@toko.com', Icons.mail_outline, dark),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Email wajib diisi' : null,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: loading ? null : () => _requestOtp(state),
                style: FilledButton.styleFrom(
                  backgroundColor: ZK.primary,
                  disabledBackgroundColor: ZK.primary.withValues(alpha: 0.6),
                  shape: const RoundedRectangleBorder(borderRadius: r14),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Kirim kode reset',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ZK.rose,
                  side: const BorderSide(color: ZK.rose, width: 1.4),
                  shape: const RoundedRectangleBorder(borderRadius: r14),
                ),
                child: const Text('Kembali ke Login',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );

  Widget _resetStep(bool dark, bool loading, AuthState state) => Form(
        key: _resetForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _otp,
              style: TextStyle(color: dark ? Colors.white : ZK.ink),
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: _dec('6 digit kode OTP', Icons.password_outlined, dark)
                  .copyWith(counterText: ''),
              validator: (v) =>
                  (v ?? '').trim().length != 6 ? 'OTP harus 6 digit' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _newPass,
              style: TextStyle(color: dark ? Colors.white : ZK.ink),
              obscureText: !_showPass,
              decoration:
                  _dec('Password baru (min 8 karakter)', Icons.lock_outline, dark).copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showPass = !_showPass),
                  icon: Icon(
                      _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: dark ? Colors.white60 : ZK.slate400),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 8 ? 'Minimal 8 karakter' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirm,
              style: TextStyle(color: dark ? Colors.white : ZK.ink),
              obscureText: !_showConfirm,
              decoration: _dec('Ulangi password baru', Icons.lock_outline, dark).copyWith(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  icon: Icon(
                      _showConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: dark ? Colors.white60 : ZK.slate400),
                ),
              ),
              validator: (v) => (v ?? '').isEmpty ? 'Ulangi password' : null,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: loading ? null : () => _doReset(state),
                style: FilledButton.styleFrom(
                  backgroundColor: ZK.primary,
                  disabledBackgroundColor: ZK.primary.withValues(alpha: 0.6),
                  shape: const RoundedRectangleBorder(borderRadius: r14),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan password baru',
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () => setState(() => _step = 1),
                  child: Text('Ganti email',
                      style: TextStyle(
                          fontSize: 12.5, color: dark ? Colors.white70 : ZK.slate500)),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: _cooldown > 0 ? null : _resendOtp,
                  child: Text(
                      _cooldown > 0 ? 'Kirim ulang (${_cooldown}s)' : 'Kirim ulang OTP',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _cooldown > 0
                              ? (dark ? Colors.white60 : ZK.slate400)
                              : ZK.primary)),
                ),
              ],
            ),
          ],
        ),
      );

  InputDecoration _dec(String hint, IconData icon, [bool dark = false]) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: dark ? Colors.white60 : ZK.slate500, fontSize: 14),
        prefixIcon: Icon(icon, size: 19, color: dark ? Colors.white60 : ZK.slate400),
        filled: true,
        fillColor: dark ? const Color(0xFF0D1830) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        enabledBorder: OutlineInputBorder(
            borderRadius: r14, borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.line)),
        focusedBorder: const OutlineInputBorder(
            borderRadius: r14,
            borderSide: BorderSide(color: ZK.primary, width: 1.6)),
        errorBorder: const OutlineInputBorder(
            borderRadius: r14, borderSide: BorderSide(color: ZK.rose)),
        focusedErrorBorder: const OutlineInputBorder(
            borderRadius: r14, borderSide: BorderSide(color: ZK.rose, width: 1.6)),
      );
}

class _Label extends StatelessWidget {
  final String text;
  final bool dark;
  const _Label(this.text, [this.dark = false]);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white70 : const Color(0xFF334155))),
      );
}
