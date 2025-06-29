// familiar_screen.dart
import 'package:flutter/material.dart';    
import 'package:firebase_database/firebase_database.dart';
import 'ecg_viewer_screen.dart';
import 'chat_screen.dart';
import 'reporte_screen.dart';
import 'alertas_screen.dart';
import '../widgets/device_status.dart';
import '../widgets/app_menu.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class InterfazFamiliar extends StatefulWidget {
  const InterfazFamiliar({super.key});

  @override
  State<InterfazFamiliar> createState() => _InterfazFamiliarState();
}

class _InterfazFamiliarState extends State<InterfazFamiliar> {
  final _alertasRef = FirebaseDatabase.instance.ref('Dispositivo/Wayne/ECG_Alertas');
  int _cantidadAlertas = 0;

  @override
  void initState() {
    super.initState();
    _alertasRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        setState(() {
          _cantidadAlertas = data.length;
        });
      }
    });
    _setupFCM(); // 👈 Aquí llamas la función
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppMenu(title: 'Resumen'),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: DeviceStatusBanner(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlertasScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, size: 32, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$_cantidadAlertas alerta${_cantidadAlertas != 1 ? 's' : ''} nueva${_cantidadAlertas != 1 ? 's' : ''}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
              children: [
                _ActionCard(
                  icon: Icons.insert_drive_file,
                  label: 'Generar Reporte',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReporteScreen()),
                  ),
                ),
                _ActionCard(
                  icon: Icons.chat_bubble,
                  label: 'Ver Mensajes',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(
                        myRole: 'familiar',
                        otherRole: 'paciente',
                      ),
                    ),
                  ),
                ),
                _ActionCard(
                  icon: Icons.settings,
                  label: 'Configurar Alertas',
                  color: Colors.orange,
                  onTap: () => _showInfo(context, 'Configuración de alertas'),
                ),
                _ActionCard(
                  icon: Icons.monitor_heart,
                  label: 'Ver ECG en Vivo',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EcgViewerScreen()),
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  void _showInfo(BuildContext ctx, String titulo) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: const Text('Funcionalidad en construcción.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }


  void _setupFCM() async {
    final messaging = FirebaseMessaging.instance;

      // Solicita permisos en iOS
      await messaging.requestPermission();

      // Token del dispositivo
      final token = await messaging.getToken();
      print('🔑 Token: $token');

      // Mensajes cuando la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Mensaje en foreground: ${message.notification?.title}');
        // Aquí podrías mostrar un snackbar o diálogo
      });

      // Mensajes cuando se hace clic y se abre la app
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('➡️ App abierta desde notificación');
        // Navegar a pantalla de alertas, por ejemplo
      });
    }

}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(0x1A),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}