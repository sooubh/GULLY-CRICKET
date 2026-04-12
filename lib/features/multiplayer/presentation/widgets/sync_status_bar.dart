import 'package:flutter/material.dart';

import '../../services/client_service.dart';

class SyncStatusBar extends StatelessWidget {
  const SyncStatusBar({
    super.key,
    required this.status,
    this.onRetry,
  });

  final SyncStatusState status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final String text;
    late final Widget leading;
    VoidCallback? onTap;

    switch (status.stage) {
      case SyncStage.syncing:
        background = Colors.green.shade700;
        text = '🔄 SYNCING...';
        leading = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
        break;
      case SyncStage.synced:
        background = Colors.green.shade800;
        final score = status.scoreText ?? '--/--';
        final overs = status.oversText ?? '-';
        text = '✅ SYNCED · $score · Over $overs';
        leading = const Icon(Icons.check_circle, color: Colors.white, size: 16);
        break;
      case SyncStage.reconnecting:
        background = Colors.amber.shade800;
        final attempt = status.attempt ?? 1;
        final maxAttempts = status.maxAttempts ?? 3;
        text = '⚠️ RECONNECTING... ($attempt/$maxAttempts)';
        leading = const Icon(Icons.wifi_find, color: Colors.white, size: 16);
        break;
      case SyncStage.failed:
        background = Colors.red.shade800;
        text = '❌ SYNC LOST · TAP TO RETRY';
        leading = const Icon(Icons.error, color: Colors.white, size: 16);
        onTap = onRetry;
        break;
    }

    final content = SizedBox(
      height: 32,
      child: ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              leading,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
