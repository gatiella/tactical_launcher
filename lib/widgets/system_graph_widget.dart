import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../themes/terminal_theme.dart';

class SystemGraphWidget extends StatefulWidget {
  const SystemGraphWidget({super.key});

  @override
  State<SystemGraphWidget> createState() => _SystemGraphWidgetState();
}

class _SystemGraphWidgetState extends State<SystemGraphWidget> {
  final List<double> _cpuData = [];
  final List<double> _ramData = [];
  final int _maxDataPoints = 50;
  Timer? _timer;
  final Random _random = Random();

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        // Simulate CPU usage (in production, get real data)
        _cpuData.add(20 + _random.nextDouble() * 60);
        if (_cpuData.length > _maxDataPoints) {
          _cpuData.removeAt(0);
        }

        // Simulate RAM usage
        _ramData.add(30 + _random.nextDouble() * 50);
        if (_ramData.length > _maxDataPoints) {
          _ramData.removeAt(0);
        }
      });
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
        color: TerminalTheme.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '▸ SYSTEM PERFORMANCE',
            style: TerminalTheme.promptText.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          // CPU Graph
          _buildGraphSection('CPU USAGE', _cpuData, TerminalTheme.cyberCyan),
          const SizedBox(height: 16),
          
          // RAM Graph
          _buildGraphSection('RAM USAGE', _ramData, TerminalTheme.matrixGreen),
        ],
      ),
    );
  }

  Widget _buildGraphSection(String label, List<double> data, Color color) {
    final currentValue = data.isNotEmpty ? data.last : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TerminalTheme.terminalText.copyWith(fontSize: 12),
            ),
            Text(
              '${currentValue.toInt()}%',
              style: TerminalTheme.promptText.copyWith(
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: CustomPaint(
            painter: GraphPainter(data, color),
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class GraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  GraphPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate points
    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / 100 * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw filled area
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots at data points
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / 100 * size.height);
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) => true;
}