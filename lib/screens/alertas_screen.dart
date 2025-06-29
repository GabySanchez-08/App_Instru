import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  List<FlSpot> _parseSeries(Map<dynamic, dynamic> raw) {
    final puntos = <FlSpot>[];
    final sorted = raw.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    int i = 0;
    for (var e in sorted) {
      final valores = (e.value as String)
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((s) => double.tryParse(s.trim()) ?? 0.0)
          .toList();
      for (var v in valores) {
        puntos.add(FlSpot(i.toDouble(), v));
        i++;
      }
    }
    return puntos;
  }

  Widget _buildGrafica(String label, List<FlSpot> puntos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: puntos,
                  isCurved: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('Dispositivo/Wayne/ECG_Alertas');

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')), 
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('No hay alertas.'));
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final alerta = data['alerta'] as Map<dynamic, dynamic>;
          final mensaje = data['mensaje'] ?? 'Alerta';
          final hora = data['hora'] ?? '--:--';
          final horaInicio = data['hora_inicio'] ?? '--:--';

          final derivaciones = alerta['Derivaciones'] as Map<dynamic, dynamic>?;

          final bD1 = derivaciones?['B_D1'] as Map<dynamic, dynamic>?;
          final bD2 = derivaciones?['B_D2'] as Map<dynamic, dynamic>?;
          final bD3 = derivaciones?['B_D3'] as Map<dynamic, dynamic>?;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(mensaje),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Evento: $mensaje'),
                    Text('Inicio del evento: $horaInicio'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (bD1 != null) _buildGrafica('Derivación D1', _parseSeries(bD1)),
              if (bD2 != null) _buildGrafica('Derivación D2', _parseSeries(bD2)),
              if (bD3 != null) _buildGrafica('Derivación D3', _parseSeries(bD3)),
            ],
          );
        },
      ),
    );
  }
}