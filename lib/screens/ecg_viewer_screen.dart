// lib/screens/ecg_viewer_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class EcgViewerScreen extends StatefulWidget {
  const EcgViewerScreen({super.key});

  @override
  EcgViewerScreenState createState() => EcgViewerScreenState();
}

class EcgViewerScreenState extends State<EcgViewerScreen> {
  // Referencias a cada derivada
  late final DatabaseReference _refD1;
  late final DatabaseReference _refD2;
  late final DatabaseReference _refD3;
  late final DatabaseReference _refBpm;

  // Listas circulares de 5s a 100Hz = 500 puntos
  final List<FlSpot> _d1 = [];
  final List<FlSpot> _d2 = [];
  final List<FlSpot> _d3 = [];
  double _timeCounter = 0; // segundos transcurridos
  double _bpm = 0;

  late StreamSubscription<DatabaseEvent> _subD1;
  late StreamSubscription<DatabaseEvent> _subD2;
  late StreamSubscription<DatabaseEvent> _subD3;
  late StreamSubscription<DatabaseEvent> _subBpm;

  @override
  void initState() {
    super.initState();
    final root = FirebaseDatabase.instance.ref('ECG_Data');
    _refD1 = root.child('D1');
    _refD2 = root.child('D2');
    _refD3 = root.child('D3');
    _refBpm = root.child('BPM');

    // Escuchar cada derivada
    _subD1 = _refD1.onChildAdded.listen((ev) => _onData(ev, _d1));
    _subD2 = _refD2.onChildAdded.listen((ev) => _onData(ev, _d2));
    _subD3 = _refD3.onChildAdded.listen((ev) => _onData(ev, _d3));
    _subBpm = _refBpm.onValue.listen((ev) {
      final v = ev.snapshot.value;
      if (v is num) {
        setState(() => _bpm = v.toDouble());
      }
    });
  }

  void _onData(DatabaseEvent ev, List<FlSpot> list) {
    final raw = ev.snapshot.value;
    if (raw is num) {
      // Añadir nuevo punto en tiempo incremental
      setState(() {
        list.add(FlSpot(_timeCounter, raw.toDouble()));
        _timeCounter += 1 / 100; // siguiente punto a +0.01s
        // Mantener solo los últimos 5 segundos
        while (list.isNotEmpty && _timeCounter - list.first.x > 5) {
          list.removeAt(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _subD1.cancel();
    _subD2.cancel();
    _subD3.cancel();
    _subBpm.cancel();
    super.dispose();
  }

  LineChartData _buildChart(List<FlSpot> spots) {
    return LineChartData(
      minX: _timeCounter > 5 ? _timeCounter - 5 : 0,
      maxX: _timeCounter,
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 22),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
      ),
      gridData: FlGridData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          dotData: FlDotData(show: false),
          color: Colors.redAccent,
          barWidth: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ECG en Vivo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // BPM arriba
            Text('BPM: ${_bpm.round()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Tres gráficos
            Expanded(
              child: ListView(
                children: [
                  SizedBox(
                    height: 120,
                    child: LineChart(_buildChart(_d1)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: LineChart(_buildChart(_d2)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: LineChart(_buildChart(_d3)),
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