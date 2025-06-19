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
  // Referencias RTDB
  late final DatabaseReference _refD1, _refD2, _refD3, _refBpm;
  late final StreamSubscription<DatabaseEvent>
      _subD1, _subD2, _subD3, _subBpm;

  // Buffers deslizantes de 30 puntos cada uno
  final List<FlSpot> _bufD1 = [];
  final List<FlSpot> _bufD2 = [];
  final List<FlSpot> _bufD3 = [];

  // Contador para eje X (avanza en 0.1s por muestra)
  int _counter = 0;

  // BPM
  double _bpm = 0;

  @override
  void initState() {
    super.initState();
    final root = FirebaseDatabase.instance.ref('Dispositivo/Wayne/ECG_Real');

    // Apuntamos a las ramas
    _refD1 = root.child('D1');
    _refD2 = root.child('D2');
    _refD3 = root.child('D3');
    _refBpm = root.child('BPM/BPM_realtime');

    // Cada vez que recibimos el array completo, lo parseamos y alimentamos el buffer
    _subD1 = _refD1.onValue.listen((e) => _feedBuffer(e.snapshot.value, _bufD1));
    _subD2 = _refD2.onValue.listen((e) => _feedBuffer(e.snapshot.value, _bufD2));
    _subD3 = _refD3.onValue.listen((e) => _feedBuffer(e.snapshot.value, _bufD3));

    // BPM en varios formatos
    _subBpm = _refBpm.onValue.listen((ev) {
      final raw = ev.snapshot.value;
      double? parsed;
      if (raw is num) {
        parsed = raw.toDouble();
      } else if (raw is String) {
        parsed = double.tryParse(raw);
      } else if (raw is Map) {
        final entries = raw.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
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

  /// Toma raw: JSON-string, List o Map con arrays de doubles.
  /// Decodifica a Lis y lo añade punto a punto al buffer,
  /// simulando un ECG que avanza y mantiene 30 puntos.
  void _feedBuffer(Object? raw, List<FlSpot> buf) {
    List<double> arr;
    Object? latest = raw;

    // Si es Map con timestamps, usamos solo el último valor
    if (raw is Map) {
      if (raw.isEmpty) return;
      final entries = raw.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      latest = entries.last.value;
    }

    // Decodificar JSON-string
    if (latest is String) {
      try {
        arr = List<double>.from(json.decode(latest));
      } catch (_) {
        return;
      }
    }
    // Directamente List<dynamic>
    else if (latest is List) {
      arr = latest.map((e) => (e as num).toDouble()).toList();
    } else {
      return;
    }

    // Por cada valor en ese array, lo añadimos al buffer
    for (var v in arr) {
      _addPoint(buf, v);
    }
  }

  /// Añade un punto al buffer (x: counter/10, y: valor), mantiene longitud 30
  void _addPoint(List<FlSpot> buf, double y) {
    setState(() {
      final x = _counter++ / 10.0;
      buf.add(FlSpot(x, y));
      if (buf.length > 30) buf.removeAt(0);
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

  LineChartData _chartData(List<FlSpot> spots, Color color) {
    final hasData = spots.any((s) => s.y != 0);
    if (!hasData) {
      // Mostrar “No hay datos” en caso de no tener lecturas distintas de 0
      return LineChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        lineBarsData: [],
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 0,
            label: HorizontalLineLabel(
              show: true,
              labelResolver: (_) => 'No hay datos',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            color: Colors.transparent,
          )
        ]),
      );
    }

    final minX = spots.first.x;
    final maxX = spots.last.x;
    return LineChartData(
      minX: minX,
      maxX: maxX,
      borderData: FlBorderData(show: true),
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, interval: (maxX - minX) / 5),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ECG Dinámico')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1) BPM
            Text(
              'BPM: ${_bpm.round()}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 2) Gráficos
            Expanded(
              child: ListView(
                children: [
                  _buildChart(_bufD1, Colors.redAccent),
                  const SizedBox(height: 12),
                  _buildChart(_bufD2, Colors.green),
                  const SizedBox(height: 12),
                  _buildChart(_bufD3, Colors.blue),
                  const SizedBox(height: 16),
                  // 3) Debug: lista de valores actuales
                  Text(
                    'Buffer D1: ${_bufD1.map((s) => s.y.toStringAsFixed(2)).toList()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buffer D2: ${_bufD2.map((s) => s.y.toStringAsFixed(2)).toList()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buffer D3: ${_bufD3.map((s) => s.y.toStringAsFixed(2)).toList()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}