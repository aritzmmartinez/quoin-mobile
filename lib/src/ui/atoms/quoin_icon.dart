import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:quoin/src/core/theme/quoin_icons.dart';

class QuoinIcon extends StatelessWidget {
  const QuoinIcon(this.icon, {super.key, this.size, this.color});

  final QuoinIconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon.data,
      size: size ?? IconTheme.of(context).size ?? 24,
      color: color,
      strokeWidth: 1.5,
    );
  }
}
