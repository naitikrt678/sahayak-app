import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class VoiceRecordingService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static final FlutterSoundPlayer _player = FlutterSoundPlayer();
  static const _uuid = Uuid();
  static const int maxRecordingDurationSeconds = 60;
  static const int targetBitrate = 32000; // 32 kbps

  static bool _isRecorderInitialized = false;
  static bool _isPlayerInitialized = false;
  static bool _isRecording = false;
  static String? _currentRecordingPath;

  static bool get isRecording => _isRecording;
  static bool get isInitialized =>
      _isRecorderInitialized && _isPlayerInitialized;

  /// Initialize the voice recording service
  static Future<bool> initialize() async {
    try {
      final permissionStatus = await Permission.microphone.request();
      if (!permissionStatus.isGranted) {
        print('Microphone permission denied');
        return false;
      }

      await _recorder.openRecorder();
      _isRecorderInitialized = true;

      await _player.openPlayer();
      _isPlayerInitialized = true;

      print('Voice recording service initialized successfully');
      return true;
    } catch (e) {
      print('Failed to initialize voice recording service: $e');
      return false;
    }
  }

  /// Start recording audio
  static Future<bool> startRecording() async {
    if (!_isRecorderInitialized || _isRecording) return false;

    try {
      final tempDir = await getTemporaryDirectory();
      final filename = '${_uuid.v4()}.m4a';
      _currentRecordingPath = '${tempDir.path}/$filename';

      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
        bitRate: targetBitrate,
        sampleRate: 22050,
        numChannels: 1,
      );

      _isRecording = true;

      // Auto-stop after max duration
      Future.delayed(Duration(seconds: maxRecordingDurationSeconds), () {
        if (_isRecording) stopRecording();
      });

      return true;
    } catch (e) {
      print('Failed to start recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return the recorded file
  static Future<VoiceRecordingResult?> stopRecording() async {
    if (!_isRecording || _currentRecordingPath == null) return null;

    try {
      await _recorder.stopRecorder();
      _isRecording = false;

      final recordedFile = File(_currentRecordingPath!);
      if (!await recordedFile.exists()) return null;

      final fileSize = await recordedFile.length();
      final duration = fileSize / (targetBitrate / 8); // estimate
      final filename = '${_uuid.v4()}.m4a';
      final bytes = await recordedFile.readAsBytes();

      final result = VoiceRecordingResult(
        bytes: bytes,
        filename: filename,
        durationSeconds: duration.clamp(
          0.0,
          maxRecordingDurationSeconds.toDouble(),
        ),
        fileSizeBytes: fileSize,
        tempFilePath: _currentRecordingPath!,
      );

      _currentRecordingPath = null;
      return result;
    } catch (e) {
      print('Failed to stop recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Cancel current recording
  static Future<void> cancelRecording() async {
    if (_isRecording) {
      try {
        await _recorder.stopRecorder();
        _isRecording = false;

        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) await file.delete();
          _currentRecordingPath = null;
        }
      } catch (e) {
        print('Error canceling recording: $e');
      }
    }
  }

  /// Save voice recording to local storage
  static Future<File> saveRecordingLocally(
    Uint8List audioBytes,
    String filename,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/voice_recordings');

      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final file = File('${audioDir.path}/$filename');
      await file.writeAsBytes(audioBytes);
      return file;
    } catch (e) {
      throw Exception('Failed to save voice recording locally: $e');
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    try {
      if (_isRecording) await cancelRecording();
      if (_isRecorderInitialized) {
        await _recorder.closeRecorder();
        _isRecorderInitialized = false;
      }
      if (_isPlayerInitialized) {
        await _player.closePlayer();
        _isPlayerInitialized = false;
      }
    } catch (e) {
      print('Error disposing voice recording service: $e');
    }
  }
}

class VoiceRecordingResult {
  final Uint8List bytes;
  final String filename;
  final double durationSeconds;
  final int fileSizeBytes;
  final String tempFilePath;

  VoiceRecordingResult({
    required this.bytes,
    required this.filename,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.tempFilePath,
  });

  String get durationFormatted {
    final minutes = (durationSeconds ~/ 60);
    final seconds = (durationSeconds % 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
