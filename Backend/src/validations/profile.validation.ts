import { z } from 'zod';

// Helper: Calculate age from DOB
const calculateAge = (dob: Date): number => {
  const diffMs = Date.now() - dob.getTime();
  const ageDate = new Date(diffMs);
  return Math.abs(ageDate.getUTCFullYear() - 1970);
};

export const basicInfoSchema = z.object({
  body: z.object({
    fullName: z.string().min(2, 'Full name must be at least 2 characters'),
    gender: z.enum(['male', 'female'], { required_error: 'Gender is required' }),
    dateOfBirth: z
      .string()
      .refine((val) => !isNaN(Date.parse(val)), 'Invalid date format')
      .refine((val) => calculateAge(new Date(val)) >= 18, 'User must be at least 18 years old'),
    maritalStatus: z.enum(['never_married', 'divorced', 'widowed', 'annulled']),
    hasChildren: z.boolean().optional(),
    childrenCount: z.number().min(0).optional(),
    heightCm: z.number().min(120, 'Height must be at least 120 cm').max(230, 'Invalid height'),
    country: z.string().default('Pakistan'),
    city: z.string().min(2, 'City is required'),
    hometown: z.string().optional(),
    motherTongue: z.string().default('Urdu'),
    languagesKnown: z.array(z.string()).default(['Urdu']),
  }),
});

export const religionCommunitySchema = z.object({
  body: z.object({
    religion: z.string().min(1, 'Religion is required'),
    sect: z.string().min(1, 'Sect is required'),
    casteBiradri: z.string().optional(),
    religiousPractice: z.enum(['practicing', 'moderate', 'liberal']).optional(),
  }),
});

export const educationCareerSchema = z.object({
  body: z.object({
    highestEducation: z.string().min(1, 'Highest education level is required'),
    fieldOfStudy: z.string().optional(),
    institute: z.string().optional(),
    occupationType: z.enum(['employed', 'business', 'student', 'homemaker', 'not_working']),
    jobTitle: z.string().optional(),
    employer: { parse: (val: any) => val, optional: () => true } as any,
    monthlyIncomeRange: z.string().optional(),
    showIncomePublicly: z.boolean().optional().default(false),
  }),
});

export const familyDetailsSchema = z.object({
  body: z.object({
    familyType: z.enum(['joint', 'nuclear']),
    familyStatus: z.enum(['traditional', 'moderate', 'liberal']),
    fatherOccupation: z.string().optional(),
    motherOccupation: z.string().optional(),
    brothersCount: z.number().min(0).optional(),
    sistersCount: z.number().min(0).optional(),
    marriedBrothersCount: z.number().min(0).optional(),
    marriedSistersCount: { parse: (val: any) => val, optional: () => true } as any,
    guardianName: z.string().optional(),
    guardianPhone: z.string().optional(),
  }),
});

export const lifestyleAboutSchema = z.object({
  body: z.object({
    diet: z.string().optional(),
    smoking: z.boolean().optional().default(false),
    hijabBeard: z.string().optional(),
    hobbies: z.array(z.string()).default([]),
    aboutMe: z
      .string()
      .min(50, 'About Me must be at least 50 characters long')
      .max(500, 'About Me cannot exceed 500 characters'),
    lookingFor: z.string().max(500).optional(),
  }),
});

export const partnerPreferencesSchema = z.object({
  body: z.object({
    ageMin: z.number().min(18).max(80),
    ageMax: z.number().min(18).max(80),
    heightMinCm: z.number().optional(),
    heightMaxCm: z.number().optional(),
    maritalStatus: z.array(z.string()).default([]),
    religionSect: z.array(z.string()).default([]),
    minEducation: z.string().optional(),
    citiesCountries: z.array(z.string()).default([]),
    occupationTypes: z.array(z.string()).default([]),
    willingToRelocate: z.boolean().optional().default(false),
    extraNotes: z.string().optional(),
  }),
});

export const addPhotoSchema = z.object({
  body: z.object({
    publicId: z.string().min(1, 'Public ID is required'),
    secureUrl: z.string().url('Invalid photo URL'),
    width: z.number().optional(),
    height: z.number().optional(),
    isPrimary: z.boolean().optional().default(false),
  }),
});
