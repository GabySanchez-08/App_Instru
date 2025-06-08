// paciente_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'perfil_screen.dart';
import 'login_screen.dart';

import '../widgets/device_status.dart';

class InterfazPaciente extends StatelessWidget {
  const InterfazPaciente({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1) AppBar flotante
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Resumen'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'perfil':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PerfilScreen()),
                      );
                      break;
                    case 'notificaciones':
                      _showInfo(context, 'Configuración de notificaciones');
                      break;
                    case 'cerrar':
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'perfil', child: Text('Ver perfil')),
                  PopupMenuItem(value: 'notificaciones', child: Text('Config. notificaciones')),
                  PopupMenuItem(value: 'cerrar', child: Text('Cerrar sesión')),
                ],
              ),
            ],
          ),

          // Nuevo bloque: Estado del dispositivo
          const SliverToBoxAdapter(
            child: DeviceStatusBanner(),
          ),

          // 2) Tarjetas de dato rápido (sin ECG)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: const [
                  _SummaryCard(icon: Icons.warning,      label: 'Alertas',    value: '1 nueva'),
                  _SummaryCard(icon: Icons.insert_chart, label: 'Reportes',   value: '3 esta semana'),
                  _SummaryCard(icon: Icons.message,      label: 'Mensajes',   value: '2 recibidos'),
                ],
              ),
            ),
          ),

          // 3) Sección de acciones rápidas en grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3,
              children: [
                _ActionCard(
                  icon: Icons.usb,
                  label: 'Conectar Dispositivo',
                  color: Colors.blue,
                  onTap: () => _showInfo(context, 'Instrucciones de conexión'),
                ),
                _ActionCard(
                  icon: Icons.report,
                  label: 'Generar Reporte',
                  color: Colors.green,
                  onTap: () => _showInfo(context, 'Exportando reporte...'),
                ),
                _ActionCard(
                  icon: Icons.message,
                  label: 'Ver Mensajes',
                  color: Colors.purple,
                  onTap: () => _showInfo(context, 'Mensajes de tu familiar'),
                ),
                _ActionCard(
                  icon: Icons.favorite,
                  label: 'Tips Salud',
                  color: Colors.orange,
                  onTap: () => _showInfo(context, 'Consejos para tu corazón'),
                ),
                _ActionCard(
                  icon: Icons.warning,
                  label: 'SOS',
                  color: Colors.red,
                  onTap: () => _showInfo(context, 'SOS enviado 🚨'),
                ),
              ],
            ),
          ),

          // 4) Histórico breve
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Histórico Reciente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _HistoryItem(
                icon: Icons.insert_chart,
                title: 'Reportes',
                subtitle: '3 generados esta semana',
              ),
              _HistoryItem(
                icon: Icons.message,
                title: 'Mensajes',
                subtitle: '2 últimos mensajes recibidos',
              ),
              _HistoryItem(
                icon: Icons.alarm,
                title: 'Recordatorios',
                subtitle: '1 pendiente hoy',
              ),
              const SizedBox(height: 24),
            ]),
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

// Tarjeta horizontal de resumen
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const Spacer(),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta de acción rápida en grid
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
      color: color.withAlpha((0.1 * 0xFF).round()),
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