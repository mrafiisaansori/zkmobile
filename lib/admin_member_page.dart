import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'main.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

// Padanan src/app/admin/member/page.tsx — CRUD member/pelanggan. Fitur PRO:
// FREE cuma dapat pesan upgrade, sama seperti _requirePro di pos_page.dart.
class AdminMemberPage extends StatefulWidget {
  const AdminMemberPage({super.key});
  @override
  State<AdminMemberPage> createState() => _AdminMemberPageState();
}

class _AdminMemberPageState extends State<AdminMemberPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Member> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (Session.isPro) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await Api.membersAdmin(search: _search.text);
      if (mounted) setState(() => _data = r);
    } catch (e) {
      if (mounted) toastError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _openForm({Member? item}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemberFormSheet(initial: item),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await Api.createMember(result);
        if (mounted) toastOk(context, 'Member ditambahkan');
      } else {
        await Api.updateMember(item.id, result);
        if (mounted) toastOk(context, 'Member diperbarui');
      }
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  Future<void> _hapus(Member item) async {
    final ok = await confirmDialog(context,
        title: 'Hapus member?', message: 'Hapus member "${item.nama}"?', danger: true);
    if (!ok) return;
    try {
      await Api.deleteMember(item.id);
      if (mounted) toastOk(context, 'Member dihapus');
      _load();
    } catch (e) {
      if (mounted) toastError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : ZK.ink;
    final muted = dark ? Colors.white60 : ZK.slate500;
    final lineColor = dark ? ZK.lineDark : ZK.line;

    if (!Session.isPro) {
      return SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_outlined, size: 44, color: ZK.amber700),
                const SizedBox(height: 14),
                Text('Fitur Member tersedia mulai paket PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
                const SizedBox(height: 8),
                Text(
                    'Kelola data pelanggan, riwayat transaksi, dan pilih member langsung dari halaman kasir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: muted)),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _search,
                      onChanged: _onSearch,
                      style: TextStyle(color: dark ? Colors.white : ZK.ink),
                      decoration: InputDecoration(
                        hintText: 'Cari nama / no. HP / kode...',
                        hintStyle: TextStyle(color: dark ? Colors.white38 : ZK.slate400, fontSize: 14),
                        prefixIcon: Icon(Icons.search, size: 20, color: dark ? Colors.white54 : ZK.slate400),
                        filled: true,
                        fillColor: dark ? ZK.cardDark : Colors.white,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: r12, borderSide: BorderSide(color: dark ? ZK.lineDark : ZK.brand200)),
                        focusedBorder: const OutlineInputBorder(
                            borderRadius: r12, borderSide: BorderSide(color: ZK.primary, width: 1.6)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                    style: FilledButton.styleFrom(
                        backgroundColor: ZK.primary,
                        shape: const RoundedRectangleBorder(borderRadius: r12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: ZK.primary))
                : _data.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        title: 'Belum ada member',
                        description: 'Tambah data pelanggan tetap Anda.')
                    : RefreshIndicator(
                        color: ZK.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _data.length,
                          itemBuilder: (_, i) {
                            final m = _data[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: dark ? ZK.cardDark : Colors.white,
                                borderRadius: r14,
                                border: Border.all(color: lineColor),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                        color:
                                            dark ? ZK.primary.withValues(alpha: 0.16) : ZK.brand50,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.people_outline, color: ZK.primary, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.nama,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                                        const SizedBox(height: 2),
                                        Text([if (m.kode != null) m.kode!, m.noHp].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: muted)),
                                        if (m.status == 0) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: ZK.rose50, borderRadius: BorderRadius.circular(999)),
                                            child: const Text('Nonaktif',
                                                style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: ZK.rose)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _openForm(item: m),
                                          icon: Icon(Icons.edit_outlined,
                                              size: 18, color: dark ? Colors.white60 : ZK.slate500)),
                                      IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _hapus(m),
                                          icon: const Icon(Icons.delete_outline, size: 18, color: ZK.rose)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MemberFormSheet extends StatefulWidget {
  final Member? initial;
  const _MemberFormSheet({this.initial});
  @override
  State<_MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends State<_MemberFormSheet> {
  late final _nama = TextEditingController(text: widget.initial?.nama ?? '');
  late final _noHp = TextEditingController(text: widget.initial?.noHp ?? '');
  late final _email = TextEditingController(text: widget.initial?.email ?? '');
  late final _alamat = TextEditingController(text: widget.initial?.alamat ?? '');
  late bool _aktif = (widget.initial?.status ?? 1) == 1;

  @override
  void dispose() {
    _nama.dispose();
    _noHp.dispose();
    _email.dispose();
    _alamat.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nama.text.trim().isEmpty) {
      toastError(context, 'Nama member wajib diisi');
      return;
    }
    if (_noHp.text.trim().isEmpty) {
      toastError(context, 'Nomor HP wajib diisi');
      return;
    }
    Navigator.pop(context, {
      'nama': _nama.text.trim(),
      'no_hp': _noHp.text.trim(),
      'email': _email.text.trim(),
      'alamat': _alamat.text.trim(),
      'status': _aktif ? 1 : 0,
    });
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeader(
                title: widget.initial == null ? 'Tambah Member' : 'Ubah Member',
                subtitle: 'Data pelanggan',
                icon: Icons.people_outline,
              ),
              Divider(height: 1, color: dark ? ZK.lineDark : ZK.brand100),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const FieldLabel('Nama member'),
                      TextField(
                          controller: _nama,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. Budi Santoso', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('No. HP'),
                      TextField(
                          controller: _noHp,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('081234567890', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Email (opsional)'),
                      TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('mis. member@email.com', dark: dark)),
                      const SizedBox(height: 14),
                      const FieldLabel('Alamat (opsional)'),
                      TextField(
                          controller: _alamat,
                          style: TextStyle(color: dark ? Colors.white : ZK.ink),
                          decoration: sheetInput('Alamat member', dark: dark)),
                      const SizedBox(height: 14),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _aktif,
                        onChanged: (v) => setState(() => _aktif = v),
                        activeThumbColor: ZK.primary,
                        title: Text('Aktif',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : ZK.ink)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: ZK.primary,
                              shape: const RoundedRectangleBorder(borderRadius: r12)),
                          child: const Text('Simpan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
