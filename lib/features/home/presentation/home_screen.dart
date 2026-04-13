import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../ads/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/offline_mode_banner.dart';
import '../../../shared/widgets/app_navigation_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppNavigationDrawer(),
      appBar: AppBar(title: const Text('Gully Cricket')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const OfflineModeBanner(),
                    const SizedBox(height: 12),
                    Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 96,
                      height: 96,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.25, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                Text(
                  'GULLY CRICKET',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        color: AppColors.accentGold,
                      ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.25, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 4),
                Text(
                  'Make every street match feel like IPL',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 320.ms)
                    .slideY(begin: 0.2, end: 0, duration: 320.ms, curve: Curves.easeOutCubic),
                const SizedBox(height: 48),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/setup'),
                    child: const Text('🏏 New Match'),
                  ),
                )
                    .animate()
                    .slideY(begin: 0.22, end: 0, duration: 300.ms, delay: 100.ms)
                    .fadeIn(delay: 100.ms, duration: 300.ms),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => context.push('/join'),
                    child: const Text('📡 Join as Viewer'),
                  ),
                )
                    .animate()
                    .slideY(begin: 0.22, end: 0, duration: 300.ms, delay: 200.ms)
                    .fadeIn(delay: 200.ms, duration: 300.ms),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => context.push('/history'),
                          child: const Text('📋 Match History'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => context.push('/teams'),
                          child: const Text('👥 Teams'),
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .slideY(begin: 0.22, end: 0, duration: 300.ms, delay: 300.ms)
                    .fadeIn(delay: 300.ms, duration: 300.ms),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => context.push('/players'),
                      child: const Text('🏆 Player Stats'),
                    ),
                    const SizedBox(width: 4),
                    const Text('•'),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      child: const Text('⚙️ Settings'),
                    ),
                  ],
                )
                    .animate()
                    .slideY(begin: 0.22, end: 0, duration: 300.ms, delay: 400.ms)
                    .fadeIn(delay: 400.ms, duration: 300.ms),
                const Spacer(),
                const Align(
                  alignment: Alignment.center,
                  child: BannerAdWidget(),
                ),
                const SizedBox(height: 8),
                Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
