import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/hive_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../scoring/presentation/active_match_provider.dart';
import '../services/host_service.dart';

class HostLobbyScreen extends ConsumerStatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  ConsumerState<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends ConsumerState<HostLobbyScreen> {
  bool _starting = true;
  int _modeIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startServer());
  }

  Future<void> _startServer() async {
    final settings = Hive.box<dynamic>(HiveKeys.settingsBox);
    final shown = (settings.get(HiveKeys.hotspotGuideShown, defaultValue: false) as bool?) ?? false;
    if (!shown) {
      final accepted = await context.push<bool>('/hotspot-guide');
      if (accepted != true) {
        if (mounted) {
          setState(() {
            _error = 'Hosting cancelled';
            _starting = false;
          });
        }
        return;
      }
    }

    final match = ref.read(activeMatchProvider);
    final host = ref.read(hostServiceProvider);
    if (match == null) {
      setState(() {
        _error = 'No active match found.';
        _starting = false;
      });
      return;
    }
    try {
      await host.startServer(match);
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Failed to start WiFi server';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final host = ref.watch(hostServiceProvider);
    final match = ref.watch(activeMatchProvider);
    final qrSize = (MediaQuery.of(context).size.width * 0.55).clamp(160.0, 240.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Host Match')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: _starting
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Starting WiFi server...')),
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          _error!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '✅ Server Running',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text('${host.hostIp} : ${AppConstants.wsPort}'),
                          const SizedBox(height: 8),
                          StreamBuilder<int>(
                            stream: host.connectedClientsStream,
                            initialData: host.connectedClients,
                            builder: (context, snapshot) {
                              return Text('Connected devices: ${snapshot.data ?? 0}');
                            },
                          ),
                          const SizedBox(height: 16),
                          ToggleButtons(
                            isSelected: <bool>[_modeIndex == 0, _modeIndex == 1],
                            onPressed: (index) => setState(() => _modeIndex = index),
                            children: const <Widget>[
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('QR Code'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Manual IP'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: _modeIndex == 0
                                ? QrImageView(
                                    data: host.buildQrData(match?.id),
                                    size: qrSize,
                                    foregroundColor: Colors.white,
                                    backgroundColor: AppColors.surface,
                                  )
                                : SelectableText(
                                    '${host.hostIp}:${AppConstants.wsPort}${AppConstants.wsPath}',
                                  ),
                          ),
                          const SizedBox(height: 12),
                          const Center(child: Text('Scan QR or enter IP manually to join')),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                              onPressed: () => context.push('/live'),
                              child: const Text('▶ Start Scoring'),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
