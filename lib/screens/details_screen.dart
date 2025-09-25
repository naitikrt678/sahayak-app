import 'package:flutter/material.dart';
import '../models/civic_report.dart';
import '../services/voice_recording_service.dart';
import 'summary_screen.dart';

class DetailsScreen extends StatefulWidget {
  final CivicReport report;
  final VoiceRecordingResult? voiceRecording;

  const DetailsScreen({super.key, required this.report, this.voiceRecording});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late CivicReport _currentReport;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _hasVoiceNote = false;
  VoiceRecordingResult? _voiceRecording;
  String _selectedCategory = '';

  final List<String> _categories = [
    'Pothole',
    'Garbage Collection',
    'Street Light',
    'Water Supply',
    'Drainage',
    'Road Damage',
    'Public Toilet',
    'Park Maintenance',
    'Traffic Signal',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
    _voiceRecording = widget.voiceRecording;
    _hasVoiceNote = _voiceRecording != null;
    _descriptionController.text = _currentReport.description;
    _additionalNotesController.text = _currentReport.additionalNotes;
    _categoryController.text = _currentReport.category;
    _selectedCategory = _currentReport.category.isEmpty
        ? _categories[0]
        : _currentReport.category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _additionalNotesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _updateReport() {
    setState(() {
      _currentReport = _currentReport.copyWith(
        description: _descriptionController.text,
        additionalNotes: _additionalNotesController.text,
        category: _selectedCategory,
        voiceNotes: _hasVoiceNote ? 'Voice note recorded' : '',
      );
    });
  }

  void _navigateToSummary() {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description of the problem'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _updateReport();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryScreen(
          report: _currentReport,
          voiceRecording: _voiceRecording,
        ),
      ),
    );
  }

  void _toggleVoiceNote() {
    setState(() {
      _hasVoiceNote = !_hasVoiceNote;
    });

    if (_hasVoiceNote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice note feature - This is a prototype placeholder'),
          backgroundColor: Color(0xFF2196F3),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selection
            const Text(
              'Problem Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  items: _categories.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Description Field
            const Text(
              'Problem Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Describe the issue in detail...\n\nFor example:\n- Size and depth of pothole\n- Amount of garbage\n- Severity of the problem',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 25),

            // Voice Note Section
            const Text(
              'Voice Note (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasVoiceNote
                      ? const Color(0xFF4CAF50)
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _hasVoiceNote ? Icons.mic : Icons.mic_none,
                        color: _hasVoiceNote
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasVoiceNote
                              ? 'Voice note recorded (Prototype placeholder)'
                              : 'Tap to record a voice note',
                          style: TextStyle(
                            fontSize: 16,
                            color: _hasVoiceNote
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_hasVoiceNote)
                        IconButton(
                          onPressed: () {
                            // Placeholder for play functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Play voice note - Prototype placeholder',
                                ),
                                backgroundColor: Color(0xFF2196F3),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _toggleVoiceNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasVoiceNote
                              ? Colors.red
                              : const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: Icon(_hasVoiceNote ? Icons.delete : Icons.mic),
                        label: Text(_hasVoiceNote ? 'Delete' : 'Record'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Additional Notes Field
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _additionalNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Any additional information, suggestions, or observations...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(15),
              ),
            ),

            const SizedBox(height: 30),

            // Priority Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        'Priority Level',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This report will be automatically prioritized based on the category and description provided.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Next Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToSummary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Next: Review Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
