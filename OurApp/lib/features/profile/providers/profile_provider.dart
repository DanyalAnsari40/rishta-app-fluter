import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/profile_model.dart';

class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final int currentStep; // 1 to 8

  ProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.currentStep = 1,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    int? currentStep,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient = ApiClient();

  ProfileNotifier() : super(ProfileState()) {
    fetchMyProfile();
  }

  Future<void> fetchMyProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.get('/profile/me');
      if (response.data['success'] == true) {
        final profile = ProfileModel.fromJson(response.data['data']);
        state = state.copyWith(profile: profile, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to fetch profile');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load profile');
    }
  }

  Future<bool> saveSection(String sectionKey, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.put('/profile/section/$sectionKey', data: data);
      if (response.data['success'] == true) {
        final updatedProfile = ProfileModel.fromJson(response.data['data']);
        state = state.copyWith(
          profile: updatedProfile,
          isSaving: false,
        );
        return true;
      } else {
        state = state.copyWith(isSaving: false, errorMessage: response.data['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save section');
      return false;
    }
  }

  /// Upload a photo to Cloudinary via signed upload, then register it in the profile.
  /// Returns true on success, false on failure.
  Future<bool> uploadPhoto(String filePath) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      // Step 1: Get signed upload signature from backend
      final sigResponse = await _apiClient.dio.get('/profile/photo-signature');
      if (sigResponse.data['success'] != true) {
        state = state.copyWith(isSaving: false, errorMessage: 'Failed to get upload signature');
        return false;
      }

      final sigData = sigResponse.data['data'];
      final String signature = sigData['signature'];
      final int timestamp = sigData['timestamp'];
      final String folder = sigData['folder'];
      final String type = sigData['type'];
      final String apiKey = sigData['apiKey'];
      final String cloudName = sigData['cloudName'];

      // Step 2: Upload directly to Cloudinary
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
        'type': type,
      });

      final uploadDio = Dio(); // Separate Dio instance for Cloudinary (no auth header)
      final uploadResponse = await uploadDio.post(uploadUrl, data: formData);

      if (uploadResponse.statusCode != 200) {
        state = state.copyWith(isSaving: false, errorMessage: 'Failed to upload photo to cloud');
        return false;
      }

      final String publicId = uploadResponse.data['public_id'];
      final String secureUrl = uploadResponse.data['secure_url'];
      final int width = uploadResponse.data['width'] ?? 0;
      final int height = uploadResponse.data['height'] ?? 0;

      // Step 3: Register the uploaded photo in the profile via backend
      final addResponse = await _apiClient.dio.post('/profile/photos', data: {
        'publicId': publicId,
        'secureUrl': secureUrl,
        'width': width,
        'height': height,
        'isPrimary': true,
      });

      if (addResponse.data['success'] == true) {
        // Re-fetch profile to get updated photos array
        await fetchMyProfile();
        state = state.copyWith(isSaving: false);
        return true;
      } else {
        state = state.copyWith(isSaving: false, errorMessage: 'Failed to save photo to profile');
        return false;
      }
    } catch (e) {
      debugPrint('Photo upload error: $e');
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to upload photo');
      return false;
    }
  }

  Future<bool> submitAllSections(Map<String, Map<String, dynamic>> allSections) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      // Save each section and check for errors
      for (final entry in allSections.entries) {
        final response = await _apiClient.dio.put(
          '/profile/section/${entry.key}',
          data: entry.value,
        );
        if (response.data['success'] != true) {
          final msg = response.data['message'] ?? 'Failed to save section: ${entry.key}';
          state = state.copyWith(isSaving: false, errorMessage: msg);
          return false;
        }
      }

      // Re-fetch updated profile from server
      final response = await _apiClient.dio.get('/profile/me');
      if (response.data['success'] == true) {
        final updatedProfile = ProfileModel.fromJson(response.data['data']);
        state = state.copyWith(
          profile: updatedProfile,
          isSaving: false,
        );
        return true;
      }
      state = state.copyWith(isSaving: false);
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to save profile. Please check your connection.';
      state = state.copyWith(isSaving: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save profile');
      return false;
    }
  }

  void setStep(int step) {
    if (step >= 1 && step <= 8) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep() {
    if (state.currentStep < 8) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});
