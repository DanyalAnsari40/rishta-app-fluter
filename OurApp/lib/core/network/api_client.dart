import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static final String baseUrl = 'http://192.168.1.47:5000/api/v1'; // Default for Android emulator & local testing
  static final String localhostUrl = 'http://192.168.1.47:5000/api/v1';

  final Dio dio;

  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh-token')) {
            // Attempt token refresh
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshResponse = await Dio().post(
                  '$baseUrl/auth/refresh-token',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200 &&
                    refreshResponse.data['success'] == true) {
                  final newAccessToken =
                      refreshResponse.data['data']['accessToken'];
                  final newRefreshToken =
                      refreshResponse.data['data']['refreshToken'];
                  final role = await TokenStorage.getUserRole() ?? 'user';
                  final verified = await TokenStorage.isEmailVerified();

                  await TokenStorage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                    role: role,
                    emailVerified: verified,
                  );

                  // Retry original request
                  error.requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';
                  final clonedRequest = await dio.request(
                    error.requestOptions.path,
                    options: Options(
                      method: error.requestOptions.method,
                      headers: error.requestOptions.headers,
                    ),
                    data: error.requestOptions.data,
                    queryParameters: error.requestOptions.queryParameters,
                  );
                  return handler.resolve(clonedRequest);
                }
              } catch (_) {
                await TokenStorage.clear();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
