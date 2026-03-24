import 'package:flutter/material.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/Api/QrCodeApi.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StudentScanTestPage extends StatefulWidget {
  const StudentScanTestPage({super.key});

  @override
  State<StudentScanTestPage> createState() => _StudentScanTestPageState();
}

enum _ScanFeedbackState { idle, inProgress, success, error, canceled }

class _ScanFeedback {
  final _ScanFeedbackState state;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? attendanceStatus;
  final int? sessionId;

  const _ScanFeedback({
    required this.state,
    required this.title,
    required this.message,
    required this.timestamp,
    this.attendanceStatus,
    this.sessionId,
  });
}

class _ScanResultDetails {
  final String? studentFirstName;
  final String? sessionTitle;
  final String? courseCode;
  final String? professorName;
  final String? sessionStartTime;
  final String? sessionEndTime;
  final String? scanTime;
  final String? attendanceStatus;
  final String? salle;
  final String? deviceId;

  const _ScanResultDetails({
    this.studentFirstName,
    this.sessionTitle,
    this.courseCode,
    this.professorName,
    this.sessionStartTime,
    this.sessionEndTime,
    this.scanTime,
    this.attendanceStatus,
    this.salle,
    this.deviceId,
  });

  bool get hasData =>
      studentFirstName != null ||
      sessionTitle != null ||
      professorName != null ||
      attendanceStatus != null;
}

class _StudentScanTestPageState extends State<StudentScanTestPage> {
  static const String _fixedDeviceId = 'student-test-device';
  static const double _fixedLatitude = 36.7065;
  static const double _fixedLongitude = 3.0786;

  int? _studentId;
  bool _isLoadingUser = true;
  bool _isLoading = false;
  bool _hasResult = false;
  _ScanResultDetails _details = const _ScanResultDetails();

  _ScanFeedback _feedback = _ScanFeedback(
    state: _ScanFeedbackState.idle,
    title: 'Scanner votre presence',
    message: 'La camera va s\'ouvrir pour scanner le QR de la session.',
    timestamp: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _loadStudentIdAndStartScan();
  }

  Future<void> _loadStudentIdAndStartScan() async {
    try {
      final userId = await getLoggedUserId();
      if (!mounted) {
        return;
      }
      setState(() {
        _studentId = userId;
        _isLoadingUser = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scanAndMarkPresence();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
        _hasResult = true;
        _feedback = _ScanFeedback(
          state: _ScanFeedbackState.error,
          title: 'Session invalide',
          message:
              'Impossible de recuperer votre identifiant. Reconnectez-vous puis reessayez.',
          timestamp: DateTime.now(),
        );
      });
    }
  }

  Future<void> _scanAndMarkPresence() async {
    if (_studentId == null) {
      setState(() {
        _hasResult = true;
        _feedback = _ScanFeedback(
          state: _ScanFeedbackState.error,
          title: 'Utilisateur inconnu',
          message:
              'Votre identifiant JWT est introuvable. Merci de vous reconnecter.',
          timestamp: DateTime.now(),
        );
      });
      return;
    }

    final String? qrToken = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _SimpleQrScannerPage()),
    );

    if (!mounted || qrToken == null || qrToken.isEmpty) {
      if (mounted) {
        setState(() {
          _hasResult = true;
          _feedback = _ScanFeedback(
            state: _ScanFeedbackState.canceled,
            title: 'Scan annule',
            message:
                'Aucun QR valide detecte. Cliquez sur "Scanner a nouveau" pour reessayer.',
            timestamp: DateTime.now(),
          );
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasResult = false;
      _details = const _ScanResultDetails();
      _feedback = _ScanFeedback(
        state: _ScanFeedbackState.inProgress,
        title: 'Verification en cours',
        message: 'Scan detecte. Verification de presence en cours...',
        timestamp: DateTime.now(),
      );
    });

    try {
      final response = await scanAttendance(
        qrCodeToken: qrToken,
        studentId: _studentId!,
        scanLatitude: _fixedLatitude,
        scanLongitude: _fixedLongitude,
        deviceId: _fixedDeviceId,
      );

      final bool success = response['success'] == true;
      final String message = (response['message'] ?? 'Reponse recue')
          .toString();
      final String? status = response['status']?.toString();
      final int? sessionId = _toInt(response['sessionId'] ?? response['id']);

      setState(() {
        _hasResult = true;
        _details = _ScanResultDetails(
          studentFirstName: response['studentFirstName']?.toString(),
          sessionTitle: response['sessionTitle']?.toString(),
          courseCode: response['courseCode']?.toString(),
          professorName: response['professorName']?.toString(),
          sessionStartTime: response['sessionStartTime']?.toString(),
          sessionEndTime: response['sessionEndTime']?.toString(),
          scanTime: response['scanTime']?.toString(),
          attendanceStatus: status,
          salle: response['salle']?.toString(),
          deviceId: response['deviceId']?.toString(),
        );
        _feedback = _ScanFeedback(
          state: success
              ? _ScanFeedbackState.success
              : _ScanFeedbackState.error,
          title: success ? 'Presence enregistree' : 'Presence non validee',
          message: message,
          timestamp: DateTime.now(),
          attendanceStatus: status,
          sessionId: sessionId,
        );
      });
    } catch (e) {
      setState(() {
        _hasResult = true;
        _feedback = _ScanFeedback(
          state: _ScanFeedbackState.error,
          title: 'Erreur de scan',
          message: 'Impossible de finaliser le scan pour le moment. Detail: $e',
          timestamp: DateTime.now(),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _scanAgain() async {
    if (_isLoading || _isLoadingUser) {
      return;
    }
    await _scanAndMarkPresence();
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _formatGps() {
    return '${_fixedLatitude.toStringAsFixed(4)}, ${_fixedLongitude.toStringAsFixed(4)}';
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y - $h:$min';
  }

  String _formatIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) {
      return '-';
    }
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return iso;
    }
    return _formatDateTime(parsed.toLocal());
  }

  IconData _feedbackIcon(_ScanFeedbackState state) {
    switch (state) {
      case _ScanFeedbackState.idle:
        return Icons.qr_code_scanner_rounded;
      case _ScanFeedbackState.inProgress:
        return Icons.hourglass_top_rounded;
      case _ScanFeedbackState.success:
        return Icons.check_circle_rounded;
      case _ScanFeedbackState.error:
        return Icons.error_rounded;
      case _ScanFeedbackState.canceled:
        return Icons.info_rounded;
    }
  }

  Color _feedbackColor(_ScanFeedbackState state) {
    switch (state) {
      case _ScanFeedbackState.idle:
        return const Color(0xFF1A73E8);
      case _ScanFeedbackState.inProgress:
        return const Color(0xFFCC8A2E);
      case _ScanFeedbackState.success:
        return const Color(0xFF1C9B63);
      case _ScanFeedbackState.error:
        return const Color(0xFFD94B4B);
      case _ScanFeedbackState.canceled:
        return const Color(0xFF6E7E92);
    }
  }

  Widget _buildResultRow({required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7B8798),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1D293D),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackColor = _feedbackColor(_feedback.state);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text('Resultat du scan'),
        actions: [
          IconButton(
            tooltip: 'Deconnexion',
            onPressed: _isLoading ? null : logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A73E8), Color(0xFF1558B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                _isLoading || _isLoadingUser
                    ? 'Ouverture de la camera et verification du QR...'
                    : 'Le resultat du scan apparait ici avec les details utiles.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feedbackColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: feedbackColor.withOpacity(0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _feedbackIcon(_feedback.state),
                        color: feedbackColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _feedback.title,
                          style: TextStyle(
                            color: feedbackColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _feedback.message,
                    style: const TextStyle(
                      color: Color(0xFF1D293D),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mis a jour: ${_formatDateTime(_feedback.timestamp)}',
                    style: const TextStyle(
                      color: Color(0xFF7B8798),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_hasResult && _details.hasData)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4E9F1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations de presence',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D293D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildResultRow(
                      label: 'Prenom',
                      value: _details.studentFirstName ?? '-',
                    ),
                    _buildResultRow(
                      label: 'Session',
                      value: _details.sessionTitle ?? '-',
                    ),
                    _buildResultRow(
                      label: 'Code module',
                      value: _details.courseCode ?? '-',
                    ),
                    _buildResultRow(
                      label: 'Professeur',
                      value: _details.professorName ?? '-',
                    ),
                    _buildResultRow(
                      label: 'Debut',
                      value: _formatIsoDate(
                        _details.sessionStartTime,
                      ).split(" - ").last,
                    ),
                    _buildResultRow(
                      label: 'Fin',
                      value: _formatIsoDate(
                        _details.sessionEndTime,
                      ).split(" - ").last,
                    ),
                    _buildResultRow(
                      label: 'Heure du scan',
                      value: _formatIsoDate(
                        _details.scanTime,
                      ).split(" - ").last,
                    ),
                    _buildResultRow(
                      label: 'Statut presence',
                      value: _details.attendanceStatus ?? '-',
                    ),
                    _buildResultRow(
                      label: 'Salle',
                      value: _details.salle ?? '-',
                    ),
                    _buildResultRow(
                      label: 'Device',
                      value: _details.deviceId ?? _fixedDeviceId,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _isLoadingUser || _studentId == null)
                    ? null
                    : _scanAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  disabledBackgroundColor: const Color(0xFF9EC2F4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.qr_code_scanner_rounded),
                label: Text(
                  _isLoading ? 'Verification...' : 'Scanner a nouveau',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleQrScannerPage extends StatefulWidget {
  const _SimpleQrScannerPage();

  @override
  State<_SimpleQrScannerPage> createState() => _SimpleQrScannerPageState();
}

class _SimpleQrScannerPageState extends State<_SimpleQrScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _alreadyHandled = false;
  bool _torchEnabled = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    if (!mounted) {
      return;
    }
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_alreadyHandled) {
      return;
    }

    final String? value = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (value == null || value.isEmpty) {
      return;
    }

    _alreadyHandled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.75),
        foregroundColor: Colors.white,
        title: const Text('Scanner le QR'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Cadrez le QR au centre pour valider votre presence',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
