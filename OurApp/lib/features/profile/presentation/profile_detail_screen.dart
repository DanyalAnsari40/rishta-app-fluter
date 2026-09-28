import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> profileData;

  const ProfileDetailScreen({super.key, required this.profileData});

  @override
  Widget build(BuildContext context) {
    final name = profileData['name'] ?? 'Member';
    final age = profileData['age'] ?? 24;
    final city = profileData['city'] ?? 'Unknown';
    final photoUrl = profileData['primaryPhotoUrl'];
    final compatibility = profileData['compatibilityPercentage'] ?? 85;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover Photo Header with Overlapping Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  color: AppTheme.primaryDark,
                  child: photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover)
                      : const Icon(Icons.favorite_rounded, size: 80, color: Colors.white24),
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person, size: 40) : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Profile Header Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$name, $age',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 24),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$city • ${profileData['religion'] ?? 'Islam'} (${profileData['sect'] ?? 'Sunni'})',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Compatibility Score Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_rounded, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          '$compatibility% Match with your preferences',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Interest sent to $name!')),
                            );
                          },
                          icon: const Icon(Icons.favorite),
                          label: const Text('Send Interest'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Icon(Icons.star_border_rounded),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Icon(Icons.share_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Section details
                  const Text('About Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    profileData['aboutMe'] ??
                        'A respectful, well-educated individual looking for a compatible life partner who values family, ethics, and personal growth.',
                    style: const TextStyle(height: 1.5, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  const Text('Education & Career', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.school_outlined, color: AppTheme.primary),
                    title: Text(profileData['education'] ?? 'Bachelors'),
                    subtitle: Text(profileData['occupation'] ?? 'Employed'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
