# Civic App - Sahayak Flutter Prototype

A Flutter prototype app for citizens to report civic issues such as potholes, garbage collection problems, and other community concerns. This is a UI-focused prototype without backend integration.

## Features

- **Photo Capture**: Take photos using camera or select from gallery
- **Location Detection**: Automatic GPS location detection with manual address editing
- **Problem Categorization**: Select from predefined problem categories
- **Detailed Reporting**: Add descriptions, voice notes (placeholder), and additional notes
- **Report Summary**: Review all details before submission
- **Confirmation Screen**: Success confirmation with next steps

## App Flow

1. **Home Screen**: Welcome screen with "Report a New Problem" button
2. **Image Selection**: Choose between camera or gallery for photo capture
3. **Photo & Location**: Preview photo and confirm/edit location details
4. **Report Details**: Add category, description, voice notes, and additional information
5. **Summary Screen**: Review all report details with edit option
6. **Confirmation**: Success message with option to submit another report

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── civic_report.dart       # Data model for civic reports
├── screens/
│   ├── home_screen.dart         # Main landing screen
│   ├── photo_location_screen.dart # Photo preview and location
│   ├── details_screen.dart      # Report details form
│   ├── summary_screen.dart      # Report summary and review
│   └── confirmation_screen.dart # Success confirmation
├── utils/
│   ├── image_service.dart       # Camera and gallery utilities
│   └── location_service.dart    # GPS and geocoding services
└── widgets/                     # (Future: Reusable UI components)
```

## Dependencies

- `image_picker`: Camera and gallery access
- `camera`: Camera functionality
- `location`: GPS location services
- `geocoding`: Address from coordinates
- `permission_handler`: Handle app permissions

## Getting Started

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Android Studio or VS Code with Flutter extension
- Android emulator or physical device for testing

### Installation

1. **Clone or navigate to the project directory**:
   ```bash
   cd c:\Users\beher\civic_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android
- Ensure Android SDK is installed
- Connect a physical device or start an emulator
- Camera and location permissions will be requested automatically

#### iOS (if needed)
- Requires Xcode and iOS simulator
- Additional permission configurations may be needed in `ios/Runner/Info.plist`

## Key Features Details

### Camera & Gallery Access
- Automatic permission handling
- Image quality optimization (80% quality, max 1080x1080)
- Support for both camera capture and gallery selection

### Location Services
- Automatic GPS detection
- Address geocoding from coordinates
- Manual address editing capability
- Permission handling with user-friendly dialogs

### Voice Notes
- Placeholder implementation for voice recording
- Visual feedback for recording state
- Play button simulation (prototype only)

### Report Management
- Unique report ID generation
- Timestamp tracking
- Data validation before navigation
- Edit capability from summary screen

## Prototype Limitations

This is a UI prototype designed to demonstrate the user flow and interface design. The following features are placeholder implementations:

- **No Backend Integration**: Reports are not actually sent to any server
- **No Database**: No local or remote data persistence
- **Voice Notes**: Visual placeholder only, no actual audio recording
- **Authentication**: Not implemented in this prototype
- **Real Submission**: Submit button shows success without actual data transmission

## Future Enhancements

To make this a production-ready app, consider adding:

1. **Backend Integration**:
   - REST API for report submission
   - Government portal integration
   - Status tracking system

2. **Authentication**:
   - User registration and login
   - Profile management
   - Report history

3. **Data Persistence**:
   - Local storage for drafts
   - Offline support
   - Sync capabilities

4. **Advanced Features**:
   - Real voice note recording
   - Multiple photo attachments
   - Report status notifications
   - Community features

5. **Administration**:
   - Admin panel for authorities
   - Report assignment and tracking
   - Analytics and reporting

## Troubleshooting

### Common Issues

1. **Permission Denied**: 
   - Ensure camera and location permissions are granted
   - Check device settings if permissions are blocked

2. **Location Not Detected**:
   - Verify GPS is enabled on device
   - Try manual address entry if automatic detection fails

3. **Build Issues**:
   - Run `flutter clean` and `flutter pub get`
   - Ensure all dependencies are compatible

### Performance Tips

- Test on physical devices for best camera and location performance
- Consider reducing image quality for better performance on older devices
- Location detection may take longer indoors or in areas with poor GPS signal

## Color Scheme

The app uses a green-based color scheme representing growth and civic responsibility:
- Primary Color: `#4CAF50` (Green)
- Background: `#E8F5E8` (Light Green)
- Text: Various shades of black and gray
- Success/Confirmation: Green tones
- Warning/Info: Orange and blue accents

## Contributing

This is a prototype project. For production development, consider:
- Following Flutter best practices
- Implementing proper state management (Provider, Bloc, etc.)
- Adding comprehensive testing
- Following accessibility guidelines
- Implementing proper error handling

## License

This is a prototype project for demonstration purposes.