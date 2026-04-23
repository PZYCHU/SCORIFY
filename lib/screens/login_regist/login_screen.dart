import 'package:flutter/material.dart';
import 'package:scorify/services/auth_service.dart';
import 'package:scorify/screens/login_regist/register_screen.dart';
import 'package:scorify/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  // bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) _showError('Error (${e.runtimeType}): ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Future<void> _signInWithGoogle() async {
  //   setState(() => _isGoogleLoading = true);
  //   try {
  //     await _authService.signInWithGoogle();
  //     if (mounted) {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => const HomeScreen()),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) _showError(e.toString());
  //   } finally {
  //     if (mounted) setState(() => _isGoogleLoading = false);
  //   }
  // }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1B4F72),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xFF2C7873), Color(0xFF4FA3A0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Logo area ──
              Expanded(
                flex: 4,
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: const Text(
                      'SCORIFY',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B4F72),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Card ──
              Expanded(
                flex: 7,
                child: SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5E8),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(36),
                          topRight: Radius.circular(36),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B4F72),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Email
                              _buildTextField(
                                controller: _emailController,
                                hint: 'Email ID',
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email tidak boleh kosong';
                                  if (!v.contains('@')) return 'Format email tidak valid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password
                              _buildTextField(
                                controller: _passwordController,
                                hint: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF2C7873),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
                                  if (v.length < 6) return 'Password minimal 6 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => _showForgotPassword(),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color(0xFF2C7873),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Sign In button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signInWithEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B4F72),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Divider
                              // Row(
                              //   children: [
                              //     Expanded(child: Divider(color: Colors.grey.shade400, thickness: 0.8)),
                              //     Padding(
                              //       padding: const EdgeInsets.symmetric(horizontal: 12),
                              //       child: Text(
                              //         'atau',
                              //         style: TextStyle(
                              //           color: Colors.grey.shade500,
                              //           fontSize: 13,
                              //         ),
                              //       ),
                              //     ),
                              //     Expanded(child: Divider(color: Colors.grey.shade400, thickness: 0.8)),
                              //   ],
                              // ),
                              // const SizedBox(height: 20),

                              // Google Sign-In button
                              // SizedBox(
                              //   width: double.infinity,
                              //   height: 52,
                              //   child: OutlinedButton.icon(
                              //     onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                              //     style: OutlinedButton.styleFrom(
                              //       side: const BorderSide(
                              //         color: Color(0xFF2C7873),
                              //         width: 1.5,
                              //       ),
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(30),
                              //       ),
                              //     ),
                              //     icon: _isGoogleLoading
                              //         ? const SizedBox(
                              //             height: 20,
                              //             width: 20,
                              //             child: CircularProgressIndicator(
                              //               color: Color(0xFF2C7873),
                              //               strokeWidth: 2.5,
                              //             ),
                              //           )
                              //         : Image.asset(
                              //             'assets/google_logo.png',
                              //             height: 22,
                              //             width: 22,
                              //             errorBuilder: (_, _, _) => const Icon(
                              //               Icons.g_mobiledata_rounded,
                              //               size: 26,
                              //               color: Color(0xFF2C7873),
                              //             ),
                              //           ),
                              //     label: const Text(
                              //       'Sign in with Google',
                              //       style: TextStyle(
                              //         color: Color(0xFF1B4F72),
                              //         fontSize: 15,
                              //         fontWeight: FontWeight.w600,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              // const SizedBox(height: 24),

                              // Register link
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const RegisterScreen()),
                                      ),
                                      child: const Text(
                                        'Register',
                                        style: TextStyle(
                                          color: Color(0xFF2C7873),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F5E8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1B4F72))),
            const SizedBox(height: 8),
            Text('Masukkan email yang terdaftar untuk menerima link reset password.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            _buildTextField(
              controller: emailCtrl,
              hint: 'Email ID',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  if (emailCtrl.text.trim().isEmpty) return;
                  Navigator.pop(context);
                  try {
                    await _authService.sendPasswordReset(emailCtrl.text.trim());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Link reset password telah dikirim ke email Anda'),
                        backgroundColor: Color(0xFF2C7873),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  } catch (e) {
                    if (mounted) _showError(e.toString());
                  }
                },
                child: const Text('Kirim Link Reset',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1B4F72)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2C7873), size: 20),
        suffixIcon: suffixIcon,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF2C7873), width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}
