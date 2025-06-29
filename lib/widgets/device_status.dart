import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class DeviceStatusBanner extends StatelessWidget {
  const DeviceStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance
        .ref('Dispositivo/Wayne/ECG_Alertas/alerta/hora'); // lectura directa

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        String text = 'Estado: —';
        Color color = Colors.grey;

        if (snapshot.hasData) {
          final val = snapshot.data!.snapshot.value;
          if (val != null && val is String) {
            try {
              final ahora = DateTime.now();
              final formato = DateFormat('HH:mm:ss');
              final horaAlerta = formato.parse(val);

              // Convertimos ambas a hoy con misma fecha
              final ahoraHoy = DateTime(0, 1, 1, ahora.hour, ahora.minute, ahora.second);
              final horaAlertaHoy = DateTime(0, 1, 1, horaAlerta.hour, horaAlerta.minute, horaAlerta.second);

              final diff = ahoraHoy.difference(horaAlertaHoy).inSeconds.abs();

              if (diff <= 20) {
                text = 'Estado: Conectado';
                color = Colors.green;
              } else {
                text = 'Estado: Desconectado';
                color = Colors.red;
              }
            } catch (_) {
              text = 'Estado: Error de formato';
              color = Colors.orange;
            }
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