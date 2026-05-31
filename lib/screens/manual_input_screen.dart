import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/specta_theme.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({super.key});

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final admin = context.read<AdminProvider>();
    final quantity = int.parse(_quantityController.text.trim());

    final ok = await admin.storeManualTicket(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      quantity: quantity,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Manual ticket created successfully',
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: SpectaTheme.neonCyan.withValues(alpha: 0.95),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            admin.error ?? 'Failed to create ticket',
            style: GoogleFonts.orbitron(fontSize: 12),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: SpectaTheme.slateBg,
      appBar: AppBar(
        backgroundColor: SpectaTheme.slateBg,
        elevation: 0,
        title: Text(
          'MANUAL TICKET',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: SpectaTheme.neonPurple,
            shadows: SpectaTheme.neonGlowPurple,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SpectaTheme.neonPurple.withValues(alpha: 0.15),
                      SpectaTheme.neonCyan.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SpectaTheme.neonPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Issue tickets directly from the command center. '
                  'Orders are auto-approved and ticket codes are generated.',
                  style: const TextStyle(
                    color: SpectaTheme.textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _OrbitronField(
                label: 'BUYER NAME',
                controller: _nameController,
                icon: LucideIcons.user,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _OrbitronField(
                label: 'EMAIL',
                controller: _emailController,
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!_emailPattern.hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _OrbitronField(
                label: 'TICKET QUANTITY',
                controller: _quantityController,
                icon: LucideIcons.ticket,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  final qty = int.tryParse(v.trim());
                  if (qty == null || qty <= 0) {
                    return 'Quantity must be greater than 0';
                  }
                  if (qty > 5) {
                    return 'Maximum 5 tickets per order';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: admin.isSubmittingManual ? null : _submit,
                child: admin.isSubmittingManual
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'CREATE TICKET',
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitronField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _OrbitronField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: SpectaTheme.textMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.orbitron(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: SpectaTheme.neonPurple, size: 20),
          ),
        ),
      ],
    );
  }
}
