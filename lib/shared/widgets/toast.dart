import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Notifikasi custom (ganti SnackBar bawaan) — kartu melayang dari atas,
// bisa di-tap atau di-swipe ke atas untuk ditutup lebih cepat. Beberapa toast
// sekaligus akan bertumpuk rapi (bukan numpuk di posisi yang sama).
enum ToastKind { success, error, info }

const _kToastHeight = 62.0; // perkiraan tinggi kartu + jarak antar toast

final List<OverlayEntry> _activeToasts = [];

void showAppToast(BuildContext context, String message, ToastKind kind) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastCard(
      message: message,
      kind: kind,
      index: _activeToasts.length,
      onDismissed: () {
        // ponytail: guard idempoten — tap manual & auto-close timer bisa
        // sama-sama memicu ini, remove() kedua akan throw kalau tak dijaga.
        if (_activeToasts.remove(entry)) entry.remove();
      },
    ),
  );
  _activeToasts.add(entry);
  overlay.insert(entry);
}

class _ToastCard extends StatefulWidget {
  final String message;
  final ToastKind kind;
  final int index;
  final VoidCallback onDismissed;
  const _ToastCard(
      {required this.message,
      required this.kind,
      required this.index,
      required this.onDismissed});
  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with SingleTickerProviderStateMixin {
  late final _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final _slide = Tween(begin: const Offset(0, -1.2), end: Offset.zero)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  late final _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5));
  double _drag = 0;
  Timer? _autoClose;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _autoClose = Timer(const Duration(milliseconds: 2600), _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _autoClose?.cancel();
    await _ctrl.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  (Color, Color, IconData) _style(bool dark) => switch (widget.kind) {
        ToastKind.success => (okTone(dark), ZK.successBg, Icons.check_circle_rounded),
        ToastKind.error => (ZK.rose, ZK.rose50, Icons.error_rounded),
        ToastKind.info => (ZK.primary, ZK.brand50, Icons.info_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (tone, toneBg, icon) = _style(dark);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8 + widget.index * _kToastHeight,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: _close,
            onVerticalDragUpdate: (d) {
              if (d.delta.dy < 0) setState(() => _drag += d.delta.dy);
            },
            onVerticalDragEnd: (_) {
              if (_drag < -18) {
                _close();
              } else {
                setState(() => _drag = 0);
              }
            },
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: dark ? ZK.cardDark : Colors.white,
                    borderRadius: r14,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: dark ? 0.5 : 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                    border: Border.all(color: tone.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                            color: dark ? tone.withValues(alpha: 0.18) : toneBg,
                            shape: BoxShape.circle),
                        child: Icon(icon, size: 19, color: tone),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(widget.message,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                color: dark ? Colors.white : ZK.slate900)),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.close_rounded,
                          size: 16, color: dark ? Colors.white60 : ZK.slate400),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
