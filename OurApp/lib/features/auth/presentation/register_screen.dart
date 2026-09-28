import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _profileCreatedFor = 'self';
  bool _is18Plus = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  final Map<String, String> _createdForOptions = {
    'self': 'Self',
    'son': 'Son',
    'daughter': 'Daughter',
    'brother': 'Brother',
    'sister': 'Sister',
    'relative': 'Relative',
    'friend': 'Friend',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_is18Plus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must confirm that you are at least 18 years old.')),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the Terms of Service & Privacy Policy.')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          profileCreatedFor: _profileCreatedFor,
          phone: _phoneController.text.trim(),
        );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header section with back button and logo
                Stack(
                  children: [
                    // Back button
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
                          "Let's Get Started!",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create your account',
                          style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),
                        
                        // Dots indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDot(false),
                            _buildDot(false),
                            _buildDot(true),
                            _buildDot(false),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Register',
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

                      _buildDropdownField(),
                      const SizedBox(height: 16),
                      _buildTextField(_emailController, 'Email Address', TextInputType.emailAddress, null),
                      const SizedBox(height: 16),
                      _buildTextField(_passwordController, 'Password', TextInputType.text, _obscurePassword, isPassword: true),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'Phone Number (Optional)', TextInputType.phone, null),
                      const SizedBox(height: 12),

                      CheckboxListTile(
                        value: _is18Plus,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFF71A65),
                        title: const Text('I confirm that I am at least 18 years old.', style: TextStyle(fontSize: 13, color: Colors.black87)),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (val) => setState(() => _is18Plus = val ?? false),
                      ),
                      CheckboxListTile(
                        value: _agreedToTerms,
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFFF71A65),
                        title: const Text('I agree to the Terms & Privacy Policy.', style: TextStyle(fontSize: 13, color: Colors.black87)),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                      ),
                      const SizedBox(height: 24),

                      // Pink Register Button
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleRegister,
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
                            : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(color: Colors.black54, fontSize: 14)),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text(
                              'Login here',
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

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF71A65) : const Color(0xFFF71A65).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _profileCreatedFor,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black45),
      decoration: InputDecoration(
        labelText: 'Select the profile for',
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
      ),
      items: _createdForOptions.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _profileCreatedFor = val);
      },
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
          if (label.contains('Optional')) return null;
          return 'This field is required';
        }
        return null;
      },
    );
  }
}

