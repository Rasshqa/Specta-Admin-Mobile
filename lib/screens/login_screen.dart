import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/auth_provider.dart';
import '../theme/specta_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    
    try {
      await auth.login(_emailController.text, _passwordController.text);
      // Main.dart's Consumer will automatically navigate based on auth.isAuthenticated
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Cyberpunk Background Elements
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SpectaTheme.neonPurple.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(
                    color: SpectaTheme.neonPurple.withOpacity(0.3),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SpectaTheme.neonCyan.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: SpectaTheme.neonCyan.withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / Title
                      Text(
                        'SPECTA XXI',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: SpectaTheme.neonGlowCyan,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GATEKEEPER ACCESS',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                          color: SpectaTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Glassmorphic Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: SpectaTheme.slateGlass.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Admin Email',
                                prefixIcon: Icon(LucideIcons.mail, color: SpectaTheme.textMuted),
                              ),
                              validator: (val) => val != null && val.contains('@') 
                                  ? null 
                                  : 'Enter a valid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(LucideIcons.lock, color: SpectaTheme.textMuted),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                                    color: SpectaTheme.textMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) => val != null && val.isNotEmpty 
                                  ? null 
                                  : 'Password is required',
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleLogin,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('INITIALIZE LINK'),
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
        ],
      ),
    );
  }
}
