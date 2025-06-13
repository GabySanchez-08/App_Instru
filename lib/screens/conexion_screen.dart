// lib/screens/conexion_screen.dart

import 'package:flutter/material.dart';

class ConexionScreen extends StatelessWidget {
  const ConexionScreen({super.key});

  final List<_PasoConexion> _pasos = const [
    _PasoConexion(
      icon: Icons.power,
      titulo: '1. Enciende el dispositivo',
      detalle:
          'Presiona el botón de encendido hasta que se ilumine la luz indicadora.',
    ),
    _PasoConexion(
      icon: Icons.wifi,
      titulo: '2. Verifica el parpadeo',
      detalle:
          'La luz debe parpadear en intervalos regulares. Si no parpadea, apaga y vuelve a encender.',
    ),
    _PasoConexion(
      icon: Icons.wifi_outlined,
      titulo: '3. Conéctate al Wi-Fi',
      detalle:
          'Asegúrate de que tu teléfono esté en la misma red Wi-Fi que el dispositivo.',
    ),
    _PasoConexion(
      icon: Icons.check_circle,
      titulo: '4. Confirma conexión',
      detalle:
          'En la app debería aparecer “Dispositivo conectado” en la parte superior.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar Dispositivo')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pasos.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final paso = _pasos[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(paso.icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paso.titulo,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(paso.detalle, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PasoConexion {
  final IconData icon;
  final String titulo;
  final String detalle;

  const _PasoConexion({
    required this.icon,
    required this.titulo,
    required this.detalle,
  });
}