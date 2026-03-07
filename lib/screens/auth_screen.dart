import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  final _supabaseService = SupabaseService();

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    // --- Input validation ---
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in email and password.');
      return;
    }
    if (_isSignUp && username.isEmpty) {
      _showError('Please enter a username.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        // --- Sign Up ---
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user != null) {
          // Create initial profile record
          await _supabaseService.createInitialProfile(
            response.user!.id,
            username,
          );

          // Check if email confirmation is required
          if (response.session == null) {
            // No session means email confirmation is pending
            if (mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF2A1B3D),
                  title: const Text('Check your email!', style: TextStyle(color: Colors.white)),
                  content: Text(
                    'We sent a confirmation link to $email.\n\nPlease click it, then come back and sign in.\n\n(Tip: To skip email confirmation for dev/testing, go to your Supabase Dashboard → Authentication → Providers → Email and disable "Confirm email".)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _isSignUp = false); // switch to sign-in mode
                      },
                      child: const Text('GOT IT', style: TextStyle(color: Color(0xFF22D3EE))),
                    ),
                  ],
                ),
              );
            }
          }
          // If session IS present, AuthGate handles the redirect automatically
        }
      } else {
        // --- Sign In ---
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        // AuthGate handles the redirect automatically
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email first!')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset link sent! Check your inbox 📧')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFA855F7);
    const neonCyan = Color(0xFF22D3EE);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0814),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Title
              const Icon(Icons.bolt, size: 80, color: primaryColor),
              const SizedBox(height: 16),
              const Text(
                'DareDay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back, challenger',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 48),

              // Form Fields
              if (_isSignUp) ...[
                _buildTextField('Username', _usernameController, Icons.person_outline),
                const SizedBox(height: 16),
              ],
              _buildTextField('Email', _emailController, Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField('Password', _passwordController, Icons.lock_outline, isPassword: true),
              const SizedBox(height: 32),

              // Action Button
              ElevatedButton(
                onPressed: _isLoading ? null : _authenticate,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: _isSignUp ? neonCyan : primaryColor,
                  foregroundColor: _isSignUp ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        _isSignUp ? 'JOIN THE DARE' : 'SIGN IN',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),

              if (!_isSignUp)
                TextButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: neonCyan.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ),

              const SizedBox(height: 16),

              // Toggle Mode
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp ? 'Already a member? Sign In' : "Don't have an account? Sign Up",
                  style: TextStyle(color: neonCyan.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFFA855F7).withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
        ),
      ),
    );
  }
}
