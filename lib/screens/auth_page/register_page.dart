import 'package:flutter/material.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../utils/input_decoration.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _numController = TextEditingController();

  FocusNode focusNode = FocusNode();
  String _phoneNumber = "";

  final List<String> roles = ['passenger', 'owner'];
  String? selectedRole;
  String? error;
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  // Initialized the class instance instance here
  final InputDecorate inputDecorate = InputDecorate();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _numController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      error = null;
    });

    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _numController.text,
      selectedRole!,
    );

    if (!mounted) return;

    if (message == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      setState(() {
        _isLoading = false;
        error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          color: const Color(0xFF1B2A4A),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          width: double.infinity,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("DriveX", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              Text(" Ride", style: TextStyle(color: Color(0xFFFF5500), fontSize: 22, fontWeight: FontWeight.bold)),
                              Text(" Rentals", style: TextStyle(color: Colors.white, fontSize: 22)),
                            ],
                          ),
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                                child: Container(
                                  color: const Color(0xFFF4F6F8),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: const Text("LOGIN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(bottom: BorderSide(color: Color(0xFFFF5500), width: 3)),
                                ),
                                child: const Text("REGISTER", style: TextStyle(color: Color(0xFFFF5500), fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 35.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const Text(
                                  "Create An Account",
                                  style: TextStyle(color: Color(0xFF1B2A4A), fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 25),

                                // Full Name
                                _buildInputField(
                                  controller: _nameController,
                                  hint: "Full Name",
                                  icon: Icons.person_outline,
                                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
                                ),

                                // Email
                                _buildInputField(
                                  controller: _emailController,
                                  hint: "Email Address",
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) => (value == null || !value.contains('@')) ? "Invalid email" : null,
                                ),

                                // Password
                                _buildInputField(
                                  controller: _passwordController,
                                  hint: "Password",
                                  icon: Icons.lock_outline,
                                  obscureText: _isPasswordObscured,
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20),
                                    onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                                  ),
                                  validator: (value) => (value == null || value.length < 6) ? 'Short password' : null,
                                ),

                                IntlPhoneField(
                                  controller: _numController,
                                  style: const TextStyle(color: Color(0xFF1B2A4A)),
                                  dropdownTextStyle: const TextStyle(color: Color(0xFF1B2A4A)),
                                  cursorColor: const Color(0xFFFF5500),
                                  decoration: inputDecorate.buildInputDecoration(
                                    "Phone Number",
                                    prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade600, size: 20),
                                  ).copyWith(
                                    counterStyle: const TextStyle(color: Colors.grey),
                                  ),
                                  initialCountryCode: 'NP',
                                  onChanged: (phone) => _phoneNumber = phone.completeNumber,
                                  validator: (value) => (value == null || value.number.length < 10)
                                      ? 'Enter 10 digit number' : null,
                                  pickerDialogStyle: PickerDialogStyle(
                                    backgroundColor: Colors.white,
                                    countryCodeStyle: const TextStyle(color: Color(0xFF1B2A4A)),
                                    countryNameStyle: const TextStyle(color: Color(0xFF1B2A4A)),
                                    searchFieldInputDecoration: inputDecorate.buildInputDecoration(
                                      'Search Country',
                                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                DropdownButtonFormField<String>(
                                  initialValue: selectedRole,
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(color: Color(0xFF1B2A4A)),
                                  borderRadius: BorderRadius.circular(8),
                                  decoration: inputDecorate.buildInputDecoration(
                                    "Select Role",
                                    prefixIcon: Icon(Icons.assignment_ind_outlined, color: Colors.grey.shade600, size: 20),
                                  ),
                                  items: roles.map((role) => DropdownMenuItem(
                                      value: role, child: Text(role.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                                  onChanged: (value) => setState(() {
                                    selectedRole = value;
                                    error = null;
                                  }),
                                  validator: (value) => value == null ? "Required" : null,
                                ),

                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                const SizedBox(height: 30),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      backgroundColor: const Color(0xFFFF5500),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    onPressed: _isLoading ? null : _handleRegister,
                                    child: _isLoading
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text("REGISTER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF1B2A4A)),
        decoration: inputDecorate.buildInputDecoration(
          hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}






/*import 'package:flutter/material.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../utils/input_decoration.dart';
import '../../utils/text_styles.dart';
import 'login_page.dart';
import 'dart:ui';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _numController = TextEditingController();

  FocusNode focusNode = FocusNode();
  String _phoneNumber = "";

  final List<String> roles = ['passenger', 'owner'];
  String? selectedRole;
  String? error;
  bool _isLoading = false;

  final InputDecorate inputDecorate = InputDecorate();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _numController.dispose();
    super.dispose();
  }

  // --- LOGIC: HANDLE REGISTRATION ---
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      error = null;
    });

    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _numController.text,
      selectedRole!,
    );

    if (!mounted) return;

    if (message == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account created successfully! Verification complete.'),
            backgroundColor: Colors.green
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      setState(() {
        _isLoading = false;
        error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/car_background.png",
              fit: BoxFit.cover,
            ),
          ),
          // Dark Overlay Gradient
          Positioned.fill(
            child: Container(
              height: double.infinity,
              width: double.infinity,
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

          // GLASS MORPHISM FORM
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                children: [
                  const Text("Create Account", style: AppTextStyles.headingWhite),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 450,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0,vertical: 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1.5, color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                               TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                  decoration: inputDecorate.buildInputDecoration("Full Name", suffixIcon: const Icon(Icons.person)),
                                  validator: (value) => value == null || value.isEmpty ? "Required" : null,
                                ),
                                const SizedBox(height: 16),

                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                  decoration: inputDecorate.buildInputDecoration("Email").copyWith(
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    suffixIcon: const Icon(Icons.email, color: Colors.white70),
                                  ),
                                  validator: (value) => (value == null || !value.contains('@')) ? "Invalid email" : null,
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  validator: (value) => (value == null || value.length < 6) ? 'Short password' : null,
                                  style: const TextStyle(color: Colors.white),
                                  obscureText: _isPasswordObscured,
                                  decoration: inputDecorate.buildInputDecoration("Password").copyWith(
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordObscured = !_isPasswordObscured;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Phone Number
                                IntlPhoneField(
                                  validator: (value) => (value == null || value.number.length < 10) ? 'Enter 10 digit number' : null,
                                  controller: _numController,
                                  style: const TextStyle(color: Colors.white),
                                  dropdownTextStyle: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.orangeAccent,
                                  decoration: inputDecorate.buildInputDecoration("Phone Number").copyWith(
                                    counterStyle: const TextStyle(color: Colors.white60),
                                  ),
                                  initialCountryCode: 'NP',
                                  onChanged: (phone) {
                                    _phoneNumber = phone.completeNumber;
                                  },
                                  pickerDialogStyle: PickerDialogStyle(
                                    backgroundColor: Colors.grey[900],
                                    countryCodeStyle: const TextStyle(color: Colors.white),
                                    countryNameStyle: const TextStyle(color: Colors.white),
                                    searchFieldInputDecoration: const InputDecoration(
                                      labelText: 'Search Country',
                                      labelStyle: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Role Dropdown
                                DropdownButtonFormField<String>(
                                  initialValue: selectedRole,
                                  decoration: inputDecorate.buildInputDecoration("Select Role"),
                                  dropdownColor: Colors.black87,
                                  style: const TextStyle(color: Colors.white),
                                  borderRadius: BorderRadius.circular(25),
                                  items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                                  onChanged: (value) => setState(() {
                                    selectedRole = value;
                                    error = null;
                                  }),
                                  validator: (value) => value == null ? "Required" : null,
                                ),

                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),

                                const SizedBox(height: 25),

                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isLoading ? null : _handleRegister,
                                    child: _isLoading
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text("Register", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Login Navigation
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                                    TextButton(
                                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                                      child: const Text("Login Now", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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
}*/