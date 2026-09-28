class PhotoModel {
  final String publicId;
  final String secureUrl;
  final int? width;
  final int? height;
  final bool isPrimary;
  final bool isApproved;

  PhotoModel({
    required this.publicId,
    required this.secureUrl,
    this.width,
    this.height,
    this.isPrimary = false,
    this.isApproved = false,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      publicId: json['publicId'] ?? '',
      secureUrl: json['secureUrl'] ?? '',
      width: json['width'],
      height: json['height'],
      isPrimary: json['isPrimary'] ?? false,
      isApproved: json['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'secureUrl': secureUrl,
      'width': width,
      'height': height,
      'isPrimary': isPrimary,
      'isApproved': isApproved,
    };
  }
}

class BasicInfoModel {
  final String fullName;
  final String gender;
  final String dateOfBirth;
  final String maritalStatus;
  final bool hasChildren;
  final int childrenCount;
  final int heightCm;
  final String country;
  final String city;
  final String? hometown;
  final String motherTongue;
  final List<String> languagesKnown;

  BasicInfoModel({
    this.fullName = '',
    this.gender = 'male',
    this.dateOfBirth = '2000-01-01',
    this.maritalStatus = 'never_married',
    this.hasChildren = false,
    this.childrenCount = 0,
    this.heightCm = 170,
    this.country = 'Pakistan',
    this.city = 'Lahore',
    this.hometown,
    this.motherTongue = 'Urdu',
    this.languagesKnown = const ['Urdu'],
  });

  factory BasicInfoModel.fromJson(Map<String, dynamic> json) {
    return BasicInfoModel(
      fullName: json['fullName'] ?? '',
      gender: json['gender'] ?? 'male',
      dateOfBirth: json['dateOfBirth'] != null
          ? json['dateOfBirth'].toString().split('T')[0]
          : '2000-01-01',
      maritalStatus: json['maritalStatus'] ?? 'never_married',
      hasChildren: json['hasChildren'] ?? false,
      childrenCount: json['childrenCount'] ?? 0,
      heightCm: json['heightCm'] ?? 170,
      country: json['country'] ?? 'Pakistan',
      city: json['city'] ?? 'Lahore',
      hometown: json['hometown'],
      motherTongue: json['motherTongue'] ?? 'Urdu',
      languagesKnown: (json['languagesKnown'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Urdu'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'maritalStatus': maritalStatus,
      'hasChildren': hasChildren,
      'childrenCount': childrenCount,
      'heightCm': heightCm,
      'country': country,
      'city': city,
      'hometown': hometown,
      'motherTongue': motherTongue,
      'languagesKnown': languagesKnown,
    };
  }
}

class ReligionCommunityModel {
  final String religion;
  final String sect;
  final String? casteBiradri;
  final String religiousPractice;

  ReligionCommunityModel({
    this.religion = 'Islam',
    this.sect = 'Sunni',
    this.casteBiradri,
    this.religiousPractice = 'moderate',
  });

  factory ReligionCommunityModel.fromJson(Map<String, dynamic> json) {
    return ReligionCommunityModel(
      religion: json['religion'] ?? 'Islam',
      sect: json['sect'] ?? 'Sunni',
      casteBiradri: json['casteBiradri'],
      religiousPractice: json['religiousPractice'] ?? 'moderate',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'religion': religion,
      'sect': sect,
      'casteBiradri': casteBiradri,
      'religiousPractice': religiousPractice,
    };
  }
}

class EducationCareerModel {
  final String highestEducation;
  final String? fieldOfStudy;
  final String? institute;
  final String occupationType;
  final String? jobTitle;
  final String? employer;
  final String? monthlyIncomeRange;
  final bool showIncomePublicly;

  EducationCareerModel({
    this.highestEducation = 'Bachelors',
    this.fieldOfStudy,
    this.institute,
    this.occupationType = 'employed',
    this.jobTitle,
    this.employer,
    this.monthlyIncomeRange,
    this.showIncomePublicly = false,
  });

  factory EducationCareerModel.fromJson(Map<String, dynamic> json) {
    return EducationCareerModel(
      highestEducation: json['highestEducation'] ?? 'Bachelors',
      fieldOfStudy: json['fieldOfStudy'],
      institute: json['institute'],
      occupationType: json['occupationType'] ?? 'employed',
      jobTitle: json['jobTitle'],
      employer: json['employer'],
      monthlyIncomeRange: json['monthlyIncomeRange'],
      showIncomePublicly: json['showIncomePublicly'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highestEducation': highestEducation,
      'fieldOfStudy': fieldOfStudy,
      'institute': institute,
      'occupationType': occupationType,
      'jobTitle': jobTitle,
      'employer': employer,
      'monthlyIncomeRange': monthlyIncomeRange,
      'showIncomePublicly': showIncomePublicly,
    };
  }
}

class FamilyDetailsModel {
  final String familyType;
  final String familyStatus;
  final String? fatherOccupation;
  final String? motherOccupation;
  final int brothersCount;
  final int sistersCount;

  FamilyDetailsModel({
    this.familyType = 'nuclear',
    this.familyStatus = 'moderate',
    this.fatherOccupation,
    this.motherOccupation,
    this.brothersCount = 0,
    this.sistersCount = 0,
  });

  factory FamilyDetailsModel.fromJson(Map<String, dynamic> json) {
    return FamilyDetailsModel(
      familyType: json['familyType'] ?? 'nuclear',
      familyStatus: json['familyStatus'] ?? 'moderate',
      fatherOccupation: json['fatherOccupation'],
      motherOccupation: json['motherOccupation'],
      brothersCount: json['brothersCount'] ?? 0,
      sistersCount: json['sistersCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'familyType': familyType,
      'familyStatus': familyStatus,
      'fatherOccupation': fatherOccupation,
      'motherOccupation': motherOccupation,
      'brothersCount': brothersCount,
      'sistersCount': sistersCount,
    };
  }
}

class LifestyleAboutModel {
  final String? diet;
  final bool smoking;
  final String? hijabBeard;
  final List<String> hobbies;
  final String aboutMe;
  final String? lookingFor;

  LifestyleAboutModel({
    this.diet = 'Halal',
    this.smoking = false,
    this.hijabBeard,
    this.hobbies = const [],
    this.aboutMe = '',
    this.lookingFor,
  });

  factory LifestyleAboutModel.fromJson(Map<String, dynamic> json) {
    return LifestyleAboutModel(
      diet: json['diet'] ?? 'Halal',
      smoking: json['smoking'] ?? false,
      hijabBeard: json['hijabBeard'],
      hobbies: (json['hobbies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      aboutMe: json['aboutMe'] ?? '',
      lookingFor: json['lookingFor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diet': diet,
      'smoking': smoking,
      'hijabBeard': hijabBeard,
      'hobbies': hobbies,
      'aboutMe': aboutMe,
      'lookingFor': lookingFor,
    };
  }
}

class PartnerPreferencesModel {
  final int ageMin;
  final int ageMax;
  final int? heightMinCm;
  final int? heightMaxCm;
  final List<String> maritalStatus;
  final List<String> citiesCountries;

  PartnerPreferencesModel({
    this.ageMin = 18,
    this.ageMax = 35,
    this.heightMinCm = 155,
    this.heightMaxCm = 190,
    this.maritalStatus = const ['never_married'],
    this.citiesCountries = const ['Lahore', 'Karachi', 'Islamabad'],
  });

  factory PartnerPreferencesModel.fromJson(Map<String, dynamic> json) {
    return PartnerPreferencesModel(
      ageMin: json['ageMin'] ?? 18,
      ageMax: json['ageMax'] ?? 35,
      heightMinCm: json['heightMinCm'] ?? 155,
      heightMaxCm: json['heightMaxCm'] ?? 190,
      maritalStatus: (json['maritalStatus'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['never_married'],
      citiesCountries: (json['citiesCountries'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Lahore'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ageMin': ageMin,
      'ageMax': ageMax,
      'heightMinCm': heightMinCm,
      'heightMaxCm': heightMaxCm,
      'maritalStatus': maritalStatus,
      'citiesCountries': citiesCountries,
    };
  }
}

class ProfileModel {
  final String id;
  final String userId;
  final BasicInfoModel basicInfo;
  final ReligionCommunityModel religionCommunity;
  final EducationCareerModel educationCareer;
  final FamilyDetailsModel familyDetails;
  final LifestyleAboutModel lifestyleAbout;
  final List<PhotoModel> photos;
  final PartnerPreferencesModel partnerPreferences;
  final int profileCompleteness;
  final bool isVerifiedBadge;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.basicInfo,
    required this.religionCommunity,
    required this.educationCareer,
    required this.familyDetails,
    required this.lifestyleAbout,
    required this.photos,
    required this.partnerPreferences,
    required this.profileCompleteness,
    this.isVerifiedBadge = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      basicInfo: BasicInfoModel.fromJson(json['basicInfo'] ?? {}),
      religionCommunity: ReligionCommunityModel.fromJson(json['religionCommunity'] ?? {}),
      educationCareer: EducationCareerModel.fromJson(json['educationCareer'] ?? {}),
      familyDetails: FamilyDetailsModel.fromJson(json['familyDetails'] ?? {}),
      lifestyleAbout: LifestyleAboutModel.fromJson(json['lifestyleAbout'] ?? {}),
      photos: (json['photos'] as List<dynamic>?)?.map((e) => PhotoModel.fromJson(e)).toList() ?? [],
      partnerPreferences: PartnerPreferencesModel.fromJson(json['partnerPreferences'] ?? {}),
      profileCompleteness: json['profileCompleteness'] ?? 0,
      isVerifiedBadge: json['isVerifiedBadge'] ?? false,
    );
  }
}
