import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../cubit/cart_cubit.dart';

// Baris pilih/ganti member (PRO) — dipakai sheet pembayaran dan form open
// bill. Member dibaca dari CartCubit, jadi langsung berubah setelah dipilih.
class MemberRow extends StatelessWidget {
  final VoidCallback? onTap;
  const MemberRow({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final m = context.watch<CartCubit>().state.member;
    return InkWell(
      onTap: onTap,
      borderRadius: r12,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: dark ? ZK.primary.withValues(alpha: 0.14) : ZK.brand50,
          borderRadius: r12,
          border: Border.all(color: dark ? ZK.primary.withValues(alpha: 0.35) : ZK.brand100),
        ),
        child: Row(
          children: [
            Icon(m == null ? Icons.person_add_alt : Icons.person, size: 20, color: ZK.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m?.nama ?? 'Tanpa member',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: dark ? Colors.white : ZK.ink)),
                  Text(m == null ? 'Ketuk untuk pilih member' : 'Ketuk untuk ganti atau lepas member',
                      style: TextStyle(fontSize: 12, color: dark ? Colors.white60 : ZK.slate600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: dark ? Colors.white60 : ZK.slate400),
          ],
        ),
      ),
    );
  }
}
