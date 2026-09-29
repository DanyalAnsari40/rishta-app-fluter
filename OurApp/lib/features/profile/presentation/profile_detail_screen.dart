import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../chat/presentation/chat_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final String? userId;

  const ProfileDetailScreen({
    super.key,
    required this.profileData,
    this.userId,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  late Map<String, dynamic> _data;
  bool _isLoading = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.profileData);
    final targetId = widget.userId ?? _data['userId'] ?? _data['_id'] ?? _data['id'];
    if (targetId != null && targetId.toString().isNotEmpty && _data.keys.length <= 3) {
      _fetchFullProfile(targetId.toString());
    }
  }

  Future<void> _fetchFullProfile(String targetId) async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/profile/$targetId');
      if (response.data['success'] == true && response.data['data'] != null) {
        setState(() {
          _data = Map<String, dynamic>.from(response.data['data']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatMaritalStatus(String? status) {
    if (status == null || status.isEmpty) return 'Single';
    final s = status.toLowerCase();
    if (s == 'never_married' || s == 'single') return 'Single';
    if (s == 'divorced') return 'Divorced';
    if (s == 'widowed') return 'Widowed';
    if (s == 'annulled') return 'Annulled';
    return status;
  }

  int _calculateAge(dynamic dob) {
    if (dob == null) return 24;
    try {
      final birthDate = DateTime.parse(dob.toString());
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age > 0 ? age : 24;
    } catch (_) {
      return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF71A65)),
        ),
      );
    }

    // Extract normalized fields from _data
    final basicInfo = _data['basicInfo'] is Map ? _data['basicInfo'] : {};
    final religionComm = _data['religionCommunity'] is Map ? _data['religionCommunity'] : {};
    final eduCareer = _data['educationCareer'] is Map ? _data['educationCareer'] : {};
    final lifestyle = _data['lifestyleAbout'] is Map ? _data['lifestyleAbout'] : {};

    final String name = _data['name'] ?? basicInfo['fullName'] ?? 'Ayesha Khan';
    final int age = _data['age'] ?? (basicInfo['dateOfBirth'] != null ? _calculateAge(basicInfo['dateOfBirth']) : 28);
    final String city = _data['city'] ?? basicInfo['city'] ?? 'Lahore';
    
    final String occupation = _data['occupation'] ??
        eduCareer['jobTitle'] ??
        eduCareer['highestEducation'] ??
        'Software Engineer';

    final String religion = _data['religion'] ?? religionComm['religion'] ?? 'Islam';
    final String maritalStatus = _formatMaritalStatus(_data['maritalStatus'] ?? basicInfo['maritalStatus']);
    final String religionAndStatus = '$religion • $maritalStatus';

    final String aboutMeRaw = _data['aboutMe'] ?? lifestyle['aboutMe'] ?? '';
    final String aboutMe = aboutMeRaw.trim().isNotEmpty
        ? aboutMeRaw
        : 'I am a simple, kind and family-oriented person. I believe in honesty, respect and building a happy life together.';

    // Extract hobbies / interests
    List<dynamic> hobbiesRaw = _data['interests'] ?? _data['hobbies'] ?? lifestyle['hobbies'] ?? [];
    List<String> interests = hobbiesRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    if (interests.isEmpty) {
      interests = ['Reading', 'Traveling', 'Cooking', 'Photography'];
    }

    // Photo URL handling
    String? photoUrl = _data['primaryPhotoUrl'] ?? _data['image'] ?? _data['photoUrl'];
    final photosList = _data['photos'] is List ? _data['photos'] as List : [];
    if (photoUrl == null && photosList.isNotEmpty) {
      final primary = photosList.firstWhere(
        (p) => p is Map && p['isPrimary'] == true,
        orElse: () => photosList.first,
      );
      if (primary is Map) {
        photoUrl = primary['secureUrl'];
      }
    }
    final bool isAsset = _data['isAsset'] == true || (photoUrl != null && photoUrl.startsWith('assets/'));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Photo Header with Gradient Overlay & Floating Heart Button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Header Image Container with Curved Bottom
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.42,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (photoUrl != null && photoUrl.isNotEmpty)
                              isAsset
                                  ? Image.asset(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildFallbackHeaderImage(),
                                    )
                                  : Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildFallbackHeaderImage(),
                                    )
                            else
                              _buildFallbackHeaderImage(),

                            // Top gradient shadow for back arrow & menu button legibility
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.35],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Top Navigation Buttons (Back Arrow & 3-Dots Menu)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showOptionsMenu(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.more_vert_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Floating Circular Heart Action Button on Bottom Right Edge
                    Positioned(
                      bottom: -22,
                      right: 24,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _isLiked = !_isLiked);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isLiked
                                  ? 'Added $name to favorites!'
                                  : 'Removed $name from favorites'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF71A65).withOpacity(0.2),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _isLiked ? Icons.favorite_rounded : Icons.favorite_rounded,
                              color: _isLiked ? const Color(0xFFF71A65) : const Color(0xFFF71A65),
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 2. Profile Summary Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name, Age & Pink Verified Badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$name, $age',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C1C1E),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF71A65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Location detail item
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            city,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF636366),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Occupation detail item
                      Row(
                        children: [
                          const Icon(
                            Icons.business_center_outlined,
                            size: 20,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            occupation,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF636366),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Religion & Marital Status detail item
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            religionAndStatus,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF636366),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // 3. About Me Section
                      const Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        aboutMe,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: Color(0xFF48484A),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 4. Interests Section
                      const Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1E),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: interests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                color: Color(0xFF9E1F46),
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Fixed Full-Width "Send Message" Action Button at Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 6
                    : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final targetUserId = widget.userId ?? _data['userId'] ?? _data['_id'] ?? _data['id'];
                    if (targetUserId != null) {
                      _startChatSession(context, targetUserId.toString(), name, photoUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Message request sent to $name!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF71A65),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(
                    Icons.mark_unread_chat_alt_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Send Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startChatSession(BuildContext context, String targetUserId, String name, String? photoUrl) async {
    try {
      final apiClient = ApiClient();
      final res = await apiClient.dio.post(
        '/chat/conversations/start',
        data: {'targetUserId': targetUserId},
      );

      if (res.data['success'] == true && context.mounted) {
        final convData = res.data['data'];
        final conversationId = convData['conversationId'].toString();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              extraData: {
                'targetUserId': targetUserId,
                'name': name,
                'primaryPhotoUrl': photoUrl,
              },
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Starting chat with $name...')),
        );
      }
    }
  }

  Widget _buildFallbackHeaderImage() {
    return Container(
      color: const Color(0xFFF4F5F8),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 100,
          color: Color(0xFFF71A65),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share Profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.red),
                title: const Text('Block User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: const Text('Report Profile', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
