import '_util.dart';

class JenisBayar {
  final int id;
  final String nama;
  JenisBayar.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        nama = '${j['NAMA'] ?? ''}';
  bool get isQris => nama.toUpperCase().contains('QRIS');
  bool get isTransfer => nama.toUpperCase().contains('TRANSFER');
  bool get isTunai => !isQris && !isTransfer;
}

class Qris {
  final String? merchantName, nmid, imageUrl;
  final bool isActive;
  Qris.fromJson(Map<String, dynamic> j)
      : merchantName = s(j['MERCHANT_NAME']),
        nmid = s(j['NMID']),
        imageUrl = s(j['IMAGE_URL']),
        isActive = j['IS_ACTIVE'] == true;
  bool get siap => isActive && imageUrl != null;
}

class TaxSetting {
  final bool ppnOn, serviceOn;
  final num ppnPersen, servicePersen;
  TaxSetting.fromJson(Map<String, dynamic> j)
      : ppnOn = j['PPN_ENABLED'] == true,
        serviceOn = j['SERVICE_ENABLED'] == true,
        ppnPersen = j['PPN_PERSEN'] ?? 0,
        servicePersen = j['SERVICE_PERSEN'] ?? 0;
}
