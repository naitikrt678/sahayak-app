# Upload Troubleshooting Guide

## Common Upload Failure Causes & Solutions

### 1. 🪣 **Storage Bucket Issues**

**Problem**: The "reports" bucket doesn't exist in Supabase Storage.

**Symptoms**:
- Upload fails immediately
- Error: "The resource was not found"
- Storage connection test fails

**Solution**:
1. Go to your Supabase Dashboard → Storage
2. Create a new bucket named "reports"
3. Set the bucket to **Public** (for read access to uploaded files)
4. Configure bucket policies:

```sql
-- Allow authenticated and anonymous users to upload files
INSERT INTO storage.buckets (id, name, public)
VALUES ('reports', 'reports', true);

-- Allow anyone to upload to images/ and audio/ folders
INSERT INTO storage.objects (bucket_id, name, owner)
VALUES ('reports', 'images/', null);

INSERT INTO storage.objects (bucket_id, name, owner) 
VALUES ('reports', 'audio/', null);
```

### 2. 🔐 **Database RLS Policy Issues**

**Problem**: Row Level Security blocks anonymous users from inserting reports.

**Symptoms**:
- Upload progresses but fails at database insertion
- Error: "new row violates row-level security policy"

**Solution**:
```sql
-- Disable RLS temporarily to test (NOT recommended for production)
ALTER TABLE reports DISABLE ROW LEVEL SECURITY;

-- OR create proper RLS policies (RECOMMENDED)
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users to insert reports
CREATE POLICY "Allow anonymous insert reports" ON reports
    FOR INSERT TO anon
    WITH CHECK (true);

-- Allow anonymous users to read their own reports
CREATE POLICY "Allow anonymous read reports" ON reports
    FOR SELECT TO anon
    USING (true);
```

### 3. 📊 **Database Schema Issues**

**Problem**: The reports table doesn't exist or has wrong column types.

**Symptoms**:
- Error: "relation 'reports' does not exist"
- Error: "column 'xyz' does not exist"

**Solution**: Run the complete schema from `DATABASE_SCHEMA.sql`:

```sql
-- Create reports table with exact schema
CREATE TABLE IF NOT EXISTS reports (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT UNIQUE NOT NULL DEFAULT nextval('reports_id_seq'),
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
```

### 4. 🌐 **Network & Connectivity Issues**

**Problem**: Network issues or API rate limits.

**Symptoms**:
- Intermittent upload failures
- Timeouts during upload
- "Network error" messages

**Solution**:
1. Check internet connectivity
2. Verify Supabase URL and API key in `.env`
3. Check Supabase project status
4. Implement retry logic (already implemented in upload queue)

### 5. 📱 **App Configuration Issues**

**Problem**: App is in mock mode or wrong environment settings.

**Symptoms**:
- Upload appears successful but data isn't in Supabase
- Files saved locally only

**Solution**:
1. Check `.env` file:
```env
USE_MOCK_DATA=false
```

2. Or toggle in app: Profile → Settings → "Use Mock Data" = OFF

### 6. 🔧 **Upload Queue Problems**

**Problem**: Upload queue gets stuck or corrupted.

**Symptoms**:
- Reports stuck in "uploading" state
- Queue shows pending items but nothing happens

**Solution**:
```dart
// Clear upload queue (add this as a debug option)
await UploadQueueService.clearCompletedUploads();
await UploadQueueService.retryFailedUploads();
```

## 🧪 **Testing Upload Functionality**

### Quick Test Checklist:
1. ✅ Supabase URL and API key are correct
2. ✅ "reports" bucket exists and is public
3. ✅ "reports" table exists with correct schema
4. ✅ RLS policies allow anonymous inserts
5. ✅ App is in live mode (not mock mode)
6. ✅ Internet connection is stable

### Debug Steps:
1. **Test Connection**: Go to Profile → Supabase Status to see connection details
2. **Check Logs**: Look at Flutter console for specific error messages
3. **Test Upload**: Try uploading a simple report and monitor progress
4. **Verify Data**: Check Supabase Dashboard for uploaded files and database records

## 🚨 **Emergency Fixes**

### Quick Fix for Immediate Testing:
```sql
-- Temporary: Disable all security (UNSAFE - for testing only)
ALTER TABLE reports DISABLE ROW LEVEL SECURITY;

-- Create bucket if missing
INSERT INTO storage.buckets (id, name, public) 
VALUES ('reports', 'reports', true) 
ON CONFLICT (id) DO NOTHING;
```

### Production-Ready Fix:
```sql
-- Enable proper RLS policies
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anonymous can insert reports" ON reports
    FOR INSERT TO anon
    WITH CHECK (true);

CREATE POLICY "Users can read all reports" ON reports
    FOR SELECT TO anon, authenticated
    USING (true);
```

## 📞 **Getting Help**

If uploads still fail after these fixes:
1. Check the Flutter console for specific error messages
2. Verify Supabase Dashboard shows the bucket and table
3. Test with a simple curl request to isolate the issue
4. Check Supabase logs in the Dashboard → Logs section

Most upload issues are resolved by ensuring the storage bucket exists and RLS policies allow anonymous users to insert data.