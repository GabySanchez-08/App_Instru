
import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 20),
            Text('Nombre: Gaby', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Correo: gaby@ejemplo.com', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Rol: Paciente', style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
            Text('Aquí podrías agregar opciones para editar el perfil, cambiar contraseña, etc.', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
