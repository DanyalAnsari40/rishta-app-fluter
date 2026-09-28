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
      appBar: AppBar(
        title: Text('Profile Setup ($currentStep/8)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: completeness / 100.0,
            backgroundColor: AppTheme.surfaceVariant,
            color: AppTheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile Completeness: $completeness%',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  Text(
                    completeness >= 70 ? 'Ready for Search ✅' : 'Requires ≥ 70%',
                    style: TextStyle(
                      color: completeness >= 70 ? AppTheme.success : AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildStepContent(currentStep),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.isSaving
                            ? null
                            : () => ref.read(profileProvider.notifier).previousStep(),
                        child: const Text('Back'),
                      ),
                    ),
                  if (currentStep > 1) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.isSaving ? null : () => _submitStep(currentStep),
                      child: state.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(currentStep == 8 ? 'Finish & Go to Home' : 'Save & Continue'),
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

  Widget _buildStepContent(int step) {
    switch (step) {
      case 1:
        return Form(
          key: _formKey1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step 1: Basic Information', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) => val == null || val.isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
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
                decoration: const InputDecoration(labelText: 'Height (cm)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _maritalStatus,
                decoration: const InputDecoration(labelText: 'Marital Status'),
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
                decoration: const InputDecoration(labelText: 'Current City'),
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
              Text('Step 2: Religion & Community', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _religion,
                decoration: const InputDecoration(labelText: 'Religion'),
                items: const [
                  DropdownMenuItem(value: 'Islam', child: Text('Islam')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _religion = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sect,
                decoration: const InputDecoration(labelText: 'Sect'),
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
                decoration: const InputDecoration(labelText: 'Caste / Biradri (Optional)'),
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
              Text('Step 3: Education & Career', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(labelText: 'Highest Education Level'),
                validator: (val) => val == null || val.isEmpty ? 'Education is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _occupationType,
                decoration: const InputDecoration(labelText: 'Occupation Type'),
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
                decoration: const InputDecoration(labelText: 'Job Title / Occupation Details'),
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
              Text('Step 4: Family Details', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _familyType,
                decoration: const InputDecoration(labelText: 'Family System'),
                items: const [
                  DropdownMenuItem(value: 'joint', child: Text('Joint Family')),
                  DropdownMenuItem(value: 'nuclear', child: Text('Nuclear Family')),
                ],
                onChanged: (val) => setState(() => _familyType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _familyStatus,
                decoration: const InputDecoration(labelText: 'Family Values'),
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
              Text('Step 5: Lifestyle & About Me', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              TextFormField(
                controller: _aboutMeController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'About Me (min 50 chars)',
                  hintText: 'Describe your personality, goals, and life values...',
                ),
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
            Text('Step 6: Photos (Up to 6)', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text('Upload clear photos. Your photos are hosted securely on Cloudinary.'),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary, style: BorderStyle.solid),
                ),
                child: Center(
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload_outlined, size: 50, color: AppTheme.primary),
                            SizedBox(height: 8),
                            Text('Tap to select photo', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Cloudinary Signed Upload', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 50, color: AppTheme.success),
                            const SizedBox(height: 8),
                            const Text('Photo Selected!', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Text(
                                _selectedImage!.name,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                            const Text('Tap to change', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
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
              Text('Step 7: Partner Preferences', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              Text('Age Preference: $_ageMin - $_ageMax years'),
              RangeSlider(
                values: RangeValues(_ageMin.toDouble(), _ageMax.toDouble()),
                min: 18,
                max: 60,
                activeColor: AppTheme.primary,
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
            Text('Step 8: Profile Review & Submit', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameController.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${_cityController.text} • $_religion ($_sect)'),
                    const Divider(height: 24),
                    Text('Education: ${_educationController.text}'),
                    Text('Occupation: $_occupationType (${_jobTitleController.text})'),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }
}
