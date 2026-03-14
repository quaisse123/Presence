import 'package:flutter/material.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/Api/JwtService.dart';
import 'package:frontend/MainScreen.dart';
import 'package:frontend/pages/profDash.dart';
import 'package:http/http.dart';

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

  static const Color primaryBlue = Color(0xFF1877F2);
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildForm(),
                  const SizedBox(height: 16),
                  _buildForgotPassword(),
                  const SizedBox(height: 28),
                  _buildLoginButton(),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildGoogleButton(),
                  const Spacer(),
                  _buildSignUpRow(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 28),
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: darkColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account to continue',
          style: TextStyle(
            fontSize: 15,
            color: darkColor.withOpacity(0.5),
            fontWeight: FontWeight.w400,
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
            label: 'Email address',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
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
    // Ajout autofillHints pour email et password
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkColor.withOpacity(0.75),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(
            fontSize: 15,
            color: darkColor,
            fontWeight: FontWeight.w500,
          ),
          validator: validator,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: darkColor.withOpacity(0.3),
              fontSize: 15,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: darkColor.withOpacity(0.35), size: 20),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: lightGrey,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE53935),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
            color: primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: const Color.fromARGB(255, 175, 163, 163),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: primaryBlue.withOpacity(0.6),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Sign in',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
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
      child: RichText(
        text: TextSpan(
          text: "Don't have an account? ",
          style: TextStyle(
            fontSize: 14,
            color: darkColor.withOpacity(0.5),
            fontWeight: FontWeight.w400,
          ),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () {},
                child: const Text(
                  'Create one',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
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
