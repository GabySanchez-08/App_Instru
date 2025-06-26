// reporte_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../widgets/grafico_derivacion.dart';

class ReporteScreen extends StatefulWidget {
  const ReporteScreen({super.key});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  List<Map<String, dynamic>> eventos = [];
  final ScreenshotController screenshotCtrl = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('eventos')
        .orderBy('hora_inicio', descending: true)
        .get();

    setState(() {
      eventos = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  List<double> _parseList(String raw) {
    raw = raw.replaceAll('[', '').replaceAll(']', '');
    return raw.split(',').map((e) => double.tryParse(e.trim()) ?? 0).toList();
  }

  Future<Uint8List> _crearGraficoComoImagen(
      List<double> datos, String label) async {
    final widget = Material(
      child: GraficoDerivacion(
        datos: datos.take(100).toList(),
        label: label,
      ),
    );

    return await screenshotCtrl.captureFromWidget(widget);
  }

  Future<Uint8List> _generarPDF() async {
    final pdf = pw.Document();

    for (var e in eventos) {
      final d1 = _parseList(e['D1']);
      final d2 = _parseList(e['D2']);
      final d3 = _parseList(e['D3']);

      final d1img = await _crearGraficoComoImagen(d1, 'D1');
      final d2img = await _crearGraficoComoImagen(d2, 'D2');
      final d3img = await _crearGraficoComoImagen(d3, 'D3');

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Evento: ${e['tipo']}'),
              pw.Text('Hora: ${e['hora_inicio']} - BPM: ${e['BPM']}'),
              pw.SizedBox(height: 10),
              pw.Text('Derivación D1'),
              pw.Image(pw.MemoryImage(d1img)),
              pw.SizedBox(height: 10),
              pw.Text('Derivación D2'),
              pw.Image(pw.MemoryImage(d2img)),
              pw.SizedBox(height: 10),
              pw.Text('Derivación D3'),
              pw.Image(pw.MemoryImage(d3img)),
              pw.Divider(),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final ultimos = eventos.length > 3 ? eventos.take(3).toList() : eventos;

    return Scaffold(
      appBar: AppBar(title: const Text('Reporte de Eventos')),
      body: eventos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Últimos eventos:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...ultimos.map((e) => Card(
                        child: ListTile(
                          title: Text('Tipo: ${e['tipo']} - BPM: ${e['BPM']}'),
                          subtitle:
                              Text('Hora: ${e['hora_inicio'] ?? '---'}'),
                        ),
                      )),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generar PDF'),
                      onPressed: () async {
                        final pdfData = await _generarPDF();
                        await Printing.layoutPdf(
                            onLayout: (format) async => pdfData);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}