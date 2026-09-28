import { IProfile } from '../models/profile.model';

export class MatchingService {
  /**
   * Calculates compatibility percentage (0% to 100%) between a viewer profile and a candidate profile.
   */
  static calculateCompatibility(viewer: Partial<IProfile>, candidate: Partial<IProfile>): number {
    let matchScore = 0;
    let totalWeight = 0;

    const prefs = viewer.partnerPreferences;
    const cBasic = candidate.basicInfo;
    const cReligion = candidate.religionCommunity;
    const cEducation = candidate.educationCareer;

    if (!cBasic) return 50; // Neutral default if details are missing

    // 1. Age Range Match (Weight: 25%)
    totalWeight += 25;
    if (prefs?.ageMin && prefs?.ageMax && cBasic.dateOfBirth) {
      const candidateAge = this.calculateAge(new Date(cBasic.dateOfBirth));
      if (candidateAge >= prefs.ageMin && candidateAge <= prefs.ageMax) {
        matchScore += 25;
      } else if (Math.abs(candidateAge - prefs.ageMin) <= 2 || Math.abs(candidateAge - prefs.ageMax) <= 2) {
        matchScore += 15; // Near match
      }
    } else {
      matchScore += 15;
    }

    // 2. Marital Status Match (Weight: 15%)
    totalWeight += 15;
    if (prefs?.maritalStatus && prefs.maritalStatus.length > 0 && cBasic.maritalStatus) {
      if (prefs.maritalStatus.includes(cBasic.maritalStatus)) {
        matchScore += 15;
      }
    } else {
      matchScore += 15;
    }

    // 3. Religion & Sect Match (Weight: 20%)
    totalWeight += 20;
    if (cReligion?.sect && prefs?.religionSect && prefs.religionSect.length > 0) {
      if (prefs.religionSect.includes(cReligion.sect)) {
        matchScore += 20;
      }
    } else if (viewer.religionCommunity?.sect === cReligion?.sect) {
      matchScore += 20;
    } else {
      matchScore += 10;
    }

    // 4. City / Location Match (Weight: 15%)
    totalWeight += 15;
    if (prefs?.citiesCountries && prefs.citiesCountries.length > 0 && cBasic.city) {
      if (prefs.citiesCountries.some((c) => c.toLowerCase() === cBasic.city.toLowerCase())) {
        matchScore += 15;
      }
    } else if (viewer.basicInfo?.city && cBasic.city.toLowerCase() === viewer.basicInfo.city.toLowerCase()) {
      matchScore += 15;
    } else {
      matchScore += 5;
    }

    // 5. Education Level Match (Weight: 15%)
    totalWeight += 15;
    if (cEducation?.highestEducation) {
      matchScore += 15;
    } else {
      matchScore += 10;
    }

    // 6. Height Range Match (Weight: 10%)
    totalWeight += 10;
    if (prefs?.heightMinCm && prefs?.heightMaxCm && cBasic.heightCm) {
      if (cBasic.heightCm >= prefs.heightMinCm && cBasic.heightCm <= prefs.heightMaxCm) {
        matchScore += 10;
      }
    } else {
      matchScore += 10;
    }

    const percentage = Math.round((matchScore / totalWeight) * 100);
    return Math.min(Math.max(percentage, 40), 99); // Bound between 40% and 99%
  }

  private static calculateAge(dob: Date): number {
    const diffMs = Date.now() - dob.getTime();
    const ageDate = new Date(diffMs);
    return Math.abs(ageDate.getUTCFullYear() - 1970);
  }
}
