// lib/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _celularCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _celularCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCelular(String uid) async {
    final nuevo = _celularCtrl.text.trim();
    if (nuevo.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('El celular no puede estar vacío')));
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({'celular': nuevo});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Celular actualizado')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error al actualizar')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('No hay usuario autenticado')),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del Usuario')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('No se encontró perfil en Firestore'));
          }

          final data = snap.data!.data()! as Map<String, dynamic>;
          // Rellenamos el controlador solo una vez
          _celularCtrl.text = data['celular'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre: ${data['nombre'] ?? ''}', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                Text('Apellido: ${data['apellido'] ?? ''}', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 10),
                Text('Correo: ${data['email'] ?? user.email}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text('Rol: ${data['rol'] ?? ''}', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 30),
                const Text('Celular:', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                TextField(
                  controller: _celularCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa tu número de celular',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _saveCelular(user.uid),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar Celular'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}