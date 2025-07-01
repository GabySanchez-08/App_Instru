// lib/screens/recomendaciones_screen.dart

import 'package:flutter/material.dart';

class TipsSalud extends StatefulWidget {
  const TipsSalud({super.key});

  @override
  State<TipsSalud> createState() => _TipsSaludState();
}

class _TipsSaludState extends State<TipsSalud> {
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
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tips de Salud Cardíaca')),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _tips.length,
        itemBuilder: (context, index) {
          final tip = _tips[index];
          final assetName = 'assets/recomendacion${index + 1}.png';
          //final assetName = 'assets/recomendacion1.png';
          return Column(
            children: [
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      assetName,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          'Imagen no encontrada\n$assetName',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: Text(
                      tip,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Indicador de página
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_tips.length, (i) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (ctx, child) {
                      // obtenemos el page como double, convirtiendo initialPage a double
                      final page = _pageController.hasClients
                          ? (_pageController.page ?? _pageController.initialPage.toDouble())
                          : _pageController.initialPage.toDouble();
                      final selected = (page - i).abs().clamp(0.0, 1.0);
                      final width = (1 - selected) * 12 + 8;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: width,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}