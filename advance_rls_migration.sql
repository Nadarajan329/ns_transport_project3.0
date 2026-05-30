-- Drop them first if they exist to avoid errors
DROP POLICY IF EXISTS "Drivers can insert their own advances" ON public.advance_history;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;

-- 1. Allow drivers to insert their own advance requests
CREATE POLICY "Drivers can insert their own advances" 
ON public.advance_history 
FOR INSERT 
WITH CHECK (driver_id = auth.uid());

-- 2. Allow drivers to update their own user profile (needed to update advance_balance)
CREATE POLICY "Users can update their own profile"
ON public.users
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());
