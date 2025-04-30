class AppInfo {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final bool isSystemApp;
  final String? iconPath;
  final DateTime installTime;
  final DateTime updateTime;
  final List<String> permissions;
  final double riskScore;

  AppInfo({
    required this.packageName,
    required this.appName,
    required this.versionName,
    required this.versionCode,
    required this.isSystemApp,
    this.iconPath,
    required this.installTime,
    required this.updateTime,
    required this.permissions,
    required this.riskScore,
  });

  // Método para evaluar el nivel de riesgo
  String get riskLevel {
    if (riskScore < 3.0) return 'Bajo';
    if (riskScore < 7.0) return 'Medio';
    return 'Alto';
  }

  // Color asociado al nivel de riesgo
  int get riskColor {
    if (riskScore < 3.0) return 0xFF06D6A0; // Verde
    if (riskScore < 7.0) return 0xFFFFB703; // Amarillo
    return 0xFFE63946; // Rojo
  }
}
