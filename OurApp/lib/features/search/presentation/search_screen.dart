import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _cityController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Expansion Panel
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surfaceVariant,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        hintText: 'Search by city (e.g. Lahore)',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 48),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _performSearch,
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSect,
                      decoration: const InputDecoration(
                        labelText: 'Sect',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All Sects')),
                        DropdownMenuItem(value: 'Sunni', child: Text('Sunni')),
                        DropdownMenuItem(value: 'Shia', child: Text('Shia')),
                      ],
                      onChanged: (val) => setState(() => _selectedSect = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedMaritalStatus,
                      decoration: const InputDecoration(
                        labelText: 'Marital Status',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Any Status')),
                        DropdownMenuItem(value: 'never_married', child: Text('Never Married')),
                        DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                      ],
                      onChanged: (val) => setState(() => _selectedMaritalStatus = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _searchResults.isEmpty
                  ? const Center(child: Text('No profiles match your search criteria.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final p = _searchResults[index];
                        return _buildSearchCard(p);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchCard(Map<String, dynamic> p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: p['primaryPhotoUrl'] != null ? NetworkImage(p['primaryPhotoUrl']) : null,
          child: p['primaryPhotoUrl'] == null ? const Icon(Icons.person) : null,
        ),
        title: Row(
          children: [
            Text('${p['name']}, ${p['age']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            if (p['isVerifiedBadge'] == true)
              const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${p['city']} • ${p['religion']} (${p['sect']})'),
            Text('${p['education']} • ${p['occupation']}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${p['compatibilityPercentage']}% Match',
            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
