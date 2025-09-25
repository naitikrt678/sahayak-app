import 'package:flutter/material.dart';
import 'dart:io';
import '../models/civic_report.dart';
import '../utils/location_service.dart';
import 'package:location/location.dart' as loc;
import 'details_screen.dart';
import 'voice_recording_screen.dart';
import '../services/voice_recording_service.dart';

class PhotoLocationScreen extends StatefulWidget {
  final CivicReport report;

  const PhotoLocationScreen({super.key, required this.report});

  @override
  State<PhotoLocationScreen> createState() => _PhotoLocationScreenState();
}

class _PhotoLocationScreenState extends State<PhotoLocationScreen> {
  late CivicReport _currentReport;
  final TextEditingController _addressController = TextEditingController();
  bool _isLoadingLocation = false;
  bool _locationDetected = false;
  VoiceRecordingResult? _voiceRecording;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;
    _detectLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Request permission first
      bool hasPermission = await LocationService.requestLocationPermission();
      if (!hasPermission) {
        _showLocationPermissionDialog();
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Show progress message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting your location...'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );

      // Use fast location method first
      loc.LocationData? locationData = await LocationService.getLocationFast();

      if (locationData != null &&
          locationData.latitude != null &&
          locationData.longitude != null) {
        // Update UI with coordinates immediately
        setState(() {
          _currentReport = _currentReport.copyWith(
            latitude: locationData.latitude,
            longitude: locationData.longitude,
          );
          _locationDetected = true;
          _addressController.text = 'Getting address...';
        });

        // Get address in background (non-blocking)
        _getAddressInBackground(
          locationData.latitude!,
          locationData.longitude!,
        );

        setState(() {
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _isLoadingLocation = false;
          _addressController.text = 'Unable to detect location';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _addressController.text = 'Error detecting location';
      });
      print('Error detecting location: $e');
    }
  }

  // Get address in background without blocking UI
  Future<void> _getAddressInBackground(
    double latitude,
    double longitude,
  ) async {
    try {
      String address = await LocationService.getAddressFromCoordinates(
        latitude,
        longitude,
      );

      // Update address when ready
      if (mounted) {
        setState(() {
          _currentReport = _currentReport.copyWith(address: address);
          _addressController.text = address;
        });
      }
    } catch (e) {
      print('Error getting address in background: $e');
      if (mounted) {
        setState(() {
          _addressController.text =
              'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
        });
      }
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Please allow location access to automatically detect your location. You can still enter the address manually.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _addressController.text = 'Enter address manually';
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onAddressChanged(String value) {
    setState(() {
      _currentReport = _currentReport.copyWith(address: value);
    });
  }

  void _navigateToDetails() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or confirm the address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update the report with the final address and voice recording
    final updatedReport = _currentReport.copyWith(
      address: _addressController.text.trim(),
      voiceNotes: _voiceRecording?.tempFilePath ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(
          report: updatedReport,
          voiceRecording: _voiceRecording,
        ),
      ),
    );
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
          'Photo & Location',
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
            // Photo Preview Section
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _currentReport.image != null
                    ? Image.file(_currentReport.image!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[300],
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

            const SizedBox(height: 30),

            // Location Section
            const Text(
              'Location Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 15),

            // GPS Status
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: _locationDetected
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _locationDetected
                      ? const Color(0xFF4CAF50)
                      : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _locationDetected ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _locationDetected
                        ? const Color(0xFF4CAF50)
                        : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isLoadingLocation
                          ? 'Detecting location...'
                          : _locationDetected
                          ? 'Location detected automatically'
                          : 'Location not detected - enter manually',
                      style: TextStyle(
                        color: _locationDetected
                            ? const Color(0xFF4CAF50)
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isLoadingLocation)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Address Field
            const Text(
              'Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              onChanged: _onAddressChanged,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter the exact location of the issue',
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

            if (_currentReport.hasLocation()) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coordinates: ${_currentReport.latitude!.toStringAsFixed(6)}, ${_currentReport.longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Voice Note Section
            const Text(
              'Voice Note (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildVoiceNoteSection(),

            const SizedBox(height: 30),

            // Retry Location Button
            if (!_locationDetected)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                child: OutlinedButton(
                  onPressed: _isLoadingLocation ? null : _detectLocation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Retry Location Detection',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Next Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToDetails,
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
                  'Next: Add Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addVoiceNote() async {
    final result = await Navigator.push<VoiceRecordingResult>(
      context,
      MaterialPageRoute(builder: (context) => const VoiceRecordingScreen()),
    );

    if (result != null) {
      setState(() {
        _voiceRecording = result;
      });
    }
  }

  void _removeVoiceNote() {
    setState(() {
      _voiceRecording = null;
    });
  }

  Widget _buildVoiceNoteSection() {
    if (_voiceRecording == null) {
      return Container(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _addVoiceNote,
          icon: const Icon(Icons.mic, color: Color(0xFF4CAF50)),
          label: const Text(
            'Add Voice Note',
            style: TextStyle(color: Color(0xFF4CAF50)),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            side: const BorderSide(color: Color(0xFF4CAF50)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mic, color: Color(0xFF4CAF50), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice note recorded (${_voiceRecording!.durationFormatted})',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: _removeVoiceNote,
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${_voiceRecording!.fileSizeFormatted}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
