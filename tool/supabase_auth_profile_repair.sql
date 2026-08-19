BEGIN;

ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS username TEXT,
  ADD COLUMN IF NOT EXISTS display_name TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT,
  ADD COLUMN IF NOT EXISTS mission_statement TEXT,
  ADD COLUMN IF NOT EXISTS is_pro BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS subscription_tier TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now());

UPDATE public.user_profiles
SET display_name = 'ASR Member'
WHERE display_name IS NULL;

ALTER TABLE public.user_profiles
  ALTER COLUMN display_name SET DEFAULT 'ASR Member',
  ALTER COLUMN display_name SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_username_key
  ON public.user_profiles (username);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  raw_name TEXT;
  derived_username TEXT;
BEGIN
  raw_name := COALESCE(
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'full_name',
    split_part(NEW.email, '@', 1),
    'ASR Member'
  );
  derived_username := LOWER(
    REGEXP_REPLACE(
      COALESCE(split_part(NEW.email, '@', 1), 'user'),
      '[^a-zA-Z0-9_]',
      '_',
      'g'
    )
  ) || '_' || SUBSTRING(NEW.id::text, 1, 8);

  INSERT INTO public.user_profiles (
    id,
    username,
    display_name,
    avatar_url,
    is_pro,
    updated_at
  )
  VALUES (
    NEW.id,
    derived_username,
    raw_name,
    NEW.raw_user_meta_data->>'avatar_url',
    false,
    timezone('utc'::text, now())
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

COMMIT;
