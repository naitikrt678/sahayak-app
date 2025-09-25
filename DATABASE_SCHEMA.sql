-- ============================================
-- SAHAYAK CIVIC APP - DATABASE SCHEMA
-- ============================================
-- This file contains the exact database schema required for the Sahayak app
-- All field names and constraints must match these specifications exactly

-- ============================================
-- REPORTS TABLE
-- ============================================
CREATE TABLE reports (
    -- Primary keys for compatibility with admin portal
    id BIGSERIAL PRIMARY KEY,  -- Admin portal expects 'id' field
    request_id BIGINT UNIQUE NOT NULL DEFAULT nextval('reports_id_seq'),  -- Citizen app uses 'request_id'
    serial_number SERIAL UNIQUE NOT NULL,
    
    -- Report classification
    category TEXT NOT NULL,
    area TEXT NOT NULL,
    
    -- Temporal data
    time TEXT NOT NULL,
    date TEXT NOT NULL,
    
    -- Status tracking
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in-process', 'completed')),
    
    -- Report content
    description TEXT NOT NULL,
    
    -- Location data (with precise decimal constraints)
    geolocation_lat DECIMAL(10, 8) NOT NULL,
    geolocation_long DECIMAL(11, 8) NOT NULL,
    address TEXT NOT NULL,
    
    -- Additional information
    additional_notes TEXT,
    landmarks TEXT,
    
    -- Priority classification
    urgency TEXT NOT NULL DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high', 'critical')),
    
    -- Media URLs
    image_url TEXT NOT NULL,
    voice_url TEXT,
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- WORKERS TABLE
-- ============================================
CREATE TABLE workers (
    -- Primary identifier (TEXT for admin portal compatibility)
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    
    -- Worker information
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    contact TEXT NOT NULL,
    area TEXT NOT NULL,
    
    -- Availability status
    available BOOLEAN DEFAULT true
);

-- ============================================
-- DISPATCHED_WORKERS TABLE
-- ============================================
CREATE TABLE dispatched_workers (
    -- Primary identifier (TEXT for admin portal compatibility)
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    
    -- Foreign key relationships
    worker_id TEXT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    report_id BIGINT NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    
    -- Dispatch tracking
    dispatched_at TIMESTAMP DEFAULT NOW(),
    estimated_completion TIMESTAMP,
    
    -- Status tracking
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'delayed')),
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_urgency ON reports(urgency);
CREATE INDEX idx_reports_category ON reports(category);
CREATE INDEX idx_reports_area ON reports(area);
CREATE INDEX idx_reports_created_at ON reports(created_at DESC);

CREATE INDEX idx_workers_category ON workers(category);
CREATE INDEX idx_workers_area ON workers(area);
CREATE INDEX idx_workers_available ON workers(available);

CREATE INDEX idx_dispatched_workers_status ON dispatched_workers(status);
CREATE INDEX idx_dispatched_workers_worker_id ON dispatched_workers(worker_id);
CREATE INDEX idx_dispatched_workers_report_id ON dispatched_workers(report_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispatched_workers ENABLE ROW LEVEL SECURITY;

-- Public read access for reports
CREATE POLICY "Public can view reports" ON reports
    FOR SELECT USING (true);

-- Authenticated users can insert reports
CREATE POLICY "Authenticated users can insert reports" ON reports
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- Admin-only update for reports
CREATE POLICY "Admin can update reports" ON reports
    FOR UPDATE TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Workers table policies (admin access only)
CREATE POLICY "Admin can manage workers" ON workers
    FOR ALL TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- Dispatched workers table policies (admin access only)
CREATE POLICY "Admin can manage dispatched workers" ON dispatched_workers
    FOR ALL TO authenticated
    USING (auth.jwt() ->> 'role' = 'admin');

-- ============================================
-- STORAGE BUCKET SETUP
-- ============================================
-- Run these commands in Supabase Dashboard > Storage
-- 1. Create bucket named 'reports'
-- 2. Set public access for read operations
-- 3. Directory structure will be:
--    reports/
--    ├── images/
--    │   └── {uuid}.jpg
--    └── audio/
--        └── {uuid}.m4a (or .ogg)

-- ============================================
-- REAL-TIME SUBSCRIPTIONS
-- ============================================
-- Enable real-time on reports table
ALTER PUBLICATION supabase_realtime ADD TABLE reports;

-- ============================================
-- CONSTRAINTS SUMMARY
-- ============================================
-- status in reports: Must be one of ('pending', 'in-process', 'completed')
-- urgency in reports: Must be one of ('low', 'medium', 'high', 'critical')
-- status in dispatched_workers: Must be one of ('active', 'completed', 'delayed')
-- geolocation_lat: DECIMAL(10, 8) - allows values like -90.12345678
-- geolocation_long: DECIMAL(11, 8) - allows values like -180.12345678