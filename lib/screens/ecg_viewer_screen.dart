import 'dart:async'; // Para manejar la suscripción

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EcgViewerScreen extends StatefulWidget {
  const EcgViewerScreen({super.key});

  @override
  EcgViewerScreenState createState() => EcgViewerScreenState();
}

class EcgViewerScreenState extends State<EcgViewerScreen> {
  final DatabaseReference _ecgDataRef = FirebaseDatabase.instance.ref('/ECG_Data');
  final List<_ECGData> dataPoints = [];

  late StreamSubscription<DatabaseEvent> _ecgSubscription;

  @override
  void initState() {
    super.initState();

    // Escuchar los nuevos datos de ECG
    _ecgSubscription = _ecgDataRef.onChildAdded.listen(_onDataAdded);
  }

  // Cancelar la suscripción cuando el widget se destruye
  @override
  void dispose() {
    _ecgSubscription.cancel();
    super.dispose();
  }

  // Manejar nuevos datos desde Firebase
  void _onDataAdded(DatabaseEvent event) {
    final dynamic data = event.snapshot.value;
    final String? timestamp = event.snapshot.key;

    if (!mounted) return; // Verifica que el widget siga en el árbol

    if (data is num && timestamp != null) {
      setState(() {
        dataPoints.add(_ECGData(timestamp, data.toDouble()));
      });

      print('🟢 ECG agregado - Timestamp: $timestamp, Value: $data');
    } else {
      print('⚠️ Dato inesperado en Firebase: $data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = dataPoints.asMap().entries.map(
      (entry) {
        final index = entry.key.toDouble();
        final value = entry.value.value;
        return FlSpot(index, value);
      },
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ECG - Gráfico + Lista'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Gráfico (parte superior, altura fija)
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 400,
                  maxY: 1600,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      dotData: FlDotData(show: false),
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
            const SizedBox(height: 20),

            // Título
            const Text(
              'Últimos datos recibidos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            // Lista de datos (resto del espacio)
            Expanded(
              child: ListView.builder(
                itemCount: dataPoints.length,
                itemBuilder: (context, index) {
                  final data = dataPoints[index];
                  return ListTile(
                    title: Text('Timestamp: ${data.time}'),
                    subtitle: Text('Valor ECG: ${data.value.toStringAsFixed(2)} mV'),
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
  _ECGData(this.time, this.value);
  final String time;
  final double value;
}