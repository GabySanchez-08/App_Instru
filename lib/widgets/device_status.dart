// lib/widgets/device_status.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceStatusBanner extends StatelessWidget {
  const DeviceStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance
        .ref('Dispositivo/ESP32/Estado');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        String text = 'Estado: —';
        Color  color = Colors.grey;

        if (snapshot.hasData) {
          final val = snapshot.data!.snapshot.value;
          if (val == 'conectado') {
            text = 'Estado: Conectado';
            color = Colors.green;
          } else if (val == 'desconectado') {
            text = 'Estado: Desconectado';
            color = Colors.red;
          }
        }

        return Container(
          width: double.infinity,
          color: color.withAlpha(0x33),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}