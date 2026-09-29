import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/photo_idea.dart';

class OfflineException implements Exception {
  final String message;
  OfflineException([this.message = 'No internet connection. Please connect to Wi-Fi or mobile data to generate fresh ideas.']);
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
}

class IdeasApiService {
  final Dio _dio;
  final Connectivity _connectivity;
  final String baseUrl;

  IdeasApiService({
    Dio? dio,
    Connectivity? connectivity,
    String? customBaseUrl,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
                receiveTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
                sendTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
                headers: {'Content-Type': 'application/json'},
              ),
            ),
        _connectivity = connectivity ?? Connectivity(),
        baseUrl = customBaseUrl ?? (Platform.isAndroid ? AppConstants.defaultBackendUrl : AppConstants.defaultBackendUrlIos);

  Future<PhotoIdeasResponse> generateIdeas({
    required String imageBase64,
    required int peopleCountHint,
    List<String> preferredStyles = const [],
    List<String> likedIdeas = const [],
    List<String> dislikedIdeas = const [],
    String language = 'en',
    String? authToken,
  }) async {
    // 1. Connectivity Check
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw OfflineException();
    }

    try {
      final response = await _dio.post(
        '$baseUrl/generate-ideas',
        data: {
          'image_base64': imageBase64,
          'people_count_hint': peopleCountHint,
          'user_preferences': {
            'preferred_styles': preferredStyles,
            'liked_ideas': likedIdeas,
            'disliked_ideas': dislikedIdeas,
          },
          'language': language,
        },
        options: Options(
          headers: {
            if (authToken != null) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is Map<String, dynamic>
            ? response.data
            : Map<String, dynamic>.from(response.data as Map);
        return PhotoIdeasResponse.fromJson(data);
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final msg = e.response?.data?['message'] ?? 'Daily scan limit reached (30/day).';
        throw RateLimitException(msg);
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Vision AI request timed out. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw OfflineException('Unable to reach PoseMuse vision servers. Check your connection.');
      }
      throw Exception(e.response?.data?['message'] ?? e.message ?? 'Failed to generate ideas');
    }
  }
}
