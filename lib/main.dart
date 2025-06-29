// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/login_screen.dart';
import 'screens/paciente_screen.dart';
import 'screens/familiar_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


// Este método maneja notificaciones cuando la app está cerrada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Notificación en segundo plano: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const CardioAlertApp());
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
        // Aún conectando con Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // No hay sesión, mostramos login
          return const LoginScreen();
        } else {
          // Ya hay un usuario, obtenemos su rol para decidir pantalla
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
                // Usuario sin perfil de Firestore; lo enviamos a registro
                return const LoginScreen(); // O tu RegisterScreen
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