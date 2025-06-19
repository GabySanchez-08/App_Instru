// lib/screens/ecg_viewer_screen.dart

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
  // Firebase RTDB references
  late final DatabaseReference _refD1, _refD2, _refD3, _refBpm;
  late final StreamSubscription<DatabaseEvent> _subD1, _subD2, _subD3, _subBpm;

  // Windows of 5s × 10Hz = 50 samples each
  final List<List<FlSpot>> _windowsD1 = [];
  final List<List<FlSpot>> _windowsD2 = [];
  final List<List<FlSpot>> _windowsD3 = [];
  int _currentWindow = 0;

  double _bpm = 0;

  @override
  void initState() {
    super.initState();

    // Point to your node in Realtime Database
    final root = FirebaseDatabase.instance.ref('Dispositivo/Wayne/ECG_Real');

    // Derivadas
    _refD1 = root.child('D1');
    _refD2 = root.child('D2');
    _refD3 = root.child('D3');

    // BPM (puede venir num, String o Map con timestamped values)
    _refBpm = root.child('BPM');

    // Escucha cada lista completa y pársea en ventanas
    _subD1 = _refD1.onValue.listen((e) => _parseAndWindow(e.snapshot.value, _windowsD1));
    _subD2 = _refD2.onValue.listen((e) => _parseAndWindow(e.snapshot.value, _windowsD2));
    _subD3 = _refD3.onValue.listen((e) => _parseAndWindow(e.snapshot.value, _windowsD3));

    // Escucha BPM y admite varios formatos
    _subBpm = _refBpm.onValue.listen((ev) {
      final raw = ev.snapshot.value;
      double? parsed;

      if (raw is num) {
        parsed = raw.toDouble();
      } else if (raw is String) {
        parsed = double.tryParse(raw);
      } else if (raw is Map) {
        final entries = raw.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final lastVal = entries.last.value;
        if (lastVal is num) {
          parsed = lastVal.toDouble();
        } else if (lastVal is String) {
          parsed = double.tryParse(lastVal);
        }
      }

      if (parsed != null) {
        setState(() => _bpm = parsed!);
      }
    });
  }

  /// Toma raw desde RTDB (String JSON, List o Map), decodifica array de doubles,
  /// lo corta en ventanas de 50 muestras y convierte a FlSpot.
  void _parseAndWindow(Object? raw, List<List<FlSpot>> windows) {
    List<double> arr;

    // Si es Map con timestamped entries, usamos solo el último
    Object? latest = raw;
    if (raw is Map) {
      if (raw.isEmpty) return;
      final entries = raw.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      latest = entries.last.value;
    }

    if (latest is String) {
      try {
        arr = List<double>.from(json.decode(latest));
      } catch (_) {
        return;
      }
    } else if (latest is List) {
      arr = latest.map((e) => (e as num).toDouble()).toList();
    } else {
      return;
    }

    const int windowSize = 50; // 5s × 10Hz
    final newWindows = <List<FlSpot>>[];

    for (var i = 0; i + windowSize <= arr.length; i += windowSize) {
      final sub = arr.sublist(i, i + windowSize);
      newWindows.add(List<FlSpot>.generate(
        windowSize,
        (j) => FlSpot(j / 10.0, sub[j]),
      ));
    }

    setState(() {
      windows
        ..clear()
        ..addAll(newWindows);
      if (_currentWindow >= windows.length) {
        _currentWindow = windows.isEmpty ? 0 : windows.length - 1;
      }
    });
  }

  @override
  void dispose() {
    _subD1.cancel();
    _subD2.cancel();
    _subD3.cancel();
    _subBpm.cancel();
    super.dispose();
  }

  LineChartData _buildChart(List<FlSpot> spots, Color color) {
    return LineChartData(
      minX: 0,
      maxX: 5,
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, interval: 1),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
      ),
      gridData: FlGridData(show: true),
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

  Widget _windowChart(List<List<FlSpot>> windows, Color color) {
    if (windows.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No hay datos',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    return SizedBox(
      height: 120,
      child: LineChart(_buildChart(windows[_currentWindow], color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ECG por Ventanas')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Siempre mostramos el BPM arriba
            Text(
              'BPM: ${_bpm.round()}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Selector de ventana
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentWindow > 0
                      ? () => setState(() => _currentWindow--)
                      : null,
                ),
                Text('Ventana ${_currentWindow + 1} / ${_windowsD1.length}'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _currentWindow < _windowsD1.length - 1
                      ? () => setState(() => _currentWindow++)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tres gráficos (D1, D2, D3)
            Expanded(
              child: ListView(
                children: [
                  _windowChart(_windowsD1, Colors.red),
                  const SizedBox(height: 8),
                  _windowChart(_windowsD2, Colors.green),
                  const SizedBox(height: 8),
                  _windowChart(_windowsD3, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}