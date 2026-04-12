import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/constants/hive_keys.dart';
import 'features/players/domain/saved_player_model.dart';
import 'features/scoring/domain/models/ball_model.dart';
import 'features/scoring/domain/models/gully_rules_model.dart';
import 'features/scoring/domain/models/innings_model.dart';
import 'features/scoring/domain/models/match_model.dart';
import 'features/scoring/domain/models/over_model.dart';
import 'features/scoring/domain/models/partnership_model.dart';
import 'features/scoring/domain/models/player_model.dart';
import 'features/teams/domain/team_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive
    ..registerAdapter(GullyRulesAdapter())
    ..registerAdapter(PlayerAdapter())
    ..registerAdapter(BallAdapter())
    ..registerAdapter(OverAdapter())
    ..registerAdapter(PartnershipAdapter())
    ..registerAdapter(InningsAdapter())
    ..registerAdapter(MatchModelAdapter())
    ..registerAdapter(SavedPlayerAdapter())
    ..registerAdapter(TeamModelAdapter());
  await Hive.openBox<MatchModel>(HiveKeys.matchBox);
  await Hive.openBox<SavedPlayer>(HiveKeys.savedPlayersBox);
  await Hive.openBox<TeamModel>(HiveKeys.teamsBox);
  await Hive.openBox(HiveKeys.settingsBox);
  await MobileAds.instance.initialize();
  runApp(const ProviderScope(child: GullyCricketApp()));
}
