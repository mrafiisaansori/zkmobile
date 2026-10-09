import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// Perangkat tampilan laporan admin (dashboard, keuangan, transaksi, closing).
// Gaya "buku besar": satu angka utama per halaman, rincian sebagai baris
// bergaris tipis dengan angka rata kolom, satu aksen biru (ZK.primary).
// Warna status (rose/amber/hijau) hanya untuk keadaan nyata, bukan hiasan.

const tabular = [FontFeature.tabularFigures()];
const okGreen = Color(0xFF047857);

class RColors {
  final Color fg, muted, line, card, soft;
  RColors(bool dark)
      : fg = dark ? Colors.white : ZK.ink,
        muted = dark ? Colors.white60 : ZK.slate600,
        line = dark ? ZK.lineDark : ZK.line,
        card = dark ? ZK.cardDark : Colors.white,
        soft = dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50;
  static RColors of(BuildContext c) => RColors(Theme.of(c).brightness == Brightness.dark);
}

// Tanggal lokal (locale id) tanpa paket intl.
String dateLabel(BuildContext c, DateTime d) => MaterialLocalizations.of(c).formatMediumDate(d);
String rangeLabel(BuildContext c, DateTimeRange r) {
  final loc = MaterialLocalizations.of(c);
  if (DateUtils.isSameDay(r.start, r.end)) return loc.formatMediumDate(r.start);
  return '${loc.formatShortMonthDay(r.start)} – ${loc.formatShortMonthDay(r.end)} ${loc.formatYear(r.end)}';
}

// Permukaan kartu tunggal: garis tipis, tanpa bayangan.
class RCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const RCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: c.card, borderRadius: r14, border: Border.all(color: c.line)),
      child: child,
    );
  }
}

// Kartu berjudul: judul menyatakan pertanyaan yang dijawab, keterangan opsional.
class RSection extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;
  final Widget child;
  const RSection({super.key, required this.title, this.caption, this.trailing, required this.child});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    return RCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.fg)),
                    if (caption != null) ...[
                      const SizedBox(height: 2),
                      Text(caption!, style: TextStyle(fontSize: 12, color: c.muted)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// Angka utama halaman + deret fakta pendukung di bawah garis aksen.
class RHero extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final List<(String, String)> facts;
  final String? footnote;
  const RHero(
      {super.key, required this.label, required this.value, this.valueColor, this.facts = const [], this.footnote});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    return RCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 34,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: valueColor ?? c.fg,
                    fontFeatures: tabular)),
          ),
          // Satu-satunya aksen: garis pendek biru di bawah angka utama.
          Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              width: 32,
              height: 3,
              decoration: BoxDecoration(color: ZK.primary, borderRadius: BorderRadius.circular(2))),
          if (facts.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < facts.length; i++) ...[
                  if (i > 0) Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 12), color: c.line),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(facts[i].$1,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: c.muted)),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(facts[i].$2,
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: c.fg, fontFeatures: tabular)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          if (footnote != null) ...[
            const SizedBox(height: 14),
            Text(footnote!, style: TextStyle(fontSize: 11.5, height: 1.4, color: c.muted)),
          ],
        ],
      ),
    );
  }
}

// Satu baris buku besar.
class RLine {
  final String label;
  final String value;
  final String? sub;
  final bool strong;
  final Color? valueColor;
  final Widget? leading;
  final VoidCallback? onTap;
  const RLine(this.label, this.value,
      {this.sub, this.strong = false, this.valueColor, this.leading, this.onTap});
}

// Daftar baris bergaris tipis. Baris `strong` (mis. hasil rumus) diberi
// garis atas lebih tegas, seperti baris total di laporan keuangan.
class RLedger extends StatelessWidget {
  final List<RLine> lines;
  const RLedger(this.lines, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++)
          InkWell(
            onTap: lines[i].onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(
                        top: BorderSide(
                            color: lines[i].strong ? c.fg.withValues(alpha: 0.5) : c.line,
                            width: lines[i].strong ? 1.2 : 1)),
              ),
              child: Row(
                children: [
                  if (lines[i].leading != null) ...[lines[i].leading!, const SizedBox(width: 10)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lines[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: lines[i].strong ? FontWeight.w700 : FontWeight.w500,
                                color: c.fg)),
                        if (lines[i].sub != null)
                          Text(lines[i].sub!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11.5, color: c.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(lines[i].value,
                      style: TextStyle(
                          fontSize: lines[i].strong ? 15 : 13.5,
                          fontWeight: lines[i].strong ? FontWeight.w800 : FontWeight.w600,
                          color: lines[i].valueColor ?? c.fg,
                          fontFeatures: tabular)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Porsi tiap baris terhadap total (per metode bayar, per kasir): nama, nilai,
// persen, dan batang tipis. Menjawab "dari mana uangnya datang".
class RShareList extends StatelessWidget {
  final List<(String label, String sub, int value)> items;
  final String Function(int) format;
  const RShareList({super.key, required this.items, required this.format});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    final total = items.fold<int>(0, (s, e) => s + e.$3);
    final sorted = [...items]..sort((a, b) => b.$3.compareTo(a.$3));
    return Column(
      children: [
        for (final e in sorted)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: e.$1,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.fg)),
                          TextSpan(text: '  ${e.$2}', style: TextStyle(fontSize: 11.5, color: c.muted)),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(format(e.$3),
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700, color: c.fg, fontFeatures: tabular)),
                    SizedBox(
                      width: 46,
                      child: Text(total == 0 ? '0%' : '${(e.$3 * 100 / total).round()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 11.5, color: c.muted, fontFeatures: tabular)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : e.$3 / total,
                    minHeight: 4,
                    backgroundColor: c.soft,
                    color: ZK.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// Kalimat kosong yang menyebut sebabnya.
class RNote extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  const RNote(this.text, {super.key, this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: color ?? c.muted), const SizedBox(width: 8)],
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color ?? c.muted))),
        ],
      ),
    );
  }
}

// Tombol periode: ikon kalender + tanggal lokal, setinggi 46.
class RDateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const RDateButton({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(borderRadius: r12, side: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
      child: InkWell(
        borderRadius: r12,
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: dark ? Colors.white : ZK.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: dark ? Colors.white : ZK.primary)),
                ),
                Icon(Icons.expand_more, size: 18, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Pilihan 2-3 opsi bersebelahan (Hari/Rentang, Sah/Batal).
class RSegmented<T> extends StatelessWidget {
  final List<(String, T)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final double? width;
  const RSegmented({super.key, required this.options, required this.selected, required this.onChanged, this.width});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: c.card, borderRadius: r12, border: Border.all(color: dark ? ZK.lineDark : ZK.brand200)),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: InkWell(
                borderRadius: r12,
                onTap: () => onChanged(o.$2),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: o.$2 == selected ? ZK.primary : null, borderRadius: r12),
                  child: Text(o.$1,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: o.$2 == selected ? Colors.white : c.muted)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Label status kecil untuk keadaan nyata (stok, sesi, selisih).
class RTag extends StatelessWidget {
  final String text;
  final Color color;
  const RTag(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

// Error dengan sebab + aksi.
class RError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const RError({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final c = RColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 32, color: c.muted),
            const SizedBox(height: 10),
            Text('Laporan gagal dimuat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.fg)),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: c.muted)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Muat ulang'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: ZK.primary,
                  minimumSize: const Size(0, 44),
                  side: const BorderSide(color: ZK.brand200),
                  shape: const RoundedRectangleBorder(borderRadius: r12)),
            ),
          ],
        ),
      ),
    );
  }
}
