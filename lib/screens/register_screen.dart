// register_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _rol = 'paciente';

  Future<void> register() async {
    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();

      // 1) Crear usuario
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2) Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({'rol': _rol, 'email': email});

      // 3) Revisar que el widget siga montado antes de llamar a context
      if (!mounted) return;

      // 4) Mostrar diálogo de éxito
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('¡Éxito!'),
          content: const Text('Usuario registrado con éxito.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Regresar'),
            ),
          ],
        ),
      );

      // 5) Una vez cerrado, volver
      if (!mounted) return;
      Navigator.of(context).pop();
    }
    on FirebaseAuthException catch (e) {
      // Determinar mensaje
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'El correo ya está registrado.';
          break;
        case 'invalid-email':
          msg = 'El correo ingresado no es válido.';
          break;
        case 'weak-password':
          msg = 'La contraseña es demasiado débil.';
          break;
        default:
          msg = 'Error registrando, por favor revisar datos.';
      }

      if (!mounted) return;
      await showError(msg);
    }
    catch (_) {
      if (!mounted) return;
      await showError('Ocurrió un error inesperado.');
    }
  }

  Future<void> showError(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Regresar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            const Text('Selecciona tu rol:'),
            DropdownButton<String>(
              value: _rol,
              items: const [
                DropdownMenuItem(value: 'paciente', child: Text('Paciente')),
                DropdownMenuItem(value: 'familiar', child: Text('Familiar')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _rol = v);
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
