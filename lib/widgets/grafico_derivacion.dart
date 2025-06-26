// widgets/grafico_derivacion.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficoDerivacion extends StatelessWidget {
  final List<double> datos;
  final String label;

  const GraficoDerivacion({
    super.key,
    required this.datos,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      datos.length,
      (i) => FlSpot(i.toDouble(), datos[i]),
    );

    return SizedBox(
      height: 150,
      width: 300,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              color: Colors.red,
            ),
          ],
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}