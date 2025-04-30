import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:more_security/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _assetsLoaded = false;
  final List<String> _loadingSteps = [
    'Iniciando More Security',
    'Cargando motor de escaneo',
    'Optimizando rendimiento',
    'Casi listo...',
  ];
  String _currentStep = 'Iniciando More Security';
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_assetsLoaded) {
          _navigateToHome();
        } else {
          _updateLoadingStep();
        }
      }
    });

    _controller.forward();
    _preloadAssets();
  }

  void _updateLoadingStep() {
    if (_stepIndex < _loadingSteps.length - 1) {
      setState(() {
        _stepIndex++;
        _currentStep = _loadingSteps[_stepIndex];
      });
      _controller.reset();
      _controller.forward();
    } else {
      _navigateToHome();
    }
  }

  Future<void> _preloadAssets() async {
    // Simular carga de recursos
    await Future.delayed(const Duration(seconds: 3));
    _assetsLoaded = true;
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o animación
            SizedBox(
              width: size.width * 0.5,
              height: size.width * 0.5,
              child: Lottie.asset(
                'assets/animations/security_check.json',
                controller: _controller,
                onLoaded: (composition) {
                  _controller.duration = composition.duration;
                  _controller.forward();
                },
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'More Security',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Protección avanzada para su dispositivo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 60),
            // Indicador de carga
            SizedBox(
              width: size.width * 0.7,
              child: LinearProgressIndicator(
                value: _stepIndex / (_loadingSteps.length - 1),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                borderRadius: BorderRadius.circular(8),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentStep,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
