import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/ball_model.dart';

class BallTimeline extends StatelessWidget {
  const BallTimeline({
    super.key,
    required this.balls,
  });

  final List<Ball> balls;

  @override
  Widget build(BuildContext context) {
    final shown = balls.length > 6 ? balls.sublist(balls.length - 6) : balls;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Text('This over:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          ...shown
              .map(
                (ball) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _BallChip(ball: ball, key: ValueKey<String>(ball.id)),
                ),
              )
              .toList()
              .animate(interval: 40.ms)
              .slideX(begin: 1.0, end: 0.0, duration: 300.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _BallChip extends StatelessWidget {
  const _BallChip({super.key, required this.ball});

  final Ball ball;

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (ball.isWicket) {
      bg = AppColors.wicketRed;
    } else if (ball.isWide || ball.isNoBall || ball.isBye || ball.isLegBye) {
      bg = AppColors.extraYellow;
    } else if (ball.runsScored == 0) {
      bg = AppColors.dotGray;
    } else {
      bg = AppColors.primaryGreen;
    }

    final label = ball.isWide
        ? 'Wd'
        : ball.isNoBall
            ? 'Nb'
            : ball.isWicket
                ? 'W'
                : ball.runsScored == 0
                    ? '·'
                    : '${ball.runsScored}';

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
