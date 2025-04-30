import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Colores principales - constantes para evitar recálculos
  static const Color primaryColor = Color(0xFF2E3B55);
  static const Color accentColor = Color(0xFF00A6FB);
  static const Color dangerColor = Color(0xFFE63946);
  static const Color warningColor = Color(0xFFFFB703);
  static const Color successColor = Color(0xFF06D6A0);

  // Caché del tema actual
  static ThemeMode? _cachedThemeMode;
  static const String _themeModeKey = 'theme_mode';

  // Retorna si el modo oscuro está activo
  static bool isDarkMode() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return _cachedThemeMode == ThemeMode.dark ||
        (_cachedThemeMode == ThemeMode.system && brightness == Brightness.dark);
  }

  // Cache ThemeData para evitar reconstrucciones innecesarias
  static final ThemeData lightTheme = _buildLightTheme();
  static final ThemeData darkTheme = _buildDarkTheme();

  // Construir el tema claro - optimizado
  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      textTheme: const TextTheme(
        // Optimizar el uso del TextTheme utilizando estilos pre-computados
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(height: 1.5),
        bodyMedium: TextStyle(height: 1.3),
      ),
      // Optimización de animaciones
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Construir el tema oscuro - optimizado
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(height: 1.5),
        bodyMedium: TextStyle(height: 1.3),
      ),
      // Optimización de animaciones
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Cargar tema guardado
  static Future<ThemeMode> getThemeMode() async {
    if (_cachedThemeMode != null) {
      return _cachedThemeMode!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
      _cachedThemeMode = ThemeMode.values[themeModeIndex];
      return _cachedThemeMode!;
    } catch (e) {
      debugPrint('Error al cargar el tema: $e');
      return ThemeMode.system;
    }
  }

  // Guardar tema seleccionado
  static Future<void> setThemeMode(ThemeMode mode) async {
    _cachedThemeMode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (e) {
      debugPrint('Error al guardar el tema: $e');
    }
  }
}
