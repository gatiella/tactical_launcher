import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../themes/terminal_theme.dart';
import 'package:battery_plus/battery_plus.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({super.key});

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool _isOnline = false;
  int _latency = 0;
  int _batteryLevel = 0;
  Timer? _timer;
  final Battery _battery = Battery();

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _checkBattery();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnection();
      _checkBattery();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 3),
      );
      stopwatch.stop();

      if (mounted) {
        setState(() {
          _isOnline = response.statusCode == 200;
          _latency = stopwatch.elapsedMilliseconds;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
          _latency = 0;
        });
      }
    }
  }

  Future<void> _checkBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _batteryLevel = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isOnline
            ? TerminalTheme.matrixGreen.withOpacity(0.1)
            : TerminalTheme.alertRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                size: 14,
                color: _isOnline ? TerminalTheme.matrixGreen : TerminalTheme.alertRed,
              ),
              const SizedBox(width: 6),
              Text(
                '${_latency}ms',
                style: TerminalTheme.terminalText.copyWith(fontSize: 10),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.battery_full,
                size: 14,
                color: TerminalTheme.matrixGreen,
              ),
              const SizedBox(width: 2),
              Text(
                '$_batteryLevel%',
                style: TerminalTheme.terminalText.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}