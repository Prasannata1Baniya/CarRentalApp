import 'package:carrentalapp/screens/auth_page/register_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../navbar/navbar_config.dart';
import '../../utils/input_decoration.dart';
import '../../widgets/app_shell.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? error;
  bool isLoading = false;
  bool _isPasswordObscured = true;
  final InputDecorate inputDecorate = InputDecorate();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final authProvider = context.read<AuthProviderMethod>();

      // 1. Log in
      final message = await authProvider.loginWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (message == 'Success') {
        // 2. Fetch the role string from Firestore
        String roleString = await authProvider.getUserRole(
            authProvider.user!.uid);

        debugPrint("Logged in as: $roleString");

        // 4. Trim and lowercase the comparison
        final role = (roleString.toLowerCase().trim() == 'owner')
            ? UserRole.owner
            : UserRole.passenger;

        if (!mounted) return;

        // 5. Navigate to the Shell with the CORRECT role
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AppShell(userRole: role)),
        );
      } else {
        setState(() {
          error = message;
        });
      }
    } catch (e) {
      setState(() {
        error = "Login Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          color: const Color(0xFF112233),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "DriveX",
                                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                " Ride",
                                style: TextStyle(color: Color(0xFFFF5500), fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                " Rentals",
                                style: TextStyle(color: Colors.white, fontSize: 22),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6F8),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    border: Border(bottom: BorderSide(color: Color(0xFFFF5500), width: 3)),
                                  ),
                                  child: const Text("LOGIN", style: TextStyle(color: Color(0xFFFF5500), fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => const RegisterPage())),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: const Text("REGISTER", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const Text(
                                  "Login & Register",
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF112233)),
                                ),
                                const SizedBox(height: 28),

                                // Email Field (Clean light-grey outline)
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Color(0xFF112233)),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: inputDecorate.buildInputDecoration(
                                    "Email Address",
                                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400, size: 20),
                                  ),
                                  validator: (value) => (value == null || !value.contains('@')) ? 'Invalid email' : null,
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  style: const TextStyle(color: Color(0xFF112233)),
                                  obscureText: _isPasswordObscured,
                                  decoration: inputDecorate.buildInputDecoration(
                                    "Password",
                                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.grey, size: 20,
                                      ),
                                      onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                                    ),
                                  ),
                                  validator: (value) => (value == null || value.length < 6) ? 'Short password' : null,
                                ),

                                // Forgot Password Action Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(color: Color(0xFF112233), decoration: TextDecoration.underline, fontSize: 13),
                                    ),
                                  ),
                                ),

                                if (error != null) _buildErrorBanner(),

                                const SizedBox(height: 20),

                                // Solid Punchy Action Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      backgroundColor: const Color(0xFFFF5500), // Intense layout orange
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    onPressed: isLoading ? null : _handleLogin,
                                    child: isLoading
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text("LOGIN", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                const Text("Or register for a new account", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                const SizedBox(height: 20),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildSocialButton("assets/images/google_logo.png"),
                                    const SizedBox(width: 16),
                                    _buildSocialButton("assets/images/facebook_logo.png"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String assetPath) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Image.asset(assetPath, height: 22, width: 22, errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, color: Colors.grey)),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
        ],
      ),
    );
  }

}




/*
import 'dart:ui';
import 'package:carrentalapp/screens/auth_page/register_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../navbar/navbar_config.dart';
import '../../utils/input_decoration.dart';
import '../../utils/text_styles.dart';
import '../../widgets/app_shell.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? error;
  bool isLoading = false;
  bool _isPasswordObscured = true;
  final InputDecorate inputDecorate = InputDecorate();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final authProvider = context.read<AuthProviderMethod>();

      // 1. Log in
      final message = await authProvider.loginWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (message == 'Success') {
        // 2. Fetch the role string from Firestore
        String roleString = await authProvider.getUserRole(
            authProvider.user!.uid);

        debugPrint("Logged in as: $roleString");

        // 4. Trim and lowercase the comparison
        final role = (roleString.toLowerCase().trim() == 'owner')
            ? UserRole.owner
            : UserRole.passenger;

        if (!mounted) return;

        // 5. Navigate to the Shell with the CORRECT role
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AppShell(userRole: role)),
        );
      } else {
        setState(() {
          error = message;
        });
      }
    } catch (e) {
      setState(() {
        error = "Login Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              "assets/images/car_background.png",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 20),
              child: Column(
                children: [
                  Text("EASY CAR RENTAL", style: AppTextStyles.headingWhite),
                  const SizedBox(height: 8),
                  const Text("Your premium journey starts here",
                      style: TextStyle(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 30),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset("assets/images/driveX_logo.png",
                                    //height: 80
                                  height: 100,
                                ),
                                const SizedBox(height: 40),

                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: inputDecorate
                                      .buildInputDecoration(
                                    "Email",
                                    suffixIcon: const Icon(Icons.email_outlined,
                                        color: Colors.white38, size: 20),
                                  ),
                                  validator: (value) =>
                                  (value == null || !value.contains('@'))
                                      ? 'Invalid email'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  style: const TextStyle(color: Colors.white),
                                  obscureText: _isPasswordObscured,
                                  decoration: inputDecorate
                                      .buildInputDecoration(
                                    "Password",
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordObscured ? Icons
                                            .visibility_off_outlined : Icons
                                            .visibility_outlined,
                                        color: Colors.white38, size: 20,
                                      ),
                                      onPressed: () =>
                                          setState(() =>
                                          _isPasswordObscured =
                                          !_isPasswordObscured),
                                    ),
                                  ),
                                  validator: (value) =>
                                  (value == null || value.length < 6)
                                      ? 'Short password'
                                      : null,
                                ),

                                if (error != null)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(top: 20),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            error!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 35),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              15)),
                                      //backgroundColor: Colors.orangeAccent,
                                      // shadowColor: Colors.orangeAccent.withValues(alpha: 0.4),
                                      backgroundColor: const Color(0xFFFF9F43),
                                      shadowColor: const Color(0xFFFF9F43).withValues(alpha: 0.3),
                                      foregroundColor: Colors.white,
                                      elevation: 8,
                                    ),
                                    onPressed: isLoading ? null : _handleLogin,
                                    child: isLoading
                                        ? const SizedBox(height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                        : const Text("LOGIN", style: TextStyle(
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold)),
                                  ),
                                ),

                                const SizedBox(height: 25),

                                // Register Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("New here? ", style: TextStyle(
                                        color: Colors.white54)),
                                    GestureDetector(
                                      onTap: () =>
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (
                                                  _) => const RegisterPage())),
                                      child: const Text("Create Account",
                                          style: TextStyle(
                                              color: Colors.orangeAccent,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration
                                                  .underline)),
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
          ),
        ],
      ),
    );
  }
}
*/