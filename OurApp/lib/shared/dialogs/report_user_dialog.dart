import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class ReportUserDialog extends StatefulWidget {
  final String targetUserId;
  final String userName;

  const ReportUserDialog({super.key, required this.targetUserId, required this.userName});

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  String _selectedReason = 'fake_profile';
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _reasons = {
    'fake_profile': 'Fake Profile / Misrepresentation',
    'inappropriate_photo': 'Inappropriate or Vulgar Photo',
    'harassment': 'Harassment or Abusive Behavior',
    'spam': 'Spam / Commercial Advertising',
    'scam': 'Financial Scam or Fraud',
    'other': 'Other Violation',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      final apiClient = ApiClient();
      await apiClient.dio.post('/safety/report', data: {
        'targetUserId': widget.targetUserId,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you for keeping our community safe.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Report ${widget.userName}', style: Theme.of(context).textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedReason,
            decoration: const InputDecoration(labelText: 'Reason for Report'),
            items: _reasons.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedReason = val);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _detailsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional Details (Optional)',
              hintText: 'Please describe the issue...',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}
