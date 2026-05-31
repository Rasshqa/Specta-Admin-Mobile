import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

enum TransactionProcessingAction { approve, reject }

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<SpectaTransaction> _pendingTransactions = [];
  bool _isLoading = false;
  bool _isSubmittingManual = false;
  String? _error;
  String? _processingInvoice;
  TransactionProcessingAction? _processingAction;

  List<SpectaTransaction> get pendingTransactions =>
      List.unmodifiable(_pendingTransactions);
  bool get isLoading => _isLoading;
  bool get isSubmittingManual => _isSubmittingManual;
  String? get error => _error;
  String? get processingInvoice => _processingInvoice;
  TransactionProcessingAction? get processingAction => _processingAction;

  bool isApproving(String invoice) =>
      _processingInvoice == invoice &&
      _processingAction == TransactionProcessingAction.approve;

  bool isRejecting(String invoice) =>
      _processingInvoice == invoice &&
      _processingAction == TransactionProcessingAction.reject;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchPendingTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingTransactions = await _apiService.getPendingTransactions();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _pendingTransactions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveTransaction(String invoice) async {
    _processingInvoice = invoice;
    _processingAction = TransactionProcessingAction.approve;
    _error = null;
    notifyListeners();

    try {
      await _apiService.approveTransaction(invoice);
      _pendingTransactions =
          _pendingTransactions.where((t) => t.invoice != invoice).toList();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _processingInvoice = null;
      _processingAction = null;
      notifyListeners();
    }
  }

  Future<bool> rejectTransaction(String invoice) async {
    _processingInvoice = invoice;
    _processingAction = TransactionProcessingAction.reject;
    _error = null;
    notifyListeners();

    try {
      await _apiService.rejectTransaction(invoice);
      _pendingTransactions =
          _pendingTransactions.where((t) => t.invoice != invoice).toList();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _processingInvoice = null;
      _processingAction = null;
      notifyListeners();
    }
  }

  Future<bool> storeManualTicket({
    required String name,
    required String email,
    required int quantity,
  }) async {
    _isSubmittingManual = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.storeManualTicket(
        name: name,
        email: email,
        quantity: quantity,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isSubmittingManual = false;
      notifyListeners();
    }
  }
}
