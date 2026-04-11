import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/match_setup/presentation/match_setup_screen.dart';
import '../features/match_setup/presentation/rules_config_screen.dart';
import '../features/match_setup/presentation/team_setup_screen.dart';
import '../features/multiplayer/presentation/host_lobby_screen.dart';
import '../features/multiplayer/presentation/join_screen.dart';
import '../features/multiplayer/presentation/spectator_screen.dart';
import '../features/result/presentation/match_history_screen.dart';
import '../features/result/presentation/result_screen.dart';
import '../features/scoring/domain/models/match_model.dart';
import '../features/scoring/presentation/live_score_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/setup',
      name: 'setup',
      builder: (BuildContext context, GoRouterState state) =>
          const MatchSetupScreen(),
    ),
    GoRoute(
      path: '/rules',
      name: 'rules',
      builder: (BuildContext context, GoRouterState state) =>
          const RulesConfigScreen(),
    ),
    GoRoute(
      path: '/teams',
      name: 'teams',
      builder: (BuildContext context, GoRouterState state) =>
          const TeamSetupScreen(),
    ),
    GoRoute(
      path: '/host',
      name: 'host',
      builder: (BuildContext context, GoRouterState state) =>
          const HostLobbyScreen(),
    ),
    GoRoute(
      path: '/join',
      name: 'join',
      builder: (BuildContext context, GoRouterState state) => const JoinScreen(),
    ),
    GoRoute(
      path: '/live',
      name: 'live',
      builder: (BuildContext context, GoRouterState state) =>
          const LiveScoreScreen(),
    ),
    GoRoute(
      path: '/spectator',
      name: 'spectator',
      builder: (BuildContext context, GoRouterState state) =>
          const SpectatorScreen(),
    ),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra;
        if (extra is Map<String, dynamic>) {
          return ResultScreen(
            matchOverride: extra['match'] as MatchModel?,
            readOnly: (extra['readOnly'] as bool?) ?? false,
          );
        }
        return const ResultScreen();
      },
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (BuildContext context, GoRouterState state) => const MatchHistoryScreen(),
    ),
  ],
);
