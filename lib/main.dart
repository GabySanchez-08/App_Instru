import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/login_screen.dart';
import 'screens/paciente_screen.dart';
import 'screens/familiar_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

String? ultimaHoraDetectada;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicializar notificaciones locales
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Inicializar notificaciones FCM en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Iniciar listener a Realtime Database
  _escucharAlertas();

  runApp(const CardioAlertApp());
}

// 🟡 Manejo de mensajes FCM en segundo plano (si decides usarlo más adelante)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Aquí puedes hacer algo con el mensaje, si lo necesitas
}

class CardioAlertApp extends StatelessWidget {
  const CardioAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardioCore',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        } else {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .get(),
            builder: (context, snap2) {
              if (snap2.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snap2.hasData || !snap2.data!.exists) {
                return const LoginScreen(); // o RegisterScreen si lo tienes
              }
              final rol = snap2.data!['rol'] as String;
              if (rol == 'paciente') {
                return const InterfazPaciente();
              } else {
                return const InterfazFamiliar();
              }
            },
          );
        }
      },
    );
  }
}

void _escucharAlertas() {
  final ref = FirebaseDatabase.instance.ref('Dispositivo/Wayne/ECG_Alertas');

  ref.onValue.listen((DatabaseEvent event) {
    final data = event.snapshot.value;
    if (data is Map && data.containsKey('hora_inicio')) {
      final hora = data['hora_inicio'];
      final mensaje = data['mensaje'] ?? 'Alerta detectada';

      if (hora != null && hora != ultimaHoraDetectada && hora != '--:--') {
        ultimaHoraDetectada = hora;

        _mostrarNotificacion(
          titulo: 'Nueva Alerta ECG',
          cuerpo: 'Alerta detectada a las $hora: $mensaje',
        );
      }
    }
  });
}

void _mostrarNotificacion({required String titulo, required String cuerpo}) {
  const androidDetails = AndroidNotificationDetails(
    'canal_alertas',
    'Alertas ECG',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
  );

  const iosDetails = DarwinNotificationDetails();

  final notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  flutterLocalNotificationsPlugin.show(
    0,
    titulo,
    cuerpo,
    notificationDetails,
  );
}