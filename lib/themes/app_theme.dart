import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // Nueva paleta de colores con morado, rosado, negro y blanco
  static const Color primaryColor = Color(0xFF7B2CBF); // Morado
  static const Color accentColor = Color(0xFFFF5C8D); // Rosado
  static const Color blackColor = Color(0xFF1A1A1A); // Negro
  static const Color whiteColor = Color(0xFFF8F8F8); // Blanco

  // Colores secundarios
  static const Color dangerColor = Color(
    0xFFE63946,
  ); // Rojo (mantener para alertas)
  static const Color warningColor = Color(
    0xFFFFB703,
  ); // Amarillo (mantener para advertencias)
  static const Color successColor = Color(
    0xFF06D6A0,
  ); // Verde (mantener para éxito)

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
        primary: primaryColor,
        secondary: accentColor,
        brightness: Brightness.light,
        background: whiteColor,
      ),
      scaffoldBackgroundColor: whiteColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: whiteColor,
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
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
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Poppins',
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          fontFamily: 'Poppins',
        ),
        bodyLarge: TextStyle(height: 1.5, fontFamily: 'Poppins'),
        bodyMedium: TextStyle(height: 1.3, fontFamily: 'Poppins'),
      ),
      fontFamily: 'Poppins',
    );
  }

  // Construir el tema oscuro - optimizado
  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        brightness: Brightness.dark,
        background: blackColor,
      ),
      scaffoldBackgroundColor: blackColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: blackColor,
        foregroundColor: whiteColor,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: whiteColor,
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        color: const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Poppins',
          color: whiteColor,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          fontFamily: 'Poppins',
          color: whiteColor,
        ),
        bodyLarge: TextStyle(
          height: 1.5,
          fontFamily: 'Poppins',
          color: Color(0xFFE0E0E0),
        ),
        bodyMedium: TextStyle(
          height: 1.3,
          fontFamily: 'Poppins',
          color: Color(0xFFE0E0E0),
        ),
      ),
      fontFamily: 'Poppins',
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
