import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart'; // Este archivo se genera con el asistente de Firebase
import 'screens/login_screen.dart'; // o tu pantalla de inicio

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //  options: DefaultFirebaseOptions.currentPlatform,
  //);
  runApp(const CardioAlertApp());
}


class CardioAlertApp extends StatelessWidget {
  const CardioAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CardioAlert',
      home: LoginScreen(),
    );
  }
}