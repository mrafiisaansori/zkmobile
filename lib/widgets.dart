import 'package:flutter/material.dart';
import 'api.dart';
import 'connectivity.dart';
import 'login_page.dart';
import 'main.dart';
import 'models.dart';
import 'theme.dart';

// Toggle tema matahari/bulan berbentuk pil dengan thumb yang meluncur +
// ikon crossfade-rotate — dipakai di header shell & halaman auth.
class ThemeToggle extends StatelessWidget {
  final double height;
  const ThemeToggle({super.key, this.height = 32});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeMode,
        builder: (_, mode, __) {
          final dark = mode == ThemeMode.dark;
          final w = height * 1.9;
          final thumb = height - 6;
          return GestureDetector(
            onTap: toggleThemeMode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: w,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(
                  colors: dark
                      ? const [Color(0xFF1E293B), Color(0xFF0B1220)]
                      : [ZK.primary, ZK.accent],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          size: height * 0.42,
                          color: Colors.white.withValues(alpha: dark ? 0.35 : 0.95)),
                      Icon(Icons.nightlight_round,
                          size: height * 0.38,
                          color: Colors.white.withValues(alpha: dark ? 0.95 : 0.35)),
                    ],
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      height: thumb,
                      width: thumb,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => RotationTransition(
                            turns: anim,
                            child: ScaleTransition(scale: anim, child: child)),
                        child: Icon(
                          dark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                          key: ValueKey(dark),
                          size: thumb * 0.58,
                          color: dark ? const Color(0xFF1E293B) : ZK.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

// Shell seragam untuk 4 tab (Dashboard/POS/Open Bill/Riwayat): header hero
// pakai ilustrasi yang sama seperti login, logo putih kiri, toggle tema +
// logout kanan, lalu konten dibungkus card putih/gelap yang menimpa ke atas
// (padanan gaya card login), sedikit overlap ke bawah ilustrasi.
class HeroShell extends StatelessWidget {
  final Widget child;
  // Override judul/subjudul header tablet — kalau null, dibaca dari
  // activeTab/tabTitles (dipakai KasirShell). Halaman di luar shell kasir
  // (mis. admin) pakai override ini supaya tidak numpang tab kasir.
  final String? titleOverride, subtitleOverride;
  // Tombol hamburger di header ponsel (kiri, sebelum logo) — dipakai admin
  // buat buka Drawer, karena admin punya terlalu banyak menu buat bottom nav.
  final VoidCallback? onMenuTap;
  const HeroShell(
      {super.key,
      required this.child,
      this.titleOverride,
      this.subtitleOverride,
      this.onMenuTap});
  static const _heroH = 128.0;
  // Header tablet tetap lebih ramping dari ponsel (sidebar bawa branding
  // sendiri), tapi diberi sedikit lebih tinggi dari revisi awal.
  static const _heroHTablet = 96.0;

  Future<void> _logout(BuildContext context) async {
    await Session.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tablet = isTablet(context);
    final heroH = tablet ? _heroHTablet : _heroH;
    // Card konten tablet dibuat siku (tanpa rounded) — cuma ponsel yang
    // menimpa ilustrasi dengan lengkungan ala card login.
    final radius = tablet ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(28));
    final card = Container(
      decoration: BoxDecoration(color: dark ? ZK.cardDark : Colors.white, borderRadius: radius),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            const _OfflineStrip(),
            Expanded(child: child),
          ],
        ),
      ),
    );
    return Stack(
      children: [
        // Ilustrasi mengisi seluruh background, konten menimpa di atasnya.
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/login_illustration.jpeg',
                  fit: BoxFit.cover, alignment: const Alignment(0, -0.35)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(
              height: heroH,
              width: double.infinity,
              child: tablet ? _tabletHeader(context) : _phoneHeader(context),
            ),
            // Tablet: konten dibatasi lebar & dipusatkan (ilustrasi tetap
            // kelihatan di kiri-kanan) alih-alih melebar penuh layar lanskap.
            Expanded(
              child: tablet
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: card,
                      ),
                    )
                  : card,
            ),
          ],
        ),
      ],
    );
  }

  // Header ponsel: ilustrasi login + logo/wordmark kiri, toggle tema +
  // logout kanan (tidak berubah dari sebelumnya).
  Widget _phoneHeader(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 10, 0),
          child: Row(
            children: [
              if (onMenuTap != null) ...[
                _headerIcon(icon: Icons.menu, tooltip: 'Menu', onTap: onMenuTap!),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.32),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/logo_splash.png', height: 24, width: 24),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ZONA KASIR',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                          height: 1.1)),
                  Text('Solusi Bisnis Anda',
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              const ThemeToggle(height: 30),
              const SizedBox(width: 8),
              _headerIcon(
                icon: Icons.logout,
                tooltip: 'Keluar',
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      );

  // Header tablet: banner aksen + judul halaman aktif (sidebar sudah bawa
  // branding/toggle/logout sendiri) + jam saat ini di kanan.
  Widget _tabletHeader(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/banner_header.jpeg', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color.fromRGBO(10, 37, 64, 0.93), Color.fromRGBO(10, 37, 64, 0.8)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (titleOverride != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(titleOverride!,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                        if (subtitleOverride != null)
                          Text(subtitleOverride!,
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                      ],
                    )
                  else
                    ValueListenableBuilder<int>(
                      valueListenable: activeTab,
                      builder: (_, tab, __) {
                        final t = tabTitles[tab.clamp(0, tabTitles.length - 1)];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.$1,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text(t.$2,
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        );
                      },
                    ),
                  const Spacer(),
                  Text(_now(),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      );

  static const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', "Jumat", 'Sabtu', 'Minggu'];
  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  String _now() {
    final n = DateTime.now();
    final jam = n.hour.toString().padLeft(2, '0');
    final menit = n.minute.toString().padLeft(2, '0');
    return '${_hari[n.weekday - 1]}, ${n.day} ${_bulan[n.month - 1]} ${n.year} · $jam:$menit';
  }

  // Chip lingkaran gelap di belakang ikon supaya tetap kontras di atas
  // ilustrasi terang maupun gelap.
  Widget _headerIcon(
          {required IconData icon, required String tooltip, required VoidCallback onTap}) =>
      Material(
        color: Colors.black.withValues(alpha: 0.32),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 46, minHeight: 46),
          icon: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

// Strip peringatan yang selalu terlihat selama koneksi terputus — muncul di
// semua halaman lewat HeroShell, bukan cuma toast sekali lewat.
class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip();
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: isOffline,
        builder: (_, offline, __) => AnimatedSize(
          duration: const Duration(milliseconds: 220),
          child: offline
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: ZK.amber700,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('OFFLINE — pakai data tersimpan terakhir',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2)),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      );
}

// Gambar produk dengan fallback ikon (padanan ProductImage + productImage()).
class ProductThumb extends StatelessWidget {
  final String? url;
  final double size;
  const ProductThumb({super.key, required this.url, this.size = 44});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
            color: dark ? ZK.bgDark : const Color(0xFFF8FAFC), borderRadius: r12),
        child: url == null
            ? Icon(Icons.inventory_2_outlined,
                size: size * 0.45, color: ZK.slate400)
            : ClipRRect(
                borderRadius: r12,
                child: Image.network(url!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        size: size * 0.45,
                        color: ZK.slate400)),
              ),
      );
  }
}

// ===== Kartu produk (padanan components/pos/ProductGrid.tsx) =====
class ProductCard extends StatelessWidget {
  final Produk produk;
  final VoidCallback onAdd;
  const ProductCard({super.key, required this.produk, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final habis = produk.stok <= 0;
    // Nada badge stok mengikuti web: habis=rose, <=10 amber, sisanya brand.
    final (bg, fg) = habis
        ? (ZK.rose50, ZK.rose)
        : produk.stok <= 10
            ? (ZK.amber50, ZK.amber700)
            : (ZK.brand50, ZK.brand700);

    return Opacity(
      opacity: habis ? 0.6 : 1,
      child: Material(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r12,
        child: InkWell(
          borderRadius: r12,
          onTap: habis ? null : onAdd,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: r12,
              border: Border.all(color: habis ? (dark ? ZK.lineDark : ZK.line) : ZK.brand200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child: produk.foto == null
                        ? const Icon(Icons.inventory_2_outlined,
                            size: 40, color: ZK.slate400)
                        : Image.network(produk.foto!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.inventory_2_outlined,
                                size: 40,
                                color: ZK.slate400)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(produk.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : ZK.slate900)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                      'Stok ${produk.stok}${produk.satuan != null ? ' ${produk.satuan}' : ''}',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(rupiah(produk.hargaJual),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: dark ? Colors.white : ZK.slate900)),
                    ),
                    if (!habis)
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                            color: ZK.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(9)),
                        child:
                            const Icon(Icons.add, size: 18, color: ZK.primary),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Skeleton grid saat produk pertama kali dimuat — terasa lebih cepat
// daripada layar kosong + spinner tengah.
class ProductGridSkeleton extends StatefulWidget {
  const ProductGridSkeleton({super.key});
  @override
  State<ProductGridSkeleton> createState() => _ProductGridSkeletonState();
}

class _ProductGridSkeletonState extends State<ProductGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  late final _fade = Tween(begin: 0.4, end: 0.85).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? Colors.white12 : const Color(0xFFE9EEF3);
    // Samakan jumlah kolom skeleton dengan grid produk asli (4 di tablet, 2
    // di ponsel), supaya ukuran kartu placeholder tidak beda dari aslinya.
    final tablet = isTablet(context);
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: tablet ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.80,
          ),
          itemCount: tablet ? 8 : 6,
          itemBuilder: (_, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? ZK.cardDark : Colors.white,
              borderRadius: r12,
              border: Border.all(color: dark ? ZK.lineDark : ZK.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: base, borderRadius: r12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 12, width: 90, color: base),
                const SizedBox(height: 6),
                Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                        color: base, borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 8),
                Container(height: 15, width: 70, color: base),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title, description;
  final IconData icon;
  const EmptyState(
      {super.key,
      required this.title,
      required this.description,
      this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: dark ? Colors.white38 : ZK.slate400),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : ZK.slate900)),
              const SizedBox(height: 4),
              Text(description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: dark ? Colors.white70 : ZK.slate500)),
            ],
          ),
        ),
    );
  }
}

// Banner sesi kasir belum dibuka — sekaligus jalan pintas membukanya.
class ShiftBanner extends StatelessWidget {
  final VoidCallback onBuka;
  const ShiftBanner({super.key, required this.onBuka});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onBuka,
        borderRadius: r12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: ZK.amber50,
            borderRadius: r12,
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: ZK.amber700),
              SizedBox(width: 8),
              Expanded(
                child: Text('Sesi kasir belum dibuka — ketuk untuk membuka.',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ZK.amber700)),
              ),
              Icon(Icons.chevron_right, size: 18, color: ZK.amber700),
            ],
          ),
        ),
      );
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onMinus, onPlus;
  const QtyStepper(
      {super.key,
      required this.qty,
      required this.onMinus,
      required this.onPlus});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
          borderRadius: r12,
          border: Border.all(color: dark ? ZK.lineDark : const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, onMinus, dark),
          SizedBox(
            width: 34,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : ZK.slate900)),
          ),
          _btn(Icons.add, onPlus, dark),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, bool dark) => InkWell(
        onTap: onTap,
        borderRadius: r12,
        child: SizedBox(
            height: 32,
            width: 32,
            child: Icon(icon, size: 15, color: dark ? Colors.white60 : ZK.muted)),
      );
}

// Kotak diskon nominal + preset persen (5/10/15/20), sama seperti web.
class DiskonBox extends StatefulWidget {
  final int subtotal, diskon;
  final ValueChanged<int> onChanged;
  const DiskonBox(
      {super.key,
      required this.subtotal,
      required this.diskon,
      required this.onChanged});
  @override
  State<DiskonBox> createState() => _DiskonBoxState();
}

class _DiskonBoxState extends State<DiskonBox> {
  late final TextEditingController _c =
      TextEditingController(text: widget.diskon > 0 ? '${widget.diskon}' : '');
  late bool _open = widget.diskon > 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(int v) {
    _c.text = v > 0 ? '$v' : '';
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dark ? ZK.primary.withValues(alpha: 0.14) : const Color(0xFFECFEFF),
        borderRadius: r12,
        border: Border.all(color: dark ? ZK.primary.withValues(alpha: 0.4) : const Color(0xFF67E8F9)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Container(
                  height: 26,
                  width: 26,
                  decoration: const BoxDecoration(
                      color: ZK.brand100, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.percent, size: 14, color: ZK.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Diskon',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : const Color(0xFF334155))),
                ),
                if (widget.diskon > 0)
                  TextButton(
                    onPressed: () => _set(0),
                    child: const Text('Hapus',
                        style: TextStyle(fontSize: 12, color: ZK.rose)),
                  ),
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    color: dark ? Colors.white54 : ZK.slate400),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: TextField(
                controller: _c,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                inputFormatters: [RupiahInputFormatter()],
                onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                decoration: InputDecoration(
                  prefixText: 'Rp  ',
                  prefixStyle: TextStyle(color: dark ? Colors.white70 : ZK.ink),
                  hintText: '0',
                  hintStyle: TextStyle(color: dark ? Colors.white38 : ZK.slate400),
                  filled: true,
                  fillColor: dark ? ZK.cardDark : Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: r12,
                      borderSide: BorderSide(color: dark ? ZK.lineDark : const Color(0xFFE2E8F0))),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: r12,
                      borderSide: BorderSide(color: ZK.primary, width: 1.6)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final p in [5, 10, 15, 20])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _persenBtn(p, dark),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _persenBtn(int p, bool dark) {
    final nilai = (widget.subtotal * p / 100).round();
    final aktif = widget.subtotal > 0 && widget.diskon == nilai;
    return InkWell(
      onTap: () => _set(nilai),
      borderRadius: r12,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: aktif ? ZK.primary : (dark ? ZK.cardDark : Colors.white),
          borderRadius: r12,
          border: Border.all(
              color: aktif ? ZK.primary : (dark ? ZK.lineDark : const Color(0xFFE2E8F0))),
        ),
        child: Text('$p%',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: aktif ? Colors.white : (dark ? Colors.white70 : ZK.muted))),
      ),
    );
  }
}

// Rincian tagihan: subtotal, potongan, pajak, total.
class TotalCard extends StatelessWidget {
  final Tagihan t;
  final TaxSetting? tax;
  const TotalCard({super.key, required this.t, required this.tax});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50, borderRadius: r14),
      child: Column(
        children: [
          _line('Subtotal', rupiah(t.subtotal), dark),
          if (t.diskon > 0) _line('Potongan', '- ${rupiah(t.diskon)}', dark),
          if (t.voucher > 0) _line('Voucher', '- ${rupiah(t.voucher)}', dark),
          if (t.ppn > 0) _line('PPN ${tax?.ppnPersen}%', rupiah(t.ppn), dark),
          if (t.service > 0)
            _line('Service ${tax?.servicePersen}%', rupiah(t.service), dark),
          Divider(height: 16, color: dark ? ZK.lineDark : ZK.brand200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total tagihan',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white70 : ZK.brand700)),
              Text(rupiah(t.total),
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: dark ? Colors.white : ZK.ink)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String l, String v, bool dark) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontSize: 13, color: dark ? Colors.white60 : ZK.muted)),
            Text(v,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : ZK.slate900)),
          ],
        ),
      );
}

class KembalianBox extends StatelessWidget {
  final int selisih;
  const KembalianBox({super.key, required this.selisih});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final kurang = selisih < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: kurang
              ? (dark ? ZK.rose.withValues(alpha: 0.16) : ZK.rose50)
              : (dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50),
          borderRadius: r12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(kurang ? 'Kurang' : 'Kembalian',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kurang ? ZK.rose : (dark ? Colors.white70 : ZK.brand700))),
          Text(rupiah(selisih.abs()),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: kurang ? ZK.rose : (dark ? Colors.white : ZK.brand700))),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context,
    {required String title,
    required String message,
    bool danger = false}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: r14),
      title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      content: Text(message, style: const TextStyle(fontSize: 14)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal', style: TextStyle(color: ZK.muted))),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          style: FilledButton.styleFrom(
              backgroundColor: danger ? ZK.rose : ZK.primary),
          child: const Text('Ya, lanjutkan'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
