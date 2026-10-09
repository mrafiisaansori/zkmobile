import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/pos_repository.dart';
import '../../../shared/widgets/sheet_common.dart';

// ===== Pilih member (padanan MemberPickerModal.tsx) =====
class MemberPickerSheet extends StatefulWidget {
  final Member? selected;
  const MemberPickerSheet({super.key, this.selected});
  @override
  State<MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<MemberPickerSheet> {
  final _repo = PosRepository();
  final _q = TextEditingController();
  List<Member> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _repo.member(search: _q.text);
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: sheetBox(dark),
        child: Column(
          children: [
            const SheetHeader(
                title: 'Pilih Member',
                subtitle: 'Member/customer untuk transaksi ini',
                icon: Icons.people_outline),
            Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _q,
                onSubmitted: (_) => _load(),
                style: TextStyle(color: dark ? Colors.white : ZK.ink),
                decoration: sheetInput('Cari nama / no HP...', dark: dark).copyWith(
                  prefixIcon: const Icon(Icons.search, size: 20, color: ZK.slate400),
                  suffixIcon: IconButton(
                      onPressed: _load, icon: const Icon(Icons.arrow_forward, size: 18, color: ZK.primary)),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                  : _data.isEmpty
                      ? const EmptyState(
                          title: 'Member tidak ditemukan',
                          description: 'Tambah member lewat aplikasi web.')
                      // Material transparan: ListTile butuh Material terdekat di
                      // atas latar sheet, kalau tidak efek ketuknya tak terlihat.
                      : Material(
                          type: MaterialType.transparency,
                          child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final m = _data[i];
                            final aktif = widget.selected?.id == m.id;
                            return ListTile(
                              onTap: () => Navigator.pop(context, m),
                              shape: const RoundedRectangleBorder(borderRadius: r12),
                              leading: CircleAvatar(
                                backgroundColor: softBg(ZK.primary, ZK.brand50, Theme.of(context).brightness == Brightness.dark),
                                child: Text(m.nama.isEmpty ? '?' : m.nama[0].toUpperCase(),
                                    style: const TextStyle(color: ZK.primary, fontWeight: FontWeight.w800)),
                              ),
                              title:
                                  Text(m.nama, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              subtitle: Text('${m.noHp}${m.kode != null ? ' · ${m.kode}' : ''}',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: aktif ? const Icon(Icons.check_circle, color: ZK.primary) : null,
                            );
                          },
                        ),
                        ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: OutlinedButton(
                  // id -1 = sinyal "tanpa member" ke pemanggil.
                  onPressed: () => Navigator.pop(context, Member.fromJson({'ID': -1, 'NAMA': ''})),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: dark ? Colors.white70 : ZK.slate500,
                      side: BorderSide(color: dark ? ZK.lineDark : ZK.line),
                      shape: const RoundedRectangleBorder(borderRadius: r12)),
                  child: const Text('Tanpa member'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
