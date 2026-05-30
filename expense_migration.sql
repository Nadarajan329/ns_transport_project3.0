-- Migration Script: Update Trip Expenses

-- 1. Drop the trigger and function that depend on old columns
DROP TRIGGER IF EXISTS trg_deduct_trip_expenses ON public.trips;
DROP FUNCTION IF EXISTS fn_deduct_trip_expenses();

-- 2. Drop old columns permanently
ALTER TABLE public.trips 
  DROP COLUMN IF EXISTS fuel_expense,
  DROP COLUMN IF EXISTS toll_expense,
  DROP COLUMN IF EXISTS food_expense;

-- 3. Add new columns
ALTER TABLE public.trips
  ADD COLUMN IF NOT EXISTS loading_expense NUMERIC DEFAULT 0 NOT NULL,
  ADD COLUMN IF NOT EXISTS unloading_expense NUMERIC DEFAULT 0 NOT NULL,
  ADD COLUMN IF NOT EXISTS other_expense_details JSONB DEFAULT '[]'::jsonb;

-- 4. Recreate the function using the new columns
CREATE OR REPLACE FUNCTION fn_deduct_trip_expenses()
RETURNS TRIGGER AS $$
DECLARE
  total_expense NUMERIC(10,2);
  old_expense NUMERIC(10,2);
  expense_diff NUMERIC(10,2);
BEGIN
  IF TG_OP = 'INSERT' THEN
    total_expense := COALESCE(NEW.loading_expense, 0) + COALESCE(NEW.unloading_expense, 0) + COALESCE(NEW.other_expense, 0);
    
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
    old_expense := COALESCE(OLD.loading_expense, 0) + COALESCE(OLD.unloading_expense, 0) + COALESCE(OLD.other_expense, 0);
    total_expense := COALESCE(NEW.loading_expense, 0) + COALESCE(NEW.unloading_expense, 0) + COALESCE(NEW.other_expense, 0);
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

-- 5. Recreate the trigger
CREATE TRIGGER trg_deduct_trip_expenses
AFTER INSERT OR UPDATE OF loading_expense, unloading_expense, other_expense
ON public.trips
FOR EACH ROW
EXECUTE FUNCTION fn_deduct_trip_expenses();
