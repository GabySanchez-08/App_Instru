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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

void login(BuildContext context) async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  try {
    // 1. Iniciar sesión con Firebase Auth
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Verificar si el widget sigue montado antes de usar context
    if (!mounted) return;

    // 3. Obtener UID y buscar el rol en Firestore
    final uid = userCredential.user!.uid;
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();

    final rol = doc['rol'];

    if (!mounted) return;

    // 4. Redirigir según el rol
    if (rol == 'paciente') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InterfazPaciente()),
      );
    } else if (rol == 'familiar') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InterfazFamiliar()),
      );
    } else {
      throw 'Rol desconocido';
    }
  } catch (e) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: const Text('Credenciales inválidas o problema al obtener rol.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
  void goToRegister(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
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
          Image.asset(
            'assets/logo_cuadrado.png',
            height: 180, // ajusta el tamaño si deseas
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Usuario'),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => login(context),
            child: const Text('Ingresar'),
          ),
          TextButton(
            onPressed: () => goToRegister(context),
            child: const Text('¿No tienes cuenta? Regístrate'),
          ),
        ],
      ),
    ),
  );
}
}