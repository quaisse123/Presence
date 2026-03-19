import 'package:flutter/material.dart';
import 'package:frontend/Api/QrCodeApi.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class StudentScanTestPage extends StatefulWidget {
  const StudentScanTestPage({super.key});

  @override
  State<StudentScanTestPage> createState() => _StudentScanTestPageState();
}

class _StudentScanTestPageState extends State<StudentScanTestPage> {
  final TextEditingController _studentIdController = TextEditingController(
    text: '1',
  );
  final TextEditingController _deviceIdController = TextEditingController(
    text: 'student-test-device',
  );
  final TextEditingController _latitudeController = TextEditingController(
    text: '36.7065',
  );
  final TextEditingController _longitudeController = TextEditingController(
    text: '3.0786',
  );

  bool _isLoading = false;
  String _lastMessage = 'Aucun scan pour le moment.';

  @override
  void initState() {
    super.initState();
    getLoggedUserId().then((userid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Test de scan de presence pour etudiant (userId: $userid).',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _deviceIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _scanAndMarkPresence() async {
    final int? studentId = int.tryParse(_studentIdController.text.trim());
    final double? latitude = double.tryParse(_latitudeController.text.trim());
    final double? longitude = double.tryParse(_longitudeController.text.trim());

    if (studentId == null || latitude == null || longitude == null) {
      setState(() {
        _lastMessage =
            'Valeurs invalides: verifie studentId, latitude et longitude avant de scanner.';
      });
      return;
    }

    final String? qrToken = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _SimpleQrScannerPage()),
    );

    if (!mounted || qrToken == null || qrToken.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _lastMessage = 'Scan detecte. Envoi vers le backend...';
    });

    try {
      final response = await scanAttendance(
        qrCodeToken: qrToken,
        studentId: studentId,
        scanLatitude: latitude,
        scanLongitude: longitude,
        deviceId: _deviceIdController.text.trim().isEmpty
            ? 'student-test-device'
            : _deviceIdController.text.trim(),
      );

      final bool success = response['success'] == true;
      final String message = (response['message'] ?? 'Reponse recue')
          .toString();

      setState(() {
        _lastMessage = '${success ? 'SUCCES' : 'ECHEC'}: $message\n$response';
      });
    } catch (e) {
      setState(() {
        _lastMessage = 'Erreur pendant le scan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Presence Etudiant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _studentIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'Device ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _scanAndMarkPresence,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(
                _isLoading ? 'Envoi...' : 'Marquer ma presence (Scanner QR)',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Resultat:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(child: Text(_lastMessage)),
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

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('Scanner le QR')),
      body: MobileScanner(controller: _scannerController, onDetect: _onDetect),
    );
  }
}
