import 'package:flutter/material.dart';

class OfficialScoreboard extends StatelessWidget {
  const OfficialScoreboard({
    super.key,
    required this.battingTeamName,
    required this.scoreText,
    required this.oversText,
    required this.targetNeedText,
    required this.strikerName,
    required this.strikerRuns,
    required this.strikerBalls,
    required this.strikerStrikeRate,
    required this.nonStrikerName,
    required this.nonStrikerRuns,
    required this.nonStrikerBalls,
    required this.nonStrikerStrikeRate,
    required this.bowlerName,
    required this.bowlerOvers,
    required this.bowlerRuns,
    required this.bowlerWickets,
    required this.bowlerEconomy,
    required this.thisOverLabels,
    required this.partnershipText,
    required this.crrText,
    required this.rrrText,
    required this.projectionText,
    required this.lastOversSection,
    required this.scorePad,
  });

  final String battingTeamName;
  final String scoreText;
  final String oversText;
  final String targetNeedText;
  final String strikerName;
  final int strikerRuns;
  final int strikerBalls;
  final double strikerStrikeRate;
  final String nonStrikerName;
  final int nonStrikerRuns;
  final int nonStrikerBalls;
  final double nonStrikerStrikeRate;
  final String bowlerName;
  final String bowlerOvers;
  final int bowlerRuns;
  final int bowlerWickets;
  final double bowlerEconomy;
  final List<String> thisOverLabels;
  final String partnershipText;
  final String crrText;
  final String rrrText;
  final String projectionText;
  final Widget lastOversSection;
  final Widget scorePad;

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(fontFamily: 'monospace');
    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.black87,
          child: const Text(
            'GULLY CRICKET — LIVE',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '$battingTeamName  $scoreText',
                      style: mono.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Text('Ov: $oversText', style: mono),
                ],
              ),
              const SizedBox(height: 4),
              Text(targetNeedText, style: mono),
            ],
          ),
        ),
        _panel(
          child: Column(
            children: <Widget>[
              _headerRow('BATTER', 'R', 'B', 'SR', mono),
              const SizedBox(height: 4),
              _dataRow('● $strikerName*', '$strikerRuns', '$strikerBalls',
                  strikerStrikeRate.toStringAsFixed(1), mono),
              const SizedBox(height: 2),
              _dataRow('  $nonStrikerName', '$nonStrikerRuns', '$nonStrikerBalls',
                  nonStrikerStrikeRate.toStringAsFixed(1), mono),
            ],
          ),
        ),
        _panel(
          child: Column(
            children: <Widget>[
              _headerRow('BOWLER', 'O', 'R', 'W', mono, trailingHeader: 'Eco'),
              const SizedBox(height: 4),
              _dataRow(
                bowlerName,
                bowlerOvers,
                '$bowlerRuns',
                '$bowlerWickets',
                mono,
                trailing: bowlerEconomy.toStringAsFixed(1),
              ),
            ],
          ),
        ),
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'THIS OVER: ${thisOverLabels.join('  ')}',
                style: mono.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text('$partnershipText  ·  CRR: $crrText', style: mono),
              const SizedBox(height: 2),
              Text('RRR: $rrrText  ·  $projectionText', style: mono),
            ],
          ),
        ),
        _panel(child: lastOversSection),
        Expanded(child: scorePad),
      ],
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget _headerRow(
    String c1,
    String c2,
    String c3,
    String c4,
    TextStyle style, {
    String? trailingHeader,
  }) {
    return Row(
      children: <Widget>[
        Expanded(flex: 6, child: Text(c1, style: style.copyWith(fontWeight: FontWeight.w700))),
        Expanded(flex: 2, child: Text(c2, textAlign: TextAlign.right, style: style)),
        Expanded(flex: 2, child: Text(c3, textAlign: TextAlign.right, style: style)),
        Expanded(flex: 3, child: Text(c4, textAlign: TextAlign.right, style: style)),
        if (trailingHeader != null)
          Expanded(flex: 2, child: Text(trailingHeader, textAlign: TextAlign.right, style: style)),
      ],
    );
  }

  Widget _dataRow(
    String c1,
    String c2,
    String c3,
    String c4,
    TextStyle style, {
    String? trailing,
  }) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 6,
          child: Text(
            c1,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(flex: 2, child: Text(c2, textAlign: TextAlign.right, style: style)),
        Expanded(flex: 2, child: Text(c3, textAlign: TextAlign.right, style: style)),
        Expanded(flex: 3, child: Text(c4, textAlign: TextAlign.right, style: style)),
        if (trailing != null) Expanded(flex: 2, child: Text(trailing, textAlign: TextAlign.right, style: style)),
      ],
    );
  }
}
