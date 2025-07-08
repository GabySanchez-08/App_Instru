import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:typed_data';

import 'reporte_screen.dart';
import 'chat_screen.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  String? ultimaHoraVista;
  Map<dynamic, dynamic>? ultimoEvento;

  String formatearFecha(String iso) {
    try {
      final date = DateFormat('HH:mm:ss yyyy-MM-dd').parse(iso);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '---';
    }
  }

  String formatearHora(String iso) {
    try {
      final date = DateFormat('HH:mm:ss yyyy-MM-dd').parse(iso);
      return DateFormat('HH:mm:ss').format(date);
    } catch (e) {
      return '---';
    }
  }

  // 🔹 OBTENER UID SEGÚN ROL
  Future<String> _determinarUID() async {
    final user = FirebaseAuth.instance.currentUser;
    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user!.uid).get();

    if (userDoc.exists && userDoc.data()!['rol'] == 'familiar') {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: 'ale@gmail.com')
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return query.docs.first.id;
      throw Exception('Paciente ale@gmail.com no encontrado');
    }
    return user.uid;
  }

  // 🔹 DESCARGAR IMAGEN DESDE URL
  Future<Uint8List> networkImageToByte(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Error al cargar imagen');
    }
  }

  Future<Uint8List> _generarPDFUltimoEvento() async {
    final uid = await _determinarUID();

    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('eventos')
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception("No hay eventos disponibles en Firestore");
    }

    // Ordenar por el ID numérico descendente
    snapshot.docs.sort((a, b) => int.parse(b.id).compareTo(int.parse(a.id)));

    final evento = snapshot.docs.first.data();
    final imagenes = evento['imagenes'] ?? {};
    final pdf = pw.Document();

    Uint8List? imgBytesD1, imgBytesD2, imgBytesD3;
    try {
      if (imagenes['D1'] != null) imgBytesD1 = await networkImageToByte(imagenes['D1']);
    } catch (_) {}
    try {
      if (imagenes['D2'] != null) imgBytesD2 = await networkImageToByte(imagenes['D2']);
    } catch (_) {}
    try {
      if (imagenes['D3'] != null) imgBytesD3 = await networkImageToByte(imagenes['D3']);
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Evento: ${evento['tipo'] ?? "--"}'),
            pw.Text('Fecha: ${formatearFecha(evento['hora_inicio'] ?? "")}'),
            pw.Text('Hora: ${formatearHora(evento['hora_inicio'] ?? "")}'),
            
            pw.Text('BPM: ${(evento['BPM'] is List && evento['BPM'].isNotEmpty) ? evento['BPM'][0] : "--"}'),
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
          ],
        ),
      ),
    );

    return pdf.save();
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
          final mensaje = data['mensaje'] ?? 'Alerta';
          final horaInicio = data['hora_inicio'] ?? '--:--';

          if (horaInicio != ultimaHoraVista && horaInicio != '--:--') {
            ultimaHoraVista = horaInicio;
            ultimoEvento = data;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Fecha: ${formatearFecha(data['hora_inicio'] ?? "")} • Hora: ${formatearHora(data['hora_inicio'] ?? "")}'),
              ),
              const SizedBox(height: 24),
              const Text('Opciones disponibles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // 🔴 BOTÓN DE EXPORTAR PDF DESDE FIRESTORE
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar Último Evento'),
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final pdfData = await _generarPDFUltimoEvento();
                    Navigator.of(context).pop();
                    await Printing.layoutPdf(onLayout: (format) async => pdfData);
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
                  }
                },
              ),

              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.insert_drive_file,
                label: 'Generar Reporte',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReporteScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.chat_bubble,
                label: 'Enviar Mensajes',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatScreen(
                      myRole: 'familiar',
                      otherRole: 'paciente',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// 🔹 CARD REUTILIZABLE
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}