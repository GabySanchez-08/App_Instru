// lib/screens/recomendaciones_screen.dart

import 'package:flutter/material.dart';

class TipsSalud extends StatelessWidget {
  const TipsSalud({super.key});

  final List<String> _tips = const [
    'Mantén una dieta balanceada: frutas, verduras y granos enteros.',
    'Bebe al menos 2 litros de agua al día.',
    'Realiza al menos 30 minutos de ejercicio moderado diario.',
    'Duerme entre 7 y 8 horas cada noche.',
    'Controla tu estrés con técnicas de respiración o meditación.',
    'Evita el tabaco y el exceso de alcohol.',
    'Realiza chequeos médicos regulares.',
    'Mantén un peso saludable y controla tu presión arterial.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tips de Salud Cardíaca')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tips.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          return ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(
              _tips[i],
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}