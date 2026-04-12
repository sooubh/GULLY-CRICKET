import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class QuickActionBar extends StatelessWidget {
  const QuickActionBar({
    super.key,
    required this.partnership,
    required this.onSwap,
    required this.onSettings,
    required this.onWifi,
  });

  final String partnership;
  final VoidCallback onSwap;
  final VoidCallback onSettings;
  final VoidCallback onWifi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                partnership,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onSwap,
            icon: const Icon(Icons.swap_horiz),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onSettings,
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onWifi,
            icon: const Icon(Icons.wifi_tethering),
          ),
        ],
      ),
    );
  }
}
