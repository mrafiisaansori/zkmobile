import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.subscriptionBilling/subscriptionSetting/createSubscriptionPayment
// (lib/api.dart lama) — cuma membungkus request/response mentah, tanpa logika
// bisnis.
class LanggananRepository {
  Future<Billing> billing() async =>
      Billing.fromJson(await apiGet('/subscription/billing') as Map<String, dynamic>);

  Future<SubscriptionSetting> setting() async =>
      SubscriptionSetting.fromJson(await apiGet('/subscription/setting') as Map<String, dynamic>);

  // Midtrans Snap — buat tagihan, balik SNAP_REDIRECT_URL buat dimuat di
  // WebView in-app (padanan createPayment di subscriptionService.js backend).
  Future<SubscriptionPayment> createPayment(String plan, String paket) async =>
      SubscriptionPayment.fromJson(
          await apiPost('/subscription/payment', {'plan': plan, 'paket': paket}) as Map<String, dynamic>);
}
