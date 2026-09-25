import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/connectivity_wrapper.dart';
import 'register_screen.dart';
import '../passenger/home_screen.dart';
import '../rider/home_screen.dart' as rider;

class LoginScreen extends StatefulWidget {
  final String? prefillEmail;
  final String? prefillPassword;

  const LoginScreen({super.key, this.prefillEmail, this.prefillPassword});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _authService   = AuthService();

  bool _obscure      = true;
  bool _loading      = false;
  bool _rememberMe   = false;

  // ── Lifecycle ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail    != null) _emailCtrl.text    = widget.prefillEmail!;
    if (widget.prefillPassword != null) _passwordCtrl.text = widget.prefillPassword!;
    _loadRemembered();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Remember Me ──────────────────────────────────────────────────────

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email') ?? '';
    final remember   = prefs.getBool('remember_me') ?? false;
    if (remember && savedEmail.isNotEmpty && widget.prefillEmail == null) {
      setState(() {
        _emailCtrl.text = savedEmail;
        _rememberMe     = true;
      });
    }
  }

  Future<void> _saveRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailCtrl.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.setBool('remember_me', false);
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ConnectivityWrapper.checkAndAlert(context)) return;
    setState(() => _loading = true);
    try {
      final cred = await _authService.login(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (cred != null && mounted) {
        await _saveRemembered();
        await NotificationService().saveTokenAfterLogin();
        final role = await _authService.getUserRole(cred.user!.uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back! Logged in successfully.'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role == 'rider'
                ? rider.RiderHomeScreen()
                : const PassengerHomeScreen(),
          ),
        );
      }
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

  /// Shows a bottom sheet where the user enters/confirms their email,
  /// then sends the reset email — no need to have typed it in the main form.
  void _forgotPassword() {
    final sheetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                MediaQuery.of(ctx).viewInsets.bottom + 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your email and we\'ll send you a reset link.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: sheetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFFFC107)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: sending
                        ? null
                        : () async {
                            final email = sheetEmailCtrl.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter your email address'),
                                  backgroundColor: Color(0xFF1E1E1E),
                                ),
                              );
                              return;
                            }
                            if (!ConnectivityWrapper.checkAndAlert(context)) {
                              return;
                            }
                            setSheetState(() => sending = true);
                            // Capture context-dependent refs before any await
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(sheetCtx);
                            try {
                              await _authService.sendPasswordReset(
                                  email: email);
                              if (!mounted) return;
                              nav.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Reset link sent! Check your inbox.'),
                                  backgroundColor: Color(0xFF4CAF50),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setSheetState(() => sending = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(_friendlyError(e.toString())),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                    child: sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _friendlyError(String error) {
    if (error.contains('user-not-found'))         return 'No account found with this email.';
    if (error.contains('wrong-password'))         return 'Incorrect password.';
    if (error.contains('invalid-credential'))     return 'Incorrect email or password.';
    if (error.contains('invalid-email'))          return 'Invalid email address.';
    if (error.contains('network-request-failed')) return 'No internet connection.';
    return 'Login failed. Please try again.';
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
                const SizedBox(height: 48),

                // ── Logo ───────────────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('YeRide.png', width: 100, height: 100,
                      fit: BoxFit.contain),
                ),

                const SizedBox(height: 32),

                // ── Heading ────────────────────────────────────────────
                const Text(
                  'Welcome back',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // ── Email ──────────────────────────────────────────────
                _buildField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter your email' : null,
                ),

                const SizedBox(height: 14),

                // ── Password ───────────────────────────────────────────
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
                      v!.length < 6 ? 'Password too short' : null,
                ),

                const SizedBox(height: 4),

                // ── Remember me + Forgot password row ─────────────────
                Row(
                  children: [
                    // Remember me
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                        activeColor: const Color(0xFFFFC107),
                        checkColor: Colors.black,
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Remember me',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 13)),
                    const Spacer(),
                    TextButton(
                      onPressed: _forgotPassword,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                            color: Color(0xFFFFC107), fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Login button ───────────────────────────────────────
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2.5))
                      : const Text(
                          'Login',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 28),

                // ── Sign up link ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?",
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        'Sign Up',
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
          borderSide: const BorderSide(color: Color(0xFFFFC107), width: 1.5),
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
