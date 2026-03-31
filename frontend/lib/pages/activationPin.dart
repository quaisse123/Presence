import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/pages/activationProfile.dart';

class ActivationPinPage extends StatefulWidget {
  final String email;

  const ActivationPinPage({super.key, required this.email});

  @override
  State<ActivationPinPage> createState() => _ActivationPinPageState();
}

class _ActivationPinPageState extends State<ActivationPinPage> {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  static const Color primaryBlue = Color(0xFF1E5A99);
  static const Color navy = Color(0xFF0F2747);

  @override
  void dispose() {
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _pinCode =>
      _pinControllers.map((controller) => controller.text).join();

  void _handlePinInput(int index, String rawValue) {
    final value = rawValue.replaceAll(RegExp(r'[^0-9]'), '');

    if (value.length > 1) {
      for (int i = 0; i < _pinControllers.length; i++) {
        _pinControllers[i].text = i < value.length ? value[i] : '';
      }

      final nextEmptyIndex = _pinControllers.indexWhere(
        (controller) => controller.text.isEmpty,
      );
      if (nextEmptyIndex == -1) {
        _focusNodes.last.unfocus();
      } else {
        _focusNodes[nextEmptyIndex].requestFocus();
      }
      setState(() {});
      return;
    }

    if (value.isEmpty) {
      _pinControllers[index].clear();
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }

    _pinControllers[index].text = value;
    _pinControllers[index].selection = TextSelection.collapsed(
      offset: _pinControllers[index].text.length,
    );

    if (index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    setState(() {});
  }

  Future<void> _verifyPin() async {
    if (_pinCode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 4-digit PIN code.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await verifyActivationPin(widget.email, _pinCode);

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      final message =
          response['message']?.toString() ?? 'PIN verified successfully';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1F7A4C),
          content: Text(message),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ActivationProfilePage(email: widget.email),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(_errorMessage(e, 'Failed to verify PIN code.')),
        ),
      );
    }
  }

  Future<void> _resendPin() async {
    setState(() => _isResending = true);

    try {
      final response = await sendActivationPin(widget.email);

      if (!mounted) {
        return;
      }

      setState(() => _isResending = false);

      for (final controller in _pinControllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();

      final message =
          response['message']?.toString() ??
          'A new PIN was sent to ${widget.email}';
      final demoPin = response['demoPin']?.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF163A66),
          content: Text(
            demoPin != null && demoPin.isNotEmpty
                ? '$message (demo PIN: $demoPin)'
                : message,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(_errorMessage(e, 'Failed to resend PIN code.')),
        ),
      );
    }
  }

  String _errorMessage(Object error, String fallback) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return fallback;
    }
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F0FA), Color(0xFFF9FCFF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -55,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -65,
              left: -50,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  color: navy.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 26,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter verification PIN',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: navy,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We sent a 4-digit code to ${widget.email}.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF54657A),
                                  height: 1.45,
                                ),
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(4, _buildPinInput),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _verifyPin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.verified_outlined),
                              label: Text(
                                _isLoading ? 'Checking...' : 'Verify PIN code',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Edit email'),
                              ),
                              TextButton(
                                onPressed: _isLoading || _isResending
                                    ? null
                                    : _resendPin,
                                child: Text(
                                  _isResending ? 'Sending...' : 'Resend code',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinInput(int index) {
    return SizedBox(
      width: 44,
      child: TextField(
        controller: _pinControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: index == _pinControllers.length - 1
            ? TextInputAction.done
            : TextInputAction.next,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: navy,
        ),
        maxLength: 1,
        onChanged: (value) => _handlePinInput(index, value),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD9E4F2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD9E4F2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 1.6),
          ),
        ),
      ),
    );
  }
}
