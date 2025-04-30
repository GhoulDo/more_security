import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:more_security/providers/app_state_provider.dart';
import 'package:more_security/screens/app_scanner_screen.dart';
import 'package:more_security/screens/file_scanner_screen.dart';
import 'package:more_security/screens/home_screen.dart';
import 'package:more_security/screens/splash_screen.dart';
import 'package:more_security/screens/vulnerability_scanner_screen.dart';
import 'package:more_security/services/analytics_service.dart';
import 'package:more_security/themes/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  // Asegura que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación preferida para mejor rendimiento
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Optimizar el rendimiento visual
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );

  // Iniciar servicios necesarios en background
  await AnalyticsService.initialize();

  runApp(
    // Usar Provider para la gestión de estado
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppStateProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'More Security',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // Iniciar con splash screen para cargar recursos
      home: const SplashScreen(),
      // Optimizar el enrutamiento con rutas nombradas
      routes: {
        '/home': (context) => const HomeScreen(),
        '/app_scanner': (context) => const AppScannerScreen(),
        '/vulnerability_scanner':
            (context) => const VulnerabilityScannerScreen(),
        '/file_scanner': (context) => const FileScannerScreen(),
      },
      // Añadir observador de navegación para analíticas
      navigatorObservers: [AnalyticsService.getNavigationObserver()],
    );
  }
}
