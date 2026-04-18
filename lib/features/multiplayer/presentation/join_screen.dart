import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_constants.dart';
import '../services/client_service.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: AppConstants.wsPort.toString(),
  );

  bool _connecting = false;
  bool _qrHandled = false;
  String _status = 'Not connected';
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect({
    required String ip,
    required int port,
    String path = AppConstants.wsPath,
  }) async {
    if (ip.isEmpty) {
      setState(() => _error = 'Please enter a valid IP address');
      return;
    }
    setState(() {
      _connecting = true;
      _status = 'Connecting to $ip...';
      _error = null;
    });
    try {
      await ref.read(clientServiceProvider).connect(ip, port, path);
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _status = 'Connected';
      });
      context.push('/spectator');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _status = 'Connection failed';
        _error = 'Unable to connect. Check IP/port and try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect. Please retry.')),
      );
    }
  }

  Future<void> _onQrDetected(String raw) async {
    if (_connecting || _qrHandled) return;
    try {
      final parsed = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final ip = (parsed['ip'] ?? parsed['hostIp'] ?? '').toString();
      final port = int.tryParse((parsed['port'] ?? AppConstants.wsPort).toString()) ?? AppConstants.wsPort;
      final path = (parsed['path'] ?? AppConstants.wsPath).toString();
      if (ip.isEmpty) throw Exception('Invalid ip');
      _qrHandled = true;
      await _connect(ip: ip, port: port, path: path);
      _qrHandled = false;
    } catch (_) {
      _qrHandled = false;
      if (!mounted) return;
      setState(() => _error = 'Invalid QR payload');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR. Scan again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientServiceProvider);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Join as Viewer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Scan QR'),
            Tab(text: 'Enter IP'),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  children: <Widget>[
                    TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Expanded(
                              child: MobileScanner(
                                onDetect: (capture) {
                                  if (capture.barcodes.isEmpty) return;
                                  final raw = capture.barcodes.first.rawValue;
                                  if (raw != null && raw.isNotEmpty) {
                                    _onQrDetected(raw);
                                  }
                                },
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _qrHandled = false),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TextField(
                                controller: _ipController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Host IP Address',
                                  hintText: '192.168.1.5',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _portController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Port'),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _connecting
                                      ? null
                                      : () => _connect(
                                            ip: _ipController.text.trim(),
                                            port:
                                                int.tryParse(_portController.text.trim()) ??
                                                AppConstants.wsPort,
                                          ),
                                  child: const Text('Connect'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Connection status: ${client.isConnected ? 'Connected' : _status}'),
                              if (_error != null) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_connecting)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const CircularProgressIndicator(),
                                const SizedBox(height: 10),
                                Text(_status),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Make sure both devices are on the same WiFi hotspot'),
        ),
      ),
    );
  }
}
