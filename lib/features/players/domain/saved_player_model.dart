import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'saved_player_model.g.dart';

// Existing scoring models occupy typeIds 0-6; SavedPlayer uses 7.
@HiveType(typeId: 7)
class SavedPlayer extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int timesPlayed;
  @HiveField(3)
  final DateTime lastPlayed;
  @HiveField(4)
  final int totalRunsCareer;
  @HiveField(5)
  final int totalWicketsCareer;
  @HiveField(6)
  final bool isFavorite;

  SavedPlayer({
    required this.id,
    required this.name,
    this.timesPlayed = 0,
    required this.lastPlayed,
    this.totalRunsCareer = 0,
    this.totalWicketsCareer = 0,
    this.isFavorite = false,
  });

  factory SavedPlayer.create(String name) => SavedPlayer(
        id: const Uuid().v4(),
        name: name.trim(),
        lastPlayed: DateTime.now(),
      );

  SavedPlayer copyWith({
    String? id,
    String? name,
    int? timesPlayed,
    DateTime? lastPlayed,
    int? totalRunsCareer,
    int? totalWicketsCareer,
    bool? isFavorite,
  }) {
    return SavedPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      timesPlayed: timesPlayed ?? this.timesPlayed,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      totalRunsCareer: totalRunsCareer ?? this.totalRunsCareer,
      totalWicketsCareer: totalWicketsCareer ?? this.totalWicketsCareer,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timesPlayed': timesPlayed,
      'lastPlayed': lastPlayed.toIso8601String(),
      'totalRunsCareer': totalRunsCareer,
      'totalWicketsCareer': totalWicketsCareer,
      'isFavorite': isFavorite,
    };
  }

  factory SavedPlayer.fromJson(Map<String, dynamic> json) {
    final lastPlayedRaw = json['lastPlayed'];
    final parsedLastPlayed = lastPlayedRaw is String
        ? DateTime.tryParse(lastPlayedRaw) ?? DateTime.now()
        : DateTime.now();
    return SavedPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      timesPlayed: json['timesPlayed'] as int? ?? 0,
      lastPlayed: parsedLastPlayed,
      totalRunsCareer: json['totalRunsCareer'] as int? ?? 0,
      totalWicketsCareer: json['totalWicketsCareer'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
