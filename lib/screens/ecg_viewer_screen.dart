import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:convert';

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

  Timer? _timerD1, _timerD2, _timerD3;

  double _bpm = 0;

  @override
  void initState() {
    super.initState();
    final root = FirebaseDatabase.instance.ref('Dispositivo/Wayne/ECG_Real');
    _refD1 = root.child('D1');
    _refD2 = root.child('D2');
    _refD3 = root.child('D3');
    _refBpm = root.child('BPM_realtime');

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

  // Maneja el nuevo array recibido desde Firebase
  void _handleNewArray(Object? raw, int derivada) {
    List<double>? parsed = _parse(raw);
    if (parsed == null || parsed.isEmpty) return;

    switch (derivada) {
      case 1:
        _timerD1?.cancel();  // Detener animación anterior
        _bufD1.clear();      // Limpiar gráfico anterior
        _animateData(parsed, _bufD1, 1); // Animar el gráfico con el nuevo conjunto de datos
        break;
      case 2:
        _timerD2?.cancel();
        _bufD2.clear();
        _animateData(parsed, _bufD2, 2);
        break;
      case 3:
        _timerD3?.cancel();
        _bufD3.clear();
        _animateData(parsed, _bufD3, 3);
        break;
    }
  }

  // Animación de los puntos a 100Hz
  void _animateData(List<double> data, List<FlSpot> buffer, int derivada) {
    int index = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 10), (t) {
      if (index >= data.length) {
        t.cancel();  // Detener el timer una vez que todos los puntos hayan sido agregados
        return;
      }

      final x = index / 100.0;  // 100 Hz → x en segundos
      final y = data[index];
      buffer.add(FlSpot(x, y));
      index++;

      setState(() {}); // Redibujar el gráfico con el nuevo punto
    });

    switch (derivada) {
      case 1:
        _timerD1 = timer;
        break;
      case 2:
        _timerD2 = timer;
        break;
      case 3:
        _timerD3 = timer;
        break;
    }
  }

  // Parseo del array de datos de Firebase
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

  // Datos de la gráfica
  LineChartData _chartData(List<FlSpot> spots, Color color) {
    return LineChartData(
      minX: 0.0,
      maxX: 3.0,  // Limitar el eje X a 3 segundos
      borderData: FlBorderData(show: true),
      gridData: FlGridData(show: true),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, _) => Text('${value.toStringAsFixed(0)}s', style: const TextStyle(fontSize: 10)),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, _) => Text('${value.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10)),
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  // Construcción de la gráfica
  Widget _buildChart(String titulo, List<FlSpot> buf, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        SizedBox(height: 120, child: LineChart(_chartData(buf, color))),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  void dispose() {
    _subD1.cancel();
    _subD2.cancel();
    _subD3.cancel();
    _subBpm.cancel();
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
            Text('BPM: ${_bpm.round()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildChart('1ra Derivada', _bufD1, Colors.redAccent),
                  _buildChart('2da Derivada', _bufD2, Colors.green),
                  _buildChart('3ra Derivada', _bufD3, Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}