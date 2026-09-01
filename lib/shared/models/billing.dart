import '_util.dart';

// ===== Langganan / billing (padanan src/types/index.ts Billing dkk) =====
class SubscriptionSetting {
  final int priceMonthly, price3Months, price6Months, priceYearly, priceBusinessMonthly, priceBusinessYearly;
  SubscriptionSetting.fromJson(Map<String, dynamic> j)
      : priceMonthly = i(j['PRICE_MONTHLY']),
        price3Months = i(j['PRICE_3_MONTHS']),
        price6Months = i(j['PRICE_6_MONTHS']),
        priceYearly = i(j['PRICE_YEARLY']),
        priceBusinessMonthly = i(j['PRICE_BUSINESS_MONTHLY']),
        priceBusinessYearly = i(j['PRICE_BUSINESS_YEARLY']);
}

class SubscriptionPayment {
  final int id, totalBayar;
  final String paket, targetPlan, status;
  final String? createdAt, snapRedirectUrl;
  SubscriptionPayment.fromJson(Map<String, dynamic> j)
      : id = i(j['ID']),
        paket = '${j['PAKET'] ?? ''}',
        targetPlan = '${j['TARGET_PLAN'] ?? ''}',
        totalBayar = i(j['TOTAL_BAYAR']),
        status = '${j['STATUS'] ?? ''}',
        createdAt = s(j['CREATED_AT']),
        snapRedirectUrl = s(j['SNAP_REDIRECT_URL']);
}

class Billing {
  final String plan;
  final String? proExpiresAt;
  final List<SubscriptionPayment> payments;
  final SubscriptionPayment? latest;
  Billing.fromJson(Map<String, dynamic> j)
      : plan = '${j['plan'] ?? 'FREE'}',
        proExpiresAt = s(j['pro_expires_at']),
        payments = ((j['payments'] as List?) ?? [])
            .map((e) => SubscriptionPayment.fromJson(e as Map<String, dynamic>))
            .toList(),
        latest = j['latest'] == null ? null : SubscriptionPayment.fromJson(j['latest'] as Map<String, dynamic>);
}
