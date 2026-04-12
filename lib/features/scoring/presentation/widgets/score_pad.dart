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
    return LayoutBuilder(
      builder: (context, constraints) {
        const gridChildAspectRatio = 1 / 0.9;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: <Widget>[
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: gridChildAspectRatio,
                  children: <Widget>[
                    _PadButton(label: '0', color: AppColors.surfaceVariant, onTap: () => onRun(0)),
                    _PadButton(label: '1', color: AppColors.surfaceVariant, onTap: () => onRun(1)),
                    _PadButton(label: '2', color: AppColors.surfaceVariant, onTap: () => onRun(2)),
                    _PadButton(label: '3', color: AppColors.surfaceVariant, onTap: () => onRun(3)),
                    _PadButton(label: '4', color: AppColors.primaryGreen, onTap: () => onRun(4)),
                    _PadButton(label: '6', color: AppColors.accentGold, onTap: () => onRun(6)),
                    _PadButton(label: 'WD', color: AppColors.extraYellow, onTap: onWide),
                    _PadButton(label: 'NB', color: AppColors.extraYellow, onTap: onNoBall),
                    _PadButton(label: 'BYE', color: AppColors.extraYellow, onTap: onBye),
                    _PadButton(label: 'LB', color: AppColors.extraYellow, onTap: onLegBye),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: _PadButton(
                        label: 'OUT',
                        color: AppColors.wicketRed,
                        onTap: onOut,
                        minHeight: 64,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PadButton(
                        label: '↩',
                        color: undoArmed ? Colors.orange : AppColors.dotGray,
                        onTap: onUndo,
                        minHeight: 64,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.minHeight = 56,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: minHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(56, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
