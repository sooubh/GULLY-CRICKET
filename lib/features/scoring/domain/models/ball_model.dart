import 'package:hive/hive.dart';

part 'ball_model.g.dart';

@HiveType(typeId: 2)
class Ball extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final int runsScored;
  @HiveField(2)
  final bool isWicket;
  @HiveField(3)
  final bool isWide;
  @HiveField(4)
  final bool isNoBall;
  @HiveField(5)
  final bool isBye;
  @HiveField(6)
  final bool isLegBye;
  @HiveField(7)
  final bool isFreeHit;
  @HiveField(8)
  final bool isOverthrow;
  @HiveField(9)
  final String? wicketType;
  @HiveField(10)
  final String? dismissedPlayerId;
  @HiveField(11)
  final String bowlerId;
  @HiveField(12)
  final String batsmanId;
  @HiveField(13)
  final int overNumber;
  @HiveField(14)
  final int ballInOver;
  @HiveField(15)
  final int totalRunsAfterBall;

  Ball({
    required this.id,
    required this.bowlerId,
    required this.batsmanId,
    required this.overNumber,
    required this.ballInOver,
    this.runsScored = 0,
    this.isWicket = false,
    this.isWide = false,
    this.isNoBall = false,
    this.isBye = false,
    this.isLegBye = false,
    this.isFreeHit = false,
    this.isOverthrow = false,
    this.wicketType,
    this.dismissedPlayerId,
    this.totalRunsAfterBall = 0,
  });

  bool get isLegalBall => !isWide && !isNoBall;

  String get displayChar {
    if (isWide) return runsScored > 0 ? 'Wd+$runsScored' : 'Wd';
    if (isNoBall) return runsScored > 0 ? 'Nb+$runsScored' : 'Nb';
    if (isWicket) return 'W';
    if (isBye) return runsScored > 0 ? 'B+$runsScored' : 'B';
    if (isLegBye) return runsScored > 0 ? 'Lb+$runsScored' : 'Lb';
    if (runsScored == 0) return '.';
    return '$runsScored';
  }

  Ball copyWith({
    String? id,
    int? runsScored,
    bool? isWicket,
    bool? isWide,
    bool? isNoBall,
    bool? isBye,
    bool? isLegBye,
    bool? isFreeHit,
    bool? isOverthrow,
    String? wicketType,
    String? dismissedPlayerId,
    String? bowlerId,
    String? batsmanId,
    int? overNumber,
    int? ballInOver,
    int? totalRunsAfterBall,
  }) {
    return Ball(
      id: id ?? this.id,
      runsScored: runsScored ?? this.runsScored,
      isWicket: isWicket ?? this.isWicket,
      isWide: isWide ?? this.isWide,
      isNoBall: isNoBall ?? this.isNoBall,
      isBye: isBye ?? this.isBye,
      isLegBye: isLegBye ?? this.isLegBye,
      isFreeHit: isFreeHit ?? this.isFreeHit,
      isOverthrow: isOverthrow ?? this.isOverthrow,
      wicketType: wicketType ?? this.wicketType,
      dismissedPlayerId: dismissedPlayerId ?? this.dismissedPlayerId,
      bowlerId: bowlerId ?? this.bowlerId,
      batsmanId: batsmanId ?? this.batsmanId,
      overNumber: overNumber ?? this.overNumber,
      ballInOver: ballInOver ?? this.ballInOver,
      totalRunsAfterBall: totalRunsAfterBall ?? this.totalRunsAfterBall,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'runsScored': runsScored,
      'isWicket': isWicket,
      'isWide': isWide,
      'isNoBall': isNoBall,
      'isBye': isBye,
      'isLegBye': isLegBye,
      'isFreeHit': isFreeHit,
      'isOverthrow': isOverthrow,
      'wicketType': wicketType,
      'dismissedPlayerId': dismissedPlayerId,
      'bowlerId': bowlerId,
      'batsmanId': batsmanId,
      'overNumber': overNumber,
      'ballInOver': ballInOver,
      'totalRunsAfterBall': totalRunsAfterBall,
    };
  }

  factory Ball.fromJson(Map<String, dynamic> json) {
    return Ball(
      id: json['id'] as String? ?? '',
      runsScored: json['runsScored'] as int? ?? 0,
      isWicket: json['isWicket'] as bool? ?? false,
      isWide: json['isWide'] as bool? ?? false,
      isNoBall: json['isNoBall'] as bool? ?? false,
      isBye: json['isBye'] as bool? ?? false,
      isLegBye: json['isLegBye'] as bool? ?? false,
      isFreeHit: json['isFreeHit'] as bool? ?? false,
      isOverthrow: json['isOverthrow'] as bool? ?? false,
      wicketType: json['wicketType'] as String?,
      dismissedPlayerId: json['dismissedPlayerId'] as String?,
      bowlerId: json['bowlerId'] as String? ?? '',
      batsmanId: json['batsmanId'] as String? ?? '',
      overNumber: json['overNumber'] as int? ?? 0,
      ballInOver: json['ballInOver'] as int? ?? 0,
      totalRunsAfterBall: json['totalRunsAfterBall'] as int? ?? 0,
    );
  }
}
