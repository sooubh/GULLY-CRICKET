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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(partnership, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(onPressed: onSwap, icon: const Icon(Icons.swap_horiz)),
          IconButton(onPressed: onSettings, icon: const Icon(Icons.settings)),
          IconButton(onPressed: onWifi, icon: const Icon(Icons.wifi_tethering)),
        ],
      ),
    );
  }
}
