import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class ReporteScreen extends StatefulWidget {
  const ReporteScreen({super.key});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  List<Map<String, dynamic>> eventos = [];

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<String> _determinarUID() async {
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    if (userDoc.exists && userDoc.data()!['rol'] == 'familiar') {
      // Buscar UID de paciente asociado a ale@gmail.com
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: 'ale@gmail.com')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      } else {
        throw Exception('Paciente ale@gmail.com no encontrado');
      }
    }
    return user.uid;
  }


  Future<void> _cargarEventos() async {
    try {
      final uid = await _determinarUID();
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('eventos')
          .get();

      final docs = snapshot.docs;

      // Ordenar manualmente por ID del documento (convertido a int)
      docs.sort((a, b) =>
          int.parse(b.id).compareTo(int.parse(a.id))); // Descendente

      // Tomar solo los 5 últimos
      final ultimosDocs = docs.take(5).toList();

      setState(() {
        eventos = ultimosDocs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error al cargar eventos: $e');
    }
  } 


  List<double> _parseList(String raw) {
    raw = raw.replaceAll('[', '').replaceAll(']', '');
    return raw.split(',').map((e) => double.tryParse(e.trim()) ?? 0).toList();
  }

  pw.Widget _graficoDeEvento(String label, List<double> data) {
    const double width = 300;
    const double height = 100;

    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final rangeY = (maxY - minY) == 0 ? 1 : (maxY - minY);

    final stepX = width / data.length;
    final lines = <pw.Widget>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = height - ((data[i] - minY) / rangeY * height);

      lines.add(pw.Positioned(
        left: x,
        top: y,
        child: pw.Container(
          width: 1,
          height: 1,
          color: PdfColors.black,
        ),
      ));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Container(
          width: width,
          height: height,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Stack(children: lines),
        ),
      ],
    );
  }

  Future<Uint8List> _generarPDF() async {
    final pdf = pw.Document();

    for (var e in eventos) {
      final d1 = _parseList(e['D1']);
      final d2 = _parseList(e['D2']);
      final d3 = _parseList(e['D3']);

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Evento: ${e['tipo']}'),
              pw.Text('Hora: ${e['hora_inicio']} - BPM: ${e['BPM']}'),
              pw.SizedBox(height: 10),
              _graficoDeEvento('Derivación D1', d1.take(100).toList()),
              pw.SizedBox(height: 10),
              _graficoDeEvento('Derivación D2', d2.take(100).toList()),
              pw.SizedBox(height: 10),
              _graficoDeEvento('Derivación D3', d3.take(100).toList()),
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
    final ultimos = eventos.length > 5 ? eventos.take(5).toList() : eventos;

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
                          subtitle: Text('Hora: ${e['hora_inicio'] ?? '---'}'),
                        ),
                      )),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generar PDF'),
                      onPressed: () async {
                        final pdfData = await _generarPDF();
                        await Printing.layoutPdf(onLayout: (format) async => pdfData);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}