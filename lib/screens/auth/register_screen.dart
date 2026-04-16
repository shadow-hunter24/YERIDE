import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../passenger/home_screen.dart';
import '../rider/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String _role = 'passenger';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _role == 'rider'
              ? const RiderHomeScreen()
              : const PassengerHomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text('Join YɛRide today',
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 32),

                // Role selector
                Row(
                  children: [
                    _roleChip('passenger', '🧑 Passenger'),
                    const SizedBox(width: 12),
                    _roleChip('rider', '🏍 Rider'),
                  ],
                ),
                const SizedBox(height: 24),

                _buildField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Enter your name' : null),
                const SizedBox(height: 16),
                _buildField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v!.isEmpty ? 'Enter your phone number' : null),
                const SizedBox(height: 16),
                _buildField(
                    controller: _emailController,
                    label: 'Email (optional)',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _register,
                  child: const Text('Create Account',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: TextStyle(color: Colors.white54)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login',
                          style: TextStyle(color: Color(0xFFFFC107))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String value, String label) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFC107) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFFFFC107) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFC107)),
        ),
      ),
    );
  }
}
