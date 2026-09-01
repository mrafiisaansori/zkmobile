import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Padanan Api.modifierGroups/createModifierGroup/updateModifierGroup/
// deleteModifierGroup/addModifierOption/deleteModifierOption dari lib/api.dart lama.
class VarianRepository {
  Future<List<ModifierGroup>> groups({String? search, int page = 1}) async =>
      apiList(await apiGet('/modifier/groups'), ModifierGroup.fromJson);

  Future<ModifierGroup> create(String nama, String tipe, bool wajib) async =>
      ModifierGroup.fromJson(
          await apiPost('/modifier/groups', {'nama': nama, 'tipe': tipe, 'wajib': wajib}));

  Future<ModifierGroup> update(int id, String nama, String tipe, bool wajib) async =>
      ModifierGroup.fromJson(await apiPut(
          '/modifier/groups/$id', {'nama': nama, 'tipe': tipe, 'wajib': wajib}));

  Future<void> delete(int id) async => apiDelete('/modifier/groups/$id');

  Future<void> addOption(int groupId, String nama, int harga) async =>
      apiPost('/modifier/groups/$groupId/options', {'nama': nama, 'harga': harga});

  Future<void> deleteOption(int id) async => apiDelete('/modifier/options/$id');
}
