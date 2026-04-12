import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ads/widgets/banner_ad_widget.dart';
import '../../scoring/domain/models/match_model.dart';
import '../../storage/services/match_repository.dart';
import '../../../shared/widgets/offline_mode_banner.dart';
import '../widgets/match_history_tile.dart';

class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  Future<void> _deleteAll(BuildContext context, WidgetRef ref, List<MatchModel> matches) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all matches?'),
        content: const Text('This will permanently remove all saved match records.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete != true) return;
    for (final match in matches) {
      await ref.read(matchListProvider.notifier).deleteMatch(match.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = [...ref.watch(matchListProvider)]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
        actions: <Widget>[
          IconButton(
            onPressed: matches.isEmpty ? null : () => _deleteAll(context, ref, matches),
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const OfflineModeBanner(),
          Expanded(
            child: matches.isEmpty
                ? const _HistoryEmptyState()
                : ListView.separated(
                    itemCount: matches.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return MatchHistoryTile(
                        match: match,
                        onTap: () => context.push(
                          '/result',
                          extra: <String, dynamic>{'match': match, 'readOnly': true},
                        ),
                        onLongPress: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete match?'),
                              content: Text('${match.team1Name} vs ${match.team2Name}'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          await ref.read(matchListProvider.notifier).deleteMatch(match.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(top: false, child: BannerAdWidget()),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Icon(Icons.sports_cricket, size: 72),
          SizedBox(height: 10),
          Text('No matches yet. Play your first match!'),
        ],
      ),
    );
  }
}
