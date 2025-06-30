import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reporte_screen.dart'; // o donde esté tu ReporteScreen
import 'chat_screen.dart'; // o donde esté tu ChatScreen
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


// Esto debe ir como variable global, fuera de las clases:
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


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

          // ⚠️ Detectar cambio de hora_inicio
          if (horaInicio != ultimaHoraVista && horaInicio != '--:--') {
            ultimaHoraVista = horaInicio;

            _mostrarNotificacion(
              titulo: 'Nueva Alerta ECG',
              cuerpo: 'Alerta detectada a las $horaInicio: $mensaje',
            );
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

  void _mostrarNotificacion({required String titulo, required String cuerpo}) {

    final androidDetails = AndroidNotificationDetails(
      'canal_alertas',
      'Alertas ECG',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    final iosDetails = DarwinNotificationDetails();

    final notiDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    

    flutterLocalNotificationsPlugin.show(
      0,
      titulo,
      cuerpo,
      notiDetails,
    );
  }
}