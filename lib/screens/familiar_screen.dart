// familiar_screen.dart// familiar_screen.dart
import 'package:flutter/material.dart';    
import 'ecg_viewer_screen.dart';


import '../widgets/device_status.dart';
import '../widgets/app_menu.dart';
import 'chat_screen.dart';  //
import 'reporte_screen.dart';

class InterfazFamiliar extends StatelessWidget {
  const InterfazFamiliar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: const AppMenu(title: 'Resumen'),
      body: CustomScrollView(
        slivers: [
          // 1) AppBar flotante con menú

          // Nuevo bloque: Estado del dispositivo
          // Indica si está conectado o desconectado
          const SliverToBoxAdapter(
            child: DeviceStatusBanner(),
          ),

          // 2) “Pinned” con últimas alertas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.notifications_active,
                          size: 32, color: Colors.redAccent),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3) Acciones rápidas en grid
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
                    MaterialPageRoute(builder: (_) => const ReporteScreen())),
                ),
                _ActionCard(
                  icon: Icons.chat_bubble,
                  label: 'Ver Mensajes',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatScreen(
                          myRole: 'familiar',
                          otherRole: 'paciente',
                        ),
                      ),
                    );
                  },
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
                    MaterialPageRoute(
                        builder: (_) => const EcgViewerScreen()),
                  ),
                ),
              ],
            ),
          ),

          // 4) Sección “Histórico de acciones”
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Histórico de acciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                _HistoryItem(
                  icon: Icons.insert_drive_file,
                  title: 'Reportes generados',
                  subtitle: '',
                ),
                _HistoryItem(
                  icon: Icons.chat_bubble,
                  title: 'Mensajes enviados',
                  subtitle: '',
                ),
                _HistoryItem(
                  icon: Icons.settings,
                  title: 'Alertas configuradas',
                  subtitle: '',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showInfo(BuildContext ctx, String titulo) {
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
}

// Tarjeta de acción rápida
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
      color: color.withAlpha(0x1A), // 10% opacidad
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

// Ítem de histórico
class _HistoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HistoryItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDetail(context, title),
    );
  }

  void _showDetail(BuildContext ctx, String title) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('Detalle en construcción.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}