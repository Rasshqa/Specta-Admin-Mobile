import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

enum ScanFeedbackType { success, warning, error }

/// Haptic + system sound feedback for gatekeeper QR scans.
class ScanFeedbackService {
  ScanFeedbackService._();

  static Future<void> play(ScanFeedbackType type) async {
    final player = AudioPlayer();
    switch (type) {
      case ScanFeedbackType.success:
        await HapticFeedback.mediumImpact();
        await player.play(AssetSource('sounds/scan_success.mp3'));
        break;
      case ScanFeedbackType.warning:
        await HapticFeedback.lightImpact();
        // Fallback for warning, using error sound or system alert
        await player.play(AssetSource('sounds/scan_error.mp3'));
        break;
      case ScanFeedbackType.error:
        await HapticFeedback.heavyImpact();
        await player.play(AssetSource('sounds/scan_error.mp3'));
        break;
    }
  }

  /// Derive feedback type from gatekeeper API response.
  static ScanFeedbackType fromScanResult({
    required bool success,
    required String message,
  }) {
    if (success) return ScanFeedbackType.success;

    final upper = message.toUpperCase();
    if (upper.contains('ALREADY SCANNED') || upper.contains('DUPLICATE')) {
      return ScanFeedbackType.warning;
    }
    return ScanFeedbackType.error;
  }
}
