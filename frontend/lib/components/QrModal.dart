import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/Api/sessionsApi.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Displays the QR modal as a bottom sheet.
/// Usage:
///   showQrModal(context, token: 'your.jwt.token');
void showQrModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QrModal(),
  );
}

class QrModal extends StatefulWidget {
  const QrModal({super.key});

  @override
  State<QrModal> createState() => _QrModalState();
}

class _QrModalState extends State<QrModal> {
  String? qrToken;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchAndSetToken();
    _timer = Timer.periodic(Duration(seconds: 3), (_) => fetchAndSetToken());
  }

  Future<void> fetchAndSetToken() async {
    final newToken = await fetchQrToken(); // ta fonction API
    debugPrint(
      'Fetching new QR token : ${newToken.substring(newToken.length - 10)}',
    );
    setState(() => qrToken = newToken);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (qrToken == null) return CircularProgressIndicator();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'QR Code de présence',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Faites scanner ce code par les étudiants',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 28),

          // QR Code container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
            ),
            child: QrImageView(
              data: qrToken!,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 28),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
