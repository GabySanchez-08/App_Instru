import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

      docs.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));

      setState(() {
        eventos = docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error al cargar eventos: $e');
    }
  }

  String formatearFecha(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '---';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String formatearHora(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '---';
    return DateFormat('HH:mm:ss').format(date);
  }

  Future<Uint8List> networkImageToByte(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Error al cargar imagen');
    }
  }

  Future<Uint8List> _generarPDF() async {
    final pdf = pw.Document();

    for (var e in eventos) {
      final imagenes = e['imagenes'] ?? {};
      final imagenD1 = imagenes['D1'];
      final imagenD2 = imagenes['D2'];
      final imagenD3 = imagenes['D3'];

      Uint8List? imgBytesD1;
      Uint8List? imgBytesD2;
      Uint8List? imgBytesD3;

      try {
        if (imagenD1 != null) imgBytesD1 = await networkImageToByte(imagenD1);
      } catch (_) {}
      try {
        if (imagenD2 != null) imgBytesD2 = await networkImageToByte(imagenD2);
      } catch (_) {}
      try {
        if (imagenD3 != null) imgBytesD3 = await networkImageToByte(imagenD3);
      } catch (_) {}

      // Obtener solo el primer valor de BPM si es un string
      String bpmRaw = e['BPM'] ?? '';
      double? bpmValue;
      try {
        final parsed = jsonDecode(bpmRaw);
        if (parsed is List && parsed.isNotEmpty) {
          bpmValue = parsed.first.toDouble();
        }
      } catch (_) {}

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Evento: ${e['tipo']}'),
              pw.Text('Fecha: ${formatearFecha(e['hora_inicio'])}'),
              pw.Text('Hora: ${formatearHora(e['hora_inicio'])}'),
              pw.Text('BPM: ${bpmValue?.toStringAsFixed(0) ?? "--"}'),
              pw.SizedBox(height: 10),
              if (imgBytesD1 != null) pw.Image(pw.MemoryImage(imgBytesD1)),
              if (imgBytesD2 != null) ...[
                pw.SizedBox(height: 10),
                pw.Image(pw.MemoryImage(imgBytesD2)),
              ],
              if (imgBytesD3 != null) ...[
                pw.SizedBox(height: 10),
                pw.Image(pw.MemoryImage(imgBytesD3)),
              ],
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
    final ultimos5 = eventos.length > 5 ? eventos.take(5).toList() : eventos;

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
                    'Eventos registrados:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...ultimos5.map((e) {
                    String bpmRaw = e['BPM'] ?? '';
                    double? bpmValue;
                    try {
                      final parsed = jsonDecode(bpmRaw);
                      if (parsed is List && parsed.isNotEmpty) {
                        bpmValue = parsed.first.toDouble();
                      }
                    } catch (_) {}

                    return Card(
                      child: ListTile(
                        title: Text('Tipo: ${e['tipo']} - BPM: ${bpmValue?.toStringAsFixed(0) ?? "--"}'),
                        subtitle: Text(
                          'Fecha: ${formatearFecha(e['hora_inicio'])} • Hora: ${formatearHora(e['hora_inicio'])}',
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Generar PDF'),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          final pdfData = await _generarPDF();
                          Navigator.of(context).pop();

                          await Printing.layoutPdf(
                            onLayout: (format) async => pdfData,
                          );
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al generar PDF: $e')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}