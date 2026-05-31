import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/transaction_model.dart';

class ApiService {
  // Singleton Pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Base URL – read from .env via ApiConfig (with safe fallback)
  static final String baseUrl = ApiConfig.baseUrl;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Read token from secure storage and inject it
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token is invalid/expired - clear storage
          await _storage.delete(key: 'auth_token');
        }
        return handler.next(e);
      },
    ));
  }

  /// Login Method hitting Laravel API
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['data']['token'];
        final user = response.data['data']['user'];
        
        // Securely store the Sanctum token
        await _storage.write(key: 'auth_token', value: token);
        
        return user; // Return user data to the AuthProvider
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? 'Network error occurred';
      throw Exception(errorMsg);
    }
  }

  /// Logout Method
  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (e) {
      // Ignore network errors on logout
    } finally {
      await _storage.delete(key: 'auth_token');
    }
  }

  /// Fetch current authenticated user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/user');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data'] as Map);
      }
      throw Exception(response.data['message'] ?? 'Failed to load user');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Network error occurred'));
    }
  }

  /// Fetch Dashboard Stats from Laravel
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard/stats');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load stats');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? 'Network error occurred';
      throw Exception(errorMsg);
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }

  /// Pending transactions awaiting admin approval
  Future<List<SpectaTransaction>> getPendingTransactions() async {
    try {
      final response = await _dio.get('/admin/transactions/pending');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> raw = response.data['data'] as List<dynamic>? ?? [];
        return raw
            .map((item) => SpectaTransaction.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }
      throw Exception(response.data['message'] ?? 'Failed to load transactions');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Network error occurred'));
    }
  }

  /// Approve a pending transaction by invoice number
  Future<void> approveTransaction(String invoice) async {
    try {
      final response =
          await _dio.post('/admin/transaction/$invoice/approve');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Approval failed');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Network error occurred'));
    }
  }

  /// Reject a pending transaction by invoice number
  Future<void> rejectTransaction(String invoice) async {
    try {
      final response = await _dio.post('/admin/transaction/$invoice/reject');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return;
      }
      throw Exception(response.data['message'] ?? 'Rejection failed');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Network error occurred'));
    }
  }

  /// Create a manual admin-issued ticket order (auto-approved)
  Future<SpectaTransaction> storeManualTicket({
    required String name,
    required String email,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post('/admin/transaction/manual', data: {
        'name': name,
        'email': email,
        'quantity': quantity,
      });
      final code = response.statusCode ?? 0;
      if ((code == 200 || code == 201) && response.data['success'] == true) {
        return SpectaTransaction.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map),
        );
      }
      throw Exception(response.data['message'] ?? 'Failed to create ticket');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Network error occurred'));
    }
  }

  /// Validate a scanned QR ticket code via Gatekeeper endpoint
  Future<Map<String, dynamic>> scanTicket(String ticketCode) async {
    try {
      final response = await _dio.post('/gatekeeper/scan', data: {
        'ticket_code': ticketCode,
      });
      return {
        'success': response.data['success'] ?? true,
        'message': response.data['message'] ?? 'ACCESS GRANTED',
        'data': response.data['data'],
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Network error',
        'data': null,
      };
    }
  }
}
