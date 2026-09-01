import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

// Bungkus endpoint /member (versi admin, bukan picker kasir) — padanan
// Api.membersAdmin()/createMember()/updateMember()/deleteMember() lama.
class MemberRepository {
  Future<List<Member>> fetchPage({String? search, int page = 1}) async =>
      apiList<Member>(
          await apiGet('/member', {
            'search': (search ?? '').isEmpty ? null : search,
            'status': null,
            'limit': 100,
          }),
          Member.fromJson);

  Future<Member> create(Map<String, dynamic> data) async =>
      Member.fromJson(await apiPost('/member', data));

  Future<Member> update(int id, Map<String, dynamic> data) async =>
      Member.fromJson(await apiPut('/member/$id', data));

  Future<void> delete(Member item) async => apiDelete('/member/${item.id}');
}
