import 'package:flutter/material.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/pages/activationProfile.dart';
import 'package:frontend/pages/activationPin.dart';

class ActivationEmailPage extends StatefulWidget {
  const ActivationEmailPage({super.key});

  @override
  State<ActivationEmailPage> createState() => _ActivationEmailPageState();
}

class _ActivationEmailPageState extends State<ActivationEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  static const String _debugEmail = 'quaisse.marouane@ensam-casa.ma';

  static const Color primaryBlue = Color(0xFF1E5A99);
  static const Color navy = Color(0xFF0F2747);

  @override
  void initState() {
    super.initState();
    _emailController.text = _debugEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final normalizedEmail = _emailController.text.trim().toLowerCase();

    setState(() => _isLoading = true);

    // Production flow (keep this block commented during quick debug tests).
    try {
      final response = await sendActivationPin(normalizedEmail);

      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      final message =
          response['message']?.toString() ??
          'PIN code sent to $normalizedEmail';
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

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ActivationPinPage(email: normalizedEmail),
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
          content: Text(_errorMessage(e, 'Failed to send PIN code.')),
        ),
      );
    }

    // Temporary debug shortcut: go directly to profile step.
    // final debugEmail = normalizedEmail.isEmpty ? _debugEmail : normalizedEmail;

    // if (!mounted) {
    //   return;
    // }

    // setState(() => _isLoading = false);
    // await Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => ActivationProfilePage(email: debugEmail),
    //   ),
    // );
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
              top: -80,
              right: -60,
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
              bottom: -70,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: navy.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Center(
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
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLogoHeader(),
                                const SizedBox(height: 24),
                                Text(
                                  'Account activation',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: navy,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter your ENSAM institutional email to receive your PIN code.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF54657A),
                                        height: 1.45,
                                      ),
                                ),
                                const SizedBox(height: 18),
                                // Container(
                                //   width: double.infinity,
                                //   padding: const EdgeInsets.all(12),
                                //   decoration: BoxDecoration(
                                //     color: subtleBackground,
                                //     borderRadius: BorderRadius.circular(14),
                                //     border: Border.all(
                                //       color: const Color(0xFFD4E0EE),
                                //     ),
                                //   ),
                                //   child: const Row(
                                //     crossAxisAlignment:
                                //         CrossAxisAlignment.start,
                                //     children: [
                                //       Icon(
                                //         Icons.verified_user_outlined,
                                //         color: primaryBlue,
                                //         size: 20,
                                //       ),
                                //       SizedBox(width: 10),
                                //       Expanded(
                                //         child: Text(
                                //           'Email must end with : @ensam-casa.ma',
                                //           style: TextStyle(
                                //             color: Color(0xFF355070),
                                //             fontSize: 13,
                                //             fontWeight: FontWeight.w500,
                                //           ),
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                // const SizedBox(height: 20),
                                Form(
                                  key: _formKey,
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: InputDecoration(
                                      labelText: 'Institutional email',
                                      hintText: 'e.g. tayar.ali@ensam-casa.ma',
                                      prefixIcon: const Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFD),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 18,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD9E4F2),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD9E4F2),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: primaryBlue,
                                          width: 1.6,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      final email =
                                          value?.trim().toLowerCase() ?? '';
                                      if (email.isEmpty) {
                                        return 'Please enter your institutional email';
                                      }

                                      final validEmailRegex = RegExp(
                                        r'^[a-z0-9._%+-]+@ensam-casa\.ma$',
                                      );
                                      if (!validEmailRegex.hasMatch(email)) {
                                        return 'Use a valid @ensam-casa.ma email address';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _submitEmail,
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
                                        : const Icon(Icons.send_rounded),
                                    label: Text(
                                      _isLoading
                                          ? 'Sending...'
                                          : 'Send PIN code',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Back to login'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/ensam_logo.png',
          fit: BoxFit.contain,
          height: 60,
          errorBuilder: (_, error, ___) {
            debugPrint('ENSAM logo load error: $error');
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'ENSAM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                  letterSpacing: 1.2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
