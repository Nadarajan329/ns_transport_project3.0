-- -- Supabase Setup Script for NS Transport 3.0

-- Create custom types (optional, can also use TEXT)
-- CREATE TYPE user_role AS ENUM ('owner', 'driver');
-- CREATE TYPE trip_status AS ENUM ('draft', 'submitted', 'approved', 'rejected');

-- Users table
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'driver' NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Trips table
CREATE TABLE public.trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  vehicle_number TEXT NOT NULL,
  trip_date DATE NOT NULL,
  from_location TEXT NOT NULL,
  to_location TEXT NOT NULL,
  load_type TEXT,
  customer_name TEXT NOT NULL,
  rent_amount NUMERIC(10,2) DEFAULT 0 NOT NULL,
  fuel_expense NUMERIC(10,2) DEFAULT 0 NOT NULL,
  toll_expense NUMERIC(10,2) DEFAULT 0 NOT NULL,
  food_expense NUMERIC(10,2) DEFAULT 0 NOT NULL,
  other_expense NUMERIC(10,2) DEFAULT 0 NOT NULL,
  advance_amount NUMERIC(10,2) DEFAULT 0 NOT NULL,
  notes TEXT,
  status TEXT DEFAULT 'draft' NOT NULL,
  bill_image TEXT,
  receipt_image TEXT,
  owner_comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_trips_driver_id ON public.trips(driver_id);
CREATE INDEX idx_trips_status ON public.trips(status);

-- Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;

-- Helper function to check if current user is owner (bypasses RLS to prevent infinite recursion)
CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'owner'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Users policies
CREATE POLICY "Users can view their own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Owners can view all users" ON public.users
  FOR SELECT USING ( public.is_owner() );

CREATE POLICY "Users can update their own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Trips policies
CREATE POLICY "Drivers can view their own trips" ON public.trips
  FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can create trips" ON public.trips
  FOR INSERT WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "Drivers can update their own draft trips" ON public.trips
  FOR UPDATE USING (auth.uid() = driver_id AND status = 'draft');

CREATE POLICY "Drivers can delete their own draft trips" ON public.trips
  FOR DELETE USING (auth.uid() = driver_id AND status = 'draft');

CREATE POLICY "Owners can manage all trips" ON public.trips
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'owner'
    )
  );

-- Storage bucket for trip images (bills, receipts)
INSERT INTO storage.buckets (id, name, public) VALUES ('trip_images', 'trip_images', true);

CREATE POLICY "Public Access to trip_images" ON storage.objects
  FOR SELECT USING (bucket_id = 'trip_images');

CREATE POLICY "Authenticated users can upload to trip_images" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'trip_images' AND auth.role() = 'authenticated');

-- Salaries table
CREATE TABLE public.salaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  total_salary NUMERIC(10,2) DEFAULT 0 NOT NULL,
  paid_amount NUMERIC(10,2) DEFAULT 0 NOT NULL,
  advance_amount NUMERIC(10,2) DEFAULT 0 NOT NULL,
  remaining_balance NUMERIC(10,2),
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Index
CREATE INDEX idx_salaries_driver_id ON public.salaries(driver_id);

-- Row Level Security for Salaries
ALTER TABLE public.salaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can manage all salaries" ON public.salaries
  FOR ALL USING ( public.is_owner() );

CREATE POLICY "Drivers can view their own salaries" ON public.salaries
  FOR SELECT USING (auth.uid() = driver_id);

