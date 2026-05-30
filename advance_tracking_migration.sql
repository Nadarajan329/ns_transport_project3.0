-- SQL Migration for Advance Tracking and Expense Deduction System

-- 1. Add advance_balance to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS advance_balance NUMERIC(10,2) DEFAULT 0;

-- 2. Create advance_history table
CREATE TABLE IF NOT EXISTS public.advance_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('given_by_owner', 'deducted_for_expense', 'expense_adjustment')),
  description TEXT,
  trip_id UUID REFERENCES public.trips(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_advance_history_driver_id ON public.advance_history(driver_id);
CREATE INDEX IF NOT EXISTS idx_advance_history_trip_id ON public.advance_history(trip_id);

-- 4. Enable RLS
ALTER TABLE public.advance_history ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for advance_history
CREATE POLICY "Drivers can view their own advance history" ON public.advance_history
  FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Owners can manage all advance history" ON public.advance_history
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'owner'
    )
  );

-- 6. Trigger to automatically deduct trip expenses from advance_balance

-- Drop existing trigger and function if they exist to allow re-running this script
DROP TRIGGER IF EXISTS trg_deduct_trip_expenses ON public.trips;
DROP FUNCTION IF EXISTS fn_deduct_trip_expenses();

CREATE OR REPLACE FUNCTION fn_deduct_trip_expenses()
RETURNS TRIGGER AS $$
DECLARE
  total_expense NUMERIC(10,2);
  old_expense NUMERIC(10,2);
  expense_diff NUMERIC(10,2);
BEGIN
  IF TG_OP = 'INSERT' THEN
    total_expense := COALESCE(NEW.fuel_expense, 0) + COALESCE(NEW.toll_expense, 0) + COALESCE(NEW.food_expense, 0) + COALESCE(NEW.other_expense, 0);
    
    IF total_expense > 0 THEN
      -- Deduct from advance_balance
      UPDATE public.users 
      SET advance_balance = advance_balance - total_expense 
      WHERE id = NEW.driver_id;

      -- Insert into advance_history
      INSERT INTO public.advance_history (driver_id, amount, type, description, trip_id)
      VALUES (NEW.driver_id, total_expense, 'deducted_for_expense', 'Trip expenses deduction', NEW.id);
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    old_expense := COALESCE(OLD.fuel_expense, 0) + COALESCE(OLD.toll_expense, 0) + COALESCE(OLD.food_expense, 0) + COALESCE(OLD.other_expense, 0);
    total_expense := COALESCE(NEW.fuel_expense, 0) + COALESCE(NEW.toll_expense, 0) + COALESCE(NEW.food_expense, 0) + COALESCE(NEW.other_expense, 0);
    expense_diff := total_expense - old_expense;

    IF expense_diff != 0 THEN
      -- Deduct the difference from advance_balance
      UPDATE public.users 
      SET advance_balance = advance_balance - expense_diff 
      WHERE id = NEW.driver_id;

      -- Update the existing advance_history record for this trip, or insert a new one if it doesn't exist
      IF EXISTS (SELECT 1 FROM public.advance_history WHERE trip_id = NEW.id AND type = 'deducted_for_expense') THEN
        UPDATE public.advance_history 
        SET amount = total_expense 
        WHERE trip_id = NEW.id AND type = 'deducted_for_expense';
      ELSE
        INSERT INTO public.advance_history (driver_id, amount, type, description, trip_id)
        VALUES (NEW.driver_id, total_expense, 'deducted_for_expense', 'Trip expenses deduction', NEW.id);
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_deduct_trip_expenses
AFTER INSERT OR UPDATE OF fuel_expense, toll_expense, food_expense, other_expense
ON public.trips
FOR EACH ROW
EXECUTE FUNCTION fn_deduct_trip_expenses();
