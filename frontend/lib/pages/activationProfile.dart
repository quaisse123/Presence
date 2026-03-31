import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/pages/login.dart';

class ActivationProfilePage extends StatefulWidget {
  final String email;

  const ActivationProfilePage({super.key, required this.email});

  @override
  State<ActivationProfilePage> createState() => _ActivationProfilePageState();
}

class _ActivationProfilePageState extends State<ActivationProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _apogeeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedLevel;
  String? _selectedSection;
  String? _selectedMajor;

  static const Color primaryBlue = Color(0xFF1E5A99);
  static const Color navy = Color(0xFF0F2747);

  static const List<String> _levels = [
    'API-I',
    'API-II',
    'CI-I',
    'CI-II',
    'CI-III',
  ];

  static const List<String> _api1Sections = ['A', 'B', 'C', 'D', 'E'];
  static const List<String> _api2Sections = ['A', 'B', 'C'];

  static const List<String> _ciMajors = [
    'GEM',
    'MSEI',
    'GMAA',
    'GSI',
    'GSMI',
    'IAGI',
    'CS2C',
  ];

  bool get _isApi => _selectedLevel == 'API-I' || _selectedLevel == 'API-II';

  bool get _isCi =>
      _selectedLevel == 'CI-I' ||
      _selectedLevel == 'CI-II' ||
      _selectedLevel == 'CI-III';

  List<String> get _sectionOptions {
    if (_selectedLevel == 'API-I') {
      return _api1Sections;
    }
    if (_selectedLevel == 'API-II') {
      return _api2Sections;
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    final extracted = _extractNames(widget.email);
    _lastNameController.text = extracted['lastName'] ?? '';
    _firstNameController.text = extracted['firstName'] ?? '';
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _apogeeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Map<String, String> _extractNames(String email) {
    final localPart = email.trim().split('@').first;
    final parts = localPart
        .split('.')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return {'lastName': '', 'firstName': ''};
    }

    final lastNameRaw = parts.first;
    final firstNameRaw = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return {
      'lastName': _toInitialCapitalization(lastNameRaw),
      'firstName': _toInitialCapitalization(firstNameRaw),
    };
  }

  String _toInitialCapitalization(String input) {
    final normalized = input.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) {
      return '';
    }

    final words = normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    final capitalized = words.map((word) {
      final chunks = word.split('-');
      final formatted = chunks.map((chunk) {
        if (chunk.isEmpty) {
          return chunk;
        }
        return chunk[0].toUpperCase() + chunk.substring(1).toLowerCase();
      }).toList();
      return formatted.join('-');
    }).toList();

    return capitalized.join(' ');
  }

  Future<void> _saveStepTwo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLevel == null) {
      _showError('Please select your level.');
      return;
    }

    if (_isApi && _selectedSection == null) {
      _showError('Please select your section.');
      return;
    }

    if (_isCi && _selectedMajor == null) {
      _showError('Please select your major.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Send step 2 payload to backend with exactly the expected activation keys.
      final response = await completeActivationProfile(
        email: widget.email,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        apogeeCode: _apogeeController.text.trim(),
        password: _passwordController.text,
        level: _selectedLevel!,
        section: _isApi ? _selectedSection : null,
        major: _isCi ? _selectedMajor : null,
      );

      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1F7A4C),
          content: Text(
            response['message']?.toString() ??
                'Activation completed, you can now log in!',
          ),
        ),
      );
      // Login redirect after a short delay to let the user read the message.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isSubmitting = false);
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red.shade700, content: Text(message)),
    );
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
                          constraints: const BoxConstraints(maxWidth: 620),
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLogoHeader(),
                                  const SizedBox(height: 15),
                                  Text(
                                    'Activation - Step 2',
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
                                    'Fill your student details to complete first access.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF54657A),
                                          height: 1.45,
                                        ),
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F8FC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFD4E0EE),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: primaryBlue,
                                          size: 19,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Quick check: names here will be used for attendance.',
                                            style: TextStyle(
                                              color: Color(0xFF355070),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  LayoutBuilder(
                                    builder: (context, box) {
                                      final isWide = box.maxWidth >= 580;
                                      final fieldWidth = isWide
                                          ? (box.maxWidth - 12) / 2
                                          : box.maxWidth;
                                      return Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          SizedBox(
                                            width: fieldWidth,
                                            child: _buildTextField(
                                              controller: _lastNameController,
                                              label: 'Last name',
                                              hint: 'e.g. Tayar',
                                              icon: Icons.badge_outlined,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'Last name is required';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                          SizedBox(
                                            width: fieldWidth,
                                            child: _buildTextField(
                                              controller: _firstNameController,
                                              label: 'First name',
                                              hint: 'e.g. Marouane',
                                              icon: Icons.person_outline,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.trim().isEmpty) {
                                                  return 'First name is required';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _apogeeController,
                                    label: 'Apogee code',
                                    hint: '8 digits, e.g. 22521773',
                                    icon: Icons.numbers,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(8),
                                    ],
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'Apogee code is required';
                                      }
                                      if (!RegExp(r'^\d{8}$').hasMatch(text)) {
                                        return 'Use exactly 8 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDropdown(
                                    selectedValue: _selectedLevel,
                                    label: 'Level',
                                    icon: Icons.school_outlined,
                                    hint: 'Select your level',
                                    items: _levels,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedLevel = value;
                                        _selectedSection = null;
                                        _selectedMajor = null;
                                      });
                                    },
                                  ),
                                  if (_isApi) ...[
                                    const SizedBox(height: 12),
                                    _buildDropdown(
                                      selectedValue: _selectedSection,
                                      label: 'Section',
                                      icon: Icons.group_outlined,
                                      hint: 'Select your section',
                                      items: _sectionOptions,
                                      onChanged: (value) {
                                        setState(
                                          () => _selectedSection = value,
                                        );
                                      },
                                    ),
                                  ],
                                  if (_isCi) ...[
                                    const SizedBox(height: 12),
                                    _buildDropdown(
                                      selectedValue: _selectedMajor,
                                      label: 'Major',
                                      icon: Icons.account_tree_outlined,
                                      hint: 'Select your major',
                                      items: _ciMajors,
                                      onChanged: (value) {
                                        setState(() => _selectedMajor = value);
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'At least 8 characters',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    validator: (value) {
                                      final text = value ?? '';
                                      if (text.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (text.length < 8) {
                                        return 'Use at least 8 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm password',
                                    hint: 'Re-enter your password',
                                    icon: Icons.lock_reset_outlined,
                                    obscureText: true,
                                    validator: (value) {
                                      final text = value ?? '';
                                      if (text.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (text != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _saveStepTwo,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      icon: _isSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.check_circle_outline,
                                            ),
                                      label: Text(
                                        _isSubmitting
                                            ? 'Saving...'
                                            : 'Continue activation',
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
                                      child: const Text('Back to PIN'),
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? selectedValue,
    required String label,
    required IconData icon,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E4F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9E4F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 1.6),
        ),
      ),
    );
  }
}
