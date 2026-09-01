import '../../../../core/network/api_client.dart';

// Padanan Api.merchantMe/updateMerchantSlug/identitas/uploadIdentitasBanner
// (lib/api.dart lama) — cuma membungkus request/response mentah, tanpa logika
// bisnis.
class KatalogRepository {
  Future<Map<String, dynamic>> merchantMe() async =>
      await apiGet('/merchant/me') as Map<String, dynamic>;

  Future<Map<String, dynamic>> identitas() async =>
      await apiGet('/identitas') as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateSlug(String slug) async =>
      await apiPut('/merchant/me', {'slug': slug}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> uploadBanner(String filePath) async =>
      await apiPostMultipart('/identitas/banner', {}, filePath: filePath, fileField: 'banner')
          as Map<String, dynamic>;
}
