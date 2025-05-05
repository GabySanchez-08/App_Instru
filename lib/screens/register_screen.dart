import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _rol = 'paciente';

  void register() async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({'rol': _rol, 'email': _emailController.text.trim()});

      Navigator.pop(context);
    } catch (e) {
      print('Error al registrar: $e');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Correo')),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true),
            const SizedBox(height: 20),
            const Text('Selecciona tu rol:'),
            DropdownButton<String>(
              value: _rol,
              items: const [
                DropdownMenuItem(value: 'paciente', child: Text('Paciente')),
                DropdownMenuItem(value: 'familiar', child: Text('Familiar')),
              ],
              onChanged: (value) {
                setState(() => _rol = value!);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: register, child: const Text('Registrarse')),
          ],
        ),
      ),
    );
  }
}
