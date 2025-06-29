// lib/screens/alertas_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

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
          final items = data.entries.toList()
            ..sort((a, b) => b.key.toString().compareTo(a.key.toString())); // Ordenar por clave descendente

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final alerta = items[index].value as Map;
              final mensaje = alerta['mensaje'] ?? 'Alerta';
              final hora = alerta['hora'] ?? '';
              final horaInicio = alerta['hora_inicio'] ?? '';
              final derivaciones = alerta['Derivaciones'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(mensaje),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hora: $hora'),
                      if (horaInicio.isNotEmpty) Text('Inicio: $horaInicio'),
                      if (derivaciones != null)
                        Text('Derivaciones: ${derivaciones.toString()}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}