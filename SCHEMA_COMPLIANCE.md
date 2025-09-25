# 📋 Sahayak App Database Schema Compliance Guide

This document outlines the exact database schema requirements and validation implemented in the Sahayak civic app.

## ✅ Schema Compliance Implementation

### 🗃️ **Reports Table**
All field names match your exact specifications:

| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| `request_id` | BIGSERIAL | PRIMARY KEY | Auto-generated unique identifier |
| `serial_number` | SERIAL | UNIQUE NOT NULL | Auto-generated sequential number |
| `category` | TEXT | NOT NULL | Report category |
| `area` | TEXT | NOT NULL | Geographic area |
| `time` | TEXT | NOT NULL | Time of report |
| `date` | TEXT | NOT NULL | Date of report |
| `status` | TEXT | CHECK constraint | Must be: 'pending', 'in-process', 'completed' |
| `description` | TEXT | NOT NULL | Report description |
| `geolocation_lat` | DECIMAL(10,8) | NOT NULL | Latitude with 8 decimal precision |
| `geolocation_long` | DECIMAL(11,8) | NOT NULL | Longitude with 8 decimal precision |
| `address` | TEXT | NOT NULL | Address description |
| `additional_notes` | TEXT | NULLABLE | Additional information |
| `landmarks` | TEXT | NULLABLE | Nearby landmarks |
| `urgency` | TEXT | CHECK constraint | Must be: 'low', 'medium', 'high', 'critical' |
| `image_url` | TEXT | NOT NULL | URL to uploaded image |
| `voice_url` | TEXT | NULLABLE | URL to uploaded voice note |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Auto-generated timestamp |

### 👷 **Workers Table**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Auto-generated unique identifier |
| `name` | TEXT | NOT NULL | Worker name |
| `category` | TEXT | NOT NULL | Worker specialty category |
| `contact` | TEXT | NOT NULL | Contact information |
| `area` | TEXT | NOT NULL | Service area |
| `available` | BOOLEAN | DEFAULT true | Availability status |

### 🚀 **Dispatched Workers Table**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| `id` | BIGSERIAL | PRIMARY KEY | Auto-generated unique identifier |
| `worker_id` | BIGINT | REFERENCES workers(id) | Foreign key to workers |
| `report_id` | BIGINT | REFERENCES reports(request_id) | Foreign key to reports |
| `dispatched_at` | TIMESTAMP | DEFAULT NOW() | Dispatch timestamp |
| `estimated_completion` | TIMESTAMP | NULLABLE | Expected completion time |
| `status` | TEXT | CHECK constraint | Must be: 'active', 'completed', 'delayed' |
| `progress` | INTEGER | CHECK (0-100) | Progress percentage |

## 🔒 **Data Validation**

### Status Validation
The app implements strict validation for all enum-like fields:

```dart
// Valid values enforced by the app
static const List<String> validReportStatuses = ['pending', 'in-process', 'completed'];
static const List<String> validUrgencyLevels = ['low', 'medium', 'high', 'critical'];
static const List<String> validDispatchedWorkerStatuses = ['active', 'completed', 'delayed'];
```

### Coordinate Validation
- **Latitude**: Must be between -90 and 90 degrees
- **Longitude**: Must be between -180 and 180 degrees
- **Precision**: Database stores up to 8 decimal places for coordinates

### Progress Validation
- **Range**: Must be between 0 and 100 (inclusive)
- **Type**: Integer values only

## 🌐 **API Methods Available**

### Reports Operations
```dart
// Insert new report with validation
SupabaseReportsService.insertReport(...)

// Update report status (validated)
SupabaseReportsService.updateReportStatus(requestId, newStatus)

// Query operations
SupabaseReportsService.getAllReports()
SupabaseReportsService.getReportsByStatus(status)
SupabaseReportsService.getReportById(requestId)
```

### Workers Operations
```dart
// Worker management
SupabaseReportsService.insertWorker(...)
SupabaseReportsService.getAllWorkers()
SupabaseReportsService.getAvailableWorkers(category: '...', area: '...')
SupabaseReportsService.updateWorkerAvailability(workerId, available)
```

### Dispatched Workers Operations
```dart
// Dispatch management
SupabaseReportsService.dispatchWorker(...)
SupabaseReportsService.updateDispatchedWorkerStatus(...)
SupabaseReportsService.getDispatchedWorkersForReport(reportId)
SupabaseReportsService.getAllDispatchedWorkers()
```

## 🗂️ **Storage Structure**

Files follow exact path conventions:
```
reports/
├── images/
│   └── {uuid}.jpg (JPEG, max 1280px, 70% quality)
└── audio/
    ├── {uuid}.m4a (AAC, ~32kbps, max 60s)
    └── {uuid}.ogg (Opus alternative)
```

## ⚡ **Performance Optimizations**

The schema includes proper indexing:
```sql
-- Performance indexes
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_urgency ON reports(urgency);
CREATE INDEX idx_reports_category ON reports(category);
CREATE INDEX idx_reports_area ON reports(area);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);
```

## 🔐 **Row Level Security (RLS)**

Proper security policies are implemented:
- **Public read access** for reports
- **Authenticated insert** for new reports
- **Admin-only updates** for reports
- **Admin-only access** for workers and dispatched_workers tables

## ✅ **Implementation Status**

- ✅ **Exact field names** match your specifications
- ✅ **Data type constraints** properly enforced
- ✅ **Validation functions** implemented in app
- ✅ **CHECK constraints** defined in database schema
- ✅ **Foreign key relationships** properly established
- ✅ **Storage path structure** follows conventions
- ✅ **Performance indexes** created
- ✅ **Security policies** implemented

## 🚀 **Ready for Production**

The schema is now fully compliant with your exact specifications and ready for production use. All database operations include proper validation and error handling to ensure data integrity.