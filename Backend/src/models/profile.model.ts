import mongoose, { Schema, Document } from 'mongoose';

export type Gender = 'male' | 'female';
export type MaritalStatus = 'never_married' | 'divorced' | 'widowed' | 'annulled';
export type FamilyType = 'joint' | 'nuclear';
export type FamilyValues = 'traditional' | 'moderate' | 'liberal';
export type OccupationType = 'employed' | 'business' | 'student' | 'homemaker' | 'not_working';
export type PhotoVisibility = 'everyone' | 'after_interest_accepted' | 'on_request';

export interface IPhoto {
  publicId: string;
  secureUrl: string;
  width?: number;
  height?: number;
  isPrimary: boolean;
  isApproved: boolean; // Managed by admin photo approval queue
  uploadedAt: Date;
}

export interface IBasicInfo {
  fullName: string;
  gender: Gender;
  dateOfBirth: Date;
  maritalStatus: MaritalStatus;
  hasChildren?: boolean;
  childrenCount?: number;
  heightCm: number;
  country: string;
  city: string;
  hometown?: string;
  motherTongue: string;
  languagesKnown: string[];
}

export interface IReligionCommunity {
  religion: string;
  sect: string;
  casteBiradri?: string;
  religiousPractice?: 'practicing' | 'moderate' | 'liberal';
}

export interface IEducationCareer {
  highestEducation: string;
  fieldOfStudy?: string;
  institute?: string;
  occupationType: OccupationType;
  jobTitle?: string;
  employer?: string;
  monthlyIncomeRange?: string;
  showIncomePublicly?: boolean;
}

export interface IFamilyDetails {
  familyType: FamilyType;
  familyStatus: FamilyValues;
  fatherOccupation?: string;
  motherOccupation?: string;
  brothersCount?: number;
  sistersCount?: number;
  marriedBrothersCount?: number;
  marriedSistersCount?: number;
  guardianName?: string;
  guardianPhone?: string;
}

export interface ILifestyleAbout {
  diet?: string;
  smoking?: boolean;
  hijabBeard?: string;
  hobbies: string[];
  aboutMe: string;
  lookingFor?: string;
}

export interface IPartnerPreferences {
  ageMin: number;
  ageMax: number;
  heightMinCm?: number;
  heightMaxCm?: number;
  maritalStatus: MaritalStatus[];
  religionSect: string[];
  minEducation?: string;
  citiesCountries: string[];
  occupationTypes: OccupationType[];
  willingToRelocate?: boolean;
  extraNotes?: string;
}

export interface IPrivacySettings {
  photoVisibility: PhotoVisibility;
  phoneVisibility: 'mutual_accept_only' | 'on_request_only';
  isPaused: boolean;
  hideLastSeen: boolean;
}

export interface IProfile extends Document {
  userId: mongoose.Types.ObjectId;
  basicInfo?: IBasicInfo;
  religionCommunity?: IReligionCommunity;
  educationCareer?: IEducationCareer;
  familyDetails?: IFamilyDetails;
  lifestyleAbout?: ILifestyleAbout;
  photos: IPhoto[];
  partnerPreferences?: IPartnerPreferences;
  privacySettings: IPrivacySettings;
  profileCompleteness: number; // 0 to 100 percentage
  isVerifiedBadge: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const photoSchema = new Schema<IPhoto>({
  publicId: { type: String, required: true },
  secureUrl: { type: String, required: true },
  width: { type: Number },
  height: { type: Number },
  isPrimary: { type: Boolean, default: false },
  isApproved: { type: Boolean, default: false }, // Moderation flag
  uploadedAt: { type: Date, default: Date.now },
});

const profileSchema = new Schema<IProfile>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },
    basicInfo: {
      fullName: { type: String },
      gender: { type: String, enum: ['male', 'female'], index: true },
      dateOfBirth: { type: Date, index: true },
      maritalStatus: {
        type: String,
        enum: ['never_married', 'divorced', 'widowed', 'annulled'],
        index: true,
      },
      hasChildren: { type: Boolean },
      childrenCount: { type: Number, default: 0 },
      heightCm: { type: Number },
      country: { type: String, default: 'Pakistan' },
      city: { type: String, index: true },
      hometown: { type: String },
      motherTongue: { type: String, default: 'Urdu' },
      languagesKnown: [{ type: String }],
    },
    religionCommunity: {
      religion: { type: String, default: 'Islam', index: true },
      sect: { type: String, index: true },
      casteBiradri: { type: String },
      religiousPractice: { type: String, enum: ['practicing', 'moderate', 'liberal'] },
    },
    educationCareer: {
      highestEducation: { type: String, index: true },
      fieldOfStudy: { type: String },
      institute: { type: String },
      occupationType: {
        type: String,
        enum: ['employed', 'business', 'student', 'homemaker', 'not_working'],
        index: true,
      },
      jobTitle: { type: String },
      employer: { type: String },
      monthlyIncomeRange: { type: String },
      showIncomePublicly: { type: Boolean, default: false },
    },
    familyDetails: {
      familyType: { type: String, enum: ['joint', 'nuclear'] },
      familyStatus: { type: String, enum: ['traditional', 'moderate', 'liberal'] },
      fatherOccupation: { type: String },
      motherOccupation: { type: String },
      brothersCount: { type: Number, default: 0 },
      sistersCount: { type: Number, default: 0 },
      marriedBrothersCount: { type: Number, default: 0 },
      marriedSistersCount: { type: Number, default: 0 },
      guardianName: { type: String, select: false },
      guardianPhone: { type: String, select: false },
    },
    lifestyleAbout: {
      diet: { type: String },
      smoking: { type: Boolean, default: false },
      hijabBeard: { type: String },
      hobbies: [{ type: String }],
      aboutMe: { type: String },
      lookingFor: { type: String },
    },
    photos: [photoSchema],
    partnerPreferences: {
      ageMin: { type: Number, default: 18 },
      ageMax: { type: Number, default: 40 },
      heightMinCm: { type: Number },
      heightMaxCm: { type: Number },
      maritalStatus: [{ type: String }],
      religionSect: [{ type: String }],
      minEducation: { type: String },
      citiesCountries: [{ type: String }],
      occupationTypes: [{ type: String }],
      willingToRelocate: { type: Boolean, default: false },
      extraNotes: { type: String },
    },
    privacySettings: {
      photoVisibility: {
        type: String,
        enum: ['everyone', 'after_interest_accepted', 'on_request'],
        default: 'everyone',
      },
      phoneVisibility: {
        type: String,
        enum: ['mutual_accept_only', 'on_request_only'],
        default: 'mutual_accept_only',
      },
      isPaused: { type: Boolean, default: false, index: true },
      hideLastSeen: { type: Boolean, default: false },
    },
    profileCompleteness: {
      type: Number,
      default: 0,
      index: true,
    },
    isVerifiedBadge: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for fast filtering
profileSchema.index({
  'basicInfo.gender': 1,
  'basicInfo.city': 1,
  'religionCommunity.religion': 1,
  'religionCommunity.sect': 1,
  profileCompleteness: 1,
});

/**
 * Calculates profile completeness percentage (0 - 100%)
 */
export function calculateProfileCompleteness(profile: Partial<IProfile>): number {
  let score = 0;

  if (profile.basicInfo?.fullName) {
    score += 25; // Basic info
  }
  if (profile.religionCommunity?.religion) {
    score += 15; // Religion & Sect
  }
  if (profile.educationCareer?.highestEducation || profile.educationCareer?.jobTitle) {
    score += 15; // Education & Career
  }
  if (profile.familyDetails?.familyType || profile.familyDetails?.familyStatus) {
    score += 10; // Family Details
  }
  if (profile.lifestyleAbout?.aboutMe && profile.lifestyleAbout.aboutMe.trim().length > 0) {
    score += 15; // About me
  }
  if (profile.photos && profile.photos.length > 0) {
    score += 10; // Photos uploaded
  }
  if (profile.partnerPreferences) {
    score += 10; // Partner preferences
  }

  return Math.min(Math.max(score, 20), 100);
}

export const Profile = mongoose.model<IProfile>('Profile', profileSchema);
