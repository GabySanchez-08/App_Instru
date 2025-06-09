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
  // Asumimos que cada ChildAdded en /ECG_Data es un latido
  final DatabaseReference _ecgRef = FirebaseDatabase.instance.ref('/ECG_Data');
  final List<_ECGData> _beats = []; // almacena sólo los últimos 3 latidos
  late StreamSubscription<DatabaseEvent> _sub;

  @override
  void initState() {
    super.initState();
    _sub = _ecgRef.onChildAdded.listen(_onBeat);
  }

  void _onBeat(DatabaseEvent ev) {
    final key = ev.snapshot.key;
    if (!mounted || key == null) return;
    // Aquí val podría contener la amplitud, pero la ignoramos
    final timestamp = int.tryParse(key);
    if (timestamp != null) {
      setState(() {
        if (_beats.length == 40) _beats.removeAt(0);
        _beats.add(_ECGData(DateTime.fromMillisecondsSinceEpoch(timestamp)));
      });
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  double _calculateBpm() {
    if (_beats.length < 2) return 0;
    // calcular intervalos
    final intervals = <double>[];
    for (var i = 1; i < _beats.length; i++) {
      intervals.add(
        _beats[i].time.difference(_beats[i - 1].time).inMilliseconds / 1000,
      );
    }
    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    if (avg == 0) return 0;
    return 60 / avg;
  }

  @override
  Widget build(BuildContext context) {
    final bpm = _calculateBpm().round();
    final spots = List<FlSpot>.generate(
      _beats.length,
      (i) => FlSpot(i.toDouble(), 1), // valor fijo para mostrar puntos alineados
    );

    return Scaffold(
      appBar: AppBar(title: const Text('ECG en Vivo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1) Gráfico simple mostrando max 3 puntos
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                      color: Colors.red,
                    ),
                  ],
                  titlesData: FlTitlesData(show: false),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2) Mostrar BPM
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('BPM: ',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(bpm > 0 ? '$bpm' : '--',
                    style:
                        TextStyle(fontSize: 24, color: Colors.redAccent)),
              ],
            ),

            const SizedBox(height: 24),

            // 3) Botón a últimas alertas
            ElevatedButton.icon(
              icon: const Icon(Icons.warning),
              label: const Text('Últimas Alertas'),
              onPressed: () {
                // Navegar a tu pantalla de alertas
                Navigator.pushNamed(context, '/alerts');
              },
            ),

            const SizedBox(height: 24),

            // 4) Lista de timestamps
            Expanded(
              child: ListView.builder(
                itemCount: _beats.length,
                itemBuilder: (ctx, i) {
                  final t = _beats[i].time;
                  return ListTile(
                    leading: const Icon(Icons.favorite, color: Colors.red),
                    title: Text(
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ECGData {
  _ECGData(this.time);
  final DateTime time;
}