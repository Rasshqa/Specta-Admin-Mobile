import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum ScanStatus { idle, scanning, success, error }

class GatekeeperState extends ChangeNotifier {
  ScanStatus _status = ScanStatus.idle;
  String? _errorMessage;
  String? _successMessage;
  String? _buyerName;

  ScanStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get buyerName => _buyerName;

  /// Sends the ticket code (manual or QR) to the backend.
  Future<void> verifyTicket(String code) async {
    _status = ScanStatus.scanning;
    _errorMessage = null;
    _successMessage = null;
    _buyerName = null;
    notifyListeners();

    try {
      final result = await ApiService().scanTicket(code);

      if (result['success'] == true) {
        _status = ScanStatus.success;
        _successMessage = result['message'] ?? 'ACCESS GRANTED';
        _buyerName = result['data']?['buyer'] ?? '';
      } else {
        _status = ScanStatus.error;
        _errorMessage = result['message'] ?? 'ACCESS DENIED';
      }
    } catch (e) {
      _status = ScanStatus.error;
      _errorMessage = 'Koneksi gagal: $e';
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = ScanStatus.idle;
    _errorMessage = null;
    _successMessage = null;
    _buyerName = null;
    notifyListeners();
  }
}
