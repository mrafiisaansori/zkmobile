import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../network/api_client.dart';
import '../theme/formatters.dart';

// Cetak struk ke printer thermal Bluetooth (classic SPP, ESC/POS text mode) —
// padanan fitur "Cetak thermal" di web yang pakai Web Bluetooth.
class ReceiptLine {
  final String name;
  final int qty;
  final int price;
  final int subtotal;
  final String? modifier;
  ReceiptLine(this.name, this.qty, this.price, this.subtotal, [this.modifier]);
}

class PrinterService {
  static final bluetooth = BlueThermalPrinter.instance;

  static Future<List<BluetoothDevice>> pairedDevices() async {
    // Android 12+ butuh izin runtime khusus, beda dari BLUETOOTH lama.
    await [Permission.bluetoothConnect, Permission.bluetoothScan].request();
    try {
      return await bluetooth.getBondedDevices();
    } catch (_) {
      return [];
    }
  }

  static Future<void> printReceipt(
    BluetoothDevice device, {
    required String noNota,
    required String tanggal,
    required List<ReceiptLine> items,
    required int total,
    int? bayar,
    int? kembalian,
    String? namaToko,
    String? alamatToko,
    String? kasir,
    String? metode,
    String? status,
    bool showBranding = false,
  }) async {
    final connected = await bluetooth.isConnected ?? false;
    if (!connected) {
      await bluetooth.connect(device);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    const divider = '--------------------------------';
    await bluetooth.printCustom(namaToko ?? 'Zona Kasir', 2, 1);
    if (alamatToko != null && alamatToko.isNotEmpty) {
      await bluetooth.printCustom(alamatToko, 0, 1);
    }
    await bluetooth.printCustom(divider, 0, 1);
    await bluetooth.printLeftRight('No', noNota, 0);
    await bluetooth.printLeftRight('Tanggal', tanggal, 0);
    if (kasir != null && kasir.isNotEmpty) {
      await bluetooth.printLeftRight('Kasir', kasir, 0);
    }
    await bluetooth.printCustom(divider, 0, 1);
    var subtotal = 0;
    for (final it in items) {
      subtotal += it.subtotal;
      await bluetooth.printCustom(it.name, 0, 0);
      if (it.modifier != null && it.modifier!.isNotEmpty) {
        await bluetooth.printCustom('  ${it.modifier}', 0, 0);
      }
      await bluetooth.printLeftRight(
          '${it.qty} x ${rupiahPlain(it.price)}', rupiahPlain(it.subtotal), 0);
    }
    await bluetooth.printCustom(divider, 0, 1);
    if (subtotal != total) await bluetooth.printLeftRight('Subtotal', rupiahPlain(subtotal), 0);
    await bluetooth.printLeftRight('TOTAL', rupiahPlain(total), 1);
    if (bayar != null) await bluetooth.printLeftRight('Bayar', rupiahPlain(bayar), 0);
    if (kembalian != null) {
      await bluetooth.printLeftRight('Kembali', rupiahPlain(kembalian), 0);
    }
    if (metode != null && metode.isNotEmpty) {
      await bluetooth.printLeftRight('Metode', metode, 0);
    }
    if (status != null && status.isNotEmpty) {
      await bluetooth.printLeftRight('Status', status, 0);
    }
    await bluetooth.printCustom(divider, 0, 1);
    await bluetooth.printCustom('Terima kasih atas kunjungan Anda', 0, 1);
    if (showBranding) {
      await bluetooth.printCustom('Powered by Zona Kasir', 0, 1);
      await bluetooth.printCustom('zonakasir.com', 0, 1);
    }
    await bluetooth.printNewLine();
    await bluetooth.printNewLine();
    await bluetooth.paperCut();
  }
}

// Struktur ringan supaya sheet pemilihan printer tidak perlu tahu bentuk
// datanya berasal dari CartItem (POS) atau DetailPenjualan (Riwayat).
class PrintableReceipt {
  final String noNota, tanggal;
  final List<ReceiptLine> items;
  final int total;
  final int? bayar, kembalian;
  final String? kasir, metode, status;
  PrintableReceipt({
    required this.noNota,
    required this.tanggal,
    required this.items,
    required this.total,
    this.bayar,
    this.kembalian,
    this.kasir,
    this.metode,
    this.status,
  });
}

Future<Map<String, String?>> tokoIdentitas() async {
  try {
    final d = await apiGet('/identitas') as Map<String, dynamic>?;
    return {
      'nama': d?['NAMA'] as String?,
      'alamat': d?['ALAMAT'] as String?,
    };
  } catch (_) {
    return {};
  }
}
