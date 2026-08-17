-- ========================================================
-- ASR App: Supabase PostgreSQL Schema & RLS Policies
-- Выполните этот скрипт в Supabase Dashboard -> SQL Editor
-- ========================================================

-- 1. Таблица профилей пользователей (готовая к RevenueCat и ASR PRO)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'User',
    avatar_url TEXT,
    mission_statement TEXT,
    is_pro BOOLEAN NOT NULL DEFAULT false,
    subscription_tier TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);


-- 2. Таблица логов фокуса (завершенных активностей)
CREATE TABLE IF NOT EXISTS public.activity_entries (
    id BIGINT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category_key TEXT NOT NULL,
    started_at BIGINT NOT NULL,
    ended_at BIGINT NOT NULL,
    duration_seconds BIGINT NOT NULL,
    date_key TEXT NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    mood TEXT,
    obstacles TEXT[],
    next_experiment TEXT,
    note TEXT,
    photo_urls TEXT[],
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id, user_id)
);

-- 3. Таблица целей
CREATE TABLE IF NOT EXISTS public.goals (
    id BIGINT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_key TEXT NOT NULL,
    activity_name TEXT,
    target_seconds BIGINT NOT NULL DEFAULT 0,
    period_type TEXT NOT NULL DEFAULT 'month',
    created_at BIGINT NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (id, user_id)
);


-- 4. Включение Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;

-- 5. Политики RLS (каждый пользователь видит и редактирует только свои данные)
DROP POLICY IF EXISTS "User profiles access policy" ON public.user_profiles;
CREATE POLICY "User profiles access policy" ON public.user_profiles
    FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Activity entries access policy" ON public.activity_entries;
CREATE POLICY "Activity entries access policy" ON public.activity_entries
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Goals access policy" ON public.goals;
CREATE POLICY "Goals access policy" ON public.goals
    FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 6. Создание приватного бакета для фото
INSERT INTO storage.buckets (id, name, public)
VALUES ('activity_photos', 'activity_photos', false)
ON CONFLICT (id) DO NOTHING;

-- 7. RLS для бакета хранилища фото (файлы хранятся в папке {user_id}/filename)
DROP POLICY IF EXISTS "Storage Insert Policy" ON storage.objects;
CREATE POLICY "Storage Insert Policy" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'activity_photos' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Storage Select Policy" ON storage.objects;
CREATE POLICY "Storage Select Policy" ON storage.objects
    FOR SELECT USING (bucket_id = 'activity_photos' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Storage Update Policy" ON storage.objects;
CREATE POLICY "Storage Update Policy" ON storage.objects
    FOR UPDATE USING (bucket_id = 'activity_photos' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "Storage Delete Policy" ON storage.objects;
CREATE POLICY "Storage Delete Policy" ON storage.objects
    FOR DELETE USING (bucket_id = 'activity_photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 8. Индексы высокой производительности для работы с миллионами записей
CREATE INDEX IF NOT EXISTS idx_activity_entries_user_started 
    ON public.activity_entries (user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_activity_entries_user_date 
    ON public.activity_entries (user_id, date_key);

CREATE INDEX IF NOT EXISTS idx_goals_user_id 
    ON public.goals (user_id);

-- 9. Функция полного удаления аккаунта пользователя (App Store & GDPR Compliant)
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void AS $$
DECLARE
    _user_id UUID := auth.uid();
BEGIN
    IF _user_id IS NULL THEN
        RAISE EXCEPTION 'Пользователь не авторизован';
    END IF;

    -- Удаление фото пользователя из приватного бакета Storage
    DELETE FROM storage.objects 
    WHERE bucket_id = 'activity_photos' 
      AND (storage.foldername(name))[1] = _user_id::text;

    -- Удаление данных из таблиц приложения
    DELETE FROM public.activity_entries WHERE user_id = _user_id;
    DELETE FROM public.goals WHERE user_id = _user_id;
    DELETE FROM public.user_profiles WHERE id = _user_id;

    -- Полное удаление аккаунта пользователя из auth.users
    DELETE FROM auth.users WHERE id = _user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

