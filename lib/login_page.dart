import 'package:flutter/material.dart';
import 'api.dart';
import 'forgot_password_page.dart';
import 'main.dart';
import 'splash_page.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _showPass = false, _remember = true;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final res = await Api.login(_user.text.trim(), _pass.text);
      final u = res['user'] as Map<String, dynamic>;
      if (u['role'] != 'kasir' && u['role'] != 'admin') {
        throw ApiException('Role akun ini belum didukung di aplikasi mobile.');
      }
      await Session.save('${res['token']}', u);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SplashGate(next: shellForRole(u['role'] as String))));
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        child: Form(key: _form, child: _formContent(dark))),
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
              child: _card(dark),
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
  }

  Widget _card(bool dark) => Container(
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
          child: Form(key: _form, child: _formContent(dark)),
        ),
      );

  Widget _formContent(bool dark) => Column(
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
                onFieldSubmitted: (_) => _submit(),
                decoration:
                    _dec('Masukkan password', Icons.lock_outline, dark).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _showPass = !_showPass),
                    icon: Icon(
                        _showPass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: dark ? Colors.white54 : ZK.slate400),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Password wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _remember,
                      activeColor: ZK.primary,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) => setState(() => _remember = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Ingat saya',
                      style: TextStyle(
                          fontSize: 13, color: dark ? Colors.white70 : ZK.slate500)),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: ZK.primary,
                    disabledBackgroundColor: ZK.primary.withValues(alpha: 0.6),
                    shape: const RoundedRectangleBorder(borderRadius: r14),
                  ),
                  child: _loading
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
                      fontSize: 11.5,
                      color: dark ? Colors.white38 : ZK.slate400,
                      fontWeight: FontWeight.w600)),
            ],
          );

  InputDecoration _dec(String hint, IconData icon, [bool dark = false]) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: dark ? Colors.white38 : ZK.slate400, fontSize: 14),
        prefixIcon: Icon(icon, size: 19, color: dark ? Colors.white54 : ZK.slate400),
        filled: true,
        fillColor: dark ? const Color(0xFF0D1830) : const Color(0xFFF8FAFC),
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
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white70 : const Color(0xFF334155))),
      );
}
