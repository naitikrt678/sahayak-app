import 'dart:io';
import 'package:flutter/material.dart';

class CivicReport {
  String? id;
  int? serialNumber;
  String? requestId;
  File? image;
  String? imagePath;
  String? imageUrl;
  double? latitude;
  double? longitude;
  String address;
  String description;
  String voiceNotes;
  String additionalNotes;
  String category;
  String area;
  String time;
  String date;
  String status;
  String urgency;
  String? landmarks;
  DateTime timestamp;

  CivicReport({
    this.id,
    this.serialNumber,
    this.requestId,
    this.image,
    this.imagePath,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.address = '',
    this.description = '',
    this.voiceNotes = '',
    this.additionalNotes = '',
    this.category = '',
    this.area = '',
    this.time = '',
    this.date = '',
    this.status = 'pending',
    this.urgency = 'medium',
    this.landmarks,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Helper method to check if location is available
  bool hasLocation() {
    return latitude != null && longitude != null;
  }

  // Helper method to check if report is complete
  bool isComplete() {
    return (image != null ||
            imagePath?.isNotEmpty == true ||
            imageUrl?.isNotEmpty == true) &&
        address.isNotEmpty &&
        description.isNotEmpty;
  }

  // Create a copy with updated values
  CivicReport copyWith({
    String? id,
    int? serialNumber,
    String? requestId,
    File? image,
    String? imagePath,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? description,
    String? voiceNotes,
    String? additionalNotes,
    String? category,
    String? area,
    String? time,
    String? date,
    String? status,
    String? urgency,
    String? landmarks,
    DateTime? timestamp,
  }) {
    return CivicReport(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      requestId: requestId ?? this.requestId,
      image: image ?? this.image,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      description: description ?? this.description,
      voiceNotes: voiceNotes ?? this.voiceNotes,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      category: category ?? this.category,
      area: area ?? this.area,
      time: time ?? this.time,
      date: date ?? this.date,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      landmarks: landmarks ?? this.landmarks,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Create from JSON data
  factory CivicReport.fromJson(Map<String, dynamic> json) {
    return CivicReport(
      id: json['id'],
      serialNumber: json['serialNumber'],
      requestId: json['requestId'],
      imageUrl: json['image'],
      latitude: json['geolocation']?['lat']?.toDouble(),
      longitude: json['geolocation']?['lng']?.toDouble(),
      address: json['geolocation']?['address'] ?? '',
      description: json['description'] ?? '',
      additionalNotes: json['additionalNotes'] ?? '',
      category: json['category'] ?? '',
      area: json['area'] ?? '',
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
      urgency: json['urgency'] ?? 'medium',
      landmarks: json['landmarks'],
      timestamp: _parseDate(json['date'], json['time']),
    );
  }

  // Helper method to parse date and time
  static DateTime _parseDate(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();

    try {
      // Parse date format: "15/03/2025"
      final dateParts = dateStr.split('/');
      if (dateParts.length == 3) {
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);

        int hour = 0;
        int minute = 0;

        // Parse time format: "10:30 AM"
        if (timeStr != null && timeStr.isNotEmpty) {
          final timePattern = RegExp(
            r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
            caseSensitive: false,
          );
          final match = timePattern.firstMatch(timeStr);
          if (match != null) {
            hour = int.parse(match.group(1)!);
            minute = int.parse(match.group(2)!);
            final ampm = match.group(3)?.toUpperCase();

            if (ampm == 'PM' && hour != 12) hour += 12;
            if (ampm == 'AM' && hour == 12) hour = 0;
          }
        }

        return DateTime(year, month, day, hour, minute);
      }
    } catch (e) {
      // If parsing fails, return current time
    }

    return DateTime.now();
  }

  // Get urgency color
  static Color getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F2F); // Red
      case 'high':
        return const Color(0xFFFF9800); // Orange
      case 'medium':
        return const Color(0xFF1976D2); // Blue
      case 'low':
        return const Color(0xFF388E3C); // Green
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  // Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'in-process':
        return const Color(0xFF1976D2); // Blue
      case 'completed':
        return const Color(0xFF388E3C); // Green
      default:
        return const Color(0xFF757575); // Grey
    }
  }
}
