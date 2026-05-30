-- Fix RLS policy to allow drivers to submit their draft trips
DROP POLICY IF EXISTS "Drivers can update their own draft trips" ON public.trips;

CREATE POLICY "Drivers can update their own draft trips" ON public.trips
  FOR UPDATE 
  USING (auth.uid() = driver_id AND status = 'draft')
  WITH CHECK (auth.uid() = driver_id AND status IN ('draft', 'submitted'));
