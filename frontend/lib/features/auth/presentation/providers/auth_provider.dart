import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({bool? isLoading, String? error, bool? isAuthenticated}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;

  AuthNotifier(this._dio) : super(AuthState(isAuthenticated: HiveStorage.isLoggedIn));

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _saveAuthData(response.data);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiException.fromDio(e).message,
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String? fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
      });
      await _saveAuthData(response.data);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiException.fromDio(e).message,
      );
      return false;
    }
  }

  Future<void> logout() async {
    await HiveStorage.clearAuth();
    state = const AuthState(isAuthenticated: false);
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await HiveStorage.saveToken(data['access_token']);
    await HiveStorage.saveRefreshToken(data['refresh_token']);
    await HiveStorage.saveUser(Map<String, dynamic>.from(data['user']));
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider));
});
