import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../../boot/screens/splash_page.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => AuthCubit(),
        child: const _LoginForm(),
      );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _showPass = false, _remember = true;

  @override
  void initState() {
    super.initState();
    // Pilihan "Ingat saya" terakhir + username terakhir (bila dulu dicentang).
    Session.loginPrefs().then((p) {
      if (!mounted) return;
      setState(() {
        _remember = p.$1;
        if (_user.text.isEmpty) _user.text = p.$2;
      });
    });
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit(AuthState state) {
    if (state.status == AuthStatus.loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().login(_user.text.trim(), _pass.text, remember: _remember);
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            toastError(context, state.error!);
          } else if (state.status == AuthStatus.success) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => SplashGate(next: shellForRole(state.role))));
          }
        },
        builder: (context, state) {
          final loading = state.status == AuthStatus.loading;
          final heroH = MediaQuery.of(context).size.height * 0.4;
          final dark = Theme.of(context).brightness == Brightness.dark;
          if (isTablet(context)) {
            return Scaffold(
              backgroundColor: dark ? ZK.bgDark : Colors.white,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset('assets/login_illustration.jpeg',
                            fit: BoxFit.cover, alignment: const Alignment(0, -0.35)),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.black.withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Card(
                        margin: const EdgeInsets.all(24),
                        color: dark ? ZK.cardDark : Colors.white,
                        elevation: 12,
                        shape: const RoundedRectangleBorder(borderRadius: r14),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                          child: SingleChildScrollView(
                              child: Form(
                                  key: _form,
                                  child: _formContent(dark, loading, state))),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(padding: const EdgeInsets.all(10), child: const ThemeToggle()),
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
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: heroH,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/login_illustration.jpeg',
                          fit: BoxFit.cover,
                          // Geser jendela crop ke bawah dikit dari topCenter agar adegan
                          // transaksi di kasir (bukan rak produk) yang terlihat penuh.
                          alignment: const Alignment(0, -0.35),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.28),
                                Colors.black.withValues(alpha: 0.08),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Card mulai 28px sebelum ilustrasi habis, supaya lengkungan atasnya
                  // menampakkan ilustrasi di baliknya, bukan background polos.
                  Positioned(
                    top: heroH - 28,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _card(dark, loading, state),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: const ThemeToggle(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _card(bool dark, bool loading, AuthState state) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        decoration: BoxDecoration(
          color: dark ? ZK.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x14000000), blurRadius: 24, offset: Offset(0, -8)),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(key: _form, child: _formContent(dark, loading, state)),
        ),
      );

  Widget _formContent(bool dark, bool loading, AuthState state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Image.asset(
                    dark ? 'assets/logo_splash.png' : 'assets/icon.png',
                    height: 36,
                    width: 36),
              ),
              const SizedBox(height: 14),
              Text('Selamat datang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : ZK.ink)),
              const SizedBox(height: 6),
              Text('Masuk untuk melanjutkan transaksi di kasir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: dark ? Colors.white70 : ZK.slate500)),
              const SizedBox(height: 26),
              _Label('Username', dark),
              TextFormField(
                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                controller: _user,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: _dec('Masukkan username', Icons.person_outline, dark),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Username wajib diisi' : null,
              ),
              const SizedBox(height: 18),
              _Label('Password', dark),
              TextFormField(
                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                controller: _pass,
                obscureText: !_showPass,
                onFieldSubmitted: (_) => _submit(state),
                decoration:
                    _dec('Masukkan password', Icons.lock_outline, dark).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showPass = !_showPass),
                    icon: Icon(
                        _showPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: dark ? Colors.white60 : ZK.slate400),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Password wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Kotak + tulisan satu area ketuk setinggi 44px.
                  InkWell(
                    borderRadius: r12,
                    onTap: () => setState(() => _remember = !_remember),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _remember,
                              activeColor: ZK.primary,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) => setState(() => _remember = v ?? true),
                            ),
                            Text('Ingat saya',
                                style: TextStyle(
                                    fontSize: 13, color: dark ? Colors.white70 : ZK.slate500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 44)),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                    child: const Text('Lupa Password?',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ZK.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: loading ? null : () => _submit(state),
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Masuk',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Powered by zonakasir.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.white60 : ZK.slate500,
                      fontWeight: FontWeight.w600)),
            ],
          );

  InputDecoration _dec(String hint, IconData icon, [bool dark = false]) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: dark ? Colors.white60 : ZK.slate500, fontSize: 14),
        prefixIcon: Icon(icon, size: 19, color: dark ? Colors.white60 : ZK.slate400),
        filled: true,
        fillColor: dark ? const Color(0xFF0D1830) : ZK.slate50,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white70 : ZK.slate700)),
      );
}
