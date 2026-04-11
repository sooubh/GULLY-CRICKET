import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scoring/domain/models/match_model.dart';
import 'hive_service.dart';

final hiveServiceProvider = Provider<HiveService>((ref) => const HiveService());

final matchListProvider = StateNotifierProvider<MatchRepository, List<MatchModel>>((ref) {
  return MatchRepository(ref.read(hiveServiceProvider));
});

class MatchRepository extends StateNotifier<List<MatchModel>> {
  MatchRepository(this._hiveService) : super(const []) {
    loadMatches();
  }

  final HiveService _hiveService;

  void loadMatches() {
    state = _hiveService.getAllMatches();
  }

  MatchModel? getMatch(String id) {
    return _hiveService.getMatch(id);
  }

  Future<void> saveMatch(MatchModel match) async {
    await _hiveService.saveMatch(match);
    loadMatches();
  }

  Future<void> deleteMatch(String id) async {
    await _hiveService.deleteMatch(id);
    loadMatches();
  }

  void loadCompletedMatches() {
    state = _hiveService.getCompletedMatches();
  }

  void loadLiveMatches() {
    state = _hiveService.getLiveMatches();
  }
}
