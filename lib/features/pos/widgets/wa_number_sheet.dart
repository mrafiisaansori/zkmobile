import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import 'sheet_common.dart';

// ===== Kirim struk via WhatsApp — dipakai di POS & Riwayat detail =====
class WaNumberSheet extends StatefulWidget {
  const WaNumberSheet({super.key});
  @override
  State<WaNumberSheet> createState() => _WaNumberSheetState();
}

class _WaNumberSheetState extends State<WaNumberSheet> {
  final _nomor = TextEditingController();

  @override
  void dispose() {
    _nomor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: sheetBox(dark),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Kirim Struk via WhatsApp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: dark ? Colors.white : ZK.ink)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nomor,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  style: TextStyle(color: dark ? Colors.white : ZK.ink),
                  decoration: sheetInput('081234567890', dark: dark),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      final n = _nomor.text.replaceAll(RegExp(r'\D'), '');
                      if (n.length < 9) {
                        toastError(context, 'Nomor WhatsApp belum valid');
                        return;
                      }
                      Navigator.pop(context, n);
                    },
                    style: FilledButton.styleFrom(
                        backgroundColor: ZK.primary, shape: const RoundedRectangleBorder(borderRadius: r12)),
                    child: const Text('Kirim', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
