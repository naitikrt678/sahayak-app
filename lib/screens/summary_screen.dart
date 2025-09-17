import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/civic_report.dart';
import '../services/local_storage_service.dart';
import 'confirmation_screen.dart';

class SummaryScreen extends StatefulWidget {
  final CivicReport report;

  const SummaryScreen({super.key, required this.report});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isSubmitting = false;

  void _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Store the report locally
      await LocalStorageService.storeReport(widget.report);

      // Simulate submission process
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isSubmitting = false;
      });

      // Navigate to confirmation screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConfirmationScreen()),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to submit report. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _editReport() {
    Navigator.pop(context);
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
          'Review Report',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _editReport,
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment,
                    size: 50,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Report Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Report ID: CIV${widget.report.timestamp.millisecondsSinceEpoch.toString().substring(8)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Photo Section
            _buildSectionCard(
              title: 'Photo Evidence',
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.report.image != null
                      ? Image.file(widget.report.image!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Category Section
            _buildSectionCard(
              title: 'Problem Category',
              child: _buildInfoRow(
                Icons.category,
                widget.report.category.isEmpty
                    ? 'Not specified'
                    : widget.report.category,
              ),
            ),

            const SizedBox(height: 15),

            // Location Section
            _buildSectionCard(
              title: 'Location Details',
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.location_on,
                    widget.report.address.isEmpty
                        ? 'No address provided'
                        : widget.report.address,
                  ),
                  if (widget.report.hasLocation()) ...[
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      Icons.gps_fixed,
                      'GPS: ${widget.report.latitude!.toStringAsFixed(6)}, ${widget.report.longitude!.toStringAsFixed(6)}',
                      isSecondary: true,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Description Section
            _buildSectionCard(
              title: 'Problem Description',
              child: Text(
                widget.report.description.isEmpty
                    ? 'No description provided'
                    : widget.report.description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),

            // Voice Note Section
            if (widget.report.voiceNotes.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 15),
                  _buildSectionCard(
                    title: 'Voice Note',
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Voice note attached (Prototype placeholder)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
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
                      ],
                    ),
                  ),
                ],
              ),

            // Additional Notes Section
            if (widget.report.additionalNotes.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 15),
                  _buildSectionCard(
                    title: 'Additional Notes',
                    child: Text(
                      widget.report.additionalNotes,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 15),

            // Timestamp Section
            _buildSectionCard(
              title: 'Report Time',
              child: _buildInfoRow(
                Icons.access_time,
                '${widget.report.timestamp.day}/${widget.report.timestamp.month}/${widget.report.timestamp.year} at ${widget.report.timestamp.hour}:${widget.report.timestamp.minute.toString().padLeft(2, '0')}',
              ),
            ),

            const SizedBox(height: 30),

            // Disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This report will be sent to the relevant authorities. You will receive updates on the status of your report.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Submit Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Submitting Report...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isSecondary = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isSecondary ? Colors.grey[600] : const Color(0xFF4CAF50),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSecondary ? 14 : 16,
              color: isSecondary ? Colors.grey[600] : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
