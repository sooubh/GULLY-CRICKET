import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/hive_keys.dart';
import '../domain/saved_player_model.dart';

class SavedPlayersService {
  Box<SavedPlayer> get _box => Hive.box<SavedPlayer>(HiveKeys.savedPlayersBox);

  List<SavedPlayer> getAllPlayers() {
    final players = _box.values.toList();
    players.sort(_sortPlayers);
    return players;
  }

  Future<void> savePlayer(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.toLowerCase();
    final exists = _box.values.any((player) => player.name.trim().toLowerCase() == normalized);
    if (exists) return;
    final player = SavedPlayer.create(trimmed);
    await _box.put(player.id, player);
  }

  Future<void> deletePlayer(String id) async {
    await _box.delete(id);
  }

  Future<void> toggleFavorite(String id) async {
    final player = _box.get(id);
    if (player == null) return;
    await _box.put(id, player.copyWith(isFavorite: !player.isFavorite));
  }

  Future<void> renamePlayer(String id, String newName) async {
    final player = _box.get(id);
    if (player == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.toLowerCase();
    final duplicate = _box.values.any(
      (saved) => saved.id != id && saved.name.trim().toLowerCase() == normalized,
    );
    if (duplicate) return;
    await _box.put(id, player.copyWith(name: trimmed));
  }

  Future<void> updateCareerStats(String playerName, int runs, int wickets) async {
    final normalized = playerName.trim().toLowerCase();
    if (normalized.isEmpty) return;
    SavedPlayer? player;
    for (final item in _box.values) {
      if (item.name.trim().toLowerCase() == normalized) {
        player = item;
        break;
      }
    }
    if (player == null) return;
    await _box.put(
      player.id,
      player.copyWith(
        timesPlayed: player.timesPlayed + 1,
        totalRunsCareer: player.totalRunsCareer + runs,
        totalWicketsCareer: player.totalWicketsCareer + wickets,
        lastPlayed: DateTime.now(),
      ),
    );
  }

  List<SavedPlayer> searchPlayers(String query) {
    final normalized = query.trim().toLowerCase();
    final source = normalized.isEmpty
        ? _box.values
        : _box.values.where((player) => player.name.toLowerCase().contains(normalized));
    final results = source.toList();
    results.sort(_sortPlayers);
    return results;
  }

  int _sortPlayers(SavedPlayer a, SavedPlayer b) {
    if (a.isFavorite && !b.isFavorite) return -1;
    if (!a.isFavorite && b.isFavorite) return 1;
    return b.lastPlayed.compareTo(a.lastPlayed);
  }
}

final savedPlayersServiceProvider = Provider<SavedPlayersService>((_) => SavedPlayersService());

final savedPlayersProvider = StateNotifierProvider<SavedPlayersNotifier, List<SavedPlayer>>((ref) {
  final service = ref.watch(savedPlayersServiceProvider);
  return SavedPlayersNotifier(service);
});

class SavedPlayersNotifier extends StateNotifier<List<SavedPlayer>> {
  SavedPlayersNotifier(this._service) : super(const []) {
    _listenable = Hive.box<SavedPlayer>(HiveKeys.savedPlayersBox).listenable();
    _listenable.addListener(_reload);
    _reload();
  }

  final SavedPlayersService _service;
  late final ValueListenable<Box<SavedPlayer>> _listenable;

  void _reload() {
    state = _service.getAllPlayers();
  }

  Future<void> savePlayer(String name) async {
    await _service.savePlayer(name);
  }

  Future<void> deletePlayer(String id) async {
    await _service.deletePlayer(id);
  }

  Future<void> toggleFavorite(String id) async {
    await _service.toggleFavorite(id);
  }

  Future<void> renamePlayer(String id, String newName) async {
    await _service.renamePlayer(id, newName);
  }

  @override
  void dispose() {
    _listenable.removeListener(_reload);
    super.dispose();
  }
}
