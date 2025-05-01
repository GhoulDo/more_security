import 'dart:async';

import 'package:flutter/material.dart';
import 'package:more_security/screens/home_screen.dart';
import 'package:more_security/themes/app_theme.dart';

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
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.accentColor.withOpacity(0.6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogoImage(size),
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
              SizedBox(
                width: size.width * 0.7,
                child: LinearProgressIndicator(
                  value: _stepIndex / (_loadingSteps.length - 1),
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accentColor,
                  ),
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
      ),
    );
  }

  Widget _buildLogoImage(Size size) {
    try {
      return Hero(
        tag: 'app_logo',
        child: Container(
          width: size.width * 0.4,
          height: size.width * 0.4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.security, size: 80, color: Colors.white),
        ),
      );
    } catch (e) {
      return const Icon(Icons.security, size: 80, color: Colors.white);
    }
  }
}
