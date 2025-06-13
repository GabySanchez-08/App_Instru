// lib/screens/colocacion_screen.dart
import 'package:flutter/material.dart';

class ColocacionScreen extends StatefulWidget {
  const ColocacionScreen({super.key});

  @override
  State<ColocacionScreen> createState() => _ColocacionScreenState();
}

class _ColocacionScreenState extends State<ColocacionScreen> {
  final List<String> _steps = [
    'Limpia la piel donde irán los electrodos.',
    'Coloca el electrodo RA en la clavícula derecha.',
    'Coloca el electrodo LA en la clavícula izquierda.',
    'Coloca el electrodo LL en la parte baja del torso izquierdo.',
    'Revisa el mapa final de colocación en el diagrama.',
  ];
  final List<String> _images = [
    'assets/Paso1.png',
    'assets/Paso2.png',
    'assets/Paso3.png',
    'assets/Paso4.png',
    'assets/Paso4.png',
  ];

  int _index = 0;

  void _next() {
    if (_index < _steps.length - 1) setState(() => _index++);
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guía de Electrodos')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Imagen del paso
            Expanded(
              flex: 3,
              child: Center(
                child: Image.asset(
                  _images[_index],
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Texto del paso
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  'Paso ${_index + 1}: ${_steps[_index]}',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Navegación
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _prev,
                ),
                Text('${_index + 1} / ${_steps.length}'),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _next,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}