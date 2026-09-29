import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<bool> submitAllSections(Map<String, Map<String, dynamic>> allSections) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      for (final entry in allSections.entries) {
        await _apiClient.dio.put('/profile/section/${entry.key}', data: entry.value);
      }
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
