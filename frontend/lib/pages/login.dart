import 'package:flutter/material.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/Api/JwtService.dart';
import 'package:frontend/MainScreen.dart';
import 'package:frontend/config/MainRedirection.dart';
import 'package:frontend/pages/activationEmail.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF1E5A99);
  static const Color navy = Color(0xFF0F2747);
  static const Color darkColor = Color(0xFF1C1E21);
  static const Color lightGrey = Color(0xFFF0F2F5);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    Map<String, dynamic> tokens;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        tokens = await login(_emailController.text, _passwordController.text);
        await saveTokens(tokens);
        String? role = await getUserRole();
        Widget page = getPageForRole(role);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        return;
      }

      setState(() => _isLoading = false);
    }
  }

  void _handleGoogleLogin() {
    // Google Sign-In logic
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
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
                                _buildHeader(),
                                const SizedBox(height: 22),
                                _buildForm(),
                                const SizedBox(height: 12),
                                _buildForgotPassword(),
                                const SizedBox(height: 22),
                                _buildLoginButton(),
                                const SizedBox(height: 14),
                                _buildSignUpRow(),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLogoHeader(),
        const SizedBox(height: 22),
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in with your ENSAM account to continue.',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF54657A),
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Ensam email address',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              final normalizedEmail = value.trim().toLowerCase();
              if (!RegExp(
                r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(normalizedEmail)) {
                return 'Please enter a valid email';
              }
              if (!normalizedEmail.endsWith('@ensam-casa.ma')) {
                return 'Email must end with @ensam-casa.ma';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: darkColor.withOpacity(0.4),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    List<String>? autofillHints;
    if (label.toLowerCase().contains('email')) {
      autofillHints = [AutofillHints.email];
    } else if (label.toLowerCase().contains('password')) {
      autofillHints = [AutofillHints.password];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF355070),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 15,
            color: navy,
            fontWeight: FontWeight.w500,
          ),
          validator: validator,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9DB0C3), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF7D94AE), size: 20),
            suffixIcon: suffixIcon,
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
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {},
        child: const Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E5A99),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: primaryBlue.withOpacity(0.6),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.login_rounded),
        label: Text(
          _isLoading ? 'Signing in...' : 'Sign in',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: darkColor.withOpacity(0.12), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(
              fontSize: 13,
              color: darkColor.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: darkColor.withOpacity(0.12), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          foregroundColor: darkColor,
          side: BorderSide(color: darkColor.withOpacity(0.15), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleLogo(),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: darkColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }

  Widget _buildSignUpRow() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            'First time here?',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF54657A),
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivationEmailPage(),
                ),
              );
            },
            child: const Text(
              'Activate my account',
              style: TextStyle(
                fontSize: 14,
                color: primaryBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintRed = Paint()..color = const Color(0xFFEA4335);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintGreen = Paint()..color = const Color(0xFF34A853);

    // Red arc (top-left)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.3,
      1.8,
      true,
      paintRed,
    );

    // Yellow arc (bottom-left)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      5.1,
      0.9,
      true,
      paintYellow,
    );

    // Green arc (bottom-right)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0.0,
      1.6,
      true,
      paintGreen,
    );

    // Blue arc (right)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.6,
      1.7,
      true,
      paintBlue,
    );

    // White center circle
    final paintWhite = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.62, paintWhite);

    // Blue right bar
    final paintBlueBar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.22, r, r * 0.44),
      paintBlueBar,
    );

    // White center again to clean
    canvas.drawCircle(Offset(cx, cy), r * 0.62, paintWhite);

    // Blue horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(cx - r * 0.05, cy - r * 0.22, r * 1.05, r * 0.44),
      paintBlueBar,
    );

    // Inner white
    canvas.drawCircle(Offset(cx, cy), r * 0.58, paintWhite);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
