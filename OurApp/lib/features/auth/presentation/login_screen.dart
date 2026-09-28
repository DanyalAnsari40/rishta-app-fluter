import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user != null && user.isAdmin) {
        context.go('/admin/dashboard');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header section matching Register Screen
                Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                        onPressed: () {
                          if (context.canPop()) context.pop();
                        },
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 30),
                        const Text(
                          'Find exactly the',
                          style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Right Partner for you!',
                          style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        
                        // Cloud-like grey background with Heart Logo
                        Container(
                          width: double.infinity,
                          height: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.favorite, color: Color(0xFFF71A65), size: 40),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('RIGHT LIFE', style: TextStyle(color: Color(0xFFF71A65), fontSize: 16, fontWeight: FontWeight.bold)),
                                    Text('PARTNER', style: TextStyle(color: const Color(0xFFF71A65).withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Welcome Back!",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Log in to your account',
                          style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 20),

                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _buildTextField(_emailController, 'Email Address', TextInputType.emailAddress, null),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, 'Password', TextInputType.text, _obscurePassword, isPassword: true),
                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFF71A65), fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pink Login Button
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF71A65),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          shadowColor: const Color(0xFFF71A65).withOpacity(0.5),
                        ),
                        child: authState.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),
                      
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      OutlinedButton.icon(
                        onPressed: authState.isLoading
                            ? null
                            : () async {
                                await ref.read(authProvider.notifier).googleLogin(
                                      'google_demo_123',
                                      'user@gmail.com',
                                      'Google User',
                                    );
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 30, color: Color(0xFF2C3E50)),
                        label: const Text('Continue with Google', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ", style: TextStyle(color: Colors.black54, fontSize: 14)),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: const Text(
                              'Register here',
                              style: TextStyle(color: Color(0xFFF71A65), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type, bool? obscure, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure ?? false,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF71A65)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure! ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: Colors.black45,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
