import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:more_security/providers/app_state_provider.dart';
import 'package:more_security/services/complete_scan_service.dart';
import 'package:more_security/utils/permission_handler.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class CompleteScanWidget extends StatefulWidget {
  const CompleteScanWidget({super.key});

  @override
  State<CompleteScanWidget> createState() => _CompleteScanWidgetState();
}

class _CompleteScanWidgetState extends State<CompleteScanWidget>
    with SingleTickerProviderStateMixin {
  final CompleteScanService _scanService = CompleteScanService();
  bool _isScanning = false;
  ScanProgress? _currentProgress;
  CompleteScanResult? _result;
  late AnimationController _animationController;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanService.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    final permissionsGranted =
        await AppPermissionHandler.checkAndRequestBasicPermissions(context);
    if (!permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Se requieren permisos para realizar un escaneo completo',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _showResults = false;
      _result = null;
    });

    try {
      _scanService.progressStream.listen((progress) {
        setState(() {
          _currentProgress = progress;
        });

        if (progress.stage == ScanStage.complete) {
          _animationController.forward();
        }
      });

      final result = await _scanService.startCompleteScan();

      setState(() {
        _result = result;
        _isScanning = false;

        final provider = Provider.of<AppStateProvider>(context, listen: false);
        provider.updateSecurityScore(result.overallSecurityScore);
        provider.updateLastScanResults('complete', result.statistics);
      });

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _showResults = true;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al escanear: $e')));
    }
  }

  String _getScanStageText(ScanStage stage) {
    switch (stage) {
      case ScanStage.initializing:
        return 'Iniciando';
      case ScanStage.scanningApps:
        return 'Escaneando aplicaciones';
      case ScanStage.scanningVulnerabilities:
        return 'Verificando vulnerabilidades';
      case ScanStage.scanningFiles:
        return 'Analizando archivos';
      case ScanStage.finishing:
        return 'Finalizando';
      case ScanStage.complete:
        return '¡Completado!';
      case ScanStage.error:
        return 'Error';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF06D6A0);
    if (score >= 60) return const Color(0xFF90BE6D);
    if (score >= 40) return const Color(0xFFFFB703);
    if (score >= 20) return const Color(0xFFF8961E);
    return const Color(0xFFE63946);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isScanning || (_result != null && !_showResults)) ...[
          CircularPercentIndicator(
            radius: 70.0,
            lineWidth: 12.0,
            percent: _currentProgress?.progress ?? 0,
            center:
                _currentProgress?.stage == ScanStage.complete
                    ? AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + _animationController.value * 0.3,
                          child: Opacity(
                            opacity: _animationController.value,
                            child: Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    )
                    : Text(
                      '${((_currentProgress?.progress ?? 0) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            progressColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey[300]!,
            animateFromLastPercent: true,
            animation: true,
          ),

          const SizedBox(height: 16),

          Text(
            _getScanStageText(
              _currentProgress?.stage ?? ScanStage.initializing,
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            _currentProgress?.message ?? 'Preparando escaneo...',
            textAlign: TextAlign.center,
          ),

          if (_currentProgress?.stage == ScanStage.complete)
            Lottie.asset(
              'assets/animations/complete.json',
              width: 200,
              height: 200,
              repeat: false,
              controller: _animationController,
            ),
        ],

        if (!_isScanning && _result == null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 120, color: Colors.purple),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escaneo Completo',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Analice su dispositivo en busca de amenazas y vulnerabilidades',
                      style: TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.search),
                      label: const Text('Iniciar Escaneo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        if (!_isScanning && _result != null && _showResults) ...[
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        _result!.overallSecurityScore >= 80
                            ? 'assets/icons/safe.png'
                            : _result!.overallSecurityScore >= 60
                            ? 'assets/icons/shield_check.png'
                            : 'assets/icons/warning.png',
                        width: 40,
                        height: 40,
                        color: _getScoreColor(_result!.overallSecurityScore),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Puntuación de seguridad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(
                                  _result!.overallSecurityScore,
                                ),
                              ),
                            ),
                            Text(
                              '${_result!.overallSecurityScore} puntos',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(
                                  _result!.overallSecurityScore,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _result!.overallSecurityScore >= 80
                        ? 'Tu dispositivo está seguro'
                        : _result!.overallSecurityScore >= 60
                        ? 'Tu dispositivo está bastante seguro'
                        : _result!.overallSecurityScore >= 40
                        ? 'Tu dispositivo necesita atención'
                        : 'Tu dispositivo está en riesgo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(_result!.overallSecurityScore),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Resultados del escaneo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 16),

                  _buildStatRow(
                    Icons.apps,
                    'Aplicaciones de alto riesgo',
                    '${_result!.statistics['highRiskApps']}/${_result!.statistics['appsScanned']}',
                    _result!.statistics['highRiskApps'] > 0
                        ? Colors.orange
                        : Colors.green,
                  ),

                  const SizedBox(height: 8),

                  _buildStatRow(
                    Icons.warning,
                    'Vulnerabilidades críticas',
                    '${_result!.statistics['criticalVulnerabilities']}',
                    _result!.statistics['criticalVulnerabilities'] > 0
                        ? Colors.red
                        : Colors.green,
                  ),

                  const SizedBox(height: 8),

                  _buildStatRow(
                    Icons.bug_report,
                    'Archivos maliciosos',
                    '${_result!.statistics['maliciousFiles']}/${_result!.statistics['filesScanned']}',
                    _result!.statistics['maliciousFiles'] > 0
                        ? Colors.red
                        : Colors.green,
                  ),

                  const SizedBox(height: 8),

                  _buildStatRow(
                    Icons.timer,
                    'Duración del escaneo',
                    '${_result!.statistics['scanDuration']} seg',
                    Colors.blue,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _startScan,
                          child: const Text('Repetir escaneo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navegar a la pantalla de resultados detallados
                            // Navigator.pushNamed(context, '/scan_details', arguments: _result);
                          },
                          child: const Text('Ver detalles'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
