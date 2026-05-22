import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class VaultProfile {
  final String id;
  final String name;
  final String? birthDate;
  final String? relationshipLabel;
  final String avatarEmoji;
  final String createdAt;

  const VaultProfile({
    required this.id,
    required this.name,
    this.birthDate,
    this.relationshipLabel,
    required this.avatarEmoji,
    required this.createdAt,
  });

  factory VaultProfile.fromJson(Map<String, dynamic> j) => VaultProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        birthDate: j['birth_date'] as String?,
        relationshipLabel: j['relationship_label'] as String?,
        avatarEmoji: j['avatar_emoji'] as String? ?? '👶',
        createdAt: j['created_at'] as String,
      );
}

class VaultRecord {
  final String id;
  final String profileId;
  final String eventDate;
  final String eventType;
  final String title;
  final String? notes;
  final String? emoji;
  final double? weightKg;
  final double? heightCm;
  final String? photoUrl;
  final int? ageYears;
  final int? ageMonths;
  final String createdAt;

  const VaultRecord({
    required this.id,
    required this.profileId,
    required this.eventDate,
    required this.eventType,
    required this.title,
    this.notes,
    this.emoji,
    this.weightKg,
    this.heightCm,
    this.photoUrl,
    this.ageYears,
    this.ageMonths,
    required this.createdAt,
  });

  factory VaultRecord.fromJson(Map<String, dynamic> j) => VaultRecord(
        id: j['id'] as String,
        profileId: j['profile_id'] as String,
        eventDate: j['event_date'] as String,
        eventType: j['event_type'] as String,
        title: j['title'] as String,
        notes: j['notes'] as String?,
        emoji: j['emoji'] as String?,
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        heightCm: (j['height_cm'] as num?)?.toDouble(),
        photoUrl: j['photo_url'] as String?,
        ageYears: j['age_years'] as int?,
        ageMonths: j['age_months'] as int?,
        createdAt: j['created_at'] as String,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final vaultProfilesProvider = FutureProvider<List<VaultProfile>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/vault/profiles');
    return (response.data as List)
        .map((e) => VaultProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

final vaultRecordsProvider =
    FutureProvider.family<List<VaultRecord>, String>((ref, profileId) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/vault/profiles/$profileId/records');
    return (response.data as List)
        .map((e) => VaultRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

final vaultTimelineProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, profileId) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/vault/profiles/$profileId/timeline');
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
});

// ── Actions ───────────────────────────────────────────────────────────────────

class VaultActions {
  final Dio _dio;
  final Ref _ref;
  VaultActions(this._dio, this._ref);

  Future<VaultProfile> createProfile({
    required String name,
    DateTime? birthDate,
    String? relationshipLabel,
    String? avatarEmoji,
    String? pin,
    WidgetRef? ref,
  }) async {
    final response = await _dio.post('/vault/profiles', data: {
      'name': name,
      if (birthDate != null) 'birth_date': DateFormat('yyyy-MM-dd').format(birthDate),
      if (relationshipLabel != null) 'relationship_label': relationshipLabel,
      if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      if (pin != null) 'pin': pin,
    });
    _ref.invalidate(vaultProfilesProvider);
    return VaultProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> verifyPin(String profileId, String pin) async {
    try {
      await _dio.post('/vault/profiles/$profileId/verify-pin',
          queryParameters: {'pin': pin});
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> deleteProfile(String profileId) async {
    await _dio.delete('/vault/profiles/$profileId');
    _ref.invalidate(vaultProfilesProvider);
  }

  Future<VaultRecord> createRecord({
    required String profileId,
    required DateTime eventDate,
    required String eventType,
    required String title,
    String? notes,
    String? emoji,
    double? weightKg,
    double? heightCm,
    int? ageYears,
    int? ageMonths,
    WidgetRef? ref,
  }) async {
    final response = await _dio.post(
      '/vault/profiles/$profileId/records',
      data: {
        'event_date': DateFormat('yyyy-MM-dd').format(eventDate),
        'event_type': eventType,
        'title': title,
        if (notes != null) 'notes': notes,
        if (emoji != null) 'emoji': emoji,
        if (weightKg != null) 'weight_kg': weightKg,
        if (heightCm != null) 'height_cm': heightCm,
        if (ageYears != null) 'age_years': ageYears,
        if (ageMonths != null) 'age_months': ageMonths,
      },
    );
    _ref.invalidate(vaultRecordsProvider(profileId));
    _ref.invalidate(vaultTimelineProvider(profileId));
    return VaultRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecord({
    required String profileId,
    required String recordId,
    WidgetRef? ref,
  }) async {
    await _dio.delete('/vault/profiles/$profileId/records/$recordId');
    _ref.invalidate(vaultRecordsProvider(profileId));
    _ref.invalidate(vaultTimelineProvider(profileId));
  }
}

final vaultActionsProvider = Provider<VaultActions>((ref) {
  return VaultActions(ref.watch(dioProvider), ref);
});
