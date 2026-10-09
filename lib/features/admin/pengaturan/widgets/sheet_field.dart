import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
export '../../../../shared/widgets/sheet_common.dart' show sheetInput, FieldLabel;

Widget settingsCard(bool dark, {required Widget child}) => Container(
      decoration: BoxDecoration(
        color: dark ? ZK.cardDark : Colors.white,
        borderRadius: r14,
        border: Border.all(color: dark ? ZK.lineDark : ZK.line),
      ),
      child: child,
    );
