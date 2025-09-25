import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'photo_location_screen.dart';
import 'about_app_screen.dart';
import '../services/media_service.dart';
import '../models/civic_report.dart';
import 'dart:io';

enum ImageSourceType { camera, gallery }

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const MapScreen(),
      const ProfileScreen(), // Profile screen moved to center
      const HistoryScreen(),
      const AboutAppScreen(), // About App screen at the end
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Photo Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _handleImageSource(ImageSourceType.camera),
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _handleImageSource(ImageSourceType.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF4CAF50)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSource(ImageSourceType sourceType) async {
    Navigator.pop(context); // Close the bottom sheet

    File? imageFile;

    if (sourceType == ImageSourceType.camera) {
      // Request camera permission and take photo
      bool hasPermission = await MediaService.requestCameraPermission();
      if (hasPermission) {
        imageFile = await MediaService.takePhoto();
      } else {
        _showPermissionDeniedDialog('Camera');
        return;
      }
    } else {
      // Request gallery permission and pick image
      bool hasPermission = await MediaService.requestGalleryPermission();
      if (hasPermission) {
        imageFile = await MediaService.pickFromGallery();
      } else {
        _showPermissionDeniedDialog('Gallery');
        return;
      }
    }

    if (imageFile != null) {
      // Create a new civic report and navigate to photo location screen
      CivicReport report = CivicReport(image: imageFile);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoLocationScreen(report: report),
        ),
      );
    }
  }

  void _showPermissionDeniedDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionType Permission Required'),
          content: Text('Please allow $permissionType access to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80, // Increased by 5 more pixels to fix overflow
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                    isActive: _currentIndex == 0,
                  ),
                ),
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.map,
                    label: 'Map',
                    index: 1,
                    isActive: _currentIndex == 1,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildCenterProfileButton(),
                ),
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.history,
                    label: 'History',
                    index: 3,
                    isActive: _currentIndex == 3,
                  ),
                ),
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.info_outline,
                    label: 'About',
                    index: 4,
                    isActive: _currentIndex == 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        height: 54, // Following overflow prevention guidelines
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? const Color(0xFF4CAF50) : Colors.grey[500],
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9, // Slightly smaller to prevent overflow
                  color: isActive ? const Color(0xFF4CAF50) : Colors.grey[500],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterProfileButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        height: 54, // Match other nav items height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, // Further reduced to fit better
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x404CAF50),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 2),
            const Flexible(
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 9, // Reduced to match other labels
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
