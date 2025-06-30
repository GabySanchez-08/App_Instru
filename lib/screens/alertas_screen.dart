import 'package:flutter/material.dart';
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

class _AlertasScreenState extends State<AlertasScreen> {
  String? ultimaHoraVista;
  Map<dynamic, dynamic>? ultimoEvento;

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
                subtitle: Text('Inicio del evento: $horaInicio'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Opciones disponibles',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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

  Future<Uint8List> _generarPDFUltimoEvento() async {
    final pdf = pw.Document();

    if (ultimoEvento == null) {
      throw Exception("No hay evento reciente disponible.");
    }

    final imagenes = ultimoEvento!['imagenes'] ?? {};
    final imagenD1 = imagenes['D1'];
    final imagenD2 = imagenes['D2'];
    final imagenD3 = imagenes['D3'];

    Uint8List? imgBytesD1;
    Uint8List? imgBytesD2;
    Uint8List? imgBytesD3;

    try {
      if (imagenD1 != null) imgBytesD1 = await _networkImageToByte(imagenD1);
    } catch (_) {}
    try {
      if (imagenD2 != null) imgBytesD2 = await _networkImageToByte(imagenD2);
    } catch (_) {}
    try {
      if (imagenD3 != null) imgBytesD3 = await _networkImageToByte(imagenD3);
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Evento: ${ultimoEvento!['tipo']}'),
            pw.Text('Fecha: ${_formatearFecha(ultimoEvento!['hora_inicio'])}'),
            pw.Text('Hora: ${_formatearHora(ultimoEvento!['hora_inicio'])}'),
            pw.Text('BPM: ${ultimoEvento!['BPM'] ?? "--"}'),
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

  Future<Uint8List> _networkImageToByte(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Error al cargar imagen');
    }
  }

  String _formatearFecha(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '---';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatearHora(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '---';
    return DateFormat('HH:mm:ss').format(date);
  }
}
