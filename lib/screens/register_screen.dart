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
  final _nombreCtrl    = TextEditingController();
  final _apellidoCtrl  = TextEditingController();
  final _celularCtrl   = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();

  String _rol = 'paciente';
  bool   _loading = false;

  Future<void> register() async {
    final nombre   = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final celular  = _celularCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (nombre.isEmpty || apellido.isEmpty || celular.isEmpty || email.isEmpty || password.isEmpty) {
      await _showError('Por favor completa todos los campos.');
      return;
    }

    setState(() => _loading = true);
    try {
      // 1) Crear usuario en Auth
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2) Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
        'nombre'   : nombre,
        'apellido' : apellido,
        'celular'  : celular,
        'email'    : email,
        'rol'      : _rol,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 3) Diálogo de éxito
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

      if (!mounted) return;
      Navigator.of(context).pop();
    }
    on FirebaseAuthException catch (e) {
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
      await _showError(msg);
    }
    catch (e) {
      await _showError('Ocurrió un error inesperado.');
    }
    finally {
      if (mounted) setState(() => _loading = false);
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
            child: const Text('Regresar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _celularCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apellidoCtrl,
                      decoration: const InputDecoration(labelText: 'Apellido'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _celularCtrl,
                      decoration: const InputDecoration(labelText: 'Celular'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
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
                    ElevatedButton(
                      onPressed: register,
                      child: const Text('Registrarse'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}