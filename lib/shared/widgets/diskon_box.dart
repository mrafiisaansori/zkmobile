import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/formatters.dart';

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
                          color: dark ? Colors.white : ZK.slate700)),
                ),
                if (widget.diskon > 0)
                  TextButton(
                    onPressed: () => _set(0),
                    child: const Text('Hapus',
                        style: TextStyle(fontSize: 12, color: ZK.rose)),
                  ),
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    color: dark ? Colors.white60 : ZK.slate400),
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
                  hintStyle: TextStyle(color: dark ? Colors.white60 : ZK.slate500),
                  filled: true,
                  fillColor: dark ? ZK.cardDark : Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: r12,
                      borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.slate200)),
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
              color: aktif ? ZK.primary : (dark ? ZK.lineDark : ZK.slate200)),
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
