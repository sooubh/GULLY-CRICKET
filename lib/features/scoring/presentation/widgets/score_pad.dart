import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ScorePad extends StatelessWidget {
  const ScorePad({
    super.key,
    required this.onRun,
    required this.onWide,
    required this.onNoBall,
    required this.onBye,
    required this.onLegBye,
    required this.onOut,
    required this.onUndo,
    required this.undoArmed,
  });

  final ValueChanged<int> onRun;
  final VoidCallback onWide;
  final VoidCallback onNoBall;
  final VoidCallback onBye;
  final VoidCallback onLegBye;
  final VoidCallback onOut;
  final VoidCallback onUndo;
  final bool undoArmed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _PadButton(label: '0', color: AppColors.surfaceVariant, onTap: () => onRun(0)),
              _PadButton(label: '1', color: AppColors.surfaceVariant, onTap: () => onRun(1)),
              _PadButton(label: '2', color: AppColors.surfaceVariant, onTap: () => onRun(2)),
              _PadButton(label: '3', color: AppColors.surfaceVariant, onTap: () => onRun(3)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _PadButton(label: '4', color: AppColors.primaryGreen, onTap: () => onRun(4)),
              _PadButton(label: '6', color: AppColors.accentGold, onTap: () => onRun(6)),
              _PadButton(label: 'WD', color: AppColors.extraYellow, onTap: onWide),
              _PadButton(label: 'NB', color: AppColors.extraYellow, onTap: onNoBall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              _PadButton(label: 'BYE', color: AppColors.extraYellow, onTap: onBye),
              _PadButton(label: 'LB', color: AppColors.extraYellow, onTap: onLegBye),
              _PadButton(
                label: 'OUT',
                color: AppColors.wicketRed,
                onTap: onOut,
                flex: 2,
                minHeight: 80,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 72,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: undoArmed ? Colors.orange : AppColors.dotGray,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onUndo,
                      child: const Text('↩'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.flex = 1,
    this.minHeight = 72,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final int flex;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: minHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(72, 72),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
