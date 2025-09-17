import 'dart:io';

class CivicReport {
  File? image;
  String? imagePath;
  double? latitude;
  double? longitude;
  String address;
  String description;
  String voiceNotes;
  String additionalNotes;
  String category;
  DateTime timestamp;

  CivicReport({
    this.image,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.address = '',
    this.description = '',
    this.voiceNotes = '',
    this.additionalNotes = '',
    this.category = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Helper method to check if location is available
  bool hasLocation() {
    return latitude != null && longitude != null;
  }

  // Helper method to check if report is complete
  bool isComplete() {
    return (image != null || imagePath?.isNotEmpty == true) &&
        address.isNotEmpty &&
        description.isNotEmpty;
  }

  // Create a copy with updated values
  CivicReport copyWith({
    File? image,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? address,
    String? description,
    String? voiceNotes,
    String? additionalNotes,
    String? category,
    DateTime? timestamp,
  }) {
    return CivicReport(
      image: image ?? this.image,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      description: description ?? this.description,
      voiceNotes: voiceNotes ?? this.voiceNotes,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
