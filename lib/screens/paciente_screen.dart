import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'perfil_screen.dart';
import 'login_screen.dart'; 

class InterfazPaciente extends StatelessWidget {
  const InterfazPaciente({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú del Paciente'),
        actions: [
          PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'perfil':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
            break;
          case 'notificaciones':
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaSimulada(titulo: 'Configuración de Notificaciones')));
            break;
          case 'cerrar':
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
            break;
        }
      },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'perfil', child: Text('Ver perfil')),
              const PopupMenuItem(value: 'notificaciones', child: Text('Configuración de notificaciones')),
              const PopupMenuItem(value: 'cerrar', child: Text('Cerrar sesión')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const SizedBox(height: 30),
            _botonOpcion(
              context,
              texto: 'Conectar Dispositivo',
              destino: const PantallaSimulada(titulo: 'Instrucciones de conexión'),
            ),
            const SizedBox(height: 20),
            _botonOpcion(
              context,
              texto: 'Generar Reporte para Médico',
              destino: const PantallaSimulada(titulo: 'Exportando datos en forma de reporte'),
            ),
            const SizedBox(height: 20),
            _botonOpcion(
              context,
              texto: 'Ver Mensajes Motivacionales',
              destino: const PantallaSimulada(titulo: 'Mostrando mensajes de tu familiar ❤️'),
            ),
            const SizedBox(height: 20),
            _botonOpcion(
              context,
              texto: 'Tips de Salud Cardíaca',
              destino: const PantallaSimulada(titulo: 'Consejos para cuidar tu corazón'),
            ),
            const SizedBox(height: 20),
            _botonOpcion(
              context,
              texto: 'Botón de Pánico (SOS)',
              destino: const PantallaSimulada(titulo: 'SOS enviado 🚨'),
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonOpcion(BuildContext context,
      {required String texto, required Widget destino, Color? color}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.blue,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
      },
      child: Text(texto),
    );
  }
}

class PantallaSimulada extends StatelessWidget {
  final String titulo;

  const PantallaSimulada({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver al Menú'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}