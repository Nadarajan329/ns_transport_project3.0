-- Migration Script: Support multiple images for bills and receipts

-- 1. Add the new array columns
ALTER TABLE public.trips 
  ADD COLUMN bill_images TEXT[] DEFAULT '{}',
  ADD COLUMN receipt_images TEXT[] DEFAULT '{}';

-- 2. Migrate existing data from old columns to new columns
UPDATE public.trips 
SET bill_images = ARRAY[bill_image] 
WHERE bill_image IS NOT NULL AND bill_image != '';

UPDATE public.trips 
SET receipt_images = ARRAY[receipt_image] 
WHERE receipt_image IS NOT NULL AND receipt_image != '';

-- 3. Drop the old columns
ALTER TABLE public.trips 
  DROP COLUMN bill_image,
  DROP COLUMN receipt_image;
