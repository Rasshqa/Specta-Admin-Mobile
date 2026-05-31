import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../state/gatekeeper_state.dart';
import '../services/scan_feedback_service.dart';
import '../theme/specta_theme.dart';

class GatekeeperScreen extends StatefulWidget {
  const GatekeeperScreen({super.key});

  @override
  State<GatekeeperScreen> createState() => _GatekeeperScreenState();
}

class _GatekeeperScreenState extends State<GatekeeperScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController cameraController;
  late TextEditingController _manualCtrl;
  late AnimationController _scanAnimationController;
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    _manualCtrl = TextEditingController();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Crucial requirement: completely shut down camera stream to save battery
    cameraController.dispose();
    _manualCtrl.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _processTicket(String code) async {
    setState(() => isScanning = false);

    final gatekeeperState = context.read<GatekeeperState>();
    await gatekeeperState.verifyTicket(code);

    final success = gatekeeperState.status == ScanStatus.success;
    final message = success 
        ? gatekeeperState.successMessage ?? 'ACCESS GRANTED' 
        : gatekeeperState.errorMessage ?? 'ACCESS DENIED';

    await ScanFeedbackService.play(
      ScanFeedbackService.fromScanResult(success: success, message: message),
    );

    // Auto dismiss after 3 seconds and resume scanning
    if (mounted) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.read<GatekeeperState>().reset();
          setState(() {
            isScanning = true;
          });
        }
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? "Unknown";
      _processTicket(code);
    }
  }

  Future<void> _verifyManualCode() async {
    final code = _manualCtrl.text.trim();
    if (code.isEmpty) return;
    
    // Close keyboard
    FocusScope.of(context).unfocus();
    _manualCtrl.clear();
    await _processTicket(code);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GatekeeperState>(
      builder: (context, gatekeeperState, child) {
        final bool showResult = gatekeeperState.status == ScanStatus.success || 
                               gatekeeperState.status == ScanStatus.error;
        final bool isResultSuccess = gatekeeperState.status == ScanStatus.success;
        final String resultMsg = isResultSuccess 
            ? (gatekeeperState.successMessage ?? 'ACCESS GRANTED') 
            : (gatekeeperState.errorMessage ?? 'ACCESS DENIED');
        final String buyerName = gatekeeperState.buyerName ?? '';

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Camera View
              MobileScanner(
                controller: cameraController,
                onDetect: _onDetect,
              ),

              // Custom Overlay
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GATEKEEPER',
                            style: GoogleFonts.orbitron(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: SpectaTheme.neonCyan,
                              shadows: SpectaTheme.neonGlowCyan,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.zap, color: Colors.white),
                            onPressed: () => cameraController.toggleTorch(),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Scanner Frame (Corner Brackets)
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: _buildCornerBrackets(),
                          ),

                          // Animated Scan Line
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AnimatedBuilder(
                              animation: _scanAnimationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                      0, _scanAnimationController.value * 250),
                                  child: Container(
                                    height: 2,
                                    width: 250,
                                    decoration: BoxDecoration(
                                      color: SpectaTheme.neonPurple,
                                      boxShadow: SpectaTheme.neonGlowPurple,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    
                    // ---- Manual Ticket Entry ----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'ATAU MASUKKAN KODE TIKET MANUAL',
                            style: GoogleFonts.orbitron(
                              color: SpectaTheme.neonCyan,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _manualCtrl,
                            style: const TextStyle(fontFamily: 'Orbitron'),
                            decoration: InputDecoration(
                              hintText: 'Masukkan kode tiket...',
                              hintStyle: const TextStyle(fontFamily: 'Orbitron'),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: SpectaTheme.neonCyan),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: SpectaTheme.neonPurple, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: gatekeeperState.status == ScanStatus.scanning
                                ? null
                                : _verifyManualCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SpectaTheme.neonCyan,
                            ),
                            child: gatekeeperState.status == ScanStatus.scanning
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'VERIFIKASI',
                                    style: TextStyle(fontFamily: 'Orbitron'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Bottom Info
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isScanning
                              ? 'ALIGN QR CODE WITHIN FRAME'
                              : 'PROCESSING...',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            letterSpacing: 3,
                            color: isScanning
                                ? Colors.white
                                : SpectaTheme.neonCyan,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scan Result Overlay
              if (showResult)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: SpectaTheme.slateGlass,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isResultSuccess
                                ? SpectaTheme.neonCyan.withValues(alpha: 0.5)
                                : Colors.redAccent.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isResultSuccess
                                  ? SpectaTheme.neonCyan.withValues(alpha: 0.3)
                                  : Colors.redAccent.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isResultSuccess
                                  ? LucideIcons.shieldCheck
                                  : LucideIcons.shieldAlert,
                              size: 64,
                              color: isResultSuccess
                                  ? SpectaTheme.neonCyan
                                  : Colors.redAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isResultSuccess ? 'ACCESS GRANTED' : 'ACCESS DENIED',
                              style: GoogleFonts.orbitron(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isResultSuccess
                                    ? SpectaTheme.neonCyan
                                    : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              resultMsg,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: SpectaTheme.textMuted, fontSize: 13),
                            ),
                            if (buyerName.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                buyerName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCornerBrackets() {
    const double length = 40;
    const double thickness = 4;
    final color = SpectaTheme.neonCyan;

    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
              width: length,
              height: thickness,
              decoration: BoxDecoration(
                  color: color, boxShadow: SpectaTheme.neonGlowCyan)),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
              width: thickness,
              height: length,
              decoration: BoxDecoration(
                  color: color, boxShadow: SpectaTheme.neonGlowCyan)),
        ),

        // Top Right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
              width: length,
              height: thickness,
              decoration: BoxDecoration(
                  color: color, boxShadow: SpectaTheme.neonGlowCyan)),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
              width: thickness,
              height: length,
              decoration: BoxDecoration(
                  color: color, boxShadow: SpectaTheme.neonGlowCyan)),
        ),

        // Bottom Left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
              width: length,
              height: thickness,
              decoration: BoxDecoration(
                  color: color, boxShadow: SpectaTheme.neonGlowCyan)),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
              width: thickness,
              height: length,
              decoration: BoxDecoration(
                  color: color, boxShadow: SpectaTheme.neonGlowCyan)),
        ),

        // Bottom Right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
              width: length,
              height: thickness,
              decoration: BoxDecoration(
                  color: color, boxShadow: SpectaTheme.neonGlowCyan)),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
              width: thickness,
              height: length,
              decoration: BoxDecoration(
                  color: color, boxShadow: SpectaTheme.neonGlowCyan)),
        ),
      ],
    );
  }
}
