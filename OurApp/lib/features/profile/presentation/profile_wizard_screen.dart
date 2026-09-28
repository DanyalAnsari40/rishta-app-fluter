import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final p = ref.read(profileProvider).profile;
      if (p != null) {
        _nameController.text = p.basicInfo.fullName;
        _cityController.text = p.basicInfo.city;
        _heightController.text = p.basicInfo.heightCm.toString();
        _casteController.text = p.religionCommunity.casteBiradri ?? '';
        _educationController.text = p.educationCareer.highestEducation;
        _jobTitleController.text = p.educationCareer.jobTitle ?? '';
        _aboutMeController.text = p.lifestyleAbout.aboutMe;
      }
    });
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
        // Photo upload step handled interactively
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
        context.go('/home');
        return;
    }

    if (success) {
      notifier.nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final currentStep = state.currentStep;
    final completeness = state.profile?.profileCompleteness ?? 0;

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
                    color: Colors.black.withOpacity(0.03),
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
                              : const Color(0xFFF71A65).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: completeness >= 70
                                ? Colors.green.shade300
                                : const Color(0xFFF71A65).withOpacity(0.3),
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
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: _buildStepContent(currentStep),
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
                    color: Colors.black.withOpacity(0.04),
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
                              color: const Color(0xFFF71A65).withOpacity(0.3),
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
                                  currentStep == 8 ? 'Finish & Go Home' : 'Save & Continue',
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

  Widget _buildStepContent(int step) {
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
                initialValue: _gender,
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
                initialValue: _maritalStatus,
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
                initialValue: _religion,
                decoration: _customInputDeco('Religion', Icons.auto_awesome_rounded),
                items: const [
                  DropdownMenuItem(value: 'Islam', child: Text('Islam')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _religion = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sect,
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
                initialValue: _occupationType,
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
                initialValue: _familyType,
                decoration: _customInputDeco('Family System', Icons.home_work_outlined),
                items: const [
                  DropdownMenuItem(value: 'joint', child: Text('Joint Family')),
                  DropdownMenuItem(value: 'nuclear', child: Text('Nuclear Family')),
                ],
                onChanged: (val) => setState(() => _familyType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _familyStatus,
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
                decoration: _customInputDeco('About Me (min 50 chars)', Icons.edit_note_rounded),
                validator: (val) {
                  if (val == null || val.length < 50) {
                    return 'Please write at least 50 characters about yourself.';
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
                  border: Border.all(color: const Color(0xFFF71A65).withOpacity(0.5), width: 1.5),
                ),
                child: Center(
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF71A65).withOpacity(0.1),
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
                      color: const Color(0xFFF71A65).withOpacity(0.1),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Review & Submit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Double check your profile details before finishing', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_nameController.text.isEmpty ? 'Sample Member' : _nameController.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${_cityController.text} • $_religion ($_sect)', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const Divider(height: 24),
                  Text('Education: ${_educationController.text}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Occupation: $_occupationType (${_jobTitleController.text})', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}
