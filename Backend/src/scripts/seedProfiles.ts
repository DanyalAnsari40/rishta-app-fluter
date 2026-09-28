import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { User } from '../models/user.model';
import { Profile } from '../models/profile.model';

async function seed() {
  await mongoose.connect('mongodb://127.0.0.1:27017/rishta_db');
  console.log('Connected to MongoDB.');

  const sampleUsers = [
    {
      email: 'ayesha.khan@gmail.com',
      fullName: 'Ayesha Khan',
      gender: 'female',
      dateOfBirth: new Date('1998-04-12'),
      city: 'Lahore',
      sect: 'Sunni',
      caste: 'Rajput',
      education: 'Masters in Computer Science',
      occupationType: 'employed',
      jobTitle: 'Software Engineer at Systems Ltd',
      maritalStatus: 'never_married',
      heightCm: 165,
      photo: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop',
      aboutMe: 'Software engineer by profession. I value family traditions and religious values while maintaining a modern mindset. Looking for a respectful partner.',
    },
    {
      email: 'fatima.zahra@gmail.com',
      fullName: 'Fatima Zahra',
      gender: 'female',
      dateOfBirth: new Date('2000-09-25'),
      city: 'Karachi',
      sect: 'Sunni',
      caste: 'Syed',
      education: 'BDS Doctor',
      occupationType: 'employed',
      jobTitle: 'Dental Surgeon',
      maritalStatus: 'never_married',
      heightCm: 162,
      photo: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop',
      aboutMe: 'Practicing doctor who loves reading and baking in free time. Family oriented and searching for a well-educated partner.',
    },
    {
      email: 'zainab.ali@gmail.com',
      fullName: 'Zainab Ali',
      gender: 'female',
      dateOfBirth: new Date('1997-11-05'),
      city: 'Islamabad',
      sect: 'Shia',
      caste: 'Malik',
      education: 'MBA Marketing',
      occupationType: 'employed',
      jobTitle: 'Marketing Executive',
      maritalStatus: 'never_married',
      heightCm: 168,
      photo: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop',
      aboutMe: 'Passionate marketer based in Islamabad. I believe in mutual respect, open communication, and shared values.',
    },
    {
      email: 'sara.ahmed@gmail.com',
      fullName: 'Sara Ahmed',
      gender: 'female',
      dateOfBirth: new Date('1999-01-30'),
      city: 'Lahore',
      sect: 'Sunni',
      caste: 'Sheikh',
      education: 'Bachelors in Graphic Design',
      occupationType: 'business',
      jobTitle: 'Creative Director / Studio Owner',
      maritalStatus: 'never_married',
      heightCm: 160,
      photo: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop',
      aboutMe: 'Creative entrepreneur running my own design studio. Looking for an ambitious, supportive life partner.',
    }
  ];

  for (const u of sampleUsers) {
    let user = await User.findOne({ email: u.email });
    if (!user) {
      const hashedPassword = await bcrypt.hash('Password123!', 12);
      user = await User.create({
        email: u.email,
        password: hashedPassword,
        role: 'user',
        status: 'active',
        emailVerified: true,
        profileCreatedFor: 'self',
      });
    }

    await Profile.findOneAndUpdate(
      { userId: user._id },
      {
        userId: user._id,
        basicInfo: {
          fullName: u.fullName,
          gender: u.gender,
          dateOfBirth: u.dateOfBirth,
          maritalStatus: u.maritalStatus,
          heightCm: u.heightCm,
          country: 'Pakistan',
          city: u.city,
          motherTongue: 'Urdu',
          languagesKnown: ['Urdu', 'English'],
        },
        religionCommunity: {
          religion: 'Islam',
          sect: u.sect,
          casteBiradri: u.caste,
          religiousPractice: 'practicing',
        },
        educationCareer: {
          highestEducation: u.education,
          occupationType: u.occupationType,
          jobTitle: u.jobTitle,
        },
        familyDetails: {
          familyType: 'nuclear',
          familyStatus: 'moderate',
          brothersCount: 1,
          sistersCount: 1,
        },
        lifestyleAbout: {
          diet: 'Halal',
          smoking: false,
          hobbies: ['Reading', 'Cooking', 'Travel'],
          aboutMe: u.aboutMe,
        },
        photos: [
          {
            publicId: `sample_${user._id}`,
            secureUrl: u.photo,
            isPrimary: true,
            isApproved: true,
            uploadedAt: new Date(),
          },
        ],
        partnerPreferences: {
          ageMin: 23,
          ageMax: 35,
          maritalStatus: ['never_married'],
          citiesCountries: ['Lahore', 'Karachi', 'Islamabad'],
        },
        privacySettings: {
          photoVisibility: 'everyone',
          phoneVisibility: 'mutual_accept_only',
          isPaused: false,
          hideLastSeen: false,
        },
        profileCompleteness: 90,
        isVerifiedBadge: true,
      },
      { upsert: true }
    );
    console.log(`Seeded profile for ${u.fullName}`);
  }

  console.log('Seeding finished successfully!');
  await mongoose.connection.close();
  process.exit(0);
}

seed().catch(console.error);
