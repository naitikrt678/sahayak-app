import 'package:flutter/material.dart';
import 'dart:async';
import '../services/voice_recording_service.dart';

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  bool _isRecording = false;
  bool _isInitialized = false;
  double _recordingDuration = 0.0;
  Timer? _timer;
  VoiceRecordingResult? _lastRecording;

  @override
  void initState() {
    super.initState();
    _initializeRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeRecording() async {
    final initialized = await VoiceRecordingService.initialize();
    setState(() {
      _isInitialized = initialized;
    });

    if (!initialized) {
      _showErrorDialog(
        'Failed to initialize voice recording. Please check microphone permissions.',
      );
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized) return;

    final success = await VoiceRecordingService.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _recordingDuration = 0.0;
      });

      // Start timer to update duration
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _recordingDuration += 0.1;
        });

        // Auto-stop at max duration
        if (_recordingDuration >=
            VoiceRecordingService.maxRecordingDurationSeconds) {
          _stopRecording();
        }
      });
    } else {
      _showErrorDialog(
        'Failed to start recording. Please check microphone permissions.',
      );
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    final result = await VoiceRecordingService.stopRecording();
    setState(() {
      _isRecording = false;
      _lastRecording = result;
    });

    if (result == null) {
      _showErrorDialog('Failed to save recording. Please try again.');
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await VoiceRecordingService.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0.0;
    });
  }

  void _saveRecording() {
    if (_lastRecording != null) {
      Navigator.pop(context, _lastRecording);
    }
  }

  void _discardRecording() {
    setState(() {
      _lastRecording = null;
      _recordingDuration = 0.0;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds ~/ 60);
    final remainingSeconds = (seconds % 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
          'Voice Note',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Recording indicator
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red.withOpacity(0.1)
                          : const Color(0xFF4CAF50).withOpacity(0.1),
                      border: Border.all(
                        color: _isRecording
                            ? Colors.red
                            : const Color(0xFF4CAF50),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 80,
                        color: _isRecording
                            ? Colors.red
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Duration display
                  Text(
                    _formatDuration(_recordingDuration),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Max duration info
                  Text(
                    'Max ${VoiceRecordingService.maxRecordingDurationSeconds}s',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 40),

                  // Recording controls
                  if (!_isRecording && _lastRecording == null) ...[
                    // Start recording button
                    ElevatedButton(
                      onPressed: _startRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                      ),
                      child: const Icon(Icons.mic, size: 30),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tap to start recording',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ] else if (_isRecording) ...[
                    // Stop and cancel buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _cancelRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(15),
                          ),
                          child: const Icon(Icons.close, size: 25),
                        ),
                        ElevatedButton(
                          onPressed: _stopRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(Icons.stop, size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Recording... Tap stop when done',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (_lastRecording != null) ...[
                    // Playback and save/discard options
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recording saved (${_lastRecording!.durationFormatted})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Size: ${_lastRecording!.fileSizeFormatted}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _discardRecording,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text(
                              'Discard',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text('Use Recording'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        SizedBox(height: 8),
                        Text(
                          'Add a voice note to provide additional details about your report. Keep it brief and clear.',
                          style: TextStyle(fontSize: 14, color: Colors.blue),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
