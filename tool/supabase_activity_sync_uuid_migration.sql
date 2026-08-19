-- Выполнить один раз в Supabase SQL Editor перед выпуском версии приложения,
-- которая синхронизирует activity_entries по sync_id.
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE public.activity_entries
  ADD COLUMN IF NOT EXISTS sync_id UUID;

UPDATE public.activity_entries
SET sync_id = gen_random_uuid()
WHERE sync_id IS NULL;

ALTER TABLE public.activity_entries
  ALTER COLUMN sync_id SET DEFAULT gen_random_uuid(),
  ALTER COLUMN sync_id SET NOT NULL;

ALTER TABLE public.activity_entries
  DROP CONSTRAINT IF EXISTS activity_entries_pkey;

ALTER TABLE public.activity_entries
  ADD CONSTRAINT activity_entries_pkey PRIMARY KEY (user_id, sync_id);

CREATE INDEX IF NOT EXISTS activity_entries_user_legacy_id_idx
  ON public.activity_entries (user_id, id);

COMMIT;
