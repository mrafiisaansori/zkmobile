import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/printer/printer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import 'sheet_common.dart';

// ===== Pilih printer Bluetooth untuk cetak struk =====
class PrinterPickerSheet extends StatefulWidget {
  final PrintableReceipt receipt;
  const PrinterPickerSheet({super.key, required this.receipt});
  @override
  State<PrinterPickerSheet> createState() => _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends State<PrinterPickerSheet> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true, _printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await PrinterService.pairedDevices();
    if (mounted) {
      setState(() {
        _devices = d;
        _loading = false;
      });
    }
  }

  Future<void> _print(BluetoothDevice device) async {
    setState(() => _printing = true);
    try {
      final id = await tokoIdentitas();
      await PrinterService.printReceipt(
        device,
        noNota: widget.receipt.noNota,
        tanggal: widget.receipt.tanggal,
        items: widget.receipt.items,
        total: widget.receipt.total,
        bayar: widget.receipt.bayar,
        kembalian: widget.receipt.kembalian,
        namaToko: id['nama'],
        alamatToko: id['alamat'],
        kasir: widget.receipt.kasir,
        metode: widget.receipt.metode,
        status: widget.receipt.status,
        showBranding: !Session.isPro,
      );
      if (!mounted) return;
      Navigator.pop(context);
      toastOk(context, 'Struk terkirim ke printer');
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: sheetBox(dark),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
                title: 'Cetak Struk',
                subtitle: 'Pilih printer Bluetooth yang sudah dipasangkan',
                icon: Icons.print_outlined),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: ZK.primary)),
              )
            else if (_devices.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                    icon: Icons.bluetooth_disabled,
                    title: 'Belum ada printer terpasang',
                    description: 'Pasangkan printer Bluetooth lewat pengaturan HP dulu, lalu coba lagi.'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _devices.length,
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    return ListTile(
                      enabled: !_printing,
                      leading: const Icon(Icons.print_outlined, color: ZK.primary),
                      title: Text(d.name ?? 'Printer', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(d.address ?? ''),
                      onTap: () => _print(d),
                    );
                  },
                ),
              ),
            if (_printing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Mencetak...', style: TextStyle(color: dark ? Colors.white60 : ZK.slate500)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
