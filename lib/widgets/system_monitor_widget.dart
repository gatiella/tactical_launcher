import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../themes/terminal_theme.dart';

class SystemMonitorWidget extends StatefulWidget {
  const SystemMonitorWidget({super.key});

  @override
  State<SystemMonitorWidget> createState() => _SystemMonitorWidgetState();
}

class _SystemMonitorWidgetState extends State<SystemMonitorWidget> {
  Timer? _timer;
  double _cpuUsage = 0.0;
  String _memoryInfo = 'N/A';
  String _uptime = '0h 0m';

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _updateStats();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _updateStats());
  }

  Future<void> _updateStats() async {
    if (!mounted) return;

    setState(() {
      _cpuUsage = (DateTime.now().millisecondsSinceEpoch % 100) / 100;
      _memoryInfo = '${(DateTime.now().second * 10) % 4000}MB / 8GB';
      
      final upMinutes = DateTime.now().minute;
      final upHours = DateTime.now().hour;
      _uptime = '${upHours}h ${upMinutes}m';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: TerminalTheme.matrixGreen, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: TerminalTheme.matrixGreen.withOpacity(0.05),
        boxShadow: [
          BoxShadow(
            color: TerminalTheme.matrixGreen.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '▸ SYSTEM MONITOR',
            style: TerminalTheme.promptText.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildMetric('CPU', '${(_cpuUsage * 100).toInt()}%', _cpuUsage),
          const SizedBox(height: 12),
          _buildMetric('MEMORY', _memoryInfo, 0.4),
          const SizedBox(height: 12),
          _buildInfoRow('UPTIME', _uptime),
          const SizedBox(height: 8),
          _buildInfoRow('PLATFORM', Platform.operatingSystem.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TerminalTheme.terminalText.copyWith(fontSize: 12)),
            Text(value, style: TerminalTheme.promptText.copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: TerminalTheme.darkGreen.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(TerminalTheme.matrixGreen),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TerminalTheme.terminalText.copyWith(fontSize: 12)),
        Text(value, style: TerminalTheme.promptText.copyWith(fontSize: 12)),
      ],
    );
  }
}