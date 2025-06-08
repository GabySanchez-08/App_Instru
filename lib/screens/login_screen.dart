// login_screen.dart
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'paciente_screen.dart';
import 'familiar_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  Future<void> login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      // 1. Sign in
      final userCred = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      // 2. Fetch role
      final uid  = userCred.user!.uid;
      final doc  = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

      if (!mounted) return;

      if (!doc.exists) {
        // no perfil en Firestore
        await _showError(
          'Tu cuenta existe en Auth pero falta perfil en Firestore.\n'
          'Regístrate para completar tu perfil.'
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
        return;
      }

      final rol = doc['rol'] as String;

      if (!mounted) return;

      // 3. Navigate by role
      if (rol == 'paciente') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InterfazPaciente()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InterfazFamiliar()),
        );
      }
    }
    on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      if (e.code == 'user-not-found') {
        msg = 'Usuario no encontrado.';
      } else if (e.code == 'wrong-password') {
        msg = 'Contraseña incorrecta.';
      } else {
        msg = 'Error iniciando sesión.';
      }
      await _showError(msg);
    }
    catch (_) {
      if (!mounted) return;
      await _showError('Ocurrió un error inesperado.');
    }
  }

  Future<void> _showError(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo_cuadrado.png', height: 180),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text('Ingresar'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }
}