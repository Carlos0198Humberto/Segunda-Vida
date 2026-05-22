import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class DiaryEntry {
  final String id;
  final String content;
  final String category;
  final String? emoji;
  final String source;
  final String date;
  final String loggedAt;

  const DiaryEntry({
    required this.id,
    required this.content,
    required this.category,
    this.emoji,
    required this.source,
    required this.date,
    required this.loggedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> j) => DiaryEntry(
        id: j['id'] as String,
        content: j['content'] as String,
        category: j['category'] as String,
        emoji: j['emoji'] as String?,
        source: j['source'] as String,
        date: j['date'] as String,
        loggedAt: j['logged_at'] as String,
      );
}

final diaryTodayProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/diary/today');
    return (response.data as List).map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

final diaryHistoryProvider = FutureProvider<List<DiaryEntry>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/diary/history', queryParameters: {'limit': 100});
    return (response.data as List).map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>)).toList();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

class DiaryActions {
  final Dio _dio;
  final Ref _ref;
  DiaryActions(this._dio, this._ref);

  Future<void> addEntry({
    required String content,
    required String category,
    String? emoji,
  }) async {
    await _dio.post('/diary/', data: {
      'content': content,
      'category': category,
      'emoji': emoji,
    });
    _ref.invalidate(diaryTodayProvider);
    _ref.invalidate(diaryHistoryProvider);
  }

  Future<void> deleteEntry(String id) async {
    await _dio.delete('/diary/$id');
    _ref.invalidate(diaryTodayProvider);
    _ref.invalidate(diaryHistoryProvider);
  }
}

final diaryActionsProvider = Provider<DiaryActions>((ref) {
  return DiaryActions(ref.watch(dioProvider), ref);
});
