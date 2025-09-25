# Supabase Integration Implementation Summary

This document outlines the complete integration of Supabase into the Flutter civic app with mock data toggle functionality.

## 🏗️ Architecture Overview

The app now supports dual-mode operation:
- **Live Mode**: Full Supabase integration with real-time updates
- **Mock Mode**: Local data simulation for development/testing

## 📋 Implemented Features

### 1. Environment Configuration
- **File**: `.env` (template provided)
- **Service**: `environment_service.dart`
- **Variables**:
  - `SUPABASE_URL`: Your Supabase project URL
  - `SUPABASE_ANON_KEY`: Your Supabase anonymous key
  - `REPORTS_BUCKET`: Storage bucket name (default: "reports")

### 2. Core Services

#### Supabase Integration
- **`supabase_service.dart`**: Core Supabase client management
- **`supabase_reports_service.dart`**: Database operations for reports table
- **`supabase_storage_service.dart`**: File upload to Supabase Storage

#### Media Processing
- **`image_compression_service.dart`**: Image compression (max 1280px, JPEG 70%)
- **`voice_recording_service.dart`**: Voice recording and compression (max 60s, AAC 32kbps)

#### Upload Management
- **`upload_service.dart`**: Unified upload orchestration
- **`upload_queue_service.dart`**: Retry queue with exponential backoff
- **Offline Support**: Local storage with automatic sync when online

#### Real-time & Notifications
- **`realtime_service.dart`**: Supabase real-time subscriptions
- **`notification_service.dart`**: Local push notifications
- **Status Updates**: Automatic notifications when report status changes

#### Data Management
- **`data_service.dart`**: Unified data access (mock vs live)
- **`settings_service.dart`**: User preferences management

### 3. Database Schema Compliance

The app inserts records into the `reports` table with exact field mapping:

```sql
-- Required Supabase table structure (EXACT field names required)
CREATE TABLE reports (
  request_id BIGSERIAL PRIMARY KEY,
  serial_number SERIAL UNIQUE NOT NULL,
  category TEXT NOT NULL,
  area TEXT NOT NULL,
  time TEXT NOT NULL,
  date TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in-process', 'completed')),
  description TEXT NOT NULL,
  geolocation_lat DECIMAL(10, 8) NOT NULL,
  geolocation_long DECIMAL(11, 8) NOT NULL,
  address TEXT NOT NULL,
  additional_notes TEXT,
  landmarks TEXT,
  urgency TEXT NOT NULL DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high', 'critical')),
  image_url TEXT NOT NULL,
  voice_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Workers table structure
CREATE TABLE workers (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  contact TEXT NOT NULL,
  area TEXT NOT NULL,
  available BOOLEAN DEFAULT true
);

-- Dispatched workers table structure
CREATE TABLE dispatched_workers (
  id BIGSERIAL PRIMARY KEY,
  worker_id BIGINT NOT NULL REFERENCES workers(id),
  report_id BIGINT NOT NULL REFERENCES reports(request_id),
  dispatched_at TIMESTAMP DEFAULT NOW(),
  estimated_completion TIMESTAMP,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'delayed')),
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100)
);
```
```

### 4. Storage Structure

Files are uploaded to the `reports` bucket with UUID-based naming following exact directory structure:
```
reports/
├── images/
│   └── {uuid}.jpg (compressed JPEG, max 1280px, 70% quality)
└── audio/
    └── {uuid}.m4a (AAC compressed, ~32kbps, max 60s)
    └── {uuid}.ogg (Opus compressed alternative)
```

**Path Format Requirements:**
- Images: `reports/images/{uuid}.jpg`
- Voice notes: `reports/audio/{uuid}.m4a` or `reports/audio/{uuid}.ogg`
- All filenames must use UUID format for uniqueness

### 5. UI Enhancements

#### New Screens
- **`settings_screen.dart`**: Mock data toggle and app preferences
- **`voice_recording_screen.dart`**: Voice note recording interface

#### Updated Screens
- **`photo_location_screen.dart`**: Added voice recording capability
- **`home_screen.dart`**: Integrated with new data service
- **`profile_screen.dart`**: Added settings navigation

## 🔧 Setup Instructions

### 1. Environment Configuration

1. Update `.env` file with your Supabase credentials:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
REPORTS_BUCKET=reports
```

2. Create the required table and storage bucket in Supabase.

### 2. Storage Bucket Setup

In Supabase Dashboard:
1. Go to Storage
2. Create bucket named "reports"
3. Set appropriate permissions for public read access

### 3. Real-time Setup

Enable real-time on the `reports` table:
```sql
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
```

## 🎯 Usage Flows

### Report Submission Flow

1. **Photo Capture**: User takes photo or selects from gallery
2. **Location Detection**: Automatic GPS location with manual override
3. **Voice Note (Optional)**: Record up to 60-second voice note
4. **Report Details**: Category, description, urgency selection
5. **Upload Process**:
   - **Live Mode**: Files compressed and queued for Supabase upload
   - **Mock Mode**: Files saved locally for simulation

### Mock Data Toggle

In Profile → Settings:
- **"Use Mock Data"**: Switch between live and mock modes
- **"Accept Admin Test Updates"**: Receive real-time updates even in mock mode

## 🔄 Real-time Updates

When in live mode:
- App subscribes to `reports` table changes
- Status updates trigger local notifications
- Automatic retry on connection restore

## 📱 Platform Support

- **Android**: Full functionality including notifications
- **iOS**: Full functionality including notifications  
- **Web**: Limited (no Image.file support, notification differences)

## 🛠️ Development Tools

### Debug Features
- Connection status indicators in Settings
- Upload queue status monitoring
- Comprehensive error logging
- Mock/live mode switching

### Testing
- Mock data available for offline development
- Upload queue visualization
- Real-time connection testing

## 🚀 Deployment Notes

1. Ensure all environment variables are set
2. Test both mock and live modes
3. Verify Supabase permissions and RLS policies
4. Test notification permissions on target devices

## 📊 Monitoring

The app provides visibility into:
- Upload queue status (pending, uploading, completed, failed)
- Connection status (Supabase and real-time)
- Data source mode (mock vs live)
- Notification delivery status

This implementation provides a robust, scalable foundation for civic engagement with seamless development and production workflows.