-- ============================================
-- SAHAYAK CIVIC APP - STORAGE SETUP
-- ============================================
-- This script ensures the storage.objects table exists with proper structure and RLS policies

-- 1. Ensure the 'reports' bucket exists in storage
-- Note: Bucket creation must be done via Supabase Dashboard, but we can ensure it exists via SQL
INSERT INTO storage.buckets (id, name, public) 
SELECT 'reports', 'reports', true 
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'reports');

-- 2. Enable Row Level Security on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Create policy to allow anonymous uploads to 'reports' bucket
CREATE POLICY "Allow anonymous uploads to reports bucket" ON storage.objects
FOR INSERT 
TO anon
WITH CHECK (bucket_id = 'reports');

-- 4. Create policy to allow anonymous reads from 'reports' bucket
CREATE POLICY "Allow anonymous reads from reports bucket" ON storage.objects
FOR SELECT
TO anon
USING (bucket_id = 'reports');

-- 5. Create policy to allow anonymous updates in 'reports' bucket (for overwrites)
CREATE POLICY "Allow anonymous updates in reports bucket" ON storage.objects
FOR UPDATE
TO anon
USING (bucket_id = 'reports')
WITH CHECK (bucket_id = 'reports');

-- 6. Create policy to allow anonymous deletes from 'reports' bucket (for cleanup)
CREATE POLICY "Allow anonymous deletes from reports bucket" ON storage.objects
FOR DELETE
TO anon
USING (bucket_id = 'reports');

-- 7. Ensure proper indexes on storage.objects for performance
CREATE INDEX IF NOT EXISTS idx_storage_objects_bucket_id ON storage.objects(bucket_id);
CREATE INDEX IF NOT EXISTS idx_storage_objects_created_at ON storage.objects(created_at DESC);
