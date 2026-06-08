import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import '../constants/app_constants.dart';

class AuthService {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  AuthService({
    required this.apiClient,
    required this.secureStorage,
  });

  /// Login with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        AppConstants.authLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final user = data['user'];

        // Store tokens securely
        await secureStorage.write(
          key: AppConstants.storageKeyAccessToken,
          value: accessToken,
        );
        await secureStorage.write(
          key: AppConstants.storageKeyRefreshToken,
          value: refreshToken,
        );
        await secureStorage.write(
          key: AppConstants.storageKeyUser,
          value: user.toString(),
        );
        await secureStorage.write(
          key: AppConstants.storageKeyUserRole,
          value: user['role'] ?? 'user',
        );

        return {
          'success': true,
          'user': user,
          'accessToken': accessToken,
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Login failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await apiClient.post(
        AppConstants.authRegister,
        data: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        },
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful',
        };
      }

      return {
        'success': false,
        'message': response.data['message'] ?? 'Registration failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      await apiClient.post(AppConstants.authLogout);
      
      // Clear stored tokens and user data
      await secureStorage.delete(key: AppConstants.storageKeyAccessToken);
      await secureStorage.delete(key: AppConstants.storageKeyRefreshToken);
      await secureStorage.delete(key: AppConstants.storageKeyUser);
      await secureStorage.delete(key: AppConstants.storageKeyUserRole);

      return true;
    } catch (e) {
      print('[Logout Error] $e');
      return false;
    }
  }

  /// Get current user info
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await apiClient.get(AppConstants.authMe);

      if (response.statusCode == 200) {
        return response.data['user'];
      }

      return null;
    } catch (e) {
      print('[Get Current User Error] $e');
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await secureStorage.read(
        key: AppConstants.storageKeyAccessToken,
      );
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    try {
      return await secureStorage.read(
        key: AppConstants.storageKeyAccessToken,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get stored user role
  Future<String?> getUserRole() async {
    try {
      return await secureStorage.read(
        key: AppConstants.storageKeyUserRole,
      );
    } catch (e) {
      return null;
    }
  }
}
