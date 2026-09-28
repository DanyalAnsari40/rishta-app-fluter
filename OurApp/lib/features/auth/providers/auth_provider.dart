import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient = ApiClient();

  AuthNotifier() : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await TokenStorage.getAccessToken();
      final role = await TokenStorage.getUserRole();
      final verified = await TokenStorage.isEmailVerified();

      if (token != null && token.isNotEmpty) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: UserModel(
            id: '',
            email: '',
            role: role ?? 'user',
            emailVerified: verified,
            profileCreatedFor: 'self',
          ),
        );
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final user = UserModel.fromJson(data['user']);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: user.role,
          emailVerified: user.emailVerified,
        );

        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.data['message'] ?? 'Login failed',
        );
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Login failed. Please check credentials.';
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An error occurred during login');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String profileCreatedFor,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'profileCreatedFor': profileCreatedFor,
        ...?phone != null && phone.isNotEmpty ? {'phone': phone} : null,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final user = UserModel.fromJson(data['user']);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: user.role,
          emailVerified: user.emailVerified,
        );

        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.data['message'] ?? 'Registration failed',
        );
        return false;
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Registration failed';
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An error occurred during registration');
      return false;
    }
  }

  Future<bool> googleLogin(String googleId, String email, String? fullName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/auth/google-login', data: {
        'googleId': googleId,
        'email': email,
        ...?fullName != null ? {'fullName': fullName} : null,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final user = UserModel.fromJson(data['user']);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          role: user.role,
          emailVerified: user.emailVerified,
        );

        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.data['message'] ?? 'Google login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Google login failed');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      await _apiClient.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {}
    await TokenStorage.clear();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
