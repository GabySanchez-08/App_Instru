import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class EcgViewerScreen extends StatefulWidget {
  const EcgViewerScreen({super.key});

  @override
  State<EcgViewerScreen> createState() => _EcgViewerScreenState();
}

class _EcgViewerScreenState extends State<EcgViewerScreen> {
  late final DatabaseReference _refD1, _refD2, _refD3, _refBpm;
  late final StreamSubscription<DatabaseEvent> _subD1, _subD2, _subD3, _subBpm;

  final List<FlSpot> _bufD1 = [];
  final List<FlSpot> _bufD2 = [];
  final List<FlSpot> _bufD3 = [];

  List<double> _pendingD1 = [], _pendingD2 = [], _pendingD3 = [];
  Timer? _timerD1, _timerD2, _timerD3;

  double _bpm = 0;

  @override
  void initState() {
    super.initState();
    final root = FirebaseDatabase.instance.ref('Dispositivo/Wayne/ECG_Real');
    _refD1 = root.child('D1');
    _refD2 = root.child('D2');
    _refD3 = root.child('D3');
    _refBpm = root.child('BPM/BPM_realtime');

    _subD1 = _refD1.onValue.listen((e) => _handleNewArray(e.snapshot.value, 1));
    _subD2 = _refD2.onValue.listen((e) => _handleNewArray(e.snapshot.value, 2));
    _subD3 = _refD3.onValue.listen((e) => _handleNewArray(e.snapshot.value, 3));

    _subBpm = _refBpm.onValue.listen((ev) {
      final raw = ev.snapshot.value;
      double? parsed;
      if (raw is num) parsed = raw.toDouble();
      else if (raw is String) parsed = double.tryParse(raw);
      else if (raw is Map) {
        final entries = raw.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        final lastVal = entries.last.value;
        if (lastVal is num) parsed = lastVal.toDouble();
        else if (lastVal is String) parsed = double.tryParse(lastVal);
      }
      if (parsed != null) setState(() => _bpm = parsed!);
    });
  }

  void _handleNewArray(Object? raw, int derivada) {
    List<double>? parsed = _parse(raw);
    if (parsed == null || parsed.isEmpty) return;

    switch (derivada) {
      case 1:
        _pendingD1 = parsed;
        _timerD1?.cancel();
        _timerD1 = Timer.periodic(
          const Duration(milliseconds: 10),
          (_) => _tick(_pendingD1, _bufD1),
        );
        break;
      case 2:
        _pendingD2 = parsed;
        _timerD2?.cancel();
        _timerD2 = Timer.periodic(
          const Duration(milliseconds: 10),
          (_) => _tick(_pendingD2, _bufD2),
        );
        break;
      case 3:
        _pendingD3 = parsed;
        _timerD3?.cancel();
        _timerD3 = Timer.periodic(
          const Duration(milliseconds: 10),
          (_) => _tick(_pendingD3, _bufD3),
        );
        break;
    }
  }

  void _tick(List<double> pending, List<FlSpot> buffer) {
    if (pending.isEmpty) return;
    final y = pending.removeAt(0);
    buffer.add(FlSpot(0, y)); // El valor X se recalcula abajo

    if (buffer.length > 400) {
      buffer.removeAt(0);
    }

    // Reasignar los valores X según índice para mantener ventana estable
    for (int i = 0; i < buffer.length; i++) {
      buffer[i] = FlSpot(i / 100.0, buffer[i].y); // 100 Hz → 5 s máx
    }

    setState(() {});
  }

  List<double>? _parse(Object? raw) {
    Object? latest = raw;
    if (raw is Map) {
      if (raw.isEmpty) return null;
      final entries = raw.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      latest = entries.last.value;
    }
    try {
      if (latest is String) return List<double>.from(json.decode(latest));
      if (latest is List) return latest.map((e) => (e as num).toDouble()).toList();
    } catch (_) {}
    return null;
  }

  LineChartData _chartData(List<FlSpot> spots, Color color) {
    if (spots.isEmpty) {
      return LineChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        lineBarsData: [],
      );
    }

    return LineChartData(
      minX: 0.0,
      maxX: 5.0,
      borderData: FlBorderData(show: true),
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, interval: 1),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          dotData: FlDotData(show: false),
          color: color,
          barWidth: 2,
        ),
      ],
    );
  }

  Widget _buildChart(List<FlSpot> buf, Color color) =>
      SizedBox(height: 120, child: LineChart(_chartData(buf, color)));

  @override
  void dispose() {
    _subD1.cancel();
    _subD2.cancel();
    _subD3.cancel();
    _subBpm.cancel();
    _timerD1?.cancel();
    _timerD2?.cancel();
    _timerD3?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ECG Dinámico')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('BPM: ${_bpm.round()}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildChart(_bufD1, Colors.redAccent),
                  const SizedBox(height: 12),
                  _buildChart(_bufD2, Colors.green),
                  const SizedBox(height: 12),
                  _buildChart(_bufD3, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}