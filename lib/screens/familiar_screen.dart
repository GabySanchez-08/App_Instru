import 'package:flutter/material.dart';

class InterfazFamiliar extends StatelessWidget {
  const InterfazFamiliar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menú del Familiar')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Text(
              '🔔 Últimas alertas del paciente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _botonOpcion(
              context,
              texto: '📤 Generar Reporte para Médico',
              destino: const PantallaSimulada(titulo: 'Exportando reporte...'),
            ),
            const SizedBox(height: 20),
            _botonOpcion(
              context,
              texto: '💬 Enviar Mensaje Motivador',
              destino: const EnviarMensajePantalla(),
            ),
            const SizedBox(height: 20),
            _botonOpcion(
              context,
              texto: '⚙️ Configurar Alertas',
              destino: const PantallaSimulada(titulo: 'Configuración de alertas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonOpcion(BuildContext context,
      {required String texto, required Widget destino}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
      },
      child: Text(texto),
    );
  }
}

class EnviarMensajePantalla extends StatefulWidget {
  const EnviarMensajePantalla({super.key});

  @override
  State<EnviarMensajePantalla> createState() => _EnviarMensajePantallaState();
}

class _EnviarMensajePantallaState extends State<EnviarMensajePantalla> {
  final TextEditingController _mensajeController = TextEditingController();
  String? _mensajeEnviado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar mensaje motivador')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Escribe un mensaje para el paciente:'),
            const SizedBox(height: 16),
            TextField(
              controller: _mensajeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ejemplo: ¡Sigue adelante, estás haciendo un gran trabajo!',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _mensajeEnviado = _mensajeController.text;
                });
              },
              child: const Text('Enviar Mensaje'),
            ),
            if (_mensajeEnviado != null) ...[
              const SizedBox(height: 30),
              Text(
                'Mensaje enviado: $_mensajeEnviado',
                style: const TextStyle(fontStyle: FontStyle.italic),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class PantallaSimulada extends StatelessWidget {
  final String titulo;

  const PantallaSimulada({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titulo,
                style: const TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver al Menú'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}