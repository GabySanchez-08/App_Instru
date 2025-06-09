// lib/widgets/app_menu.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/perfil_screen.dart';

class AppMenu extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppMenu({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'perfil') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
            } else if (value == 'notificaciones') {
              // you can extract a showInfo here too
            } else if (value == 'cerrar') {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'perfil', child: Text('Ver perfil')),
            PopupMenuItem(value: 'notificaciones', child: Text('Notificaciones')),
            PopupMenuItem(value: 'cerrar', child: Text('Cerrar sesión')),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}