import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  void _navigate(BuildContext context, String route) {
    final currentPath = GoRouterState.of(context).uri.path;
    Navigator.of(context).pop();

    if (currentPath == route) {
      return;
    }

    if (route == '/') {
      context.go('/');
      return;
    }

    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Icon(Icons.sports_cricket, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'Gully Cricket',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => _navigate(context, '/'),
            ),
            ListTile(
              leading: const Icon(Icons.sports_cricket_outlined),
              title: const Text('New Match'),
              onTap: () => _navigate(context, '/setup'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Match History'),
              onTap: () => _navigate(context, '/history'),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Teams'),
              onTap: () => _navigate(context, '/teams'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Player Stats'),
              onTap: () => _navigate(context, '/players'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => _navigate(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdaptiveBackOrMenuButton extends StatelessWidget {
  const AdaptiveBackOrMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      );
    }

    return Builder(
      builder: (innerContext) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(innerContext).openDrawer(),
      ),
    );
  }
}