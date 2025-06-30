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
    final xMax = puntos.isNotEmpty ? puntos.last.x.toDouble() : 100.0;
    final yValues = puntos.map((e) => e.y);
    final yMin = yValues.isNotEmpty ? yValues.reduce((a, b) => a < b ? a : b) : -1.0;
    final yMax = yValues.isNotEmpty ? yValues.reduce((a, b) => a > b ? a : b) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            minScale: 1.0,
            maxScale: 5.0,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: xMax,
                minY: yMin - 0.5,
                maxY: yMax + 0.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: puntos,
                    isCurved: false,
                    color: Colors.blueAccent,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 100,
                      getTitlesWidget: (value, _) => Text(
                        '${(value / 100).toStringAsFixed(1)}s',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.5,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(),
                    bottom: BorderSide(),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItems: (spots) => spots.map((spot) {
                      return LineTooltipItem(
                        '${(spot.x / 100).toStringAsFixed(2)}s\n${spot.y.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 10,
                ),
              ),
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
          //final hora = data['hora'] ?? '--:--';
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
                    //Text('Hora de alerta: $hora'),
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