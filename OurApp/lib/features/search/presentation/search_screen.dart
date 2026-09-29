import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../profile/presentation/profile_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _cityController = TextEditingController();
  String? _selectedGender; // null/'all', 'male', 'female'
  String? _selectedSect;
  String? _selectedMaritalStatus;
  bool _isLoading = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final queryParams = <String, String>{};
      if (_cityController.text.isNotEmpty) {
        queryParams['city'] = _cityController.text.trim();
      }
      if (_selectedGender != null && _selectedGender != 'all') {
        queryParams['gender'] = _selectedGender!;
      }
      if (_selectedSect != null) {
        queryParams['sect'] = _selectedSect!;
      }
      if (_selectedMaritalStatus != null) {
        queryParams['maritalStatus'] = _selectedMaritalStatus!;
      }

      final response = await apiClient.dio.get('/search', queryParameters: queryParams);

      if (response.data['success'] == true) {
        setState(() {
          _searchResults = response.data['data']['results'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _cityController.clear();
      _selectedGender = null;
      _selectedSect = null;
      _selectedMaritalStatus = null;
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _cityController.text.isNotEmpty ||
        (_selectedGender != null && _selectedGender != 'all') ||
        _selectedSect != null ||
        _selectedMaritalStatus != null;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Sleek Floating Search Header Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input with integrated Gradient Search Button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_rounded, color: Color(0xFFF71A65), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          onSubmitted: (_) => _performSearch(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: 'Search city (e.g. Lahore, Karachi)',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_cityController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                          onPressed: () {
                            _cityController.clear();
                            _performSearch();
                          },
                        ),
                      GestureDetector(
                        onTap: _performSearch,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF71A65), Color(0xFFFF4884)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF71A65).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                'Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Multi-Filter Dropdowns Row (Gender, Sect, Status)
                Row(
                  children: [
                    // Gender Dropdown
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            hint: const Row(
                              children: [
                                Icon(Icons.wc_rounded, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('Gender: All', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Gender: All', style: TextStyle(fontSize: 11)),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female Only', style: TextStyle(fontSize: 11)),
                              ),
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male Only', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedGender = val);
                              _performSearch();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Sect Dropdown
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSect,
                            isExpanded: true,
                            hint: const Row(
                              children: [
                                Icon(Icons.people_outline_rounded, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('Sect: All', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Sect: All', style: TextStyle(fontSize: 11)),
                              ),
                              DropdownMenuItem(
                                value: 'Sunni',
                                child: Text('Sunni', style: TextStyle(fontSize: 11)),
                              ),
                              DropdownMenuItem(
                                value: 'Shia',
                                child: Text('Shia', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedSect = val);
                              _performSearch();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Marital Status Dropdown
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMaritalStatus,
                            isExpanded: true,
                            hint: const Row(
                              children: [
                                Icon(Icons.favorite_outline_rounded, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('Status: Any', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
                            items: const [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Status: Any', style: TextStyle(fontSize: 11)),
                              ),
                              DropdownMenuItem(
                                value: 'never_married',
                                child: Text('Never Married', style: TextStyle(fontSize: 11)),
                              ),
                              DropdownMenuItem(
                                value: 'divorced',
                                child: Text('Divorced', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedMaritalStatus = val);
                              _performSearch();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (hasActiveFilters) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _clearFilters,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFF71A65)),
                          SizedBox(width: 4),
                          Text(
                            'Clear Filters',
                            style: TextStyle(
                              color: Color(0xFFF71A65),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results Counter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isLoading ? 'Searching...' : '${_searchResults.length} Profiles Found',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF71A65)))
                : _searchResults.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final p = _searchResults[index];
                          return _buildSearchCard(p);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF71A65).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFF71A65)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching profiles',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your city or filters',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(Map<String, dynamic> p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileDetailScreen(profileData: p),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Profile Photo with gradient ring
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF71A65), Color(0xFFFF528E)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: p['primaryPhotoUrl'] != null ? NetworkImage(p['primaryPhotoUrl']) : null,
                  child: p['primaryPhotoUrl'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(width: 14),

              // Profile info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${p['name'] ?? 'Member'}, ${p['age'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (p['isVerifiedBadge'] == true)
                          const Icon(Icons.verified_rounded, color: Color(0xFFF71A65), size: 16),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          '${p['city'] ?? 'Pakistan'} • ${p['sect'] ?? 'Muslim'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${p['education'] ?? 'Educated'} • ${p['occupation'] ?? 'Professional'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Compatibility percentage badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF71A65).withOpacity(0.12),
                      const Color(0xFFFF528E).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF71A65).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${p['compatibilityPercentage'] ?? 85}%',
                      style: const TextStyle(
                        color: Color(0xFFF71A65),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Match',
                      style: TextStyle(
                        color: Color(0xFFF71A65),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
