import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'team_model.g.dart';

const Object _unsetValue = Object();

@HiveType(typeId: 8)
class TeamModel extends HiveObject {
  TeamModel({
    required this.id,
    required this.name,
    this.shortName,
    this.colorHex = '#2E7D32',
    this.playerNames = const <String>[],
    required this.createdAt,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.ties = 0,
    this.isFavorite = false,
    this.captainName,
  });

  factory TeamModel.create({
    required String name,
    String? shortName,
    String colorHex = '#2E7D32',
    List<String> playerNames = const <String>[],
    String? captainName,
  }) {
    return TeamModel(
      id: const Uuid().v4(),
      name: name.trim(),
      shortName: shortName?.trim().isEmpty == true ? null : shortName?.trim(),
      colorHex: colorHex,
      playerNames: playerNames,
      createdAt: DateTime.now(),
      captainName: captainName?.trim().isEmpty == true ? null : captainName?.trim(),
    );
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? shortName;

  @HiveField(3)
  final String colorHex;

  @HiveField(4)
  final List<String> playerNames;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final int matchesPlayed;

  @HiveField(7)
  final int wins;

  @HiveField(8)
  final int losses;

  @HiveField(9)
  final int ties;

  @HiveField(10)
  final bool isFavorite;

  @HiveField(11)
  final String? captainName;

  double get winPercentage => matchesPlayed == 0 ? 0 : (wins / matchesPlayed) * 100;

  String get record => '$wins W / $losses L / $ties T';

  TeamModel copyWith({
    String? id,
    String? name,
    Object? shortName = _unsetValue,
    String? colorHex,
    List<String>? playerNames,
    DateTime? createdAt,
    int? matchesPlayed,
    int? wins,
    int? losses,
    int? ties,
    bool? isFavorite,
    Object? captainName = _unsetValue,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: identical(shortName, _unsetValue) ? this.shortName : shortName as String?,
      colorHex: colorHex ?? this.colorHex,
      playerNames: playerNames ?? this.playerNames,
      createdAt: createdAt ?? this.createdAt,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      ties: ties ?? this.ties,
      isFavorite: isFavorite ?? this.isFavorite,
      captainName: identical(captainName, _unsetValue) ? this.captainName : captainName as String?,
    );
  }
}
