import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../storage/services/match_repository.dart';
import '../domain/team_model.dart';
import '../services/teams_service.dart';
import '../../../shared/widgets/app_navigation_drawer.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matches = ref.read(matchListProvider);
      ref.read(teamsProvider.notifier).syncStatsWithMatches(matches);
    });
  }

  Future<void> _showTeamActions(TeamModel team) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(team.isFavorite ? Icons.star : Icons.star_border),
                title: Text(team.isFavorite ? 'Remove favorite' : 'Mark as favorite'),
                onTap: () => Navigator.of(context).pop('favorite'),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit team'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete team'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == 'favorite') {
      await ref.read(teamsProvider.notifier).toggleFavorite(team.id);
      return;
    }
    if (action == 'edit' && mounted) {
      context.push('/teams/create?teamId=${team.id}');
      return;
    }
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete team?'),
          content: Text(team.name),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(teamsProvider.notifier).deleteTeam(team.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsProvider);
    final matches = ref.watch(matchListProvider);
    final notifier = ref.read(teamsProvider.notifier);

    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(
        leading: const AdaptiveBackOrMenuButton(),
        title: const Text('My Teams'),
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
          IconButton(
            onPressed: () => context.push('/teams/create'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: teams.isEmpty
          ? const Center(child: Text('No teams yet. Tap + to create your first team.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final team = teams[index];
                final summary = notifier.summaryForTeam(team, matches);
                return _TeamCard(
                  summary: summary,
                  onTap: () => context.push('/teams/${team.id}'),
                  onLongPress: () => _showTeamActions(team),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: teams.length,
            ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.summary,
    required this.onTap,
    required this.onLongPress,
  });

  final TeamMatchSummary summary;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final team = summary.team;
    final color = _parseColor(team.colorHex);
    final rosterPreview = _rosterPreview(team.playerNames);
    final lastPlayed = summary.lastPlayedAt == null ? 'Never' : _relativeTime(summary.lastPlayedAt!);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(radius: 10, backgroundColor: color),
                  const SizedBox(width: 8),
                  if ((team.shortName ?? '').isNotEmpty)
                    Text(
                      '[${team.shortName}]',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if ((team.shortName ?? '').isNotEmpty) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      team.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (team.isFavorite) const Icon(Icons.star, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${team.matchesPlayed} matches · ${team.wins}W ${team.losses}L ${team.ties}T · ${team.winPercentage.toStringAsFixed(0)}% win',
              ),
              const SizedBox(height: 4),
              Text('Roster: $rosterPreview'),
              const SizedBox(height: 4),
              Text('Last played: $lastPlayed'),
            ],
          ),
        ),
      ),
    );
  }
}

String _rosterPreview(List<String> players) {
  if (players.isEmpty) {
    return 'No players';
  }
  if (players.length <= 3) {
    return players.join(', ');
  }
  final firstThree = players.take(3).join(', ');
  return '$firstThree +${players.length - 3} more';
}

Color _parseColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final argb = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  return Color(int.tryParse(argb, radix: 16) ?? 0xFF2E7D32);
}

String _relativeTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays > 0) {
    return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
  }
  if (diff.inHours > 0) {
    return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
  }
  if (diff.inMinutes > 0) {
    return diff.inMinutes == 1 ? '1 minute ago' : '${diff.inMinutes} minutes ago';
  }
  return 'Just now';
}
