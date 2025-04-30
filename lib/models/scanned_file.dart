enum FileRiskLevel { safe, suspicious, malicious, unknown }

class ScannedFile {
  final String filePath;
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final DateTime lastModified;
  final FileRiskLevel riskLevel;
  final String? detectionName;
  final List<String> reasons;

  ScannedFile({
    required this.filePath,
    required this.fileName,
    required this.fileExtension,
    required this.fileSize,
    required this.lastModified,
    required this.riskLevel,
    this.detectionName,
    required this.reasons,
  });

  // Color asociado al nivel de riesgo
  int get riskColor {
    switch (riskLevel) {
      case FileRiskLevel.safe:
        return 0xFF06D6A0; // Verde
      case FileRiskLevel.suspicious:
        return 0xFFFFB703; // Amarillo
      case FileRiskLevel.malicious:
        return 0xFFE63946; // Rojo
      case FileRiskLevel.unknown:
        return 0xFF6C757D; // Gris
    }
  }

  // Icono asociado al tipo de archivo
  String getFileIcon() {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return 'assets/icons/pdf_icon.png';
      case 'doc':
      case 'docx':
        return 'assets/icons/doc_icon.png';
      case 'xls':
      case 'xlsx':
        return 'assets/icons/xls_icon.png';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'assets/icons/image_icon.png';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'assets/icons/video_icon.png';
      case 'mp3':
      case 'wav':
        return 'assets/icons/audio_icon.png';
      case 'apk':
        return 'assets/icons/apk_icon.png';
      default:
        return 'assets/icons/file_icon.png';
    }
  }
}
