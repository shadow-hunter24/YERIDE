import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/connectivity_wrapper.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _authService     = AuthService();

  bool   _obscure  = true;
  bool   _loading  = false;
  String _role     = 'passenger';

  // ── Lifecycle ────────────────────────────────────────────────────────

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ConnectivityWrapper.checkAndAlert(context)) return;
    setState(() => _loading = true);
    try {
      await _authService.register(
        name:     _nameCtrl.text.trim(),
        phone:    _phoneCtrl.text.trim(),
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role:     _role,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            prefillEmail:    _emailCtrl.text.trim(),
            prefillPassword: _passwordCtrl.text,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.toString())),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String error) {
    if (error.contains('email-already-in-use')) return 'Email already registered.';
    if (error.contains('invalid-email'))        return 'Invalid email address.';
    if (error.contains('weak-password'))        return 'Password is too weak.';
    if (error.contains('network-request-failed')) return 'No internet connection.';
    return 'Registration failed. Please try again.';
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // ── Top bar with back arrow ────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Logo ───────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('YeRide.png', width: 80, height: 80,
                      fit: BoxFit.contain),
                ),

                const SizedBox(height: 20),

                // ── Heading ────────────────────────────────────────────
                const Text(
                  'Create Account',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join YɛRide today',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // ── Role picker ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _roleChip('passenger', Icons.person_outline, 'Passenger')),
                    const SizedBox(width: 12),
                    Expanded(child: _roleChip('rider', Icons.electric_moped, 'Rider')),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Fields ─────────────────────────────────────────────
                _buildField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter your phone number' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? 'Minimum 6 characters' : null,
                ),

                const SizedBox(height: 28),

                // ── Create Account button ──────────────────────────────
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5))
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 24),

                // ── Login link ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                            color: Color(0xFFFFC107),
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _roleChip(String value, IconData icon, String label) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFC107)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFFC107) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? Colors.black : Colors.white54),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                  color: selected ? Colors.black : Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ],
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
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFFFC107), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
