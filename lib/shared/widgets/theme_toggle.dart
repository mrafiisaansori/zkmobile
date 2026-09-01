import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_cubit.dart';

// Toggle tema matahari/bulan berbentuk pil dengan thumb yang meluncur +
// ikon crossfade-rotate — dipakai di header shell & halaman auth.
class ThemeToggle extends StatelessWidget {
  final double height;
  const ThemeToggle({super.key, this.height = 32});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          final dark = mode == ThemeMode.dark;
          final w = height * 1.9;
          final thumb = height - 6;
          return GestureDetector(
            onTap: () => context.read<ThemeCubit>().toggle(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: w,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(
                  colors: dark
                      ? const [Color(0xFF1E293B), Color(0xFF0B1220)]
                      : [ZK.primary, ZK.accent],
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          size: height * 0.42,
                          color: Colors.white.withValues(alpha: dark ? 0.35 : 0.95)),
                      Icon(Icons.nightlight_round,
                          size: height * 0.38,
                          color: Colors.white.withValues(alpha: dark ? 0.95 : 0.35)),
                    ],
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      height: thumb,
                      width: thumb,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) => RotationTransition(
                            turns: anim,
                            child: ScaleTransition(scale: anim, child: child)),
                        child: Icon(
                          dark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                          key: ValueKey(dark),
                          size: thumb * 0.58,
                          color: dark ? const Color(0xFF1E293B) : ZK.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
