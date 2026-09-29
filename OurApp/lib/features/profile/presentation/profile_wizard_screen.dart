import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';
import '../../../data/models/profile_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileWizardScreen extends ConsumerStatefulWidget {
  const ProfileWizardScreen({super.key});

  @override
  ConsumerState<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends ConsumerState<ProfileWizardScreen> {
  // Form Keys
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();
  final _formKey5 = GlobalKey<FormState>();
  final _formKey7 = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _heightController = TextEditingController(text: '172');
  final _casteController = TextEditingController();
  final _educationController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _aboutMeController = TextEditingController();

  String _gender = 'male';
  String _maritalStatus = 'never_married';
  String _religion = 'Islam';
  String _sect = 'Sunni';
  String _occupationType = 'employed';
  String _familyType = 'nuclear';
  String _familyStatus = 'moderate';
  int _ageMin = 18;
  int _ageMax = 35;
  bool _isDataPopulated = false;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _populateFromProfile(ProfileModel p) {
    if (_isDataPopulated) return;
    _isDataPopulated = true;

    if (p.basicInfo.fullName.isNotEmpty) _nameController.text = p.basicInfo.fullName;
    if (p.basicInfo.city.isNotEmpty) _cityController.text = p.basicInfo.city;
    if (p.basicInfo.heightCm > 0) _heightController.text = p.basicInfo.heightCm.toString();
    if (p.basicInfo.gender.isNotEmpty) _gender = p.basicInfo.gender;
    if (p.basicInfo.maritalStatus.isNotEmpty) _maritalStatus = p.basicInfo.maritalStatus;

    if (p.religionCommunity.religion.isNotEmpty) _religion = p.religionCommunity.religion;
    if (p.religionCommunity.sect.isNotEmpty) _sect = p.religionCommunity.sect;
    if (p.religionCommunity.casteBiradri != null) _casteController.text = p.religionCommunity.casteBiradri!;

    if (p.educationCareer.highestEducation.isNotEmpty) _educationController.text = p.educationCareer.highestEducation;
    if (p.educationCareer.occupationType.isNotEmpty) _occupationType = p.educationCareer.occupationType;
    if (p.educationCareer.jobTitle != null) _jobTitleController.text = p.educationCareer.jobTitle!;

    if (p.familyDetails.familyType.isNotEmpty) _familyType = p.familyDetails.familyType;
    if (p.familyDetails.familyStatus.isNotEmpty) _familyStatus = p.familyDetails.familyStatus;

    if (p.lifestyleAbout.aboutMe.isNotEmpty) _aboutMeController.text = p.lifestyleAbout.aboutMe;

    if (p.partnerPreferences.ageMin > 0) _ageMin = p.partnerPreferences.ageMin;
    if (p.partnerPreferences.ageMax > 0) _ageMax = p.partnerPreferences.ageMax;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _heightController.dispose();
    _casteController.dispose();
    _educationController.dispose();
    _jobTitleController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _submitStep(int step) async {
    final notifier = ref.read(profileProvider.notifier);
    bool success = false;

    switch (step) {
      case 1:
        if (!_formKey1.currentState!.validate()) return;
        success = await notifier.saveSection('basic-info', {
          'fullName': _nameController.text.trim(),
          'gender': _gender,
          'dateOfBirth': '1998-06-15',
          'maritalStatus': _maritalStatus,
          'heightCm': int.tryParse(_heightController.text) ?? 170,
          'country': 'Pakistan',
          'city': _cityController.text.trim(),
          'motherTongue': 'Urdu',
          'languagesKnown': ['Urdu', 'English'],
        });
        break;

      case 2:
        if (!_formKey2.currentState!.validate()) return;
        success = await notifier.saveSection('religion-community', {
          'religion': _religion,
          'sect': _sect,
          'casteBiradri': _casteController.text.trim(),
          'religiousPractice': 'moderate',
        });
        break;

      case 3:
        if (!_formKey3.currentState!.validate()) return;
        success = await notifier.saveSection('education-career', {
          'highestEducation': _educationController.text.trim(),
          'occupationType': _occupationType,
          'jobTitle': _jobTitleController.text.trim(),
        });
        break;

      case 4:
        if (!_formKey4.currentState!.validate()) return;
        success = await notifier.saveSection('family-details', {
          'familyType': _familyType,
          'familyStatus': _familyStatus,
          'brothersCount': 1,
          'sistersCount': 1,
        });
        break;

      case 5:
        if (!_formKey5.currentState!.validate()) return;
        success = await notifier.saveSection('lifestyle-about', {
          'diet': 'Halal',
          'smoking': false,
          'hobbies': ['Reading', 'Traveling'],
          'aboutMe': _aboutMeController.text.trim(),
        });
        break;

      case 6:
        // Photo upload step
        success = true;
        break;

      case 7:
        if (!_formKey7.currentState!.validate()) return;
        success = await notifier.saveSection('partner-preferences', {
          'ageMin': _ageMin,
          'ageMax': _ageMax,
          'maritalStatus': ['never_married'],
          'citiesCountries': ['Lahore', 'Karachi', 'Islamabad'],
        });
        break;

      case 8:
        // Complete Profile Save to Backend Database
        final allSections = {
          'basic-info': {
            'fullName': _nameController.text.trim().isEmpty ? 'Danyal Hussain' : _nameController.text.trim(),
            'gender': _gender,
            'dateOfBirth': '1998-06-15',
            'maritalStatus': _maritalStatus,
            'heightCm': int.tryParse(_heightController.text) ?? 172,
            'country': 'Pakistan',
            'city': _cityController.text.trim().isEmpty ? 'Lahore' : _cityController.text.trim(),
            'motherTongue': 'Urdu',
            'languagesKnown': ['Urdu', 'English'],
          },
          'religion-community': {
            'religion': _religion,
            'sect': _sect,
            'casteBiradri': _casteController.text.trim(),
            'religiousPractice': 'moderate',
          },
          'education-career': {
            'highestEducation': _educationController.text.trim().isEmpty ? 'Bachelors' : _educationController.text.trim(),
            'occupationType': _occupationType,
            'jobTitle': _jobTitleController.text.trim().isEmpty ? 'Software Engineer' : _jobTitleController.text.trim(),
          },
          'family-details': {
            'familyType': _familyType,
            'familyStatus': _familyStatus,
            'brothersCount': 1,
            'sistersCount': 1,
          },
          'lifestyle-about': {
            'diet': 'Halal',
            'smoking': false,
            'hobbies': ['Reading', 'Traveling'],
            'aboutMe': _aboutMeController.text.trim().isEmpty
                ? 'I am a respectful, educated individual looking for a compatible life partner with shared family values.'
                : _aboutMeController.text.trim(),
          },
          'partner-preferences': {
            'ageMin': _ageMin,
            'ageMax': _ageMax,
            'maritalStatus': ['never_married'],
            'citiesCountries': ['Lahore', 'Karachi', 'Islamabad'],
          },
        };

        final saveOk = await notifier.submitAllSections(allSections);
        if (mounted) {
          if (saveOk) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile saved & completed in database successfully! 🎉'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
            context.go('/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ref.read(profileProvider).errorMessage ?? 'Failed to save profile.'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
        return;
    }

    if (success) {
      notifier.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    // Auto populate existing profile data when profile state arrives from backend
    if (state.profile != null) {
      _populateFromProfile(state.profile!);
    }

    final currentStep = state.currentStep;
    final completeness = state.profile?.profileCompleteness ?? 85;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress & Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step $currentStep of 8',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: completeness >= 70
                              ? Colors.green.shade50
                              : const Color(0xFFF71A65).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: completeness >= 70
                                ? Colors.green.shade300
                                : const Color(0xFFF71A65).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$completeness% Completed ${completeness >= 70 ? '✅' : ''}',
                          style: TextStyle(
                            color: completeness >= 70 ? Colors.green.shade700 : const Color(0xFFF71A65),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Animated Step Segment Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: currentStep / 8.0,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF4F5F8),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF71A65)),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: _buildStepContent(currentStep, state),
                ),
              ),
            ),

            // Bottom Navigation Buttons
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (currentStep > 1)
                    Expanded(
                      child: GestureDetector(
                        onTap: state.isSaving
                            ? null
                            : () => ref.read(profileProvider.notifier).previousStep(),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (currentStep > 1) const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: state.isSaving ? null : () => _submitStep(currentStep),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF71A65), Color(0xFFFF4884)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF71A65).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: state.isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  currentStep == 8 ? 'Finish & Save Profile' : 'Save & Continue',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _customInputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFF71A65), size: 20),
      filled: true,
      fillColor: const Color(0xFFF4F5F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF71A65), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildStepContent(int step, ProfileState state) {
    switch (step) {
      case 1:
        return Form(
          key: _formKey1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Basic Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Tell us a bit about yourself to get started', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: _customInputDeco('Full Name', Icons.person_outline_rounded),
                validator: (val) => val == null || val.isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: _customInputDeco('Gender', Icons.wc_rounded),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: (val) => setState(() => _gender = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: _customInputDeco('Height (cm)', Icons.height_rounded),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _maritalStatus,
                decoration: _customInputDeco('Marital Status', Icons.favorite_outline_rounded),
                items: const [
                  DropdownMenuItem(value: 'never_married', child: Text('Never Married')),
                  DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                  DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                ],
                onChanged: (val) => setState(() => _maritalStatus = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: _customInputDeco('Current City', Icons.location_on_outlined),
                validator: (val) => val == null || val.isEmpty ? 'City is required' : null,
              ),
            ],
          ),
        );

      case 2:
        return Form(
          key: _formKey2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Religion & Community', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Help us find matches from your preferred community', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _religion,
                decoration: _customInputDeco('Religion', Icons.auto_awesome_rounded),
                items: const [
                  DropdownMenuItem(value: 'Islam', child: Text('Islam')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _religion = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sect,
                decoration: _customInputDeco('Sect', Icons.people_outline_rounded),
                items: const [
                  DropdownMenuItem(value: 'Sunni', child: Text('Sunni')),
                  DropdownMenuItem(value: 'Shia', child: Text('Shia')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _sect = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _casteController,
                decoration: _customInputDeco('Caste / Biradri (Optional)', Icons.diversity_3_rounded),
              ),
            ],
          ),
        );

      case 3:
        return Form(
          key: _formKey3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Education & Career', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Share your educational qualifications and career details', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _educationController,
                decoration: _customInputDeco('Highest Education', Icons.school_outlined),
                validator: (val) => val == null || val.isEmpty ? 'Education is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _occupationType,
                decoration: _customInputDeco('Occupation Type', Icons.work_outline_rounded),
                items: const [
                  DropdownMenuItem(value: 'employed', child: Text('Employed')),
                  DropdownMenuItem(value: 'business', child: Text('Business')),
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'homemaker', child: Text('Homemaker')),
                ],
                onChanged: (val) => setState(() => _occupationType = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jobTitleController,
                decoration: _customInputDeco('Job Title / Position', Icons.badge_outlined),
              ),
            ],
          ),
        );

      case 4:
        return Form(
          key: _formKey4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Family Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Information about your family structure and values', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _familyType,
                decoration: _customInputDeco('Family System', Icons.home_work_outlined),
                items: const [
                  DropdownMenuItem(value: 'joint', child: Text('Joint Family')),
                  DropdownMenuItem(value: 'nuclear', child: Text('Nuclear Family')),
                ],
                onChanged: (val) => setState(() => _familyType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _familyStatus,
                decoration: _customInputDeco('Family Values', Icons.family_restroom_rounded),
                items: const [
                  DropdownMenuItem(value: 'traditional', child: Text('Traditional')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'liberal', child: Text('Liberal')),
                ],
                onChanged: (val) => setState(() => _familyStatus = val!),
              ),
            ],
          ),
        );

      case 5:
        return Form(
          key: _formKey5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lifestyle & About Me', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Write a brief bio about your goals and interests', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _aboutMeController,
                maxLines: 5,
                decoration: _customInputDeco('About Me (min 20 chars)', Icons.edit_note_rounded),
                validator: (val) {
                  if (val == null || val.trim().length < 20) {
                    return 'Please write at least 20 characters about yourself.';
                  }
                  return null;
                },
              ),
            ],
          ),
        );

      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Profile Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Add a clear photo. Verified photos receive 3x more interest!', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF71A65).withValues(alpha: 0.5), width: 1.5),
                ),
                child: Center(
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF71A65).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFFF71A65)),
                            ),
                            const SizedBox(height: 12),
                            const Text('Tap to select photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Supported format: JPG, PNG', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 50, color: Colors.green),
                            const SizedBox(height: 8),
                            const Text('Photo Ready!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Text(
                                _selectedImage!.name,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                            const Text('Tap to change', style: TextStyle(color: Color(0xFFF71A65), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        );

      case 7:
        return Form(
          key: _formKey7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Partner Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Set your preferred age criteria for matches', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Age Range:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF71A65).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_ageMin - $_ageMax Years',
                      style: const TextStyle(color: Color(0xFFF71A65), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RangeSlider(
                values: RangeValues(_ageMin.toDouble(), _ageMax.toDouble()),
                min: 18,
                max: 60,
                activeColor: const Color(0xFFF71A65),
                inactiveColor: const Color(0xFFF4F5F8),
                onChanged: (RangeValues values) {
                  setState(() {
                    _ageMin = values.start.round();
                    _ageMax = values.end.round();
                  });
                },
              ),
            ],
          ),
        );

      case 8:
        // 8. Detailed Profile Review Step
        final fullName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Danyal Hussain';
        final city = _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Lahore';
        final height = _heightController.text.trim().isNotEmpty ? _heightController.text.trim() : '172';
        final education = _educationController.text.trim().isNotEmpty ? _educationController.text.trim() : 'Bachelors in CS';
        final jobTitle = _jobTitleController.text.trim().isNotEmpty ? _jobTitleController.text.trim() : 'Software Engineer';
        final about = _aboutMeController.text.trim().isNotEmpty
            ? _aboutMeController.text.trim()
            : 'I am a respectful, educated individual looking for a compatible life partner with shared family values.';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profile Review & Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Text(
                    'Ready to Save ✅',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Review your information below before saving to the database', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),

            // Main Review Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Photo Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          backgroundImage: _selectedImage != null
                              ? FileImage(File(_selectedImage!.path)) as ImageProvider
                              : const AssetImage('assets/images/usman_ali.jpg'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$city, Pakistan • $_gender',
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_maritalStatus • ${height}cm',
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Detail Rows
                  _buildReviewRow(Icons.auto_awesome_rounded, 'Religion & Sect', '$_religion ($_sect) ${_casteController.text.isNotEmpty ? "• ${_casteController.text}" : ""}'),
                  const SizedBox(height: 10),
                  _buildReviewRow(Icons.school_outlined, 'Education', education),
                  const SizedBox(height: 10),
                  _buildReviewRow(Icons.work_outline_rounded, 'Career', '$_occupationType • $jobTitle'),
                  const SizedBox(height: 10),
                  _buildReviewRow(Icons.home_work_outlined, 'Family', '$_familyType Family • $_familyStatus Values'),
                  const SizedBox(height: 10),
                  _buildReviewRow(Icons.favorite_outline_rounded, 'Partner Age Goal', '$_ageMin - $_ageMax Years'),

                  const SizedBox(height: 14),
                  const Text('About Me:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    about,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF2C2C2E)),
          ),
        ),
      ],
    );
  }
}
